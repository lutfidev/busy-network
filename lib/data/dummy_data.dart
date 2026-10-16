/// Angka yang belum dihitung game: progres awal (sampai langkah 8) dan
/// potret layar hasil di desain (deep link, screenshot). Level & jaringan
/// ada di `lib/game/`, snapshot state di `dummy_states.dart`.
library;

import '../game/levels/levels.dart';
import '../game/progress/progress.dart';
import '../game/result/level_result.dart';

abstract final class DummyData {
  /// Progres awal seperti Peta Babak di desain: level 1–4 selesai
  /// (3/2/3/1 bintang), level 5 sekarang. Langkah 8: mulai dari level 1.
  static final progress = Progress(const {1: 3, 2: 2, 3: 3, 4: 1});

  /// Biang kerok di potret hasil desain.
  static const _blockB = FullCable(
    area: 'Blok B',
    minute: 20 * 60,
    heavyUsers: ['Bu Sri', 'Pak Rudi'],
    suggestFiber: true,
  );

  /// Hasil Berhasil di desain (`?bintang=1..3`, angka logika prototipe;
  /// bintangnya keluar dari aturan).
  static LevelResult success(int stars) => LevelResult(
    level: Levels.level5,
    satisfaction: stars >= 2 ? 86 : 72,
    budgetLeft: stars >= 3 ? 240000 : 120000,
    complaints: stars >= 3 ? 2 : (stars == 2 ? 3 : 7),
    housesLost: 0,
    culprit: _blockB,
  );

  /// Hasil Gagal di desain.
  static const fail = LevelResult(
    level: Levels.level5,
    satisfaction: 41,
    budgetLeft: 120000,
    complaints: 11,
    housesLost: 2,
    culprit: _blockB,
  );
}
