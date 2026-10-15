import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/screens/queue_panel/queue_logic.dart';
import 'package:busy_network/widgets/status_dot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueueModel', () {
    test('kondisi awal sesuai desain: 25/20 Mbps, kelebihan beban', () {
      final m = QueueModel.initial();
      expect(m.load, 25);
      expect(m.overloaded, isTrue);
      final r4 = m.houses.firstWhere((h) => h.id == 'r4');
      final r5 = m.houses.firstWhere((h) => h.id == 'r5');
      expect(m.statusOf(r4), ServiceStatus.jam);
      expect(m.statusOf(r5), ServiceStatus.slow);
      expect(m.priority, {'w'});
    });

    test('menurunkan batas Bu Sri mengurangi beban', () {
      final m = QueueModel.initial().withLimit('r4', 8);
      expect(m.load, 17);
      expect(m.overloaded, isFalse);
      expect(m.tight, isFalse);
      final r4 = m.houses.firstWhere((h) => h.id == 'r4');
      expect(m.statusOf(r4), ServiceStatus.slow); // 8 < 16 × 0,6
    });

    test('beban 18 Mbps dianggap pas-pasan', () {
      final m = QueueModel.initial().withLimit('r4', 9);
      expect(m.load, 18);
      expect(m.tight, isTrue);
    });

    test('toggle prioritas', () {
      final m = QueueModel.initial().togglePriority('w').togglePriority('r1');
      expect(m.priority, {'r1'});
    });
  });

  group('QueueModel.fromState', () {
    test('diturunkan dari snapshot fase jalan', () {
      final m = QueueModel.initial();
      expect(m.cableLabel, 'Kabel Router → Rumah 4');
      expect(m.capacityMbps, 20);
      expect(m.houses.map((h) => h.id).toList(), DummyStates.queueOrder);
      expect(
        {
          for (final h in m.houses)
            if (h.onOverloadedCable) h.id,
        },
        {'r4', 'r5'},
      );
      final w = m.houses.firstWhere((h) => h.id == 'w');
      expect(w.name, 'Warung Bu Ijah');
      expect(w.where, 'Blok A');
      expect(w.packageMbps, 20);
      expect(w.usageMbps, 12);
      expect(m.limits['w'], 20);
    });

    test('tanpa kabel penuh: pakai kabel dengan rasio beban tertinggi', () {
      final state = GameState(
        Levels.level5,
        phase: GamePhase.run,
        frame: const SimFrame(
          houses: {
            'r4': HouseLive(state: HouseState.ok, patience: 1, usageMbps: 10),
            'r1': HouseLive(state: HouseState.ok, patience: 1, usageMbps: 4),
          },
        ),
      );
      final m = QueueModel.fromState(
        state,
        order: const ['r4', 'r1'],
        priority: const {},
      );
      expect(m.cableLabel, 'Kabel Router → Rumah 4');
      expect(m.overloaded, isFalse);
    });

    test('ubah batas mempertahankan judul kabel', () {
      final m = QueueModel.initial().withLimit('r4', 8).togglePriority('r1');
      expect(m.cableLabel, 'Kabel Router → Rumah 4');
    });
  });
}
