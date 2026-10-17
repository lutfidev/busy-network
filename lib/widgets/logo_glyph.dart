import 'dart:ui';

import '../theme/theme.dart';
import 'icons/svg_draw.dart';

/// Glyph logo Jaringan Sibuk (ubin di Beranda): dua rumah hijau, kabel
/// fiber ke router oranye, satu rumah kuning. Dipakai juga untuk ikon
/// launcher & splash (`test/tool/brand_test.dart`).
abstract final class LogoGlyph {
  /// ViewBox gambar.
  static const size = Size(48, 48);

  /// Kotak yang benar-benar terisi gambar (untuk menengahkan glyph).
  static const bounds = Rect.fromLTRB(3, 9, 45, 48);

  /// Gambar glyph di viewBox [size]. [cutout] = warna garis di sekeliling
  /// router: samakan dengan latar supaya router terpisah dari kabel.
  static void paint(
    Canvas canvas, {
    Color cutout = AppColors.surfaceNightRaised,
  }) {
    SvgDraw.stroke(
      canvas,
      'M24 30 V44 M24 30 L8 14 M24 30 L40 14',
      AppColors.nightCableIdle,
      4,
    );
    SvgDraw.stroke(canvas, 'M24 30 L40 14', AppColors.primary, 4);
    SvgDraw.circle(canvas, const Offset(8, 14), 5, fill: AppColors.statusOk);
    SvgDraw.circle(canvas, const Offset(40, 14), 5, fill: AppColors.statusOk);
    SvgDraw.circle(canvas, const Offset(24, 44), 4, fill: AppColors.star);
    SvgDraw.rrect(
      canvas,
      const Rect.fromLTWH(16, 22, 16, 16),
      5,
      fill: AppColors.primary,
      stroke: cutout,
      strokeWidth: 2.5,
    );
  }
}
