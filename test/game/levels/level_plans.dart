import 'dart:ui';

import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/result/level_result.dart';

import '../sim/sim_fixtures.dart';

/// Satu tarikan kabel: dari [from] lewat titik grid [via] (koordinat peta)
/// lalu menempel di [to].
class Pull {
  const Pull(
    this.from,
    this.to, {
    this.kind = CableKind.lan,
    this.via = const [],
  });

  /// Tarikan fiber.
  const Pull.fiber(this.from, this.to, {this.via = const []})
    : kind = CableKind.fiber;

  final String from;
  final String to;
  final CableKind kind;
  final List<Offset> via;

  @override
  String toString() => '$from→$to${kind == CableKind.fiber ? ' (fiber)' : ''}';
}

/// Rancangan level: kabel awal yang dibongkar ([remove]) lalu [pulls].
class Plan {
  const Plan(this.pulls, {this.remove = const []});

  final List<String> remove;
  final List<Pull> pulls;
}

/// Fase Rancang [level] setelah [plan] ditarik sungguhan (jari di titik
/// grid). Melempar bila ada tarikan yang tidak tersambung.
GameState design(LevelDef level, Plan plan, {int? budget}) {
  final s = GameState(level, budget: budget);
  for (final id in plan.remove) {
    s.removeCable(id);
  }
  for (final pull in plan.pulls) {
    s.selectCable(pull.kind);
    if (!s.beginCable(pull.from)) {
      throw StateError('Level ${level.number}: tidak bisa mulai $pull');
    }
    for (final p in pull.via) {
      s.dragCable(p);
    }
    s.dragCable(s.positionOf(pull.to));
    final drop = s.endCable();
    if (drop != CableDrop.connected) {
      throw StateError('Level ${level.number}: $pull → $drop');
    }
  }
  return s;
}

/// Hasil hari [level] dengan rancangan [plan], tanpa mengatur antrean
/// kecuali [limits].
LevelResult play(
  LevelDef level,
  Plan plan, {
  Map<String, int> limits = const {},
  Set<String> priority = const {},
}) {
  final s = design(level, plan)..startDay();
  if (limits.isNotEmpty || priority.isNotEmpty) {
    s.setQueue(limits: limits, priority: priority);
  }
  return LevelResult.of(playDay(s));
}

const _r = LevelDef.routerId;

/// Rancangan acuan tiap level: lulus dengan 3★ (bukti level bisa
/// diselesaikan sempurna). Bukan satu-satunya jawaban.
const referencePlans = <int, Plan>{
  1: Plan([Pull(_r, 'r1'), Pull(_r, 'r2')]),
  // Rantai Rumah 1 → Rumah 2 lebih hemat daripada dua kabel dari router.
  2: Plan([Pull(_r, 'r1'), Pull('r1', 'r2'), Pull(_r, 'r3')]),
  3: Plan([
    Pull.fiber(_r, 'w'),
    Pull(_r, 'r1'),
    Pull(_r, 'r2'),
    Pull(_r, 'r3'),
  ]),
  // Tiang cukup LAN bila rumah bawah disambung langsung dari router.
  4: Plan([
    Pull(_r, 'j1'),
    Pull('j1', 'r1'),
    Pull('j1', 'r2'),
    Pull('j1', 'r3'),
    Pull(_r, 'r4'),
    Pull(_r, 'r5'),
  ]),
  5: Plan([Pull(_r, 'r5'), Pull(_r, 'r7'), Pull('r7', 'r6')]),
  // Rumah 4 pindah ke Rumah 5; Rumah 6 lewat Rumah 5.
  6: Plan([Pull('r5', 'r4'), Pull('r5', 'r6')], remove: ['c-r4']),
  // Rumah 3 langsung dari router supaya tiang cukup LAN.
  7: Plan([
    Pull(_r, 'j1'),
    Pull('j1', 'r1'),
    Pull('j1', 'r2'),
    Pull(_r, 'r3'),
    Pull(_r, 'r4'),
    Pull('r4', 'r5'),
    Pull(_r, 'r7'),
    Pull('r7', 'r6'),
  ]),
  // Fiber lewat Rumah 6 ke tiang, ruko masing-masing satu LAN.
  8: Plan([
    Pull.fiber(_r, 'r6'),
    Pull.fiber('r6', 'j1'),
    Pull('j1', 'k1'),
    Pull('j1', 'r1'),
    Pull('j1', 'k2'),
    Pull(_r, 'r4'),
    Pull('r4', 'r2'),
    Pull(_r, 'r5'),
    Pull('r5', 'r3'),
  ]),
  // Berpasangan: tiap kabel dari router membawa dua rumah.
  9: Plan([
    Pull(_r, 'r2'),
    Pull('r2', 'r1'),
    Pull(_r, 'r4'),
    Pull('r4', 'r3'),
    Pull(_r, 'r6'),
    Pull('r6', 'r5'),
    Pull(_r, 'r8'),
    Pull('r8', 'r7'),
  ]),
  // Fiber ke tiang 1, tiang 2 dicabang dari tiang 1.
  10: Plan([
    Pull(_r, 'r1'),
    Pull('r1', 'r2'),
    Pull.fiber(_r, 'j1'),
    Pull('j1', 'r3'),
    Pull('j1', 'r4'),
    Pull('r4', 'r5'),
    Pull(_r, 'r9'),
    Pull('r9', 'r8'),
    Pull('j1', 'j2'),
    Pull('j2', 'r7'),
    Pull('j2', 'r6'),
  ]),
  11: Plan([
    Pull(_r, 'r2'),
    Pull('r2', 'r1'),
    Pull(_r, 'r3'),
    Pull('r3', 'r4'),
    Pull(_r, 'r5'),
    Pull(_r, 'r10'),
    Pull('r10', 'r6'),
    Pull(_r, 'r7'),
    Pull(_r, 'r9'),
    Pull('r9', 'r8'),
  ]),
  // Pos Ronda jadi pusat fiber untuk rumah bawah; yang lain sendiri-sendiri
  // atau berpasangan kecil (aman saat nobar 1,5×).
  12: Plan([
    Pull.fiber(_r, 'pos'),
    Pull(_r, 'r2'),
    Pull(_r, 'r1'),
    Pull('r1', 'r8'),
    Pull(_r, 'r3'),
    Pull(_r, 'r4'),
    Pull('pos', 'r5'),
    Pull('pos', 'r7'),
    Pull('pos', 'r6'),
  ]),
};
