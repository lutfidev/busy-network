import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/sim/queue_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  QueuePlan design() => QueuePlan.of(DummyStates.run().day!);

  group('bingkai desain', () {
    test('kabel Router → Rumah 4: 25/20 Mbps, kelebihan beban', () {
      final p = design();
      expect(p.cableLabel, 'Kabel Router → Rumah 4');
      expect(p.capacityMbps, 20);
      expect(p.load, 25);
      expect(p.overloaded, isTrue);
      expect(
        {
          for (final h in p.houses)
            if (h.onCable) h.id,
        },
        {'r4', 'r5'},
      );
    });

    test('urutan rumah sama dengan desain', () {
      expect(design().houses.map((h) => h.id), [
        'r4',
        'r5',
        'r3',
        'w',
        'r1',
        'r6',
        'r7',
      ]);
    });

    test('status: Bu Sri macet, Pak Rudi & Kak Dewi mulai lambat', () {
      final p = design();
      expect(p.statusOf('r4'), HouseState.jam);
      expect(p.statusOf('r5'), HouseState.slow);
      expect(p.statusOf('r3'), HouseState.slow);
      expect(p.statusOf('w'), HouseState.ok);
    });

    test('isi kartu & antrean awal dari hari', () {
      final p = design();
      final w = p.houses.firstWhere((h) => h.id == 'w');
      expect(w.name, 'Warung Bu Ijah');
      expect(w.where, 'Blok A');
      expect(w.packageMbps, 20);
      expect(w.usageMbps, 12);
      expect(p.limits['w'], 20);
      expect(p.priority, {'w'});
      expect(p.useOf('r3'), 8.5);
    });

    test('pemakai terbesar di kabel: Bu Sri lalu Pak Rudi', () {
      expect(design().heaviest.map((h) => h.name), ['Bu Sri', 'Pak Rudi']);
    });
  });

  group('menggeser antrean', () {
    test('batas Bu Sri 8: beban 17, lega; Bu Sri mulai lambat', () {
      final p = design().withLimit('r4', 8);
      expect(p.load, 17);
      expect(p.overloaded, isFalse);
      expect(p.tight, isFalse);
      expect(p.useOf('r4'), 8);
      expect(p.statusOf('r4'), HouseState.slow);
    });

    test('beban 18 Mbps dianggap pas-pasan', () {
      final p = design().withLimit('r4', 9);
      expect(p.load, 18);
      expect(p.tight, isTrue);
    });

    test('prioritas Bu Sri: tidak macet lagi', () {
      final p = design().togglePriority('r4');
      expect(p.priority, {'w', 'r4'});
      expect(p.statusOf('r4'), HouseState.slow); // sabar 15%
      expect(p.overloaded, isTrue);
    });

    test('toggle prioritas & judul kabel tetap', () {
      final p = design().togglePriority('w').togglePriority('r1');
      expect(p.priority, {'r1'});
      expect(p.withLimit('r4', 8).cableLabel, 'Kabel Router → Rumah 4');
    });

    test('pratinjau tidak mengubah hari', () {
      final state = DummyStates.run();
      QueuePlan.of(state.day!).withLimit('r4', 8);
      expect(state.day!.limits['r4'], 20);
    });
  });

  group('kabel lain', () {
    test('tanpa kabel penuh: pakai kabel dengan rasio beban tertinggi', () {
      final p = QueuePlan.of((GameState(Levels.level5)..startDay()).day!);
      expect(p.cableLabel, 'Kabel Router → Rumah 4');
      expect(p.overloaded, isFalse);
    });

    test('kabel tersesak berpangkal di junction: nama dari hulunya', () {
      Cable initial(String id) =>
          Levels.level5.cables.firstWhere((c) => c.id == id);
      final state = GameState(
        Levels.level5,
        cables: [initial('c-w'), initial('c-r3')],
      )..startDay(minute: 20 * 60);
      final p = QueuePlan.of(state.day!);
      expect(p.cableLabel, 'Kabel Router → Rumah 3');
      expect(p.houses.firstWhere((h) => h.onCable).id, 'r3');
    });

    test('kabel paralel ke junction: hanya rumah di ujungnya dihitung', () {
      Cable initial(String id) =>
          Levels.level5.cables.firstWhere((c) => c.id == id);
      final state = GameState(
        Levels.level5,
        cables: [
          initial('c-w'),
          initial('c-r1'),
          initial('c-r3'),
          const Cable(
            id: 'c-x',
            from: LevelDef.routerId,
            to: 'r6',
            via: ['j1'],
            points: [Offset(195, 216), Offset(195, 400)],
          ),
        ],
      )..startDay(minute: 20 * 60);
      final p = QueuePlan.of(state.day!);
      expect(p.cable!.id, 'c-x');
      expect(
        [
          for (final h in p.houses)
            if (h.onCable) h.id,
        ],
        ['r6'],
      );
      expect(p.load, 11);
      expect(p.overloaded, isFalse);
    });

    test('tanpa kabel sama sekali: panel tetap terbentuk', () {
      final state = GameState(
        Levels.level5,
        junctions: const [],
        cables: const [],
      )..startDay();
      final p = QueuePlan.of(state.day!);
      expect(p.cableLabel, isEmpty);
      expect(p.houses, isEmpty);
      expect(p.capacityMbps, 0);
      expect(p.overloaded, isFalse);
    });
  });
}
