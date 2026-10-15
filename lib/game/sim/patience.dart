import '../map_scene.dart';

/// Aturan status & kesabaran rumah saat hari berjalan.
abstract final class Patience {
  /// Sabar atau layanan di bawah ini → "mulai lambat".
  static const slowBelow = 0.6;

  /// Sabar turun per jam permainan sebanyak kekurangan layanan × ini.
  static const shortfallPerHour = 1.0;

  /// Tambahan turun per jam bila macet (kabel yang menyambungkan rumah
  /// penuh) atau bila hanya ada kabel penuh di hulunya.
  static const jamPerHour = 0.3;
  static const congestedPerHour = 0.15;

  /// Sabar naik per jam bila terlayani penuh.
  static const recoverPerHour = 0.1;

  /// Toleransi pembulatan layanan "penuh".
  static const _epsilon = 1e-9;

  /// Layanan [service] (terlayani / pemakaian) kurang dari penuh?
  static bool short(double service) => service < 1 - _epsilon;

  /// Status rumah: [jam] = kabelnya penuh dan rumah ini kekurangan.
  static HouseState status({
    required bool jam,
    required double patience,
    required double service,
  }) {
    if (jam) return HouseState.jam;
    if (patience < slowBelow || service < slowBelow) return HouseState.slow;
    return HouseState.ok;
  }

  /// Perubahan sabar per jam permainan.
  static double ratePerHour({
    required double service,
    required bool jam,
    required bool congested,
  }) {
    if (!short(service)) return recoverPerHour;
    final extra = jam
        ? jamPerHour
        : congested
        ? congestedPerHour
        : 0.0;
    return -(shortfallPerHour * (1 - service) + extra);
  }
}
