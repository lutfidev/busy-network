import 'package:flutter/foundation.dart';

import '../../theme/theme.dart';

/// Pose animasi peta pada satu saat — padanan `@keyframes` di desain
/// Fase Jalan. Dihitung dari detik berjalan (`NetworkGame.update`), lalu
/// dibaca `render()` komponen peta.
@immutable
class MapMotion {
  const MapMotion({
    this.flowPhase = 0,
    this.jamPhase = 0,
    this.alarmOpacity = 1,
  });

  /// Bingkai statis (animasi mati) = gambar desain.
  static const still = MapMotion();

  factory MapMotion.at(double seconds) => MapMotion(
    flowPhase:
        AppMotion.trafficAdvance *
        Keyframes.loop(seconds, AppMotion.trafficFlow),
    jamPhase:
        AppMotion.trafficJamAdvance *
        Keyframes.loop(seconds, AppMotion.trafficJam),
    alarmOpacity: AppMotion.alarmOpacity.at(
      Keyframes.loop(seconds, AppMotion.alarmBlink),
    ),
  );

  /// Pergeseran titik trafik (px) di kabel lancar (js-flow).
  final double flowPhase;

  /// Pergeseran titik trafik (px) di kabel macet (js-jam).
  final double jamPhase;

  /// Opasitas lapisan merah kabel penuh, cincin alarm rumah, dan LED merah
  /// router (js-alarm).
  final double alarmOpacity;
}
