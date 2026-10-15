import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/core/format.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/screens/design_phase/design_phase_screen.dart';
import 'package:busy_network/screens/queue_panel/queue_panel_screen.dart';
import 'package:busy_network/screens/run_phase/run_phase_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';
import 'run_fixtures.dart';

void main() {
  setUpFonts();

  group('bingkai desain (deep link)', () {
    testWidgets('20:15 jam sibuk, kepuasan 62%, komplain Bu Sri', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.run);
      expect(find.text('20:15'), findsOneWidget);
      expect(find.text('JAM SIBUK'), findsOneWidget);
      expect(find.text('62% / target 80%'), findsOneWidget);
      expect(find.text('Bu Sri – Rumah 4'), findsOneWidget);
      expect(find.text('Komplain baru · 20:14'), findsOneWidget);
      expect(
        find.text('Bang, kok lemot?? Anak saya lagi ujian online!'),
        findsOneWidget,
      );
    });

    testWidgets('komplain menjeda hari; Abaikan → jam jalan lagi', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      final session = GameSession();
      await pumpApp(tester, location: AppRoutes.run, session: session);
      final day = session.currentDay().day!;
      await playFor(tester, 2);
      expect(day.minute, 20 * 60 + 15);

      await tester.tap(find.text('Abaikan'));
      await tester.pump();
      expect(find.text('Bu Sri – Rumah 4'), findsNothing);
      // 1 detik = 12 menit permainan.
      await playFor(tester, 1);
      expect(day.minute, closeTo(20 * 60 + 27, 1));
      expect(find.text(IdFormat.clock(day.minute)), findsOneWidget);
    });

    testWidgets('percepat: 1 detik = 48 menit permainan', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      final session = GameSession();
      await pumpApp(tester, location: AppRoutes.run, session: session);
      final day = session.currentDay().day!;
      await tester.tap(find.text('Abaikan'));
      await tester.tap(find.bySemanticsLabel('Percepat ke akhir hari'));
      await tester.pump();
      await playFor(tester, 1);
      expect(day.minute, closeTo(20 * 60 + 15 + 48, 1));
    });
  });

  group('panel antrean', () {
    testWidgets('Atur antrean menjawab komplain dan membuka panel', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      final session = GameSession();
      await pumpApp(tester, location: AppRoutes.run, session: session);
      await tester.tap(find.text('Atur antrean'));
      await tester.pumpAndSettle();
      expect(find.byType(QueuePanelScreen), findsOneWidget);
      expect(session.currentDay().day!.complaint, isNull);
      expect(find.text('20:15'), findsOneWidget);
    });

    testWidgets('Terapkan menyimpan prioritas ke hari; Lanjutkan kembali', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      final session = GameSession();
      await pumpApp(tester, location: AppRoutes.queue, session: session);
      final day = session.currentDay().day!;
      expect(day.priority, {'w'});

      await tester.tap(find.bySemanticsLabel('Prioritaskan Bu Sri'));
      await tester.pump();
      expect(day.priority, {'w'}, reason: 'belum diterapkan');
      await tester.tap(find.text('Terapkan'));
      await tester.pump();
      expect(day.priority, {'w', 'r4'});
      expect(find.text('Tersimpan'), findsOneWidget);

      // Bu Sri dilayani dulu: tidak macet lagi di peta.
      expect(day.frame.houses['r4']!.state, isNot(HouseState.jam));

      await tester.tap(find.text('Lanjutkan'));
      await playFor(tester, 1);
      expect(find.byType(RunPhaseScreen), findsOneWidget);
      expect(day.complaint, isNull);
      expect(day.minute, greaterThan(20 * 60 + 15));
    });

    testWidgets('Lanjutkan tanpa Terapkan tetap menyimpan', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      final session = GameSession();
      await pumpApp(tester, location: AppRoutes.queue, session: session);
      await tester.tap(find.bySemanticsLabel('Prioritaskan Pak Rudi'));
      await tester.tap(find.text('Lanjutkan'));
      await tester.pump();
      expect(session.currentDay().day!.priority, {'w', 'r5'});
    });
  });

  testWidgets('jeda: jam berhenti begitu panel mulai meluncur masuk', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final session = GameSession()..begin(winningDay(minute: 12 * 60));
    final day = session.last!.day!;
    await pumpApp(
      tester,
      location: AppRoutes.run,
      session: session,
      settle: false,
    );
    await playFor(tester, 0.5);
    final paused = day.minute;
    expect(paused, greaterThan(12 * 60));

    await tester.tap(find.bySemanticsLabel('Jeda dan atur antrean'));
    await playFor(tester, 0.2); // panel masih meluncur
    expect(day.minute, paused);
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanelScreen), findsOneWidget);
    expect(day.minute, paused);
    expect(find.text(IdFormat.clock(paused)), findsOneWidget);

    await tester.tap(find.text('Lanjutkan'));
    await playFor(tester, 1);
    expect(day.minute, greaterThan(paused));
  });

  testWidgets('Mulai Hari diketuk dua kali: tetap satu hari', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final session = GameSession();
    await pumpApp(tester, location: AppRoutes.design, session: session);
    final button = find.text('Mulai Hari', skipOffstage: false);
    await tester.tap(button);
    final first = session.last;
    // Ketukan kedua di frame yang sama, ketiga saat rute Jalan masih
    // meluncur masuk (animasi mati: transisi dipercepat 20×).
    await tester.tap(button, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 5));
    await tester.tap(button, warnIfMissed: false);
    await playFor(tester, 0.5);
    expect(session.last, same(first));
    expect(find.byType(RunPhaseScreen), findsOneWidget);
  });

  testWidgets('back ke Fase Rancang membatalkan hari', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final session = GameSession()..begin(winningDay(minute: 12 * 60));
    final day = session.last!;
    await pumpApp(
      tester,
      location: AppRoutes.run,
      session: session,
      settle: false,
    );
    await playFor(tester, 0.5);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
    expect(session.last, isNull);
    expect(day.phase, GamePhase.run, reason: 'hari ditinggal, tidak selesai');
  });

  testWidgets('Mulai Hari memakai rancangan; rancangan tetap utuh', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final session = GameSession();
    await pumpApp(tester, location: AppRoutes.design, session: session);
    await tester.tap(find.text('Mulai Hari'));
    await playFor(tester, 0.5);
    final day = session.last!;
    expect(day.phase, GamePhase.run);
    expect(day.connectedCount, 4);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('4/7 rumah tersambung'), findsOneWidget);
    expect(find.text('Rp 850.000'), findsOneWidget);
  });
}
