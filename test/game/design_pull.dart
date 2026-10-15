import 'dart:ui';

import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';

/// Jalur jari tarikan di desain Fase Rancang (koordinat peta): tekan
/// router, turun ke (195, 300), miring ke (255, 360), jari masih menempel.
const designPullPath = [Offset(195, 240), Offset(195, 300), Offset(255, 360)];

/// Level 5 dengan tarikan desain sedang berjalan.
GameState designPull({CableKind kind = CableKind.lan, int? budget}) {
  final s = GameState(Levels.level5, selectedCable: kind, budget: budget)
    ..beginCable(LevelDef.routerId);
  for (final p in designPullPath.skip(1)) {
    s.dragCable(p);
  }
  return s;
}
