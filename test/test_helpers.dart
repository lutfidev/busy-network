import 'package:busy_network/app/app.dart';
import 'package:busy_network/game/network_game.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flame/game.dart' hide RouterComponent;
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

/// Titik layar untuk koordinat peta [p] (390×472) di peta yang tampil.
Offset mapToScreen(WidgetTester tester, Offset p) {
  final rect = tester.getRect(find.byType(GameWidget<NetworkGame>));
  return rect.topLeft + p * (rect.width / AppSizes.mapArea.width);
}

/// Seret jari di peta melewati [path] (koordinat peta). Tanpa [release],
/// jari tetap menempel; gestur dikembalikan untuk dilepas sendiri.
///
/// Tiap langkah memajukan waktu 50 ms: pengenal ketuk Flame memasang timer
/// pendek yang harus habis sebelum test selesai.
Future<TestGesture> dragOnMap(
  WidgetTester tester,
  List<Offset> path, {
  bool release = true,
}) async {
  const step = Duration(milliseconds: 50);
  final gesture = await tester.startGesture(mapToScreen(tester, path.first));
  for (final p in path.skip(1)) {
    await gesture.moveTo(mapToScreen(tester, p));
    await tester.pump(step);
  }
  if (release) {
    await gesture.up();
    await tester.pumpAndSettle();
  }
  return gesture;
}

/// Tunggu font google_fonts yang diminta layar selesai dimuat, lalu tata
/// ulang. Tanpa ini test pertama di satu file memakai font cadangan.
Future<void> loadAppFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    await GoogleFonts.pendingFonts();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}
