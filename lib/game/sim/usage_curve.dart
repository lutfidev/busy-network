import 'sim_clock.dart';

/// Kurva pemakaian harian: bagian `HouseDef.peakMbps` yang dipakai rumah.
///
/// Pagi 25% (06–08), siang 35% (08–12), sore 45%, naik lurus ke 100% dalam
/// [rampHours] jam sebelum jam sibuk, 100% selama jam sibuk, lalu turun
/// lurus ke [lateShare] di 24:00.
abstract final class UsageCurve {
  static const morningShare = 0.25;
  static const middayShare = 0.35;
  static const afternoonShare = 0.45;
  static const lateShare = 0.3;
  static const rampHours = 2;

  /// Bagian pemakaian puncak pada [minute] (menit sejak 00:00).
  static double shareAt(
    num minute, {
    int rushFrom = SimClock.defaultRushFrom,
    int rushTo = SimClock.defaultRushTo,
  }) {
    final hour = minute / 60;
    final rampFrom = rushFrom - rampHours;
    if (hour >= rushFrom && hour <= rushTo) return 1;
    if (hour > rushTo) {
      const end = SimClock.dayEnd / 60;
      final t = ((hour - rushTo) / (end - rushTo)).clamp(0.0, 1.0);
      return 1 + (lateShare - 1) * t;
    }
    final base = hour < 8
        ? morningShare
        : hour < 12
        ? middayShare
        : afternoonShare;
    if (hour <= rampFrom) return base;
    final t = (hour - rampFrom) / rampHours;
    return base + (1 - base) * t;
  }
}
