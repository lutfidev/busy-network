import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/sim/sim.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sim_fixtures.dart';

void main() {
  final net = Network(level: Levels.level5, cables: designCables);

  test('kabel penuh: rumah di hilirnya dibagi proporsional', () {
    final served = Flow.serve(net, peakDemand, const {});
    // Router → Rumah 4 membawa 16 + 9 = 25 Mbps di kabel 20 Mbps.
    expect(served['r4'], closeTo(12.8, 1e-9));
    expect(served['r5'], closeTo(7.2, 1e-9));
    for (final id in ['r1', 'w', 'r3', 'r6', 'r7']) {
      expect(served[id], peakDemand[id], reason: id);
    }
  });

  test('prioritas dilayani dulu, sisanya untuk yang lain', () {
    final served = Flow.serve(net, peakDemand, const {'r5'});
    expect(served['r5'], 9);
    expect(served['r4'], 11);
  });

  test('semua prioritas: dibagi proporsional di antara mereka', () {
    final served = Flow.serve(net, peakDemand, const {'r4', 'r5'});
    expect(served['r4'], closeTo(12.8, 1e-9));
    expect(served['r5'], closeTo(7.2, 1e-9));
  });

  test('pemotongan di hulu mengurangi beban hop di hilir', () {
    // Fiber Warung diganti LAN: router → j1 membawa 24,5 > 20.
    final lanWarung = Network(
      level: Levels.level5,
      cables: [
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
      ],
    );
    final served = Flow.serve(lanWarung, peakDemand, const {});
    final upstream = served['r1']! + served['w']! + served['r3']!;
    expect(upstream, closeTo(20, 1e-9));
    expect(served['w'], closeTo(12 * 20 / 24.5, 1e-9));
  });

  test('rumah tidak tersambung tidak ikut', () {
    final start = Network(level: Levels.level5, cables: Levels.level5.cables);
    final served = Flow.serve(start, peakDemand, const {});
    expect(served.keys.toSet(), {'r1', 'w', 'r3', 'r4'});
  });
}
