import 'package:busy_network/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setUpFonts();

  testWidgets('fase rancang: pilih fiber mengubah biaya tarikan', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.design);
    expect(find.text('Rp 850.000'), findsOneWidget);
    expect(find.text('−Rp 45.000 sedang ditarik'), findsOneWidget);
    expect(find.text('3 segmen · Rp 45.000'), findsOneWidget);

    await tester.tap(find.text('Fiber'));
    await tester.pumpAndSettle();
    expect(find.text('−Rp 180.000 sedang ditarik'), findsOneWidget);
    expect(find.text('3 segmen · Rp 180.000'), findsOneWidget);
  });

  testWidgets('fase rancang: mode hapus menampilkan banner', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.design);
    const banner = 'Mode hapus: ketuk kabel buat dibongkar. Uangnya balik 50%.';
    expect(find.text(banner), findsNothing);
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text(banner), findsOneWidget);
    // Memilih kabel mematikan mode hapus (seperti prototipe).
    await tester.tap(find.text('LAN'));
    await tester.pumpAndSettle();
    expect(find.text(banner), findsNothing);
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
