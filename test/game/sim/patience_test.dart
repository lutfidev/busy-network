import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/sim/sim.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('status', () {
    HouseState status({
      bool jam = false,
      double patience = 1,
      double service = 1,
    }) => Patience.status(jam: jam, patience: patience, service: service);

    test('macet bila kabelnya penuh', () {
      expect(status(jam: true), HouseState.jam);
    });

    test('mulai lambat bila sabar atau layanan < 60%', () {
      expect(status(patience: 0.59), HouseState.slow);
      expect(status(service: 0.59), HouseState.slow);
    });

    test('lancar bila sabar & layanan ≥ 60%', () {
      expect(status(patience: 0.6, service: 0.6), HouseState.ok);
    });
  });

  group('perubahan sabar per jam', () {
    double rate({
      double service = 1,
      bool jam = false,
      bool congested = false,
    }) =>
        Patience.ratePerHour(service: service, jam: jam, congested: congested);

    test('terlayani penuh: pulih', () {
      expect(rate(), Patience.recoverPerHour);
      expect(rate(congested: true), Patience.recoverPerHour);
    });

    test('kekurangan layanan', () {
      expect(rate(service: 0.75), closeTo(-0.25, 1e-9));
    });

    test('macet lebih cepat habis daripada sekadar di hilir kabel penuh', () {
      expect(rate(service: 0.8, jam: true), closeTo(-0.5, 1e-9));
      expect(rate(service: 0.8, congested: true), closeTo(-0.35, 1e-9));
    });
  });
}
