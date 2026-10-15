import '../../core/format.dart';
import '../../data/dummy_data.dart';
import '../../game/levels/levels.dart';

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

/// Ringkasan hasil level berdasarkan jumlah bintang (logika prototipe).
class SuccessSummary {
  SuccessSummary(this.stars)
    : satisfaction = stars >= 2 ? 86 : 72,
      remainingBudget = stars >= 3 ? 240000 : 120000,
      complaints = stars >= 3 ? 2 : (stars == 2 ? 3 : 7);

  final int stars;
  final int satisfaction;
  final int remainingBudget;
  final int complaints;

  List<StarRule> get rules {
    final target = Levels.level5.targetSatisfaction;
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
            'Kepuasan akhir ≥ ${IdFormat.percent(target)} · kamu '
            '${IdFormat.percent(satisfaction)}',
        passed: stars >= 2,
      ),
      StarRule(
        stars: 3,
        title: 'Kepuasan tinggi & hemat',
        detail:
            'Sisa anggaran ≥ ${IdFormat.rupiah(DummyData.savingsTarget)} · '
            'kamu ${IdFormat.rupiah(remainingBudget)}',
        passed: stars >= 3,
      ),
    ];
  }

  /// Tips; `null` bila sudah 3 bintang.
  String? get tip => switch (stars) {
    >= 3 => null,
    2 =>
      'Pakai LAN di jalur yang sepi. Fiber cukup buat kabel utama, '
          'sisanya buat bintang ketiga.',
    _ =>
      'Jalur Blok B penuh pas jam sibuk. Coba fiber di kabel utama, atau '
          'batasi jatah sebelum jam 19.',
  };
}
