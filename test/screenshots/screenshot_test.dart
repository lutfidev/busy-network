// Potret layar ke PNG untuk dibandingkan dengan `design/reference/`.
//
//   flutter test test/screenshots --dart-define=SCREENSHOTS=true
//
// Tanpa define di atas, test ini dilewati (tidak ikut `flutter test` biasa).
import 'package:busy_network/gallery/widget_gallery_screen.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'capture.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('galeri', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
