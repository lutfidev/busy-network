import 'package:busy_network/game/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';

final _design = Progress(const {1: 3, 2: 2, 3: 3, 4: 1});

void main() {
  test('kosong: hanya level 1 terbuka & sekarang', () {
    final p = Progress(const {});
    expect(p.current, 1);
    expect(p.isOpen(1), isTrue);
    expect(p.isOpen(2), isFalse);
    expect(p.totalStars, 0);
  });

  test('progres desain: 9 bintang, 4 level, level 5 sekarang', () {
    expect(_design.totalStars, 9);
    expect(_design.levelsDone(12), 4);
    expect(_design.current, 5);
    expect(_design.isOpen(5), isTrue);
    expect(_design.isOpen(6), isFalse);
    expect(_design.starsOf(2), 2);
    expect(_design.starsOf(5), 0);
  });

  test('record: bintang terbaik dipakai; tidak turun', () {
    final won = _design.record(5, 2);
    expect(won.starsOf(5), 2);
    expect(won.current, 6);
    expect(won.record(5, 1), same(won));
    expect(won.record(5, 0), same(won));
    expect(won.record(5, 3).starsOf(5), 3);
    expect(_design.starsOf(5), 0, reason: 'tidak mengubah aslinya');
  });

  test('bintang di luar 0..3 atau level < 1 ditolak', () {
    expect(() => Progress(const {1: 4}), throwsArgumentError);
    expect(() => Progress(const {0: 1}), throwsArgumentError);
    expect(() => _design.record(5, 4), throwsArgumentError);
  });

  test('encode/decode bolak-balik', () {
    final p = _design.record(5, 3);
    expect(p.encode(), '{"versi":1,"bintang":{"1":3,"2":2,"3":3,"4":1,"5":3}}');
    expect(Progress.decode(p.encode()), p);
  });

  test('data kosong, rusak, atau versi lain → null', () {
    for (final s in [
      null,
      '',
      'bukan json',
      '[]',
      '{"versi":2,"bintang":{}}',
      '{"versi":1}',
      '{"versi":1,"bintang":{"x":1}}',
      '{"versi":1,"bintang":{"1":"3"}}',
      '{"versi":1,"bintang":{"1":9}}',
    ]) {
      expect(Progress.decode(s), isNull, reason: '$s');
    }
  });
}
