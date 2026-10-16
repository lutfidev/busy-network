import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/sim/sim.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sim_fixtures.dart';

const _level = Levels.level5;

DaySim _sim(
  List<Cable> cables, {
  int minute = SimClock.dayStart,
  Map<String, double> patience = const {},
  Map<String, int> limits = const {},
  Set<String> priority = const {},
  Complaint? complaint,
}) => DaySim(
  level: _level,
  network: Network(level: _level, cables: cables),
  minute: minute,
  patience: patience,
  limits: limits,
  priority: priority,
  complaint: complaint,
);

/// Mainkan sampai 24:00 dengan langkah [chunk] menit; komplain langsung
/// diabaikan. Mengembalikan komplain yang muncul.
List<Complaint> _playDay(DaySim sim, {double chunk = 1}) {
  final complaints = <Complaint>[];
  while (!sim.over) {
    sim.advance(chunk);
    if (sim.complaint case final c?) {
      complaints.add(c);
      sim.dismissComplaint();
    }
  }
  return complaints;
}

/// Potret bingkai Fase Jalan di desain.
const _designPatience = {
  'r1': 0.9,
  'w': 0.85,
  'r3': 0.55,
  'r4': 0.15,
  'r5': 0.4,
  'r6': 0.8,
  'r7': 0.75,
};

void main() {
  group('awal hari', () {
    test('06:00, sabar penuh, batas = paket', () {
      final sim = _sim(designCables);
      expect(sim.minute, SimClock.dayStart);
      expect(sim.over, isFalse);
      expect(sim.complaint, isNull);
      expect(sim.limits, {for (final h in _level.houses) h.id: h.packageMbps});
      final r4 = sim.frame.houses['r4']!;
      expect(r4.patience, 1);
      expect(r4.state, HouseState.ok);
      expect(r4.usageMbps, 16 * UsageCurve.morningShare);
      expect(sim.satisfaction, 100);
    });

    test('rumah belum tersambung dihitung 0 di kepuasan', () {
      final sim = _sim(_level.cables);
      expect(sim.frame.houses.keys, ['r1', 'w', 'r3', 'r4']);
      expect(sim.satisfaction, 57); // 4/7
    });
  });

  group('jam', () {
    test('pecahan menit ditabung', () {
      final sim = _sim(designCables);
      expect(sim.advance(0.6), isFalse);
      expect(sim.minute, SimClock.dayStart);
      expect(sim.advance(0.6), isTrue);
      expect(sim.minute, SimClock.dayStart + 1);
      expect(sim.frame.minute, SimClock.dayStart + 1);
    });

    test('berhenti di 24:00', () {
      final sim = _sim(designFiberCables);
      _playDay(sim, chunk: 50);
      expect(sim.minute, SimClock.dayEnd);
      expect(sim.over, isTrue);
      expect(sim.advance(10), isFalse);
    });

    test('deterministik: potongan langkah tidak mengubah hasil', () {
      final a = _sim(designCables);
      final b = _sim(designCables);
      expect(_playDay(a), _playDay(b, chunk: 7.3));
      expect(a.satisfaction, b.satisfaction);
      for (final id in a.frame.houses.keys) {
        expect(
          a.frame.houses[id]!.patience,
          b.frame.houses[id]!.patience,
          reason: id,
        );
      }
    });
  });

  group('bingkai desain 20:15 dihitung dari potret', () {
    final sim = _sim(
      designCables,
      minute: 20 * 60 + 15,
      patience: _designPatience,
      priority: const {'w'},
      complaint: const Complaint(houseId: 'r4', minute: 20 * 60 + 14),
    );
    final houses = sim.frame.houses;

    test('pemakaian puncak, kabel Rumah 4 membawa 25 Mbps', () {
      expect(houses['r4']!.demandMbps, 16);
      expect(houses['r5']!.demandMbps, 9);
      expect(houses['r4']!.servedMbps, closeTo(12.8, 1e-9));
    });

    test('Bu Sri macet, Kak Dewi & Pak Rudi mulai lambat, sisanya lancar', () {
      expect(
        {for (final e in houses.entries) e.key: e.value.state},
        {
          'r1': HouseState.ok,
          'w': HouseState.ok,
          'r3': HouseState.slow,
          'r4': HouseState.jam,
          'r5': HouseState.slow,
          'r6': HouseState.ok,
          'r7': HouseState.ok,
        },
      );
    });

    test('kepuasan 62% (rata-rata sabar, dibulatkan ke bawah)', () {
      expect(sim.satisfaction, 62);
    });

    test('komplain menjeda hari', () {
      expect(sim.complaint, const Complaint(houseId: 'r4', minute: 1214));
      expect(sim.advance(5), isFalse);
      expect(sim.minute, 20 * 60 + 15);
      sim.dismissComplaint();
      expect(sim.advance(1), isTrue);
    });
  });

  group('sepanjang hari', () {
    test('jaringan desain tanpa diatur: Bu Sri komplain, gagal target', () {
      final sim = _sim(designCables);
      final complaints = _playDay(sim);
      expect(complaints, const [
        Complaint(houseId: 'r4', minute: 18 * 60 + 17),
      ]);
      expect(sim.complaints, 1);
      expect(sim.satisfaction, lessThan(_level.targetSatisfaction));
    });

    test('Bu Sri dibatasi 11 Mbps: kabel tidak penuh, lolos target', () {
      final sim = _sim(designCables, limits: const {'r4': 11});
      expect(_playDay(sim), isEmpty);
      expect(sim.satisfaction, greaterThanOrEqualTo(_level.targetSatisfaction));
    });

    test('kabel Rumah 4 fiber: semua lancar sampai akhir', () {
      final sim = _sim(designFiberCables);
      expect(_playDay(sim), isEmpty);
      expect(sim.satisfaction, 100);
    });

    test('sabar macet habis lebih cepat daripada yang di hilirnya', () {
      final sim = _sim(designCables);
      while (sim.minute < 20 * 60 + 15) {
        sim.advance(1);
        sim.dismissComplaint();
      }
      final r4 = sim.frame.houses['r4']!.patience;
      final r5 = sim.frame.houses['r5']!.patience;
      expect(r4, lessThan(r5));
      expect(r5, lessThan(1));
    });
  });

  group('komplain', () {
    test('rumah yang sama tidak komplain lagi dalam 2 jam', () {
      final sim = _sim(
        designCables,
        minute: 18 * 60,
        complaint: const Complaint(houseId: 'r4', minute: 18 * 60),
      )..dismissComplaint();
      while (sim.minute < 18 * 60 + 30) {
        sim.advance(1);
      }
      expect(sim.frame.houses['r4']!.state, HouseState.jam);
      expect(sim.complaint, isNull);
      expect(sim.complaints, 0);
    });

    test('rumah yang macet bersamaan komplain bergiliran', () {
      // Fiber Warung diganti LAN: jam 20:00 kabel Warung (24,5/20) dan
      // kabel Rumah 4 (25/20) sama-sama penuh.
      final sim = _sim([
        for (final c in designCables)
          c.id == 'c-w'
              ? Cable(
                  id: c.id,
                  from: c.from,
                  to: c.to,
                  via: c.via,
                  points: c.points,
                )
              : c,
      ], minute: 20 * 60);
      expect(sim.frame.houses['w']!.state, HouseState.jam);
      expect(sim.frame.houses['r4']!.state, HouseState.jam);
      sim.advance(1);
      expect(sim.complaint!.houseId, 'w');
      sim
        ..dismissComplaint()
        ..advance(1);
      expect(sim.complaint!.houseId, 'r4');
      sim
        ..dismissComplaint()
        ..advance(30);
      expect(sim.complaint, isNull, reason: 'sekali per masa macet');
      expect(sim.complaints, 2);
    });

    test('macet sejak masa jeda: komplain begitu jedanya habis', () {
      // Komplain 18:00 (sebelum macet); Rumah 4 macet sejak 18:17 saat
      // masih jeda, jeda 2 jam habis 20:00.
      final sim = _sim(
        designCables,
        minute: 18 * 60,
        complaint: const Complaint(houseId: 'r4', minute: 18 * 60),
      )..dismissComplaint();
      while (sim.complaint == null && sim.minute < 21 * 60) {
        sim.advance(1);
      }
      expect(sim.complaint, const Complaint(houseId: 'r4', minute: 20 * 60));
    });

    test('mengubah antrean tidak memicu komplain', () {
      final sim = _sim(designCables, minute: 20 * 60, limits: const {'r4': 11})
        ..setQueue(limits: const {}, priority: const {});
      expect(sim.frame.houses['r4']!.state, HouseState.jam);
      expect(sim.complaint, isNull);
    });
  });

  group('antrean', () {
    DaySim peak() => _sim(designCables, minute: 20 * 60);

    test('batas Bu Sri 11: kabel tidak penuh, Bu Sri kekurangan', () {
      final sim = peak()
        ..setQueue(limits: const {'r4': 11}, priority: const {});
      final r4 = sim.frame.houses['r4']!;
      expect(r4.demandMbps, 11);
      expect(r4.servedMbps, 11);
      expect(r4.state, HouseState.ok); // 11/16 ≥ 60%
      expect(sim.frame.houses['r5']!.servedMbps, 9);
      expect(sim.limits['r4'], 11);
    });

    test('prioritas Bu Sri: tidak macet, Pak Rudi yang kekurangan', () {
      final sim = peak()..setQueue(limits: const {}, priority: const {'r4'});
      expect(sim.frame.houses['r4']!.state, HouseState.ok);
      expect(sim.frame.houses['r5']!.servedMbps, 4);
      expect(sim.frame.houses['r5']!.state, HouseState.slow);
    });

    test('pratinjau tidak mengubah hari', () {
      final sim = peak();
      final preview = sim.preview(limits: const {'r4': 11}, priority: const {});
      expect(preview['r4']!.demandMbps, 11);
      expect(sim.frame.houses['r4']!.demandMbps, 16);
      expect(sim.limits['r4'], 20);
    });

    test('batas di luar 1..paket atau rumah tak tersambung ditolak', () {
      final sim = _sim(_level.cables);
      expect(
        () => sim.setQueue(limits: const {'r4': 21}, priority: const {}),
        throwsArgumentError,
      );
      expect(
        () => sim.setQueue(limits: const {'r4': 0}, priority: const {}),
        throwsArgumentError,
      );
      expect(
        () => sim.setQueue(limits: const {'r5': 5}, priority: const {}),
        throwsArgumentError,
      );
      expect(
        () => sim.setQueue(limits: const {}, priority: const {'r5'}),
        throwsArgumentError,
      );
    });
  });

  group('statistik hari', () {
    test('jaringan desain: kabel Rumah 4 penuh 258 menit mulai 18:17, '
        'terparah 19:00; sabar Rumah 4 & 5 sempat habis', () {
      final sim = _sim(designCables);
      _playDay(sim);
      expect(sim.fullMinutes('c-r4'), 258);
      expect(sim.firstFullMinute('c-r4'), 18 * 60 + 17);
      expect(sim.peakMinute('c-r4'), 19 * 60);
      for (final c in designCables.where((c) => c.id != 'c-r4')) {
        expect(sim.fullMinutes(c.id), 0, reason: c.id);
        expect(sim.firstFullMinute(c.id), isNull, reason: c.id);
        expect(sim.peakMinute(c.id), isNull, reason: c.id);
      }
      expect(sim.exhausted, {'r4', 'r5'});
    });

    test('kabel Rumah 4 fiber: tidak ada yang penuh atau habis sabar', () {
      final sim = _sim(designFiberCables);
      _playDay(sim);
      for (final c in designFiberCables) {
        expect(sim.fullMinutes(c.id), 0, reason: c.id);
      }
      expect(sim.exhausted, isEmpty);
    });

    test('sabar 0% dari potret langsung tercatat habis', () {
      final sim = _sim(designCables, minute: 20 * 60, patience: {'r7': 0});
      expect(sim.exhausted, {'r7'});
    });

    test('tidak bertambah selama hari dijeda komplain', () {
      final sim = _sim(
        designCables,
        minute: 20 * 60,
        complaint: const Complaint(houseId: 'r4', minute: 20 * 60),
      );
      sim.advance(30);
      expect(sim.fullMinutes('c-r4'), 0);
    });
  });
}
