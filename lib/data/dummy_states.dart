import 'dart:ui';

import '../game/levels/levels.dart';
import '../game/model/model.dart';
import '../game/sim/sim.dart';

/// Snapshot [GameState] dari desain: tutorial (deep link `?langkah=`) dan
/// bingkai Fase Jalan (deep link, screenshot). Koordinat persis dari desain.
/// Fase Rancang & hari yang dimainkan memakai state asli.
abstract final class DummyStates {
  // ── Tutorial level 1 ──────────────────────────────────────────────────
  /// Langkah 1 polos, 2 pelajaran Router → Rumah 1 (kabel panduan tanpa jari,
  /// tangan tutorial yang jadi jarinya), 3 potret Rumah 1 tersambung. Potret
  /// langkah 3 belum memotong biaya: desain tetap menampilkan Rp 200.000.
  /// Tutorial yang dimainkan berjalan dari langkah 1/2 di state yang sama.
  static GameState tutorial(int step) {
    assert(step >= 1 && step <= 3, 'langkah tutorial 1..3');
    const lesson = Levels.tutorialLesson;
    return switch (step) {
      1 => GameState(Levels.level1),
      2 => GameState(Levels.level1, lesson: lesson),
      _ => GameState(
        Levels.level1,
        cables: [
          Cable(
            id: 'c-r1',
            from: lesson.from,
            to: lesson.to,
            points: lesson.guide,
          ),
        ],
      ),
    };
  }

  // ── Gang Melati (level 5) ─────────────────────────────────────────────
  /// Fase jalan, jam sibuk 20:15: hari dilanjutkan dari potret desain (sabar
  /// tiap rumah, Warung diprioritaskan, komplain Bu Sri 20:14). Status,
  /// beban, badge "Penuh! 25/20", dan kepuasan 62% dihitung simulasi.
  static GameState run() {
    const level = Levels.level5;
    Cable initial(String id) => level.cables.firstWhere((c) => c.id == id);
    return GameState(
      level,
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
    )..startDay(
      minute: runMinute,
      patience: const {
        'r1': 36 / 40,
        'w': 34 / 40,
        'r3': 22 / 40,
        // Desain: bar 7/40 tapi label "sabar 15%"; model memakai 15%.
        'r4': 0.15,
        'r5': 16 / 40,
        'r6': 32 / 40,
        'r7': 30 / 40,
      },
      priority: const {'w'},
      complaint: const Complaint(houseId: 'r4', minute: 20 * 60 + 14),
      complaints: 1,
    );
  }

  /// Jam bingkai Fase Jalan di desain.
  static const runMinute = 20 * 60 + 15;
}
