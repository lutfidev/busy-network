// Gambar ikon launcher & splash dari glyph logo Beranda ke assets/brand/.
//
//   flutter test test/tool/brand_test.dart --dart-define=BRAND=true
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//   git checkout android/app/src/main/AndroidManifest.xml
//
// Tanpa define di atas, test ini dilewati (tidak ikut `flutter test` biasa).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busy_network/theme/theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'logo_render.dart';

const bool _enabled = bool.fromEnvironment('BRAND');

Future<void> _render(
  String name, {
  required double canvasSize,
  required double glyphWidth,
  Color? background,
}) async {
  final image = await renderLogo(
    canvasSize: canvasSize,
    glyphWidth: glyphWidth,
    background: background,
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('assets/brand/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('ikon & splash', (tester) async {
    await tester.runAsync(() async {
      // Ikon lama (persegi penuh, Android memotong sudutnya sendiri).
      await _render(
        'icon',
        canvasSize: 1024,
        glyphWidth: 600,
        background: AppColors.groundNight,
      );
      // Ikon adaptif: latar groundNight dari warna, glyph di zona aman
      // (lingkaran 66/108 dari kanvas) setelah inset 16% generatornya.
      await _render('icon_foreground', canvasSize: 1024, glyphWidth: 620);
      // Splash Android 12+: ikon 288 dp, yang terlihat lingkaran 192 dp.
      await _render('splash_android12', canvasSize: 1152, glyphWidth: 520);
      // Splash Android lama: gambar di tengah layar, 192 dp @4x.
      await _render('splash', canvasSize: 768, glyphWidth: 480);
    });
  }, skip: !_enabled);
}
