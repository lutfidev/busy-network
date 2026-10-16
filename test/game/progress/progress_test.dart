import 'package:busy_network/game/levels/levels.dart';
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

  test('empty = progres kosong tanpa tutorial', () {
    expect(Progress.empty, Progress(const {}));
    expect(Progress.empty.tutorialDone, isFalse);
    expect(Progress.empty.current, 1);
  });

  group('level bos butuh bintang babak', () {
    const chapter = Levels.chapter;

    test('level biasa: sama dengan isOpen', () {
      expect(Progress.empty.canPlay(chapter, 1), isTrue);
      expect(Progress.empty.canPlay(chapter, 2), isFalse);
      expect(_design.canPlay(chapter, 5), isTrue);
    });

    test('level 11 selesai tapi bintang < 24 → bos terkunci', () {
      final p = Progress({for (var n = 1; n <= 11; n++) n: 2});
      expect(p.starsUpTo(11), 22);
      expect(p.isOpen(12), isTrue);
      expect(p.canPlay(chapter, 12), isFalse);
    });

    test('24 bintang dari level 1–11 → bos terbuka', () {
      final p = Progress({for (var n = 1; n <= 11; n++) n: n <= 2 ? 3 : 2});
      expect(p.starsUpTo(11), 24);
      expect(p.canPlay(chapter, 12), isTrue);
    });

    test('bintang cukup tapi level 11 belum selesai → terkunci', () {
      final p = Progress({for (var n = 1; n <= 10; n++) n: 3});
      expect(p.starsUpTo(11), 30);
      expect(p.canPlay(chapter, 12), isFalse);
    });

    test('bintang bos sendiri tidak dihitung', () {
      final p = Progress({for (var n = 1; n <= 11; n++) n: 1, 12: 3});
      expect(p.starsUpTo(11), 11);
      expect(p.totalStars, 14);
    });
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

  group('tutorial', () {
    test('awalnya belum selesai; completeTutorial menandai sekali', () {
      expect(_design.tutorialDone, isFalse);
      final done = _design.completeTutorial();
      expect(done.tutorialDone, isTrue);
      expect(done.totalStars, 9, reason: 'bintang tetap');
      expect(done.completeTutorial(), same(done));
      expect(_design.tutorialDone, isFalse, reason: 'tidak mengubah aslinya');
    });

    test('record mempertahankan tanda; == membedakannya', () {
      final done = _design.completeTutorial();
      expect(done.record(5, 2).tutorialDone, isTrue);
      expect(done, isNot(_design));
      expect(
        done,
        Progress(const {1: 3, 2: 2, 3: 3, 4: 1}, tutorialDone: true),
      );
      expect(done.hashCode, isNot(_design.hashCode));
    });

    test('JSON: kunci tutorial hanya bila selesai', () {
      expect(
        _design.encode(),
        '{"versi":1,"bintang":{"1":3,"2":2,"3":3,"4":1}}',
      );
      final done = _design.completeTutorial();
      expect(
        done.encode(),
        '{"versi":1,"bintang":{"1":3,"2":2,"3":3,"4":1},"tutorial":true}',
      );
      expect(Progress.decode(done.encode()), done);
      expect(Progress.decode(_design.encode())!.tutorialDone, isFalse);
    });

    test('tutorial bukan bool → data rusak', () {
      for (final s in [
        '{"versi":1,"bintang":{},"tutorial":"ya"}',
        '{"versi":1,"bintang":{},"tutorial":1}',
        '{"versi":1,"bintang":{},"tutorial":null}',
      ]) {
        expect(Progress.decode(s), isNull, reason: s);
      }
      expect(
        Progress.decode('{"versi":1,"bintang":{},"tutorial":false}'),
        Progress(const {}),
      );
    });
  });
}
