import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const draft = CableDraft(
    from: LevelDef.routerId,
    kind: CableKind.lan,
    points: [Offset(195, 264), Offset(195, 300), Offset(255, 360)],
    target: 'r5',
    handle: Offset(255, 360),
  );

  GameState level5() => GameState(Levels.level5, draft: draft);

  int countNotifications(GameState s, void Function() action) {
    var n = 0;
    s.addListener(() => n++);
    action();
    return n;
  }

  test('default diambil dari level', () {
    final s = GameState(Levels.level5);
    expect(s.phase, GamePhase.design);
    expect(s.budget, 850000);
    expect(s.cables, Levels.level5.cables);
    expect(s.junctions, Levels.level5.junctions);
    expect(s.selectedCable, CableKind.lan);
    expect(s.connectedCount, 4);
    expect(s.draft, isNull);
    expect(s.draftCost, 0);
    expect(s.frame, isNull);
  });

  test('daftar kabel tidak bisa diubah dari luar', () {
    final s = GameState(Levels.level5);
    expect(() => s.cables.clear(), throwsUnsupportedError);
    expect(() => s.junctions.clear(), throwsUnsupportedError);
  });

  test('biaya draft = segmen × harga kabel', () {
    expect(level5().draftCost, 45000);
  });

  group('selectCable', () {
    test('ganti jenis draft & biaya, beri tahu sekali', () {
      final s = level5();
      final n = countNotifications(s, () => s.selectCable(CableKind.fiber));
      expect(n, 1);
      expect(s.selectedCable, CableKind.fiber);
      expect(s.draft!.kind, CableKind.fiber);
      expect(s.draftCost, 180000);
    });

    test('bolak-balik kembali ke LAN', () {
      final s = level5()
        ..selectCable(CableKind.fiber)
        ..selectCable(CableKind.lan);
      expect(s.draft!.kind, CableKind.lan);
      expect(s.draftCost, 45000);
    });

    test('jenis yang sama tidak memberi tahu', () {
      final s = level5();
      expect(countNotifications(s, () => s.selectCable(CableKind.lan)), 0);
    });

    test('jenis terkunci ditolak', () {
      final s = GameState(Levels.level1);
      expect(() => s.selectCable(CableKind.fiber), throwsArgumentError);
      expect(
        () => GameState(Levels.level1, selectedCable: CableKind.fiber),
        throwsArgumentError,
      );
    });
  });

  test('setDraft memberi tahu & bisa dikosongkan', () {
    final s = level5();
    expect(countNotifications(s, () => s.setDraft(null)), 1);
    expect(s.draft, isNull);
    expect(s.draftCost, 0);
  });

  group('fase', () {
    test('startDay: rancang → jalan, draft dibuang, frame awal', () {
      final s = level5();
      expect(countNotifications(s, s.startDay), 1);
      expect(s.phase, GamePhase.run);
      expect(s.draft, isNull);
      expect(s.frame!.houses.keys.toSet(), {'r1', 'w', 'r3', 'r4'});
      final r1 = s.frame!.houses['r1']!;
      expect(r1.state, HouseState.ok);
      expect(r1.patience, 1);
      expect(r1.usageMbps, 0);
    });

    test('updateFrame hanya di fase jalan', () {
      final s = level5();
      const frame = SimFrame(houses: {});
      expect(() => s.updateFrame(frame), throwsStateError);
      s.startDay();
      expect(countNotifications(s, () => s.updateFrame(frame)), 1);
      expect(s.frame, same(frame));
    });

    test('finishDay: jalan → hasil', () {
      final s = level5()..startDay();
      expect(countNotifications(s, s.finishDay), 1);
      expect(s.phase, GamePhase.result);
    });

    test('transisi tidak sah ditolak', () {
      final s = level5();
      expect(s.finishDay, throwsStateError);
      s
        ..startDay()
        ..finishDay();
      expect(s.startDay, throwsStateError);
      expect(() => s.setDraft(draft), throwsStateError);
    });
  });

  test('SimFrame.usage', () {
    const frame = SimFrame(
      houses: {
        'r4': HouseLive(state: HouseState.jam, patience: 0.15, usageMbps: 16),
      },
    );
    expect(frame.usage, {'r4': 16});
  });
}
