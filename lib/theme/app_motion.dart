import 'package:flutter/animation.dart';

import 'keyframes.dart';

/// Token gerak (kartu "Elevasi & gerak").
abstract final class AppMotion {
  /// Tombol ditekan / dilepas.
  static const press = Duration(milliseconds: 120);

  /// Panel naik dari bawah.
  static const sheetIn = Duration(milliseconds: 300);

  /// Pindah sorotan tutorial.
  static const spotlight = Duration(milliseconds: 350);

  /// Trafik normal: titik tiap 18 px, maju 36 px per 1,4 s.
  static const trafficFlow = Duration(milliseconds: 1400);
  static const double trafficGap = 18;
  static const double trafficAdvance = 36;

  /// Trafik macet: titik tiap 9 px, maju 18 px per 3,2 s (js-jam).
  static const trafficJam = Duration(milliseconds: 3200);
  static const double trafficJamGap = 9;
  static const double trafficJamAdvance = 18;

  /// Kabel penuh, cincin rumah macet & LED router berkedip (js-alarm).
  static const alarmBlink = Duration(milliseconds: 700);
  static const alarmOpacity = Keyframes([(0, 1), (0.5, 0.25), (1, 1)]);

  static const Curve standard = Curves.easeOut;
  static const Curve pop = Cubic(0.2, 1.4, 0.4, 1);
}
