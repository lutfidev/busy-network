import 'dart:math' as math;

import '../model/network.dart';

/// Aliran data di pohon jaringan.
abstract final class Flow {
  /// Mbps yang sampai di tiap rumah tersambung.
  ///
  /// [demand] = permintaan rumah (sudah dibatasi antrean). Hop ditelusuri
  /// dari router ke hilir; di hop yang kelebihan beban, rumah [priority]
  /// di hilirnya dilayani dulu, sisanya dibagi proporsional. Hop yang
  /// sudah memotong aliran di hulu mengurangi beban hop di bawahnya.
  static Map<String, double> serve(
    Network network,
    Map<String, double> demand,
    Set<String> priority,
  ) {
    final served = {
      for (final id in network.connectedHouses) id: demand[id] ?? 0.0,
    };
    for (final hop in network.treeHops) {
      final below = network.housesBelow(hop.to);
      final capacity = hop.cable.spec.capacityMbps.toDouble();
      if (_sum(below, served) <= capacity) continue;
      var room = capacity;
      for (final group in [
        below.where(priority.contains),
        below.where((id) => !priority.contains(id)),
      ]) {
        final want = _sum(group, served);
        if (want <= 0) continue;
        final share = want <= room ? 1.0 : room / want;
        for (final id in group) {
          served[id] = served[id]! * share;
        }
        room = math.max(0, room - want * share);
      }
    }
    return served;
  }

  static double _sum(Iterable<String> ids, Map<String, double> values) =>
      ids.fold(0.0, (sum, id) => sum + values[id]!);
}
