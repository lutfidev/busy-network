import '../../core/format.dart';
import '../../game/map_scene.dart';
import '../../game/result/level_result.dart';
import '../../game/sim/sim.dart';

/// Satu syarat bintang di daftar hasil.
class StarRule {
  const StarRule({
    required this.stars,
    required this.title,
    required this.detail,
    required this.passed,
  });

  final int stars;
  final String title;
  final String detail;
  final bool passed;
}

/// Isi layar Hasil Berhasil dari [result]: syarat bintang & tips.
class SuccessSummary {
  const SuccessSummary(this.result);

  final LevelResult result;

  List<StarRule> get rules {
    final level = result.level;
    return [
      const StarRule(
        stars: 1,
        title: 'Selesai',
        detail: 'Hari lewat tanpa bangkrut',
        passed: true,
      ),
      StarRule(
        stars: 2,
        title: 'Kepuasan tinggi',
        detail:
            'Kepuasan akhir ≥ ${IdFormat.percent(level.targetSatisfaction)} · '
            'kamu ${IdFormat.percent(result.satisfaction)}',
        passed: result.stars >= 2,
      ),
      StarRule(
        stars: 3,
        title: 'Kepuasan tinggi & hemat',
        detail:
            'Sisa anggaran ≥ ${IdFormat.rupiah(level.savingsTarget)} · '
            'kamu ${IdFormat.rupiah(result.budgetLeft)}',
        passed: result.stars >= 3,
      ),
    ];
  }

  /// Tips; `null` bila sudah 3 bintang atau tidak ada biang kerok.
  String? get tip => switch (result.stars) {
    >= 3 => null,
    // Fiber belum terbuka (level 1): bintang ketiga = hemat segmen.
    2 when !_fiberOpen =>
      'Tarik kabel lewat jalur terpendek. Sisa anggarannya buat bintang '
          'ketiga.',
    2 =>
      'Pakai LAN di jalur yang sepi. Fiber cukup buat kabel utama, '
          'sisanya buat bintang ketiga.',
    _ => switch (result.culprit) {
      FullCable(:final area, suggestFiber: true) =>
        'Jalur $area penuh pas jam sibuk. Coba fiber di kabel utama, atau '
            'batasi jatah sebelum jam $_rushFrom.',
      FullCable(:final area) =>
        'Jalur $area penuh pas jam sibuk. Batasi jatah sebelum jam '
            '$_rushFrom.',
      Unconnected(:final customers) =>
        'Masih ada ${customers.length} rumah yang belum tersambung. '
            'Sambungkan biar kepuasan naik.',
      TightLimit(:final customers) =>
        'Jatah ${customers.first} kebatasan. Naikkan batasnya, kabelnya '
            'masih kuat.',
      null => null,
    },
  };

  bool get _fiberOpen =>
      result.level.unlockedCables.any((spec) => spec.kind == CableKind.fiber);

  int get _rushFrom => result.level.rushHourFrom ?? SimClock.defaultRushFrom;
}
