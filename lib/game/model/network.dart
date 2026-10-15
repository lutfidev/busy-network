import 'dart:math' as math;

import 'cable.dart';
import 'level_def.dart';

/// Satu sambungan antar-node di dalam [cable]. Kabel yang lewat junction
/// terdiri dari beberapa hop.
class Hop {
  const Hop(this.cable, this.from, this.to);

  final Cable cable;
  final String from;
  final String to;
}

/// Pohon jaringan: router → kabel → junction/rumah.
///
/// Kabel berarah dari hulu (`from`) ke hilir (`to`). Pohon ditelusuri dari
/// router; node yang sudah punya induk tidak diambil lagi (aman dari
/// siklus). Rumah yang tidak terjangkau router tidak ikut beban.
class Network {
  Network({required LevelDef level, required List<Cable> cables})
    : _houseIds = {for (final h in level.houses) h.id} {
    final out = <String, List<Hop>>{};
    for (final c in cables) {
      final stops = c.stops;
      for (var i = 1; i < stops.length; i++) {
        (out[stops[i - 1]] ??= []).add(Hop(c, stops[i - 1], stops[i]));
      }
    }
    final queue = [LevelDef.routerId];
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      for (final hop in out[node] ?? const <Hop>[]) {
        if (hop.to == LevelDef.routerId || _parent.containsKey(hop.to)) {
          continue;
        }
        _parent[hop.to] = hop;
        (_children[node] ??= []).add(hop.to);
        queue.add(hop.to);
      }
    }
    connectedHouses = {
      for (final id in _parent.keys)
        if (_houseIds.contains(id)) id,
    };
  }

  final Set<String> _houseIds;
  final _parent = <String, Hop>{};
  final _children = <String, List<String>>{};

  /// Rumah yang terjangkau dari router.
  late final Set<String> connectedHouses;

  /// Hop yang memberi [nodeId] internet; `null` untuk router / node lepas.
  Hop? parentOf(String nodeId) => _parent[nodeId];

  /// Rumah tersambung di subpohon [nodeId] (termasuk [nodeId] sendiri).
  Set<String> housesBelow(String nodeId) {
    final result = <String>{};
    final stack = [nodeId];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (connectedHouses.contains(node)) result.add(node);
      stack.addAll(_children[node] ?? const <String>[]);
    }
    return result;
  }

  double hopLoad(Hop hop, Map<String, double> usage) =>
      housesBelow(hop.to).fold(0.0, (sum, id) => sum + (usage[id] ?? 0));

  /// Beban hop terberat di [cable].
  double cableLoad(Cable cable, Map<String, double> usage) =>
      _hops(cable).fold(0.0, (m, hop) => math.max(m, hopLoad(hop, usage)));

  bool isOverloaded(Cable cable, Map<String, double> usage) =>
      _hops(cable).any((hop) => _over(hop, usage));

  /// Kabel ini atau salah satu hop di hulunya kelebihan beban.
  bool isJammed(Cable cable, Map<String, double> usage) {
    if (isOverloaded(cable, usage)) return true;
    for (var hop = _parent[cable.from]; hop != null; hop = _parent[hop.from]) {
      if (_over(hop, usage)) return true;
    }
    return false;
  }

  bool _over(Hop hop, Map<String, double> usage) =>
      hopLoad(hop, usage) > hop.cable.spec.capacityMbps;

  static List<Hop> _hops(Cable cable) {
    final stops = cable.stops;
    return [
      for (var i = 1; i < stops.length; i++) Hop(cable, stops[i - 1], stops[i]),
    ];
  }
}
