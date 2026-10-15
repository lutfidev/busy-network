import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../design_pull.dart';
import 'cable_checks.dart';

const _router = LevelDef.routerId;

int notifications(GameState s, void Function() action) {
  var n = 0;
  void count() => n++;
  s.addListener(count);
  action();
  s.removeListener(count);
  return n;
}

void main() {
  group('mulai tarikan', () {
    test('dari router, junction & rumah yang tersambung', () {
      final s = GameState(Levels.level5);
      expect(s.canStartCable(_router), isTrue);
      expect(s.canStartCable('j1'), isTrue);
      expect(s.canStartCable('r4'), isTrue);
      expect(s.canStartCable('r5'), isFalse, reason: 'belum tersambung');
      expect(s.canStartCable('zz'), isFalse);
    });

    test('junction yang putus tidak bisa jadi sumber', () {
      final s = GameState(Levels.level5)..removeCable('c-w');
      expect(s.canStartCable('j1'), isFalse);
      expect(s.canStartCable('r1'), isFalse);
    });

    test('ditolak di mode hapus & di luar fase rancang', () {
      final s = GameState(Levels.level5)..setErasing(true);
      expect(notifications(s, () => expect(s.beginCable(_router), isFalse)), 0);
      s.setErasing(false);
      s.startDay();
      expect(s.beginCable(_router), isFalse);
    });

    test('jari masih di sumber: belum ada draft', () {
      final s = GameState(Levels.level5);
      expect(notifications(s, () => s.beginCable(_router)), 1);
      expect(s.pulling, isTrue);
      s.dragCable(const Offset(200, 236));
      expect(s.draft, isNull);
      expect(s.draftCost, 0);
    });
  });

  group('tarikan desain', () {
    test('sama dengan desain: 3 segmen, cincin di Rumah 5, jari di grid', () {
      final s = designPull();
      expect(s.pulling, isTrue);
      final d = s.draft!;
      expect(d.from, _router);
      expect(d.points, const [
        Offset(195, 264),
        Offset(195, 300),
        Offset(255, 360),
      ]);
      expect(d.target, 'r5');
      expect(d.handle, const Offset(255, 360));
      expect(d.segments, 3);
      expect(s.draftCost, 45000);
      expect(s.budget, 850000, reason: 'belum dipotong');
    });

    test('ganti ke fiber di tengah tarikan', () {
      final s = designPull()..selectCable(CableKind.fiber);
      expect(s.draftCost, 180000);
      s.dragCable(const Offset(255, 330));
      expect(s.draft!.kind, CableKind.fiber);
    });

    test('lepas di luar rumah → batal, tidak ada yang berubah', () {
      final s = designPull();
      expect(notifications(s, () => expect(s.endCable(), CableDrop.missed)), 1);
      expect(s.pulling, isFalse);
      expect(s.draft, isNull);
      expect(s.cables, Levels.level5.cables);
      expect(s.budget, 850000);
    });

    test('jari tidak tepat di titik grid: ujung kabel tetap di grid', () {
      final s = GameState(Levels.level5)
        ..beginCable(_router)
        ..dragCable(const Offset(197, 296))
        ..dragCable(const Offset(252, 362));
      expect(s.draft!.points, designPull().draft!.points);
      expect(s.draft!.handle, const Offset(255, 360));
    });

    test('jauh dari rumah mana pun: tanpa cincin snap', () {
      final s = GameState(Levels.level5)
        ..beginCable(_router)
        ..dragCable(const Offset(105, 210));
      expect(s.draft!.target, isNull);
    });
  });

  group('menempel & tersambung', () {
    test('jari masuk cincin Rumah 5 → kabel masuk rumah, jari hilang', () {
      final s = designPull()..dragCable(const Offset(300, 380));
      final d = s.draft!;
      expect(d.target, 'r5');
      expect(d.handle, isNull);
      expect(d.points, const [
        Offset(195, 264),
        Offset(195, 300),
        Offset(285, 390),
        Offset(295, 390),
      ]);
      expect(d.segments, 5);
      expect(s.draftCost, 75000);
    });

    test('lepas → kabel terpasang, anggaran terpotong, rumah tersambung', () {
      final s = designPull()..dragCable(const Offset(300, 380));
      expect(s.endCable(), CableDrop.connected);
      final cable = s.cables.last;
      expect(cable.id, 'c-r5');
      expect(cable.from, _router);
      expect(cable.to, 'r5');
      expect(cable.kind, CableKind.lan);
      expect(cable.cost, 75000);
      expectValidCable(s.level, cable, s.positionOf);
      expect(s.budget, 850000 - 75000);
      expect(s.connectedHouses, contains('r5'));
      expect(s.connectedCount, 5);
      expect(s.draft, isNull);
      expect(s.pulling, isFalse);
    });

    test('keluar lagi dari cincin → lepas dari rumah', () {
      final s = designPull()
        ..dragCable(const Offset(300, 380))
        ..dragCable(const Offset(252, 362));
      expect(s.draft!.handle, const Offset(255, 360));
      expect(s.draft!.points.last, const Offset(255, 360));
      expect(s.endCable(), CableDrop.missed);
    });

    test('Rumah 4 → Rumah 5 = kabel di desain Fase Jalan', () {
      final s = GameState(Levels.level5)
        ..beginCable('r4')
        ..dragCable(const Offset(315, 300))
        ..dragCable(const Offset(318, 384));
      expect(s.endCable(), CableDrop.connected);
      final run = DummyStates.run().cables.firstWhere((c) => c.id == 'c-r5');
      expect(s.cables.last.from, 'r4');
      expect(s.cables.last.points, run.points);
    });

    test('router → Rumah 6 lurus ke bawah', () {
      final s = GameState(Levels.level5)
        ..beginCable(_router)
        ..dragCable(const Offset(195, 420));
      expect(s.draft!.points, const [Offset(195, 264), Offset(195, 400)]);
      expect(s.endCable(), CableDrop.connected);
      expect(s.connectedHouses, contains('r6'));
    });

    test('node lain menghalangi jalur', () {
      final s = GameState(Levels.level5)
        ..beginCable(_router)
        ..dragCable(const Offset(195, 120));
      expect(s.draft!.handle, const Offset(195, 180), reason: 'j1 di y=150');
    });

    test('rumah tersambung tidak jadi tujuan', () {
      final s = GameState(Levels.level5)
        ..beginCable(_router)
        ..dragCable(const Offset(285, 240))
        ..dragCable(const Offset(312, 244));
      expect(s.draft?.target, isNot('r4'));
      expect(s.endCable(), CableDrop.missed);
      expect(s.cables, Levels.level5.cables);
    });

    test('id kabel baru unik', () {
      final s = GameState(
        Levels.level5,
        cables: [
          ...Levels.level5.cables,
          // Kabel mati dari Rumah 6 (belum tersambung) ke Rumah 5.
          const Cable(
            id: 'c-r5',
            from: 'r6',
            to: 'r5',
            points: [Offset(209, 406), Offset(301, 404)],
          ),
        ],
      );
      expect(s.connectedHouses, isNot(contains('r5')));
      s
        ..beginCable(_router)
        ..dragCable(const Offset(195, 300))
        ..dragCable(const Offset(255, 360))
        ..dragCable(const Offset(312, 388));
      expect(s.endCable(), CableDrop.connected);
      expect(s.cables.last.id, 'c-r5-2');
    });
  });

  group('anggaran', () {
    test('anggaran kurang: draft ditandai, kabel tidak dipasang', () {
      final s = designPull(budget: 60000)..dragCable(const Offset(300, 380));
      expect(s.draftOverBudget, isTrue);
      expect(s.endCable(), CableDrop.overBudget);
      expect(s.refusedCost, 75000);
      expect(s.budget, 60000);
      expect(s.cables, Levels.level5.cables);
      expect(s.connectedHouses, isNot(contains('r5')));
    });

    test('pas anggaran masih boleh', () {
      final s = designPull(budget: 75000)..dragCable(const Offset(300, 380));
      expect(s.draftOverBudget, isFalse);
      expect(s.endCable(), CableDrop.connected);
      expect(s.budget, 0);
    });

    test('penolakan hilang saat tarikan berikutnya', () {
      final s = designPull(budget: 0)..dragCable(const Offset(300, 380));
      s.endCable();
      expect(s.refusedCost, isNotNull);
      s.beginCable(_router);
      expect(s.refusedCost, isNull);
    });
  });

  group('bongkar', () {
    test('uang kembali 50%, rumah hilir putus', () {
      final s = GameState(Levels.level5);
      final cable = s.cables.firstWhere((c) => c.id == 'c-r4');
      expect(cable.cost, 45000);
      expect(notifications(s, () => expect(s.removeCable('c-r4'), 22500)), 1);
      expect(s.budget, 850000 + 22500);
      expect(s.cables.map((c) => c.id), isNot(contains('c-r4')));
      expect(s.connectedHouses, {'r1', 'w', 'r3'});
    });

    test('fiber lewat junction: semua di hilir j1 putus', () {
      final s = GameState(Levels.level5);
      expect(s.removeCable('c-w'), 150000, reason: '5 segmen fiber / 2');
      expect(s.connectedHouses, {'r4'});
      expect(s.cables.map((c) => c.id), containsAll(['c-r1', 'c-r3']));
    });

    test('kabel yang baru dipasang juga bisa dibongkar', () {
      final s = designPull()..dragCable(const Offset(300, 380));
      s.endCable();
      s.removeCable('c-r5');
      expect(s.budget, 850000 - 75000 + 37500);
      expect(s.connectedCount, 4);
    });

    test('id tak dikenal & fase jalan ditolak', () {
      final s = GameState(Levels.level5);
      expect(() => s.removeCable('zz'), throwsArgumentError);
      s.startDay();
      expect(() => s.removeCable('c-r4'), throwsStateError);
    });
  });

  group('mode hapus', () {
    test('menyala → tarikan batal', () {
      final s = designPull()..setErasing(true);
      expect(s.erasing, isTrue);
      expect(s.pulling, isFalse);
      expect(s.draft, isNull);
    });

    test('pilih kabel mematikan mode hapus (jenis sama pun)', () {
      final s = GameState(Levels.level5)..setErasing(true);
      expect(notifications(s, () => s.selectCable(CableKind.lan)), 1);
      expect(s.erasing, isFalse);
    });

    test('nilai sama tidak memberi tahu', () {
      final s = GameState(Levels.level5);
      expect(notifications(s, () => s.setErasing(false)), 0);
    });
  });

  test('cancelCable membuang tarikan', () {
    final s = designPull();
    expect(notifications(s, s.cancelCable), 1);
    expect(s.pulling, isFalse);
    expect(s.draft, isNull);
    expect(notifications(s, s.cancelCable), 0);
  });

  test('positionOf termasuk junction tambahan state', () {
    final s = DummyStates.run();
    expect(s.positionOf('j2'), const Offset(195, 330));
    expect(s.positionOf(_router), const Offset(195, 240));
  });
}
