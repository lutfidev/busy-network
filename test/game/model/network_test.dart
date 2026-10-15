import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/cable.dart';
import 'package:busy_network/game/model/level_def.dart';
import 'package:busy_network/game/model/network.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const level = Levels.level5;
  Cable initial(String id) => level.cables.firstWhere((c) => c.id == id);

  // Kabel tambahan di snapshot fase jalan (lihat spec).
  const extra = [
    Cable(
      id: 'c-r6',
      from: LevelDef.routerId,
      to: 'r6',
      via: ['j2'],
      points: [Offset(195, 264), Offset(195, 400)],
    ),
    Cable(
      id: 'c-r7',
      from: 'j2',
      to: 'r7',
      points: [Offset(195, 330), Offset(95, 330)],
    ),
    Cable(
      id: 'c-r5',
      from: 'r4',
      to: 'r5',
      points: [Offset(315, 260), Offset(315, 370)],
    ),
  ];
  const usage = {
    'r1': 4.0,
    'w': 12.0,
    'r3': 8.5,
    'r4': 16.0,
    'r5': 9.0,
    'r6': 11.0,
    'r7': 6.0,
  };
  final runCables = [...level.cables, ...extra];
  Cable runCable(String id) => runCables.firstWhere((c) => c.id == id);

  test('level 5 awal: 4 rumah tersambung', () {
    final net = Network(level: level, cables: level.cables);
    expect(net.connectedHouses, {'r1', 'w', 'r3', 'r4'});
  });

  test('junction mendapat induk dari kabel yang melewatinya', () {
    final net = Network(level: level, cables: level.cables);
    final j1 = net.parentOf('j1')!;
    expect(j1.cable.id, 'c-w');
    expect((j1.from, j1.to), (LevelDef.routerId, 'j1'));
    expect(net.parentOf('w')!.from, 'j1');
    expect(net.parentOf('r1')!.cable.id, 'c-r1');
    expect(net.parentOf(LevelDef.routerId), isNull);
  });

  test('hop pohon berurutan hulu dulu; kedalaman node', () {
    final net = Network(level: level, cables: runCables);
    final seen = {LevelDef.routerId};
    for (final hop in net.treeHops) {
      expect(seen, contains(hop.from), reason: '${hop.from} → ${hop.to}');
      seen.add(hop.to);
    }
    expect(seen, containsAll(usage.keys));
    expect(net.depthOf(LevelDef.routerId), 0);
    expect(net.depthOf('r4'), 1);
    expect(net.depthOf('r5'), 2);
    expect(net.depthOf('w'), 2); // router → j1 → Warung
  });

  group('snapshot fase jalan', () {
    final net = Network(level: level, cables: runCables);

    test('semua 7 rumah tersambung', () {
      expect(net.connectedHouses, hasLength(7));
    });

    test('beban Router → Rumah 4 = 16 + 9 = 25', () {
      expect(net.housesBelow('r4'), {'r4', 'r5'});
      expect(net.hopLoad(net.parentOf('r4')!, usage), 25);
      expect(net.cableLoad(initial('c-r4'), usage), 25);
    });

    test('fiber Warung: hop terberat router → j1 = 24,5', () {
      expect(net.cableLoad(initial('c-w'), usage), 24.5);
      expect(net.hopLoad(net.parentOf('w')!, usage), 12);
    });

    test('hanya kabel Rumah 4 yang kelebihan beban', () {
      final overloaded = [
        for (final c in runCables)
          if (net.isOverloaded(c, usage)) c.id,
      ];
      expect(overloaded, ['c-r4']);
    });

    test('macet menular ke hilir', () {
      expect(net.isJammed(runCable('c-r4'), usage), isTrue);
      expect(net.isJammed(runCable('c-r5'), usage), isTrue);
      expect(net.isJammed(runCable('c-r6'), usage), isFalse);
      expect(net.isJammed(runCable('c-r7'), usage), isFalse);
      expect(net.isJammed(runCable('c-r1'), usage), isFalse);
      expect(net.isJammed(runCable('c-w'), usage), isFalse);
    });
  });

  test('rumah tanpa jalur ke router tidak tersambung & tidak berbeban', () {
    final net = Network(level: level, cables: [initial('c-r1')]);
    expect(net.connectedHouses, isEmpty);
    expect(net.cableLoad(initial('c-r1'), usage), 0);
    expect(net.isOverloaded(initial('c-r1'), usage), isFalse);
  });

  test('siklus & kabel ke arah router tidak membuat macet', () {
    const step = [Offset.zero, Offset(30, 0)];
    const loop = [
      Cable(id: 'a', from: LevelDef.routerId, to: 'r4', points: step),
      Cable(id: 'b', from: 'r4', to: 'r5', points: step),
      Cable(id: 'c', from: 'r5', to: 'r4', points: step),
      Cable(id: 'd', from: 'r5', to: LevelDef.routerId, points: step),
    ];
    final net = Network(level: level, cables: loop);
    expect(net.connectedHouses, {'r4', 'r5'});
    expect(net.parentOf('r4')!.cable.id, 'a');
    expect(net.parentOf(LevelDef.routerId), isNull);
    expect(net.cableLoad(loop.first, usage), 25);
    // Kabel balik tidak mengalirkan apa pun.
    expect(net.cableLoad(loop[2], usage), 0);
    expect(net.isOverloaded(loop[2], usage), isFalse);
    expect(net.cableLoad(loop[3], usage), 0);
    expect(net.isOverloaded(loop[3], usage), isFalse);
  });

  test('kabel di luar pohon tidak ikut beban', () {
    const step = [Offset.zero, Offset(30, 0)];
    const main = Cable(
      id: 'a',
      from: LevelDef.routerId,
      to: 'r4',
      points: step,
    );
    const parallel = Cable(
      id: 'b',
      from: LevelDef.routerId,
      to: 'r4',
      points: step,
    );
    const fromLoose = Cable(id: 'c', from: 'r7', to: 'r4', points: step);
    final net = Network(
      level: level,
      cables: const [main, parallel, fromLoose],
    );
    expect(net.cableLoad(main, usage), 16);
    expect(net.cableLoad(parallel, usage), 0);
    expect(net.cableLoad(fromLoose, usage), 0);
    expect(net.isJammed(fromLoose, usage), isFalse);
  });
}
