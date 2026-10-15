import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/screens/design_phase/design_phase_screen.dart';
import 'package:busy_network/screens/home/home_screen.dart';
import 'package:busy_network/screens/level_map/level_map_screen.dart';
import 'package:busy_network/screens/queue_panel/queue_panel_screen.dart';
import 'package:busy_network/screens/result_fail/result_fail_screen.dart';
import 'package:busy_network/screens/result_success/result_success_screen.dart';
import 'package:busy_network/screens/run_phase/run_phase_screen.dart';
import 'package:busy_network/screens/tutorial/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';
import 'run_fixtures.dart';

void main() {
  setUpFonts();

  setUp(() {});

  testWidgets('alur utama: Beranda → Peta → Rancang → Jalan → Antrean → '
      'Jalan → hari habis → Gagal → Coba Lagi', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Level 5, Gang Melati')));
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);

    // Hari berjalan tidak pernah settle: pompa beberapa frame saja.
    await tester.tap(find.text('Mulai Hari'));
    await playFor(tester, 1);
    expect(find.byType(RunPhaseScreen), findsOneWidget);
    // Rancangan awal: 4 dari 7 rumah tersambung → kepuasan 57%.
    expect(find.text('57% / target 80%'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Jeda dan atur antrean'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanelScreen), findsOneWidget);

    await tester.tap(find.text('Lanjutkan'));
    await playFor(tester, 1);
    expect(find.byType(RunPhaseScreen), findsOneWidget);

    // Sisa hari berjalan sampai 24:00; 57% < target 80% → gagal.
    await tester.pumpAndSettle();
    expect(find.byType(ResultFailScreen), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
    expect(find.text('4/7 rumah tersambung'), findsOneWidget);
  });

  testWidgets('percepat → hasil berhasil → level berikutnya → peta', (
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
    expect(find.text('23:00'), findsOneWidget);

    final fast = find.bySemanticsLabel('Percepat ke akhir hari');
    expect(tester.getSemantics(fast), isSemantics(isToggled: false));
    await tester.tap(fast);
    await tester.pump();
    expect(tester.getSemantics(fast), isSemantics(isToggled: true));

    await tester.pumpAndSettle();
    expect(find.byType(ResultSuccessScreen), findsOneWidget);
    expect(find.text('Hari beres!'), findsOneWidget);
    expect(session.last!.phase, GamePhase.result);

    await tester.tap(find.text('Level Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('tombol jeda membuka panel antrean', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.run);
    await tester.tap(find.bySemanticsLabel('Jeda dan atur antrean'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanelScreen), findsOneWidget);
  });

  testWidgets('level 1 membuka tutorial; 3 langkah lalu Mulai Hari', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.levelMap);

    await tester.tap(find.bySemanticsLabel(RegExp('^Level 1,')));
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsOneWidget);
    expect(find.text('TUTORIAL · 1 DARI 3'), findsOneWidget);
    expect(find.text('0/2 rumah tersambung'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Tarik kabel ke rumah'), findsOneWidget);

    await tester.tap(find.text('Udah, lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Mantap, Rumah 1 nyala!'), findsOneWidget);
    expect(find.text('1/2 rumah tersambung'), findsOneWidget);

    await tester.tap(find.text('Mulai Hari'));
    await tester.pumpAndSettle();
    expect(find.byType(RunPhaseScreen), findsOneWidget);
  });

  testWidgets('Lewati di tutorial kembali ke peta', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.tutorial);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);
  });

  testWidgets('level terkunci tidak bisa dibuka', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.levelMap);
    await tester.tap(find.bySemanticsLabel('Level 6 terkunci'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);
  });

  testWidgets('tombol kembali & Balik ke peta', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.fail);
    await tester.tap(find.text('Balik ke peta'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Kembali ke Beranda'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('tombol back Android mengikuti rute bersarang', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.queue);
    expect(find.byType(QueuePanelScreen), findsOneWidget);

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.byType(RunPhaseScreen), findsOneWidget);
  });
}
