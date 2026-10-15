import 'dart:ui';

import '../game/levels/levels.dart';
import '../game/map_scene.dart';
import '../game/model/model.dart';

/// Snapshot [GameState] per layar, pengganti peta statis. Diganti state
/// game asli di langkah 4 (tarik kabel) dan 5 (simulasi). Koordinat persis
/// dari desain.
abstract final class DummyStates {
  // ── Tutorial level 1 ──────────────────────────────────────────────────
  static const _tutorialCable = [Offset(105, 315), Offset(255, 165)];

  /// Langkah 1 polos, 2 kabel dipandu (tanpa jari, tangan tutorial yang
  /// jadi jarinya), 3 Rumah 1 tersambung. Snapshot belum memotong biaya:
  /// desain tetap menampilkan Rp 200.000.
  static GameState tutorial(int step) {
    assert(step >= 1 && step <= 3, 'langkah tutorial 1..3');
    return switch (step) {
      1 => GameState(Levels.level1),
      2 => GameState(
        Levels.level1,
        draft: const CableDraft(
          from: LevelDef.routerId,
          kind: CableKind.lan,
          points: _tutorialCable,
        ),
      ),
      _ => GameState(
        Levels.level1,
        cables: const [
          Cable(
            id: 'c-r1',
            from: LevelDef.routerId,
            to: 'r1',
            points: _tutorialCable,
          ),
        ],
      ),
    };
  }

  // ── Gang Melati (level 5) ─────────────────────────────────────────────
  /// Fase rancang: sedang menarik kabel [kind] dari router ke Rumah 5.
  static GameState design(CableKind kind) => GameState(
    Levels.level5,
    selectedCable: kind,
    draft: CableDraft(
      from: LevelDef.routerId,
      kind: kind,
      points: const [Offset(195, 264), Offset(195, 300), Offset(255, 360)],
      target: 'r5',
      handle: const Offset(255, 360),
    ),
  );

  /// Fase jalan, jam sibuk: kabel Router → Rumah 4 penuh (16 + 9 Mbps).
  static GameState run() {
    const level = Levels.level5;
    Cable initial(String id) => level.cables.firstWhere((c) => c.id == id);
    HouseLive live(String id, HouseState state, double patience) => HouseLive(
      state: state,
      patience: patience,
      usageMbps: level.house(id).peakMbps,
    );
    return GameState(
      level,
      phase: GamePhase.run,
      junctions: [
        ...level.junctions,
        const Junction(id: 'j2', position: Offset(195, 330)),
      ],
      cables: [
        initial('c-r1'),
        initial('c-r3'),
        const Cable(
          id: 'c-r6',
          from: LevelDef.routerId,
          to: 'r6',
          via: ['j2'],
          points: [Offset(195, 264), Offset(195, 400)],
        ),
        const Cable(
          id: 'c-r7',
          from: 'j2',
          to: 'r7',
          points: [Offset(195, 330), Offset(95, 330)],
        ),
        const Cable(
          id: 'c-r5',
          from: 'r4',
          to: 'r5',
          points: [Offset(315, 260), Offset(315, 370)],
        ),
        initial('c-w'),
        initial('c-r4'),
      ],
      frame: SimFrame(
        houses: {
          'r1': live('r1', HouseState.ok, 36 / 40),
          'w': live('w', HouseState.ok, 34 / 40),
          'r3': live('r3', HouseState.slow, 22 / 40),
          // Desain: bar 7/40 tapi label "sabar 15%"; model memakai 15%.
          'r4': live('r4', HouseState.jam, 0.15),
          'r5': live('r5', HouseState.slow, 16 / 40),
          'r6': live('r6', HouseState.ok, 32 / 40),
          'r7': live('r7', HouseState.ok, 30 / 40),
        },
      ),
    );
  }

  // ── Panel antrean ─────────────────────────────────────────────────────
  /// Urutan kartu di panel antrean (desain).
  static const queueOrder = ['r4', 'r5', 'r3', 'w', 'r1', 'r6', 'r7'];

  /// Rumah yang diprioritaskan saat panel dibuka.
  static const queuePriority = {'w'};
}
