// Potret layar ke PNG untuk dibandingkan dengan `design/reference/`.
//
//   flutter test test/screenshots --dart-define=SCREENSHOTS=true
//
// Hasil di build/screenshots/<lebar>x<tinggi>/. Tanpa define di atas, test
// ini dilewati (tidak ikut `flutter test` biasa).
import 'package:busy_network/app/app.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/gallery/widget_gallery_screen.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/design_pull.dart';
import '../test_helpers.dart';
import 'capture.dart';

const _screens = <String, String>{
  '01-beranda': AppRoutes.home,
  '02-peta-babak-1': AppRoutes.levelMap,
  '03-tutorial-1': '${AppRoutes.tutorial}?${AppRoutes.stepParam}=1',
  '03-tutorial-2': '${AppRoutes.tutorial}?${AppRoutes.stepParam}=2',
  '03-tutorial-3': '${AppRoutes.tutorial}?${AppRoutes.stepParam}=3',
  '04-fase-rancang': AppRoutes.design,
  '04-fase-rancang-level-1': '${AppRoutes.design}?${AppRoutes.levelParam}=1',
  '05-fase-jalan': AppRoutes.run,
  '06-panel-atur-antrean': AppRoutes.queue,
  '07-hasil-berhasil-1': '${AppRoutes.success}?${AppRoutes.starsParam}=1',
  '07-hasil-berhasil-2': '${AppRoutes.success}?${AppRoutes.starsParam}=2',
  '07-hasil-berhasil-3': '${AppRoutes.success}?${AppRoutes.starsParam}=3',
  '08-hasil-gagal': AppRoutes.fail,
};

/// Aksi sebelum dipotret; gestur yang dikembalikan dilepas sesudahnya.
final _before = <String, Future<TestGesture> Function(WidgetTester)>{
  // Bingkai desain: jari masih menarik kabel router → arah Rumah 5.
  '04-fase-rancang': (tester) =>
      dragOnMap(tester, designPullPath, release: false),
};

const _sizes = [Size(390, 844), Size(360, 740)];

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final size in _sizes) {
    final folder = '${size.width.toInt()}x${size.height.toInt()}';
    for (final MapEntry(key: name, value: location) in _screens.entries) {
      testWidgets('$folder/$name', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        disableAnimations(tester);
        await tester.pumpWidget(
          capturable(JaringanSibukApp(initialLocation: location)),
        );
        await tester.pumpAndSettle();
        final gesture = await _before[name]?.call(tester);
        await capture(tester, '$folder/$name');
        await gesture?.up();
      }, skip: !screenshotsEnabled);
    }
  }

  testWidgets('galeri', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    disableAnimations(tester);
    await tester.pumpWidget(
      capturable(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const WidgetGalleryScreen(),
        ),
      ),
    );
    await capture(tester, 'gallery');
  }, skip: !screenshotsEnabled);
}
