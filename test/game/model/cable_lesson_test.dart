import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

const _router = LevelDef.routerId;
const _lesson = Levels.tutorialLesson;

/// Rumah 2 level 1 sudah tersambung lewat kabel router → Rumah 2.
const _cableToR2 = Cable(
  id: 'c-r2',
  from: _router,
  to: 'r2',
  points: [Offset(129, 315), Offset(295, 345)],
);

/// Tutorial level 1 langkah 2.
GameState lessonState({List<Cable>? cables}) =>
    GameState(Levels.level1, cables: cables, lesson: _lesson);

/// Tekan router, seret melewati [path], tanpa melepas.
GameState pullThrough(GameState s, List<Offset> path) {
  expect(s.beginCable(_router), isTrue);
  for (final p in path) {
    s.dragCable(p);
  }
  return s;
}

const _toHouse1 = [Offset(165, 255), Offset(255, 165)];
const _toHouse2 = [Offset(210, 330), Offset(315, 345)];

void main() {
  test('pelajaran tutorial: router → Rumah 1, garis desain', () {
    expect(_lesson.from, _router);
    expect(_lesson.to, 'r1');
    expect(_lesson.guide, const [Offset(105, 315), Offset(255, 165)]);
  });

  group('sumber & tujuan', () {
    test('hanya sumber pelajaran yang bisa mulai menarik', () {
      final s = lessonState(cables: const [_cableToR2]);
      expect(s.canStartCable(_router), isTrue);
      expect(
        s.canStartCable('r2'),
        isFalse,
        reason: 'tersambung, bukan sumber',
      );
      expect(
        GameState(
          Levels.level1,
          cables: const [_cableToR2],
        ).canStartCable('r2'),
        isTrue,
        reason: 'tanpa pelajaran boleh',
      );
    });

    test('rumah selain tujuan tidak diberi cincin & tidak tersambung', () {
      final s = pullThrough(lessonState(), _toHouse2);
      expect(s.draft?.target, isNull);
      expect(s.endCable(), CableDrop.missed);
      expect(s.connectedCount, 0);
      expect(s.budget, 200000);
    });

    test('tanpa pelajaran Rumah 2 jadi tujuan', () {
      final s = GameState(Levels.level1);
      pullThrough(s, _toHouse2);
      expect(s.endCable(), CableDrop.connected);
    });

    test('lepas di Rumah 1 → tersambung, anggaran terpotong 4 segmen', () {
      final s = pullThrough(lessonState(), _toHouse1);
      expect(s.draft?.target, 'r1');
      expect(s.endCable(), CableDrop.connected);
      expect(s.isConnected('r1'), isTrue);
      expect(s.budget, 140000);
    });
  });

  group('kabel panduan', () {
    test('diam: garis pelajaran tanpa jari & cincin', () {
      final guide = lessonState().guide!;
      expect(guide.from, _router);
      expect(guide.kind, CableKind.lan);
      expect(guide.points, _lesson.guide);
      expect(guide.handle, isNull);
      expect(guide.target, isNull);
    });

    test('hilang selama menarik, muncul lagi bila batal', () {
      final s = lessonState()..beginCable(_router);
      expect(s.guide, isNull);
      s.dragCable(_toHouse2.first);
      expect(s.guide, isNull);
      s.endCable();
      expect(s.guide?.points, _lesson.guide);
    });

    test('hilang setelah tujuan tersambung', () {
      final s = pullThrough(lessonState(), _toHouse1)..endCable();
      expect(s.guide, isNull);
    });

    test('tanpa pelajaran tidak ada', () {
      expect(GameState(Levels.level1).guide, isNull);
    });
  });

  test('setLesson memberi tahu; nilai sama tidak', () {
    final s = GameState(Levels.level1);
    var n = 0;
    s.addListener(() => n++);
    s.setLesson(_lesson);
    expect(s.lesson, _lesson);
    s.setLesson(_lesson);
    expect(n, 1);
    s.setLesson(null);
    expect(s.guide, isNull);
    expect(n, 2);
  });

  test('hari dari rancangan tidak membawa pelajaran', () {
    final day = (pullThrough(lessonState(), _toHouse1)..endCable()).planDay();
    expect(day.lesson, isNull);
    expect(day.isConnected('r1'), isTrue);
  });
}
