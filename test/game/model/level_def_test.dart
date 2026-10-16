import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/cable.dart';
import 'package:busy_network/game/model/level_def.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cable_checks.dart';

void main() {
  test('sel grid model = sel grid peta', () {
    expect(LevelDef.cell, AppSpacing.mapCell);
  });

  for (final level in Levels.all) {
    group('Level ${level.number}', () {
      test('id node & kabel unik', () {
        final ids = [
          LevelDef.routerId,
          ...level.houses.map((h) => h.id),
          ...level.junctions.map((j) => j.id),
        ];
        expect(ids.toSet(), hasLength(ids.length));
        final cables = level.cables.map((c) => c.id).toList();
        expect(cables.toSet(), hasLength(cables.length));
      });

      test('node di grid level', () {
        expect(level.onGrid(level.routerPosition), isTrue);
        for (final h in level.houses) {
          expect(level.onGrid(h.position), isTrue, reason: h.id);
        }
        for (final j in level.junctions) {
          expect(level.onGrid(j.position), isTrue, reason: j.id);
        }
      });

      test('kabel awal sah', () {
        for (final c in level.cables) {
          expectValidCable(level, c, level.positionOf);
        }
      });
    });
  }

  test('kabel terbuka mengikuti level buka', () {
    expect(Levels.level1.unlockedCables, [CableSpec.lan]);
    expect(Levels.level5.unlockedCables, [CableSpec.lan, CableSpec.fiber]);
  });

  test('tempat default = label', () {
    expect(Levels.level5.house('r4').place, 'Rumah 4');
    expect(Levels.level5.house('w').place, 'Blok A');
  });

  test('positionOf router, rumah, junction', () {
    const l = Levels.level5;
    expect(l.positionOf(LevelDef.routerId), const Offset(195, 240));
    expect(l.positionOf('r5'), const Offset(315, 390));
    expect(l.positionOf('j1'), const Offset(195, 150));
    expect(() => l.positionOf('zz'), throwsArgumentError);
  });

  test('onGrid memakai titik asal level', () {
    expect(Levels.level1.onGrid(const Offset(105, 315)), isTrue);
    expect(Levels.level5.onGrid(const Offset(105, 315)), isFalse);
    expect(Levels.level5.onGrid(const Offset(195, 240)), isTrue);
  });

  test('label blok malam level 1 = siang', () {
    expect(Levels.level1.nightBlockLabels, same(Levels.level1.blockLabels));
  });

  group('aturan lulus, blok & babak', () {
    test('batas lulus di bawah target; hemat default Rp 200.000', () {
      expect(Levels.level5.passSatisfaction, 60);
      expect(Levels.level5.targetSatisfaction, 80);
      expect(Levels.level1.passSatisfaction, 40);
      expect(Levels.level5.savingsTarget, LevelDef.defaultSavingsTarget);
      expect(LevelDef.defaultSavingsTarget, 200000);
    });

    test('blok rumah level 5', () {
      expect(
        {for (final h in Levels.level5.houses) h.id: h.block},
        {
          'r1': 'Blok A',
          'w': 'Blok A',
          'r3': 'Blok A',
          'r4': 'Blok B',
          'r5': 'Blok B',
          'r6': 'Blok C',
          'r7': 'Blok C',
        },
      );
      expect(Levels.level1.house('r1').block, 'Blok A');
      expect(Levels.level1.house('r2').block, isNull);
    });

    test('byNumber: hanya level yang ada datanya', () {
      expect(Levels.byNumber(1), same(Levels.level1));
      expect(Levels.byNumber(5), same(Levels.level5));
      expect(Levels.byNumber(6), isNull);
      expect(Levels.byNumber(0), isNull);
    });

    test('babak 1: 12 level, 36 bintang', () {
      expect(Levels.chapter.number, 1);
      expect(Levels.chapter.name, 'Perumahan Batam');
      expect(Levels.chapter.levelCount, 12);
      expect(Levels.chapter.starsTotal, 36);
    });
  });
}
