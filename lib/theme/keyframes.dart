import 'package:flutter/animation.dart';

/// Satu `@keyframes` CSS dari desain: [stops] berisi `(persen 0..1, nilai)`
/// dan [curve] (`animation-timing-function`) berlaku **per segmen** antar
/// keyframe, sama seperti di browser.
///
/// Dihitung dari waktu, bukan dari [AnimationController], supaya sama saja
/// dipakai widget (lewat `LoopClock`) maupun `update(dt)` Flame
/// (`NetworkGame`).
class Keyframes {
  const Keyframes(this.stops, {this.curve = Curves.easeInOut});

  final List<(double, double)> stops;
  final Curve curve;

  /// Nilai pada posisi [t] (0..1) dalam satu siklus.
  double at(double t) {
    if (t <= stops.first.$1) return stops.first.$2;
    for (var i = 1; i < stops.length; i++) {
      final (end, to) = stops[i];
      if (t > end) continue;
      final (start, from) = stops[i - 1];
      if (end == start) return to;
      return from + (to - from) * curve.transform((t - start) / (end - start));
    }
    return stops.last.$2;
  }

  /// Posisi 0..1 dalam siklus `animation: <period> infinite`.
  static double loop(double seconds, Duration period) {
    final p = _seconds(period);
    return (seconds % p) / p;
  }

  /// Seperti [loop] untuk `animation-direction: alternate`: 0→1 lalu 1→0.
  static double alternate(double seconds, Duration period) {
    final n = seconds / _seconds(period);
    final f = n - n.floorToDouble();
    return n.floor().isEven ? f : 1 - f;
  }

  static double _seconds(Duration d) =>
      d.inMicroseconds / Duration.microsecondsPerSecond;
}
