import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';

import '../game/sim/sim_fixtures.dart';

/// Hari level 5 yang pasti lolos: jaringan desain dengan kabel Rumah 4
/// fiber, semua rumah sabar penuh, mulai pada [minute].
GameState winningDay({required int minute}) => GameState(
  Levels.level5,
  junctions: DummyStates.run().junctions,
  cables: designFiberCables,
)..startDay(minute: minute);
