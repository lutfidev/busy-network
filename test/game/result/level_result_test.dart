import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/result/level_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sim/sim_fixtures.dart';

const _level5 = Levels.level5;
Cable _initial(String id) => _level5.cables.firstWhere((c) => c.id == id);
Cable _lan(String id, String from, String to) => Cable(
  id: id,
  from: from,
  to: to,
  points: const [Offset(0, 0), Offset(30, 0)],
);

/// Level uji tanpa fiber (nomor 1), rumah 15 Mbps di jam sibuk.
LevelDef _testLevel(Map<String, String?> blocks) => LevelDef(
  number: 1,
  name: 'Uji',
  gridOrigin: Offset.zero,
  routerPosition: Offset.zero,
  houses: [
    for (final MapEntry(key: id, value: block) in blocks.entries)
      HouseDef(
        id: id,
        label: 'Rumah $id',
        position: Offset.zero,
        customer: 'Pelanggan $id',
        block: block,
        packageMbps: 20,
        peakMbps: 15,
      ),
  ],
  budget: 200000,
  targetSatisfaction: 60,
  passSatisfaction: 40,
  blockLabels: const [],
);

LevelResult _result(GameState game) => LevelResult.of(playDay(game));

void main() {
  group('starsFor', () {
    int stars(LevelDef level, int satisfaction, [int budget = 0]) =>
        LevelResult.starsFor(
          level,
          satisfaction: satisfaction,
          budgetLeft: budget,
        );

    test('level 5: gagal < 60, 1★ < 80, 2★, 3★ dengan sisa Rp 200.000', () {
      expect(stars(_level5, 59, 999999), 0);
      expect(stars(_level5, 60), 1);
      expect(stars(_level5, 79, 999999), 1);
      expect(stars(_level5, 80, 199999), 2);
      expect(stars(_level5, 80, 200000), 3);
      expect(stars(_level5, 100, 850000), 3);
    });

    test('level 1: lulus mulai 40%', () {
      expect(stars(Levels.level1, 39), 0);
      expect(stars(Levels.level1, 40), 1);
    });
  });

  group('dari hari yang dimainkan', () {
    test('jaringan desain tanpa diatur: 75% → 1★, Blok B biang keroknya', () {
      final r = _result(designDay(designCables));
      expect(r.satisfaction, 75);
      expect(r.stars, 1);
      expect(r.passed, isTrue);
      expect(r.budgetLeft, 850000);
      expect(r.complaints, 1);
      expect(r.housesLost, 2);
      expect(
        r.culprit,
        isA<FullCable>()
            .having((c) => c.area, 'area', 'Blok B')
            .having((c) => c.minute, 'minute', 19 * 60)
            .having((c) => c.heavyUsers, 'heavyUsers', ['Bu Sri', 'Pak Rudi'])
            .having((c) => c.suggestFiber, 'suggestFiber', isTrue),
      );
    });

    test('kabel Rumah 4 fiber: 100%, 3★, tanpa biang kerok', () {
      final r = _result(designDay(designFiberCables));
      expect(r.satisfaction, 100);
      expect(r.stars, 3);
      expect(r.housesLost, 0);
      expect(r.culprit, isNull);
    });

    test('rancangan awal 4/7: 57% gagal, 3 rumah belum tersambung', () {
      final r = _result(designDay(_level5.cables));
      expect(r.satisfaction, 57);
      expect(r.stars, 0);
      expect(r.passed, isFalse);
      expect(r.housesLost, 3);
      expect(
        r.culprit,
        isA<Unconnected>().having((c) => c.customers, 'customers', [
          'Pak Rudi',
          'Bang Togar',
          'Mbak Wulan',
        ]),
      );
    });

    test('kabel penuh didahulukan dari rumah belum tersambung', () {
      final r5 = designCables.firstWhere((c) => c.id == 'c-r5');
      final r = _result(designDay([..._level5.cables, r5]));
      expect(r.satisfaction, 46);
      expect(r.stars, 0);
      expect(r.housesLost, 4);
      expect(
        r.culprit,
        isA<FullCable>().having((c) => c.area, 'area', 'Blok B'),
      );
    });

    test('Bu Sri dibatasi 11 Mbps: jatah terlalu ketat', () {
      final r = _result(designDay(designCables, limits: {'r4': 11}));
      expect(r.satisfaction, 87);
      expect(r.housesLost, 1);
      expect(
        r.culprit,
        isA<TightLimit>().having((c) => c.customers, 'customers', ['Bu Sri']),
      );
    });

    test('hari belum selesai → StateError', () {
      expect(() => LevelResult.of(designDay(designCables)), throwsStateError);
    });
  });

  group('area biang kerok', () {
    test('kabel campur blok → label rumah di ujung kabel', () {
      final r = _result(
        designDay([..._level5.cables, _lan('c-r6', 'r4', 'r6')]),
      );
      expect(
        r.culprit,
        isA<FullCable>().having((c) => c.area, 'area', 'Rumah 4').having(
          (c) => c.heavyUsers,
          'heavyUsers',
          ['Bu Sri', 'Bang Togar'],
        ),
      );
    });

    test('kabel ke junction, satu blok → blok', () {
      final r = _result(
        designDay([
          _lan('c-j1', LevelDef.routerId, 'j1'),
          _initial('c-r1'),
          _initial('c-r3'),
          _lan('c-w', 'j1', 'w'),
        ]),
      );
      expect(
        r.culprit,
        isA<FullCable>().having((c) => c.area, 'area', 'Blok A').having(
          (c) => c.heavyUsers,
          'heavyUsers',
          ['Warung Bu Ijah', 'Kak Dewi'],
        ),
      );
    });

    test('kabel ke junction, campur blok → rumah pertama yang dialiri', () {
      final r = _result(
        designDay([
          _lan('c-j1', LevelDef.routerId, 'j1'),
          _initial('c-r1'),
          _initial('c-r3'),
          _lan('c-r4', 'j1', 'r4'),
        ]),
      );
      expect(
        r.culprit,
        isA<FullCable>().having((c) => c.area, 'area', 'Rumah 1'),
      );
    });

    test('rumah tanpa blok → label rumah di ujung kabel', () {
      final level = _testLevel({'a': null, 'b': 'Blok X'});
      final r = _result(
        GameState(
          level,
          cables: [_lan('c-a', LevelDef.routerId, 'a'), _lan('c-b', 'a', 'b')],
        )..startDay(),
      );
      expect(
        r.culprit,
        isA<FullCable>().having((c) => c.area, 'area', 'Rumah a'),
      );
    });

    test(
      'fiber belum terbuka → tidak menyarankan fiber; jam sibuk default',
      () {
        final level = _testLevel({'a': 'Blok X', 'b': 'Blok X'});
        final r = _result(
          GameState(
            level,
            cables: [
              _lan('c-a', LevelDef.routerId, 'a'),
              _lan('c-b', 'a', 'b'),
            ],
          )..startDay(),
        );
        expect(
          r.culprit,
          isA<FullCable>()
              .having((c) => c.suggestFiber, 'suggestFiber', isFalse)
              .having((c) => c.minute, 'minute', 19 * 60),
        );
      },
    );

    test('seri lama penuh → kabel yang lebih dulu dipasang', () {
      final level = _testLevel({
        'a': 'Blok X',
        'b': 'Blok X',
        'c': 'Blok Y',
        'd': 'Blok Y',
      });
      final r = _result(
        GameState(
          level,
          cables: [
            _lan('c-a', LevelDef.routerId, 'a'),
            _lan('c-b', 'a', 'b'),
            _lan('c-c', LevelDef.routerId, 'c'),
            _lan('c-d', 'c', 'd'),
          ],
        )..startDay(),
      );
      expect(
        r.culprit,
        isA<FullCable>().having((c) => c.area, 'area', 'Blok X'),
      );
    });
  });

  group('level 1 (tarikan sungguhan)', () {
    const router = LevelDef.routerId;
    const toHouse1 = [Offset(180, 240), Offset(255, 165)];
    const toHouse2 = [Offset(210, 330), Offset(315, 345)];
    const house1ToHouse2 = [Offset(285, 255), Offset(315, 345)];
    // Memutar lewat atas: 7 segmen, satu lebih dari jalur terpendek.
    const toHouse2Detour = [
      Offset(165, 255),
      Offset(255, 255),
      Offset(315, 345),
    ];

    /// Level 1 dengan kabel dari tarikan [pulls] (sumber, jalur jari),
    /// dimainkan sampai 24:00.
    LevelResult play(List<(String, List<Offset>)> pulls) {
      final game = GameState(Levels.level1);
      for (final (from, path) in pulls) {
        expect(game.beginCable(from), isTrue);
        for (final p in path) {
          game.dragCable(p);
        }
        expect(game.endCable(), CableDrop.connected);
      }
      return LevelResult.of(playDay(game.planDay()));
    }

    test('target hemat Rp 30.000', () {
      expect(Levels.level1.savingsTarget, 30000);
    });

    test('Rumah 1 saja (tutorial): 50% → 1★', () {
      final r = play([(router, toHouse1)]);
      expect(r.satisfaction, 50);
      expect(r.budgetLeft, 125000);
      expect(r.stars, 1);
    });

    test('dua kabel dari router: sisa Rp 35.000 → 3★', () {
      final r = play([(router, toHouse1), (router, toHouse2)]);
      expect(r.satisfaction, 100);
      expect(r.budgetLeft, 35000);
      expect(r.stars, 3);
    });

    test('rantai lewat Rumah 1: sisa Rp 50.000 → 3★', () {
      final r = play([(router, toHouse1), ('r1', house1ToHouse2)]);
      expect(r.budgetLeft, 50000);
      expect(r.stars, 3);
    });

    test('satu segmen terbuang: sisa Rp 20.000 → 2★', () {
      final r = play([(router, toHouse1), (router, toHouse2Detour)]);
      expect(r.satisfaction, 100);
      expect(r.budgetLeft, 20000);
      expect(r.stars, 2);
    });
  });
}
