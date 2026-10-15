import 'package:busy_network/game/sim/sim.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  double at(int hour, [int minute = 0]) =>
      UsageCurve.shareAt(hour * 60 + minute);

  test('pagi, siang, sore bertingkat', () {
    expect(at(6), 0.25);
    expect(at(7, 59), 0.25);
    expect(at(8), 0.35);
    expect(at(12), 0.45);
    expect(at(17), 0.45);
  });

  test('naik lurus 2 jam sebelum jam sibuk', () {
    expect(at(18), closeTo(0.725, 1e-9));
    expect(at(19), 1);
  });

  test('penuh selama jam sibuk, lalu turun ke 30% di 24:00', () {
    expect(at(20, 15), 1);
    expect(at(22), 1);
    expect(at(23), closeTo(0.65, 1e-9));
    expect(at(24), closeTo(0.3, 1e-9));
  });

  test('mengikuti jam sibuk level', () {
    double share(int hour) =>
        UsageCurve.shareAt(hour * 60, rushFrom: 17, rushTo: 20);
    expect(share(15), 0.45);
    expect(share(17), 1);
    expect(share(20), 1);
    expect(share(22), closeTo(0.65, 1e-9));
  });

  test('jam permainan: 1.080 menit dalam 90 detik', () {
    expect(SimClock.minutesPerSecond, 12);
    expect(SimClock.dayEnd - SimClock.dayStart, 1080);
  });
}
