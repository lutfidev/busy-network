import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Elevasi: tombol "tebal" pakai bayangan padat (tanpa blur) 5–6 px yang
/// turun 4 px saat ditekan; panel & dialog pakai bayangan lembut.
abstract final class AppElevation {
  /// Tinggi bayangan padat tombol standar dan tombol hero.
  static const double chunky = 5;
  static const double chunkyLarge = 6;

  /// Seberapa jauh tombol turun saat ditekan.
  static const double pressDepth = 4;

  /// Bayangan padat di bawah node level.
  static const double levelNode = 4;

  static List<BoxShadow> solid(Color color, double depth) => [
    BoxShadow(color: color, offset: Offset(0, depth)),
  ];

  /// Bottom sheet / bar bawah: 0 -6 24 rgba(27,35,51,.08).
  static const List<BoxShadow> sheet = [
    BoxShadow(
      color: AppColors.shadowInk08,
      offset: Offset(0, -6),
      blurRadius: 24,
    ),
  ];

  /// Kartu dialog di atas scrim: 0 10 30 rgba(0,0,0,.25).
  static const List<BoxShadow> dialog = [
    BoxShadow(
      color: AppColors.shadowBlack25,
      offset: Offset(0, 10),
      blurRadius: 30,
    ),
  ];

  /// Kenop sakelar: 0 1 3 rgba(27,35,51,.25) (tidak ada di desain).
  static const List<BoxShadow> toggleKnob = [
    BoxShadow(
      color: AppColors.shadowInk25,
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// Pop-up di peta malam: 0 10 30 rgba(0,0,0,.4).
  static const List<BoxShadow> popupNight = [
    BoxShadow(
      color: AppColors.shadowBlack40,
      offset: Offset(0, 10),
      blurRadius: 30,
    ),
  ];

  /// Tooltip kecil: 0 6 16 rgba(27,35,51,.25).
  static const List<BoxShadow> tooltip = [
    BoxShadow(
      color: AppColors.shadowInk25,
      offset: Offset(0, 6),
      blurRadius: 16,
    ),
  ];
}
