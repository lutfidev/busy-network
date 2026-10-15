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
}
