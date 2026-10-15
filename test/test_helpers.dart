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

Future<void> pumpApp(WidgetTester tester, {String location = '/'}) async {
  await tester.pumpWidget(JaringanSibukApp(initialLocation: location));
  await tester.pumpAndSettle();
}
