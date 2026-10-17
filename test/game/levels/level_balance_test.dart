import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'level_plans.dart';

const _r = LevelDef.routerId;

/// Bintang rancangan [plan] di level [number].
int _stars(int number, Plan plan, {Map<String, int> limits = const {}}) =>
    play(Levels.byNumber(number)!, plan, limits: limits).stars;

void main() {
  group('rancangan acuan', () {
    for (final level in Levels.all) {
      test('level ${level.number} bisa 3★, semua rumah tersambung', () {
        final plan = referencePlans[level.number]!;
        final s = design(level, plan);
        expect(s.connectedCount, level.houses.length);
        final r = play(level, plan);
        expect(r.stars, 3, reason: '${r.satisfaction}% sisa ${r.budgetLeft}');
      });
    }
  });

  // Jebakan yang membuat tiap level jadi teka-teki: rancangan yang kelihatan
  // wajar tapi tidak mendapat 3★.
  group('jebakan', () {
    test('level 2: semua kabel dari router terlalu boros → 2★', () {
      expect(
        _stars(2, const Plan([Pull(_r, 'r1'), Pull(_r, 'r2'), Pull(_r, 'r3')])),
        2,
      );
    });

    test('level 3: Warnet lewat LAN atau dibiarkan → 1★', () {
      const lan = Plan([
        Pull(_r, 'w'),
        Pull(_r, 'r1'),
        Pull(_r, 'r2'),
        Pull('r2', 'r3'),
      ]);
      expect(_stars(3, lan), 1);
      expect(_stars(3, lan, limits: {'w': 20}), 1);
      expect(
        _stars(3, const Plan([Pull(_r, 'r1'), Pull(_r, 'r2'), Pull(_r, 'r3')])),
        1,
      );
    });

    test('level 4: semua lewat tiang LAN gagal; fiber ke tiang → 2★', () {
      List<Pull> viaPole(CableKind kind) => [
        Pull(_r, 'j1', kind: kind),
        for (final h in ['r1', 'r2', 'r3', 'r4', 'r5']) Pull('j1', h),
      ];
      expect(_stars(4, Plan(viaPole(CableKind.lan))), 0);
      expect(_stars(4, Plan(viaPole(CableKind.fiber))), 2);
    });

    test('level 6: jaringan lama gagal; antrean saja tidak cukup', () {
      expect(_stars(6, const Plan([])), 0);
      expect(
        _stars(
          6,
          const Plan([Pull('r5', 'r6')]),
          limits: {'r1': 5, 'r2': 4, 'r3': 5, 'r4': 5},
        ),
        1,
      );
    });

    test('level 7: tiga rumah lewat tiang LAN → 1★; fiber → 2★', () {
      List<Pull> plan(CableKind pole) => [
        Pull(_r, 'j1', kind: pole),
        Pull('j1', 'r1'),
        Pull('j1', 'r2'),
        Pull('j1', 'r3'),
        Pull(_r, 'r4'),
        Pull('r4', 'r5'),
        Pull(_r, 'r7'),
        Pull('r7', 'r6'),
      ];
      expect(_stars(7, Plan(plan(CableKind.lan))), 1);
      expect(_stars(7, Plan(plan(CableKind.fiber))), 2);
    });

    test('level 8: tanpa fiber, ruko berbagi kabel → gagal', () {
      expect(
        _stars(
          8,
          const Plan([
            Pull(_r, 'r6'),
            Pull('r6', 'j1'),
            Pull('j1', 'r1'),
            Pull('j1', 'k2'),
            Pull(_r, 'r4'),
            Pull('r4', 'r2'),
            Pull('r2', 'k1'),
            Pull(_r, 'r5'),
            Pull('r5', 'r3'),
          ]),
        ),
        0,
      );
    });

    test('level 9: semua dari router → 2★; bertiga sekabel → gagal', () {
      expect(
        _stars(9, Plan([for (var i = 1; i <= 8; i++) Pull(_r, 'r$i')])),
        2,
      );
      expect(
        _stars(
          9,
          const Plan([
            Pull(_r, 'r2'),
            Pull('r2', 'r1'),
            Pull('r2', 'r3'),
            Pull(_r, 'r4'),
            Pull('r4', 'r5'),
            Pull(_r, 'r6'),
            Pull('r6', 'r7'),
            Pull(_r, 'r8'),
          ]),
        ),
        0,
      );
    });

    test('level 10: rantai tiga rumah lewat 20 Mbps → 1★', () {
      expect(
        _stars(
          10,
          const Plan([
            Pull(_r, 'r1'),
            Pull('r1', 'r2'),
            Pull(_r, 'j1'),
            Pull('j1', 'r3'),
            Pull('j1', 'r4'),
            Pull(_r, 'r9'),
            Pull('r9', 'r8'),
            Pull('r8', 'r7'),
            Pull(_r, 'j2'),
            Pull('j2', 'r6'),
            Pull('r6', 'r5'),
          ]),
        ),
        1,
      );
    });

    test('level 11: semua dari router → 2★', () {
      expect(
        _stars(11, Plan([for (var i = 1; i <= 10; i++) Pull(_r, 'r$i')])),
        2,
      );
    });

    test('level 12: rantai yang aman di jam biasa penuh saat nobar', () {
      const chained = Plan([
        Pull.fiber(_r, 'pos'),
        Pull(_r, 'r2'),
        Pull(_r, 'r1'),
        Pull(_r, 'r3'),
        Pull(_r, 'r4'),
        Pull(_r, 'r5'),
        Pull(_r, 'r7'),
        Pull(_r, 'r8'),
        // Rumah 7 + Rumah 6 = 18 Mbps; saat nobar 27 Mbps.
        Pull('r7', 'r6'),
      ]);
      expect(_stars(12, chained), 1);
      const lanPos = Plan([
        Pull(_r, 'pos'),
        Pull(_r, 'r2'),
        Pull(_r, 'r1'),
        Pull('r1', 'r8'),
        Pull(_r, 'r3'),
        Pull(_r, 'r4'),
        Pull(_r, 'r5'),
        Pull(_r, 'r7'),
        Pull('r7', 'r6'),
      ]);
      expect(_stars(12, lanPos), lessThan(2));
    });
  });

  test('lonjakan nobar: rantai Rumah 7 → Rumah 6 penuh hanya 20–22', () {
    final s = design(
      Levels.level12,
      const Plan([Pull(_r, 'r7'), Pull('r7', 'r6')]),
    )..startDay();
    final day = s.day!;
    bool full() => day.network.isOverloaded(
      day.network.cables.firstWhere((c) => c.id == 'c-r7'),
      day.frame.demand,
    );
    void until(int minute) {
      while (day.minute < minute) {
        day.dismissComplaint();
        day.advance((minute - day.minute).toDouble());
      }
    }

    until(19 * 60 + 59);
    expect(full(), isFalse);
    until(20 * 60);
    expect(full(), isTrue);
    until(22 * 60 - 1);
    expect(full(), isTrue);
    until(22 * 60);
    expect(full(), isFalse);
  });
}
