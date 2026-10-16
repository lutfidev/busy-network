import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:busy_network/screens/design_phase/design_phase_screen.dart';
import 'package:busy_network/screens/level_map/level_map_screen.dart';
import 'package:busy_network/screens/result_success/result_success_screen.dart';
import 'package:busy_network/screens/run_phase/run_phase_screen.dart';
import 'package:busy_network/screens/tutorial/tutorial_overlay.dart';
import 'package:busy_network/screens/tutorial/tutorial_screen.dart';
import 'package:busy_network/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

/// Jari dari router ke Rumah 1 (lurus miring, 4 segmen) / Rumah 2
/// (koordinat peta level 1). Titik antara di titik grid supaya jalurnya sama
/// di skala peta mana pun.
const _toHouse1 = [Offset(105, 315), Offset(165, 255), Offset(255, 165)];
const _toHouse2 = [Offset(105, 315), Offset(210, 330), Offset(315, 345)];

String _step(int n) => '${AppRoutes.tutorial}?${AppRoutes.stepParam}=$n';

GameSession _session(MemoryProgressStore store) =>
    GameSession(progress: ProgressBook(store));

void main() {
  setUpFonts();

  testWidgets('langkah 2 menunggu tarikan Router → Rumah 1, lalu langkah 3', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.tutorial);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('TUTORIAL · 2 DARI 3'), findsOneWidget);
    expect(find.text('Udah, lanjut'), findsNothing);

    await dragOnMap(tester, _toHouse1);
    expect(find.text('TUTORIAL · 3 DARI 3'), findsOneWidget);
    expect(find.text('Mantap, Rumah 1 nyala!'), findsOneWidget);
    expect(find.text('1/2 rumah tersambung'), findsOneWidget);
    expect(find.text('Rp 140.000'), findsOneWidget);
  });

  testWidgets('langkah 2: ke Rumah 2 tidak tersambung', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: _step(2));
    await dragOnMap(tester, _toHouse2);
    expect(find.text('Tarik kabel ke rumah'), findsOneWidget);
    expect(find.text('0/2 rumah tersambung'), findsOneWidget);
    expect(find.text('Rp 200.000'), findsOneWidget);
  });

  testWidgets('langkah 2: tangan hilang selama jari menarik', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: _step(2));
    expect(find.byType(TutorialHand), findsOneWidget);
    final gesture = await dragOnMap(
      tester,
      _toHouse1.take(2).toList(),
      release: false,
    );
    expect(find.byType(TutorialHand), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialHand), findsOneWidget);
    expect(find.text('Tarik kabel ke rumah'), findsOneWidget);
  });

  testWidgets('scrim menahan sentuhan di luar sorotan', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.tutorial);
    await tester.tap(
      find.bySemanticsLabel('Kembali ke peta'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsOneWidget);
    expect(find.byType(LevelMapScreen), findsNothing);
  });

  testWidgets('langkah 1: peta diam, Mulai Hari tertahan', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.tutorial);
    await dragOnMap(tester, _toHouse1);
    expect(find.text('0/2 rumah tersambung'), findsOneWidget);

    await tester.tap(find.text('Mulai Hari'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(RunPhaseScreen), findsNothing);

    // Aktivasi tanpa uji sentuh (mis. pembaca layar) juga ditahan.
    tester
        .widget<ChunkyButton>(find.widgetWithText(ChunkyButton, 'Mulai Hari'))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(RunPhaseScreen), findsNothing);
    expect(find.text('TUTORIAL · 1 DARI 3'), findsOneWidget);
  });

  testWidgets('Peta → tutorial → Mulai Hari → hari level 1 → 1 bintang', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final store = MemoryProgressStore(Progress(const {}));
    final session = _session(store);
    await pumpApp(tester, location: AppRoutes.levelMap, session: session);
    await tester.tap(find.bySemanticsLabel(RegExp('^Level 1,')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await dragOnMap(tester, _toHouse1);
    expect(find.text('Rp 140.000'), findsOneWidget);

    await tester.tap(find.text('Mulai Hari'));
    await playFor(tester, 1);
    expect(find.byType(RunPhaseScreen), findsOneWidget);
    expect(session.last?.level.number, 1);
    expect(store.load()!.tutorialDone, isTrue);

    await tester.pumpAndSettle();
    expect(find.byType(ResultSuccessScreen), findsOneWidget);
    expect(find.text('LEVEL 1 · RUMAH PERTAMA'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Rp 140.000'), findsOneWidget);
    expect(session.progress.progress.starsOf(1), 1);
    expect(store.load()!.starsOf(1), 1);
  });

  testWidgets('back dari hari tutorial → Fase Rancang level 1', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: _step(2));
    await dragOnMap(tester, _toHouse1);
    await tester.tap(find.text('Mulai Hari'));
    await playFor(tester, 1);
    expect(find.byType(RunPhaseScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
    expect(find.text('Rumah Pertama'), findsOneWidget);
  });

  testWidgets('Lewati menandai selesai; Level 1 lalu membuka Fase Rancang', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final store = MemoryProgressStore();
    await pumpApp(
      tester,
      location: AppRoutes.tutorial,
      session: _session(store),
    );
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);
    expect(store.load()!.tutorialDone, isTrue);
    expect(store.load()!.totalStars, 0, reason: 'bintang tidak berubah');

    await tester.tap(
      find.bySemanticsLabel('Level 1, Rumah Pertama, main sekarang'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
  });

  testWidgets('tutorial selesai tetap tersimpan saat aplikasi dibuka ulang', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final store = MemoryProgressStore();
    await pumpApp(
      tester,
      location: AppRoutes.tutorial,
      session: _session(store),
    );
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    // Tutup aplikasi (State & router lama dibuang), lalu buka lagi.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(
      tester,
      location: AppRoutes.levelMap,
      session: _session(store),
    );
    await tester.tap(
      find.bySemanticsLabel('Level 1, Rumah Pertama, main sekarang'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
    expect(find.byType(TutorialScreen), findsNothing);
  });
}
