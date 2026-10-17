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
import 'package:busy_network/widgets/widgets.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const bool _enabled = bool.fromEnvironment('BRAND');

/// Glyph ditengahkan di kanvas [canvasSize] px dengan lebar [glyphWidth]
/// px, di atas [background] (`null` = transparan).
Future<void> _render(
  String name, {
  required double canvasSize,
  required double glyphWidth,
  Color? background,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (background != null) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      Paint()..color = background,
    );
  }
  const bounds = LogoGlyph.bounds;
  final scale = glyphWidth / bounds.width;
  canvas
    ..translate(canvasSize / 2, canvasSize / 2)
    ..scale(scale)
    ..translate(-bounds.center.dx, -bounds.center.dy);
  LogoGlyph.paint(canvas, cutout: background ?? AppColors.groundNight);
  final image = await recorder.endRecording().toImage(
    canvasSize.toInt(),
    canvasSize.toInt(),
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
