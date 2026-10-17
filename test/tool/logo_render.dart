import 'dart:ui' as ui;

import 'package:busy_network/theme/theme.dart';
import 'package:busy_network/widgets/widgets.dart';
import 'package:flutter/painting.dart';

/// Glyph logo ditengahkan di kanvas [canvasSize] px dengan lebar
/// [glyphWidth] px, di atas [background] (`null` = transparan). Dipakai
/// ikon launcher, splash (`brand_test.dart`), dan ikon Play Store
/// (`store_test.dart`).
Future<ui.Image> renderLogo({
  required double canvasSize,
  required double glyphWidth,
  Color? background,
}) {
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
  return recorder.endRecording().toImage(
    canvasSize.toInt(),
    canvasSize.toInt(),
  );
}
