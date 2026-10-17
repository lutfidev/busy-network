import 'package:flutter/painting.dart';

/// Ukuran komponen yang berulang (tinggi tombol, ikon, node peta).
abstract final class AppSizes {
  /// Kanvas desain (Figma/HTML) — semua koordinat peta mengacu ke sini.
  static const Size designCanvas = Size(390, 844);

  /// Area peta jaringan di layar level.
  static const Size mapArea = Size(390, 472);

  // Tombol
  static const double buttonHero = 72;
  static const double buttonLarge = 60;
  static const double buttonTall = 62;
  static const double buttonPanel = 58;
  static const double button = 56;
  static const double buttonOutline = 52;
  static const double buttonSmall = 44;
  static const double textButton = 48;

  // Tombol ikon bulat
  static const double iconButton = 48;
  static const double iconButtonMedium = 44;
  static const double iconButtonSmall = 40;

  // Ikon
  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 22;
  static const double iconXl = 26;
  static const double handPointer = 56;

  // Chip & pill
  static const double chip = 28;
  static const double counterPill = 44;
  static const double statusPill = 36;

  // Node peta babak
  static const double levelNode = 60;
  static const double levelNodeCurrent = 72;
  static const double levelNodeLocked = 48;
  static const double levelNodeBorder = 4;
  static const double levelStar = 17;

  // Node peta jaringan
  static const double houseRadius = 20;
  static const double routerSize = 48;

  /// Bidang sentuh minimum node peta (jari-jari, px peta): 48 px diameter.
  static const double mapTouchRadius = 24;

  /// Jarak ketuk dari garis kabel yang masih dihitung kena (mode Hapus).
  static const double cableTouchSlop = 12;

  // Progress
  static const double progressThin = 6;
  static const double progress = 8;
  static const double progressMedium = 10;
  static const double progressThick = 12;

  // Lain-lain
  static const double sheetHandleWidth = 44;
  static const double sheetHandleHeight = 5;
  static const double avatar = 38;
  static const double logoTile = 76;
  static const double bossTile = 72;

  /// Lebar maksimum kartu dialog (Pengaturan; tidak ada di desain).
  static const double dialogMaxWidth = 360;

  /// Sakelar (Pengaturan; tidak ada di desain): pill 52×32, kenop 26.
  static const double toggleWidth = 52;
  static const double toggleHeight = 32;
  static const double toggleKnob = 26;
}
