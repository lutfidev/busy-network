/// Data dummy untuk layar yang belum punya logika game: progres babak dan
/// angka hasil (langkah 6). Level & jaringan ada di `lib/game/`, simulasi
/// hari di `lib/game/sim/`; snapshot state ada di `dummy_states.dart`.
library;

import '../game/progress/progress.dart';

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
  /// Progres awal seperti Peta Babak di desain: level 1–4 selesai
  /// (3/2/3/1 bintang), level 5 sekarang. Langkah 8: mulai dari level 1.
  static final progress = Progress(const {1: 3, 2: 2, 3: 3, 4: 1});

  static const chapter = ChapterInfo(
    number: 1,
    name: 'Perumahan Batam',
    starsEarned: 9,
    starsTotal: 36,
    levelsDone: 4,
    levelsTotal: 12,
  );

  // ── Hasil ─────────────────────────────────────────────────────────────
  static const savingsTarget = 200000;

  static const failSatisfaction = 41;
  static const failComplaints = 11;
  static const failHousesLost = 2;
}
