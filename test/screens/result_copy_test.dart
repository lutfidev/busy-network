import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/result/level_result.dart';
import 'package:busy_network/screens/result_fail/fail_cause.dart';
import 'package:busy_network/screens/result_success/result_success_data.dart';
import 'package:flutter_test/flutter_test.dart';

LevelResult _oneStar(Culprit? culprit, {int level = 5}) => LevelResult(
  level: Levels.byNumber(level)!,
  satisfaction: level == 5 ? 70 : 50,
  budgetLeft: 0,
  complaints: 0,
  housesLost: 0,
  culprit: culprit,
);

void main() {
  group('biang kerok layar gagal', () {
    test('kabel penuh (teks desain)', () {
      final cause = failCause(DummyData.fail.culprit!);
      expect(cause.title, 'Kabel ke Blok B kelebihan beban jam 20:00.');
      expect(
        cause.hint,
        'Ganti kabel utamanya ke fiber, atau batasi jatah Bu Sri dan Pak '
        'Rudi sebelum jam sibuk.',
      );
    });

    test('kabel penuh tanpa saran fiber, satu pemakai', () {
      final cause = failCause(
        const FullCable(
          area: 'Rumah 2',
          minute: 19 * 60 + 5,
          heavyUsers: ['Bu Lina'],
          suggestFiber: false,
        ),
      );
      expect(cause.title, 'Kabel ke Rumah 2 kelebihan beban jam 19:05.');
      expect(cause.hint, 'Batasi jatah Bu Lina sebelum jam sibuk.');
    });

    test('rumah belum tersambung', () {
      final cause = failCause(
        const Unconnected(['Pak Rudi', 'Bang Togar', 'Mbak Wulan']),
      );
      expect(cause.title, '3 rumah belum tersambung.');
      expect(
        cause.hint,
        'Tarik kabel ke Pak Rudi dan Bang Togar sebelum mulai hari.',
      );
      expect(
        failCause(const Unconnected(['Pak Rudi'])).hint,
        'Tarik kabel ke Pak Rudi sebelum mulai hari.',
      );
    });

    test('jatah terlalu ketat', () {
      expect(
        failCause(const TightLimit(['Bu Sri', 'Pak Rudi'])).title,
        'Jatah Bu Sri dan Pak Rudi dibatasi terlalu ketat.',
      );
      final one = failCause(const TightLimit(['Bu Sri']));
      expect(one.title, 'Jatah Bu Sri dibatasi terlalu ketat.');
      expect(one.hint, 'Naikkan batas antreannya, kabelnya masih kuat.');
    });
  });

  group('tips layar berhasil', () {
    test('3★ tanpa tips; 2★ teks desain', () {
      expect(SuccessSummary(DummyData.success(3)).tip, isNull);
      expect(
        SuccessSummary(DummyData.success(2)).tip,
        'Pakai LAN di jalur yang sepi. Fiber cukup buat kabel utama, '
        'sisanya buat bintang ketiga.',
      );
    });

    test('2★ di level yang fibernya belum terbuka: tanpa fiber', () {
      const twoStars = LevelResult(
        level: Levels.level1,
        satisfaction: 100,
        budgetLeft: 35000,
        complaints: 0,
        housesLost: 0,
      );
      expect(twoStars.stars, 2);
      expect(
        SuccessSummary(twoStars).tip,
        'Tarik kabel lewat jalur terpendek. Sisa anggarannya buat bintang '
        'ketiga.',
      );
    });

    test('1★ kabel penuh (teks desain) & tanpa fiber', () {
      expect(
        SuccessSummary(DummyData.success(1)).tip,
        'Jalur Blok B penuh pas jam sibuk. Coba fiber di kabel utama, atau '
        'batasi jatah sebelum jam 19.',
      );
      expect(
        SuccessSummary(
          _oneStar(
            const FullCable(
              area: 'Rumah 2',
              minute: 19 * 60,
              heavyUsers: ['Bu Lina'],
              suggestFiber: false,
            ),
            level: 1,
          ),
        ).tip,
        'Jalur Rumah 2 penuh pas jam sibuk. Batasi jatah sebelum jam 19.',
      );
    });

    test('1★ belum tersambung, jatah ketat, tanpa biang kerok', () {
      expect(
        SuccessSummary(_oneStar(const Unconnected(['A', 'B']))).tip,
        'Masih ada 2 rumah yang belum tersambung. Sambungkan biar kepuasan '
        'naik.',
      );
      expect(
        SuccessSummary(_oneStar(const TightLimit(['Bu Sri']))).tip,
        'Jatah Bu Sri kebatasan. Naikkan batasnya, kabelnya masih kuat.',
      );
      expect(SuccessSummary(_oneStar(null)).tip, isNull);
    });

    test('syarat bintang dari level & hasil', () {
      final rules = SuccessSummary(DummyData.success(1)).rules;
      expect([for (final r in rules) r.passed], [true, false, false]);
      expect(rules[1].detail, 'Kepuasan akhir ≥ 80% · kamu 72%');
      expect(rules[2].detail, 'Sisa anggaran ≥ Rp 200.000 · kamu Rp 120.000');
    });
  });
}
