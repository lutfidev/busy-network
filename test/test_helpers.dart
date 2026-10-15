import 'package:busy_network/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font dibundel di assets → jangan coba unduh saat test.
void setUpFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Atur ukuran layar logis (dpr 1) dan pulihkan setelah test.
void setScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Nyalakan setelan aksesibilitas "hapus animasi"
/// (`MediaQuery.disableAnimations`) sampai test selesai.
///
/// Animasi berulang (trafik, cincin level, tangan tutorial) tidak pernah
/// selesai, jadi tanpa ini `pumpAndSettle` macet. Dengan animasi mati,
/// layar tampil di bingkai statisnya (sama dengan referensi desain).
void disableAnimations(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Pompa aplikasi (animasi mati, lihat [disableAnimations]) di [location].
Future<void> pumpApp(WidgetTester tester, {String location = '/'}) async {
  disableAnimations(tester);
  await tester.pumpWidget(JaringanSibukApp(initialLocation: location));
  await tester.pumpAndSettle();
}
