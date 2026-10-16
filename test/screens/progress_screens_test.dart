import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:busy_network/game/sim/sim.dart';
import 'package:busy_network/screens/design_phase/design_phase_screen.dart';
import 'package:busy_network/screens/level_map/level_map_screen.dart';
import 'package:busy_network/screens/queue_panel/queue_panel_screen.dart';
import 'package:busy_network/screens/run_phase/run_phase_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../game/sim/sim_fixtures.dart';
import '../test_helpers.dart';
import 'run_fixtures.dart';

GameSession _with(Progress progress) =>
    GameSession(progress: ProgressBook(MemoryProgressStore(progress)));

void main() {
  setUpFonts();

  testWidgets('Peta: level 5 selesai, level 6 sekarang tapi belum tersedia', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      location: AppRoutes.levelMap,
      session: _with(Progress(const {1: 3, 2: 2, 3: 3, 4: 1, 5: 3})),
    );
    expect(
      find.bySemanticsLabel('Bintang terkumpul 12 dari 36'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Level 5, 3 bintang'), findsOneWidget);
    expect(find.text('Gang Melati'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Level 6, belum tersedia'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);
    expect(find.byType(DesignPhaseScreen), findsNothing);
    semantics.dispose();
  });

  testWidgets('Beranda membaca progres', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      session: _with(Progress(const {1: 3, 2: 2, 3: 3, 4: 1, 5: 3})),
    );
    expect(find.text('5 / 12 level'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Bintang terkumpul 12 dari 36'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('menang level 5 → Level Berikutnya → peta berubah', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    final session = GameSession()..begin(winningDay(minute: 23 * 60));
    await pumpApp(
      tester,
      location: AppRoutes.run,
      session: session,
      settle: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Level Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Level 5, 3 bintang'), findsOneWidget);
    expect(find.bySemanticsLabel('Level 6, belum tersedia'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Bintang terkumpul 12 dari 36'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('progres bertahan saat aplikasi dibuka ulang', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    final store = MemoryProgressStore();
    final first = GameSession(progress: ProgressBook(store));
    final day = winningDay(minute: SimClock.dayStart);
    first.begin(day);
    playDay(day);
    first.finish();
    await pumpApp(
      tester,
      location: AppRoutes.levelMap,
      session: GameSession(progress: ProgressBook(store)),
    );
    expect(find.bySemanticsLabel('Level 5, 3 bintang'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('semua level 1–11 selesai: peta tetap tampil', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      location: AppRoutes.levelMap,
      session: _with(Progress({for (var n = 1; n <= 11; n++) n: 1})),
    );
    expect(find.bySemanticsLabel('Level 11, 1 bintang'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('main sekarang|belum tersedia')),
      findsNothing,
    );
    semantics.dispose();
  });

  group('tutorial selesai', () {
    final done = Progress(const {1: 3, 2: 2, 3: 3, 4: 1}).completeTutorial();

    String location(WidgetTester tester, Type screen) =>
        GoRouter.of(tester.element(find.byType(screen)))
            .routerDelegate
            .currentConfiguration
            .uri
            .toString();

    testWidgets('label Level 1 menyebut tutorial hanya sebelum selesai', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, location: AppRoutes.levelMap);
      expect(find.bySemanticsLabel('Level 1, 3 bintang, tutorial'), findsOne);
      semantics.dispose();
    });

    testWidgets('Level 1 membuka Fase Rancang level 1', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, location: AppRoutes.levelMap, session: _with(done));
      await tester.tap(find.bySemanticsLabel('Level 1, 3 bintang'));
      await tester.pumpAndSettle();
      expect(find.byType(DesignPhaseScreen), findsOneWidget);
      expect(find.text('Rumah Pertama'), findsOneWidget);
      expect(find.text('Jam sibuk 19–22'), findsOneWidget);
      expect(find.text('Terbuka di level 3'), findsOneWidget);
      expect(find.text('Rp 200.000'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('hari level 1: rute Fase Jalan & Panel Antrean ber-level', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(
        tester,
        location: AppRoutes.play(1, tutorialDone: true),
        session: _with(done),
      );
      await dragOnMap(tester, const [
        Offset(105, 315),
        Offset(165, 255),
        Offset(255, 165),
      ]);
      expect(find.text('1/2 rumah tersambung'), findsOneWidget);
      await tester.tap(find.text('Mulai Hari'));
      await playFor(tester, 1);
      expect(location(tester, RunPhaseScreen), AppRoutes.runOf(1));

      await tester.tap(find.bySemanticsLabel('Jeda dan atur antrean'));
      await tester.pumpAndSettle();
      expect(location(tester, QueuePanelScreen), AppRoutes.queueOf(1));

      await tester.tap(find.text('Lanjutkan'));
      await playFor(tester, 1);
      expect(location(tester, RunPhaseScreen), AppRoutes.runOf(1));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Rumah Pertama'), findsOneWidget);
      expect(find.text('1/2 rumah tersambung'), findsOneWidget);
    });
  });
}
