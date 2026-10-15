import 'package:busy_network/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdFormat', () {
    test('rupiah memakai titik ribuan dan spasi setelah Rp', () {
      expect(IdFormat.rupiah(850000), 'Rp 850.000');
      expect(IdFormat.rupiah(15000), 'Rp 15.000');
      expect(IdFormat.rupiah(1250000), 'Rp 1.250.000');
      expect(IdFormat.rupiah(0), 'Rp 0');
    });

    test('rupiah negatif memakai tanda minus tipografis', () {
      expect(IdFormat.rupiah(-45000), '−Rp 45.000');
    });

    test('mbps memakai koma desimal', () {
      expect(IdFormat.mbps(8.5), '8,5 Mbps');
      expect(IdFormat.mbps(20), '20 Mbps');
      expect(IdFormat.mbps(8.55), '8,6 Mbps');
      expect(IdFormat.mbps(1500), '1.500 Mbps');
    });

    test('rasio, persen, jam, rentang jam', () {
      expect(IdFormat.ratio(25, 20), '25/20');
      expect(IdFormat.ratio(25, 20, spaced: true), '25 / 20');
      expect(IdFormat.percent(62), '62%');
      expect(IdFormat.percent(0.62, fraction: true), '62%');
      expect(IdFormat.clock(20 * 60 + 15), '20:15');
      expect(IdFormat.clock(6 * 60), '06:00');
      expect(IdFormat.hourRange(19, 22), '19–22');
      expect(IdFormat.hour(6), '06');
    });
  });
}
