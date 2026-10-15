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

  /// Cincin level aktif membesar 1 → 1,55 sambil memudar (js-ring).
  static const ringPulse = Duration(milliseconds: 1800);
  static const ringScale = Keyframes([
    (0, 1),
    (1, 1.55),
  ], curve: Curves.easeOut);
  static const ringOpacity = Keyframes([
    (0, 0.7),
    (1, 0),
  ], curve: Curves.easeOut);

  /// Pose statis cincin: sedang membesar (skala ±1,2), seperti referensi.
  static const ringStill = Duration(milliseconds: 450);

  /// Bintang hasil "pop" bergiliran: membesar sambil berputar (js-star).
  static const starPop = Duration(milliseconds: 550);
  static const starPopDelays = [
    Duration(milliseconds: 200),
    Duration(milliseconds: 600),
    Duration(milliseconds: 1000),
  ];
  static const Curve starPopCurve = Cubic(0.2, 1.3, 0.4, 1);
  static const starPopScale = Keyframes([
    (0, 0),
    (0.65, 1.2),
    (1, 1),
  ], curve: starPopCurve);

  /// Sudut putar (derajat).
  static const starPopAngle = Keyframes([
    (0, -40),
    (0.65, 8),
    (1, 0),
  ], curve: starPopCurve);
  static const starPopOpacity = Keyframes([
    (0, 0),
    (0.65, 1),
    (1, 1),
  ], curve: starPopCurve);

  static const Curve standard = Curves.easeOut;
  static const Curve pop = Cubic(0.2, 1.4, 0.4, 1);
}
