/// Skala jarak (kartu "Jarak").
///
/// Token inti: 4 · 8 · 12 · 16 · 24 · 32. Nilai pendukung (2, 6, 10, 14,
/// 18, 20) muncul di layar prototipe untuk celah antar-elemen kecil.
abstract final class AppSpacing {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;

  /// Gutter kiri-kanan layar.
  static const double screenGutter = s16;

  /// Jarak antar-kartu (8–12).
  static const double cardGap = s10;

  /// Padding kartu (12–16).
  static const double cardPadding = s14;

  /// Ukuran sel grid peta.
  static const double mapCell = 30;
}
