/// Jam simulasi. Waktu dalam menit sejak 00:00 (`IdFormat.clock`).
abstract final class SimClock {
  /// Hari mulai 06:00 dan selesai 24:00.
  static const dayStart = 6 * 60;
  static const dayEnd = 24 * 60;

  /// Satu hari permainan berlangsung sekian detik (kecepatan normal).
  static const secondsPerDay = 90.0;

  /// Menit permainan per detik: 1.080 / 90 = 12.
  static const minutesPerSecond = (dayEnd - dayStart) / secondsPerDay;

  /// Kelipatan kecepatan tombol percepat.
  static const fastForward = 4;

  /// Satu frame paling lama dihitung sekian detik, supaya jeda (rute
  /// tertutup, app di latar belakang) tidak jadi lompatan waktu.
  static const maxFrameSeconds = 0.1;

  /// Jam sibuk untuk level yang tidak menentukannya (level 1).
  static const defaultRushFrom = 19;
  static const defaultRushTo = 22;
}
