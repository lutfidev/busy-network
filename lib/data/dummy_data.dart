/// Data dummy untuk layar yang belum punya logika game: progres babak,
/// jam & kepuasan fase jalan, komplain, dan angka hasil. Level & jaringan
/// ada di `lib/game/`; snapshot state ada di `dummy_states.dart`.
library;

class ChapterInfo {
  const ChapterInfo({
    required this.number,
    required this.name,
    required this.starsEarned,
    required this.starsTotal,
    required this.levelsDone,
    required this.levelsTotal,
  });

  final int number;
  final String name;
  final int starsEarned;
  final int starsTotal;
  final int levelsDone;
  final int levelsTotal;

  /// Progres babak untuk bar di Beranda. Desain memakai lebar 33%.
  double get progress => levelsDone / levelsTotal;
}

abstract final class DummyData {
  static const chapter = ChapterInfo(
    number: 1,
    name: 'Perumahan Batam',
    starsEarned: 9,
    starsTotal: 36,
    levelsDone: 4,
    levelsTotal: 12,
  );

  // ── Fase jalan ────────────────────────────────────────────────────────
  static const dayStartHour = 6;
  static const dayEndHour = 24;
  static const runClockMinutes = 20 * 60 + 15;
  static const runSatisfaction = 62;

  /// Rumah yang komplain (nama & label diambil dari definisi level).
  static const complaintHouseId = 'r4';
  static const complaintClockMinutes = 20 * 60 + 14;
  static const complaintMessage =
      'Bang, kok lemot?? Anak saya lagi ujian online!';

  // ── Hasil ─────────────────────────────────────────────────────────────
  static const savingsTarget = 200000;

  static const failSatisfaction = 41;
  static const failComplaints = 11;
  static const failHousesLost = 2;
}
