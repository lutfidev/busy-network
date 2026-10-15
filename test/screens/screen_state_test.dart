import 'package:busy_network/app/routes.dart';
import 'package:busy_network/game/network_game.dart';
import 'package:flame/game.dart' hide RouterComponent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/design_pull.dart';
import '../test_helpers.dart';

/// Router → Rumah 6, lurus ke bawah: 5 segmen.
const _toHouse6 = [Offset(195, 240), Offset(195, 330), Offset(196, 418)];

void main() {
  setUpFonts();

  group('fase rancang', () {
    testWidgets('tarikan desain: tooltip biaya di atas jari, fiber 4×', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.design);
      expect(find.text('Rp 850.000'), findsOneWidget);
      expect(find.textContaining('sedang ditarik'), findsNothing);
      expect(find.textContaining('segmen ·'), findsNothing);

      final gesture = await dragOnMap(tester, designPullPath, release: false);
      expect(find.text('−Rp 45.000 sedang ditarik'), findsOneWidget);
      final tooltip = find.text('3 segmen · Rp 45.000');
      expect(tooltip, findsOneWidget);
      final finger = mapToScreen(tester, const Offset(255, 360));
      final map = tester.getRect(find.byType(GameWidget<NetworkGame>));
      expect(tester.getRect(tooltip).bottom, lessThan(finger.dy));
      expect(tester.getRect(tooltip).right, lessThanOrEqualTo(map.right));

      // Jari kedua memilih fiber sementara tarikan masih berjalan.
      await tester.tap(find.text('Fiber'));
      await tester.pumpAndSettle();
      expect(find.text('−Rp 180.000 sedang ditarik'), findsOneWidget);
      expect(find.text('3 segmen · Rp 180.000'), findsOneWidget);

      // Lepas di luar rumah: batal.
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.textContaining('segmen ·'), findsNothing);
      expect(find.text('Rp 850.000'), findsOneWidget);
      expect(find.text('4/7 rumah tersambung'), findsOneWidget);
    });

    testWidgets('tarik ke Rumah 6 → tersambung, anggaran terpotong', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.design);
      expect(find.text('4/7 rumah tersambung'), findsOneWidget);

      final gesture = await dragOnMap(tester, _toHouse6, release: false);
      expect(find.text('5 segmen · Rp 75.000'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Rp 775.000'), findsOneWidget);
      expect(find.text('5/7 rumah tersambung'), findsOneWidget);
      expect(find.textContaining('sedang ditarik'), findsNothing);
    });

    testWidgets('mode hapus: ketuk kabel → dibongkar, uang balik 50%', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.design);
      const banner =
          'Mode hapus: ketuk kabel buat dibongkar. Uangnya balik 50%.';
      expect(find.text(banner), findsNothing);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text(banner), findsOneWidget);

      // Kabel Router → Rumah 4 (3 segmen LAN, Rp 45.000).
      await tester.tapAt(mapToScreen(tester, const Offset(257, 240)));
      await tester.pumpAndSettle();
      expect(find.text('Rp 872.500'), findsOneWidget);
      expect(find.text('3/7 rumah tersambung'), findsOneWidget);

      // Memilih kabel mematikan mode hapus (seperti prototipe).
      await tester.tap(find.text('LAN'));
      await tester.pumpAndSettle();
      expect(find.text(banner), findsNothing);
    });

    testWidgets('mode hapus: tidak bisa menarik kabel', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.design);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await dragOnMap(tester, _toHouse6);
      expect(find.text('4/7 rumah tersambung'), findsOneWidget);
      expect(find.text('Rp 850.000'), findsOneWidget);
    });

    testWidgets('anggaran kurang → kabel ditolak dengan banner', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.design);
      await tester.tap(find.text('Fiber'));
      await tester.pumpAndSettle();

      await dragOnMap(tester, _toHouse6);
      expect(find.text('Rp 550.000'), findsOneWidget);
      await dragOnMap(tester, [...designPullPath, const Offset(312, 386)]);
      expect(find.text('Rp 250.000'), findsOneWidget);
      expect(find.text('6/7 rumah tersambung'), findsOneWidget);

      // Rumah 6 → kiri → naik ke Rumah 7: 6 segmen fiber = Rp 360.000.
      final gesture = await dragOnMap(tester, const [
        Offset(195, 420),
        Offset(75, 420),
        Offset(76, 334),
      ], release: false);
      expect(find.text('6 segmen · Rp 360.000'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        find.text('Anggaran kurang: kabel ini Rp 360.000, sisa Rp 250.000.'),
        findsOneWidget,
      );
      expect(find.text('Rp 250.000'), findsOneWidget);
      expect(find.text('6/7 rumah tersambung'), findsOneWidget);

      // Tarikan berikutnya menghapus banner.
      await dragOnMap(tester, _toHouse6.take(2).toList());
      expect(find.textContaining('Anggaran kurang'), findsNothing);
    });
  });

  testWidgets('panel antrean: terapkan → tersimpan', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.queue);
    expect(find.text('25 / 20 Mbps'), findsOneWidget);
    expect(
      find.text('Kelebihan 5 Mbps. Turunkan batas Bu Sri atau Pak Rudi.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();
    expect(find.text('Tersimpan'), findsOneWidget);
  });

  testWidgets('panel antrean: prioritas bisa di-toggle', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, location: AppRoutes.queue);
    final prio = find.bySemanticsLabel('Prioritaskan Bu Sri');
    expect(tester.getSemantics(prio), isSemantics(isToggled: false));
    await tester.tap(prio);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(prio), isSemantics(isToggled: true));
    semantics.dispose();
  });

  for (final (stars, puas, sisa, komplain) in [
    (1, '72%', 'Rp 120.000', '7'),
    (2, '86%', 'Rp 120.000', '3'),
    (3, '86%', 'Rp 240.000', '2'),
  ]) {
    testWidgets('hasil berhasil $stars bintang', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.successWithStars(stars));
      expect(
        find.bySemanticsLabel('Dapat $stars dari 3 bintang'),
        findsOneWidget,
      );
      expect(find.text(puas), findsOneWidget);
      expect(find.text(sisa), findsOneWidget);
      expect(find.text(komplain), findsOneWidget);
    });
  }
}
