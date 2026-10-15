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

  /// Kabel yang sedang ditarik: putus-putus 10/8 maju 36 px per 1 s
  /// (js-march, linear).
  static const cableMarch = Duration(seconds: 1);
  static const double cableMarchAdvance = 36;
  static const double cableDash = 10;
  static const double cableDashGap = 8;

  /// Cincin snap rumah tujuan berdenyut 0,9 → 0,25 → 0,9 (js-snap).
  static const snapPulse = Duration(milliseconds: 1100);
  static const snapOpacity = Keyframes([(0, 0.9), (0.5, 0.25), (1, 0.9)]);

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

  /// Tangan tutorial mengangguk ke [handBobOffset] lalu kembali (js-bob).
  static const handBob = Duration(milliseconds: 1200);
  static const handBobOffset = Offset(4, 8);
  static const handBobAmount = Keyframes([(0, 0), (0.5, 1), (1, 0)]);

  /// Tangan menyeret sejauh [handDragOffset] (router → Rumah 1), lalu
  /// memudar dan mengulang (js-drag).
  static const handDrag = Duration(milliseconds: 2400);
  static const handDragOffset = Offset(150, -150);
  static const handDragAmount = Keyframes([
    (0, 0),
    (0.12, 0),
    (0.72, 1),
    (1, 1),
  ]);
  static const handDragOpacity = Keyframes([
    (0, 0),
    (0.12, 1),
    (0.88, 1),
    (1, 0),
  ]);

  /// Pose statis tangan seret: di titik awal, sudah terlihat (12%).
  static const handDragStill = Duration(milliseconds: 288);

  /// Latar Beranda: trafik kota maju [trafficAdvance] per siklus
  /// (js-flow & js-flow-slow).
  static const homeFlow = Duration(milliseconds: 1800);
  static const homeFlowSlow = Duration(milliseconds: 3400);

  /// Seluruh peta kota bergeser pelan bolak-balik (js-drift, alternate).
  static const homeDrift = Duration(seconds: 16);
  static const homeDriftOffset = Offset(-14, -20);
  static const homeDriftAmount = Keyframes([(0, 0), (1, 1)]);

  /// Rumah macet di latar berkedip (js-blink).
  static const homeBlink = Duration(milliseconds: 2400);
  static const homeBlinkOpacity = Keyframes([(0, 1), (0.5, 0.35), (1, 1)]);

  static const Curve standard = Curves.easeOut;
  static const Curve pop = Cubic(0.2, 1.4, 0.4, 1);
}
