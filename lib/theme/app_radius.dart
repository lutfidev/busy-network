import 'package:flutter/painting.dart';

/// Radius sudut (kartu "Radius").
///
/// Chip 8 · tombol kecil 14 · kartu 18 · tombol besar & panel 20–22 ·
/// bottom sheet 28 · pill.
abstract final class AppRadius {
  static const double chip = 8;
  static const double iconTile = 12;
  static const double buttonSmall = 14;
  static const double bubble = 16;
  static const double card = 18;
  static const double button = 20;
  static const double panel = 22;
  static const double buttonLarge = 24;
  static const double hero = 26;
  static const double sheet = 28;
  static const double pill = 999;

  static const BorderRadius chipAll = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius iconTileAll = BorderRadius.all(
    Radius.circular(iconTile),
  );
  static const BorderRadius buttonSmallAll = BorderRadius.all(
    Radius.circular(buttonSmall),
  );
  static const BorderRadius bubbleAll = BorderRadius.all(
    Radius.circular(bubble),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonAll = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius panelAll = BorderRadius.all(Radius.circular(panel));
  static const BorderRadius buttonLargeAll = BorderRadius.all(
    Radius.circular(buttonLarge),
  );
  static const BorderRadius heroAll = BorderRadius.all(Radius.circular(hero));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );

  /// Gelembung chat: sudut kiri-atas lancip.
  static const BorderRadius speechBubble = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(bubble),
    bottomLeft: Radius.circular(bubble),
    bottomRight: Radius.circular(bubble),
  );
}
