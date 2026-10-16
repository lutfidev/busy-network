import 'package:busy_network/app/routes.dart';
import 'package:busy_network/gallery/widget_gallery_screen.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/design_pull.dart';
import '../test_helpers.dart';

/// Setiap layar harus bebas overflow di lebar 360 px (dan ukuran umum
/// lain). Overflow RenderFlex dilaporkan sebagai exception → test gagal.
const _routes = <String>[
  AppRoutes.home,
  AppRoutes.levelMap,
  '${AppRoutes.tutorial}?${AppRoutes.stepParam}=1',
  '${AppRoutes.tutorial}?${AppRoutes.stepParam}=2',
  '${AppRoutes.tutorial}?${AppRoutes.stepParam}=3',
  AppRoutes.design,
  '${AppRoutes.design}?${AppRoutes.levelParam}=1',
  AppRoutes.run,
  AppRoutes.queue,
  '${AppRoutes.success}?${AppRoutes.starsParam}=1',
  '${AppRoutes.success}?${AppRoutes.starsParam}=3',
  AppRoutes.fail,
  AppRoutes.gallery,
];

const _sizes = <Size>[
  Size(360, 640),
  Size(360, 740),
  Size(360, 800),
  Size(390, 844),
  Size(412, 915),
];

void main() {
  setUpFonts();

  for (final size in _sizes) {
    for (final route in _routes) {
      testWidgets('tanpa overflow: $route @ ${size.width}×${size.height}', (
        tester,
      ) async {
        setScreenSize(tester, size);
        await pumpApp(tester, location: route);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final route in _routes) {
    testWidgets('tanpa overflow (teks 130%): $route @ 360×800', (tester) async {
      setScreenSize(tester, const Size(360, 800));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, location: route);
      expect(tester.takeException(), isNull);
    });
  }

  // Fase Rancang mulai kosong: tooltip biaya baru muncul saat menarik.
  for (final (size, textScale) in [
    for (final size in _sizes) (size, 1.0),
    (const Size(360, 800), 1.3),
  ]) {
    testWidgets('tanpa overflow: rancang sambil menarik @ '
        '${size.width}×${size.height}, teks ${textScale * 100}%', (
      tester,
    ) async {
      setScreenSize(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, location: AppRoutes.design);
      // Tata letak sebelum font termuat sudah dicek test rute di atas.
      await loadAppFonts(tester);
      tester.takeException();
      await tester.tap(find.text('Fiber'));
      await tester.pumpAndSettle();
      final gesture = await dragOnMap(tester, [
        ...designPullPath,
        const Offset(312, 386),
      ], release: false);
      expect(find.textContaining('segmen · Rp'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('galeri bisa di-scroll sampai bawah di 360 px', (tester) async {
    setScreenSize(tester, const Size(360, 740));
    disableAnimations(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const WidgetGalleryScreen()),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Kabel & trafik'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
