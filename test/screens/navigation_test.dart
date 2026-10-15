import 'package:busy_network/app/routes.dart';
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

void main() {
  setUpFonts();

  setUp(() {});

  testWidgets('alur utama: Beranda → Peta → Rancang → Jalan → Antrean → '
      'Jalan → Gagal → Coba Lagi', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Level 5, Gang Melati')));
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);

    await tester.tap(find.text('Mulai Hari'));
    await tester.pumpAndSettle();
    expect(find.byType(RunPhaseScreen), findsOneWidget);

    await tester.tap(find.text('Atur antrean'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanelScreen), findsOneWidget);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.byType(RunPhaseScreen), findsOneWidget);

    await tester.tap(find.text('Abaikan'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultFailScreen), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
  });

  testWidgets('percepat → hasil berhasil → level berikutnya → peta', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.run);

    await tester.tap(find.bySemanticsLabel('Percepat ke akhir hari'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultSuccessScreen), findsOneWidget);
    expect(find.text('Hari beres!'), findsOneWidget);

    await tester.tap(find.text('Level Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);
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
