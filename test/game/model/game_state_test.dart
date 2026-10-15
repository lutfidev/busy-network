import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/sim/sim.dart';
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
    test('startDay: rancang → jalan, draft dibuang, hari mulai 06:00', () {
      final s = level5();
      expect(countNotifications(s, s.startDay), 1);
      expect(s.phase, GamePhase.run);
      expect(s.draft, isNull);
      expect(s.day!.minute, SimClock.dayStart);
      expect(s.frame!.houses.keys.toSet(), {'r1', 'w', 'r3', 'r4'});
      final r1 = s.frame!.houses['r1']!;
      expect(r1.state, HouseState.ok);
      expect(r1.patience, 1);
      expect(r1.usageMbps, 4 * UsageCurve.morningShare);
    });

    test('startDay dari potret: jam, sabar, prioritas, komplain', () {
      final s = GameState(Levels.level5)
        ..startDay(
          minute: 20 * 60,
          patience: const {'r4': 0.5},
          priority: const {'w'},
          complaint: const Complaint(houseId: 'r4', minute: 20 * 60),
          complaints: 2,
        );
      expect(s.day!.minute, 20 * 60);
      expect(s.frame!.houses['r4']!.patience, 0.5);
      expect(s.day!.priority, {'w'});
      expect(s.day!.complaint!.houseId, 'r4');
      expect(s.day!.complaints, 2);
    });

    test('planDay: salinan fase jalan, rancangan tetap utuh', () {
      final s = level5()..removeCable('c-r4');
      final day = s.planDay();
      expect(s.phase, GamePhase.design);
      expect(s.draft, isNotNull);
      expect(day.phase, GamePhase.run);
      expect(day.budget, s.budget);
      expect(day.cables, s.cables);
      expect(day.frame!.houses.keys, isNot(contains('r4')));
    });

    test('advanceDay maju per menit & hanya memberi tahu bila jam berubah', () {
      final s = level5()..startDay();
      // 0,05 detik = 0,6 menit permainan.
      expect(countNotifications(s, () => s.advanceDay(0.05)), 0);
      expect(countNotifications(s, () => s.advanceDay(0.05)), 1);
      expect(s.day!.minute, SimClock.dayStart + 1);
    });

    test('advanceDay sampai 24:00 → fase hasil', () {
      final s = level5()..startDay();
      while (s.phase == GamePhase.run) {
        s.advanceDay(10);
      }
      expect(s.phase, GamePhase.result);
      expect(s.day!.over, isTrue);
      expect(() => s.advanceDay(1), throwsStateError);
    });

    test('setQueue & dismissComplaint diteruskan ke hari', () {
      final s = GameState(Levels.level5)
        ..startDay(complaint: const Complaint(houseId: 'r4', minute: 360));
      expect(
        countNotifications(
          s,
          () => s.setQueue(limits: const {'r4': 10}, priority: const {'r1'}),
        ),
        1,
      );
      expect(s.day!.limits['r4'], 10);
      expect(s.day!.priority, {'r1'});
      expect(countNotifications(s, s.dismissComplaint), 1);
      expect(s.day!.complaint, isNull);
      expect(countNotifications(s, s.dismissComplaint), 0);
    });

    test('transisi tidak sah ditolak', () {
      final s = level5();
      expect(() => s.advanceDay(1), throwsStateError);
      expect(
        () => s.setQueue(limits: const {}, priority: const {}),
        throwsStateError,
      );
      expect(s.dismissComplaint, throwsStateError);
      s
        ..startDay()
        ..advanceDay(SimClock.secondsPerDay);
      expect(s.phase, GamePhase.result);
      expect(s.startDay, throwsStateError);
      expect(() => s.setDraft(draft), throwsStateError);
    });
  });
}
