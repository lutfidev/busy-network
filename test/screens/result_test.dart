import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:busy_network/screens/design_phase/design_phase_screen.dart';
import 'package:busy_network/screens/level_map/level_map_screen.dart';
import 'package:busy_network/screens/tutorial/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/sim/sim_fixtures.dart';
import '../game/levels/level_plans.dart';
import '../test_helpers.dart';

/// Sesi dengan [game] yang sudah dimainkan sampai 24:00 dan ditutup.
GameSession _finished(GameState game) {
  final session = GameSession()..begin(game);
  playDay(game);
  session.finish();
  return session;
}

void main() {
  setUpFonts();

  testWidgets('berhasil 1★ dari hari asli: angka & tips biang kerok', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final session = _finished(designDay(designCables));
    await pumpApp(tester, location: AppRoutes.success, session: session);
    expect(find.text('LEVEL 5 · GANG MELATI'), findsOneWidget);
    expect(find.bySemanticsLabel('Dapat 1 dari 3 bintang'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Rp 850.000'), findsOneWidget);
    expect(find.text('Kepuasan akhir ≥ 80% · kamu 75%'), findsOneWidget);
    expect(
      find.text(
        'Jalur Blok B penuh pas jam sibuk. Coba fiber di kabel utama, atau '
        'batasi jatah sebelum jam 19.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('gagal dari hari asli: kabel Blok B, 4 rumah pindah', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final r5 = designCables.firstWhere((c) => c.id == 'c-r5');
    final session = _finished(designDay([...Levels.level5.cables, r5]));
    await pumpApp(tester, location: AppRoutes.fail, session: session);
    expect(
      find.text(
        'Kepuasan cuma 46%, targetnya 80%. Nggak apa, besok coba lagi.',
      ),
      findsOneWidget,
    );
    expect(find.text('4 rumah'), findsOneWidget);
    expect(
      find.text('Kabel ke Blok B kelebihan beban jam 19:00.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Ganti kabel utamanya ke fiber, atau batasi jatah Bu Sri dan Pak '
        'Rudi sebelum jam sibuk.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('deep link gagal = potret desain', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.fail);
    expect(find.text('41%'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('2 rumah'), findsOneWidget);
    expect(
      find.text('Kabel ke Blok B kelebihan beban jam 20:00.'),
      findsOneWidget,
    );
  });

  testWidgets('Ulangi memulai level dari awal', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final session = _finished(designDay(designCables));
    await pumpApp(tester, location: AppRoutes.success, session: session);
    await tester.tap(find.text('Ulangi'));
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
    expect(find.text('4/7 rumah tersambung'), findsOneWidget);
    expect(find.text('Rp 850.000'), findsOneWidget);
  });

  testWidgets('Level Berikutnya: level 6 → Fase Rancang level 6', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final session = _finished(designDay(designCables));
    await pumpApp(tester, location: AppRoutes.success, session: session);
    await tester.tap(find.text('Level Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
    expect(find.text('Warisan Pak RT'), findsOneWidget);
  });

  group('Level Berikutnya dari level 11', () {
    /// Sesi dengan hari level 11 (rancangan acuan, 3★) yang sudah selesai,
    /// di atas progres [before].
    GameSession level11Done(Progress before) {
      final session = GameSession(
        progress: ProgressBook(MemoryProgressStore(before)),
      );
      final day = design(Levels.level11, referencePlans[11]!).planDay();
      session.begin(day);
      playDay(day);
      session.finish();
      return session;
    }

    testWidgets('bintang < 24 → "Balik ke peta" (bos terkunci)', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      final session = level11Done(
        Progress({for (var n = 1; n <= 10; n++) n: 2}),
      );
      expect(session.progress.progress.starsUpTo(11), 23);
      await pumpApp(tester, location: AppRoutes.success, session: session);
      expect(find.text('Level Berikutnya'), findsNothing);
      await tester.tap(find.text('Balik ke peta'));
      await tester.pumpAndSettle();
      expect(find.byType(LevelMapScreen), findsOneWidget);
    });

    testWidgets('bintang ≥ 24 → Fase Rancang level bos', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      final session = level11Done(
        Progress({for (var n = 1; n <= 10; n++) n: n == 1 ? 3 : 2}),
      );
      expect(session.progress.progress.starsUpTo(11), 24);
      await pumpApp(tester, location: AppRoutes.success, session: session);
      await tester.tap(find.text('Level Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.byType(DesignPhaseScreen), findsOneWidget);
      expect(find.text('Malam Final Sepak Bola'), findsOneWidget);
    });
  });

  test('play: level 1 tutorial sampai selesai, lainnya Fase Rancang', () {
    expect(AppRoutes.play(1, tutorialDone: false), AppRoutes.tutorial);
    expect(AppRoutes.play(1, tutorialDone: true), '/peta/rancang?level=1');
    expect(AppRoutes.play(5, tutorialDone: false), '/peta/rancang?level=5');
  });

  test('rute Fase Jalan & Panel Antrean membawa level', () {
    expect(AppRoutes.runOf(1), '/peta/rancang/jalan?level=1');
    expect(AppRoutes.queueOf(5), '/peta/rancang/jalan/antrean?level=5');
  });

  group('Ulangi level 1', () {
    /// Sesi dengan hari level 1 (Rumah 1 saja) yang sudah selesai.
    GameSession level1Done({required bool tutorialDone}) {
      final progress = ProgressBook(
        MemoryProgressStore(
          tutorialDone ? Progress(const {}).completeTutorial() : null,
        ),
      );
      final game = GameState(
        Levels.level1,
        cables: DummyStates.tutorial(3).cables,
      )..startDay();
      final session = GameSession(progress: progress)..begin(game);
      playDay(game);
      session.finish();
      return session;
    }

    testWidgets('tutorial selesai → Fase Rancang level 1', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      final session = level1Done(tutorialDone: true);
      await pumpApp(tester, location: AppRoutes.success, session: session);
      await tester.tap(find.text('Ulangi'));
      await tester.pumpAndSettle();
      expect(find.byType(DesignPhaseScreen), findsOneWidget);
      expect(find.text('Rumah Pertama'), findsOneWidget);
      expect(find.text('0/2 rumah tersambung'), findsOneWidget);
    });

    testWidgets('tutorial belum selesai → tutorial', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      final session = level1Done(tutorialDone: false);
      await pumpApp(tester, location: AppRoutes.success, session: session);
      await tester.tap(find.text('Ulangi'));
      await tester.pumpAndSettle();
      expect(find.byType(TutorialScreen), findsOneWidget);
    });
  });
}
