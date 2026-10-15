import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';

/// Jaringan Fase Jalan di desain (Rumah 5 lewat Rumah 4, Rumah 6 & 7 lewat
/// j2).
final designCables = DummyStates.run().cables;

/// Jaringan desain dengan kabel Router → Rumah 4 diganti fiber.
final designFiberCables = [
  for (final c in designCables)
    c.id == 'c-r4'
        ? Cable(
            id: c.id,
            from: c.from,
            to: c.to,
            kind: CableKind.fiber,
            points: c.points,
          )
        : c,
];

/// Pemakaian puncak (jam sibuk) tiap rumah level 5.
final peakDemand = {for (final h in Levels.level5.houses) h.id: h.peakMbps};
