import '../../data/dummy_states.dart';
import '../../game/model/model.dart';
import '../../widgets/status_dot.dart';

/// Satu rumah di panel antrean.
class QueueHouse {
  const QueueHouse({
    required this.id,
    required this.name,
    required this.where,
    required this.packageMbps,
    required this.usageMbps,
    required this.initialLimit,
    this.onOverloadedCable = false,
  });

  final String id;
  final String name;
  final String where;
  final int packageMbps;
  final double usageMbps;
  final int initialLimit;

  /// Rumah yang lewat kabel yang disorot panel.
  final bool onOverloadedCable;
}

/// Hitungan panel antrean (port dari logika prototipe HTML).
///
/// Murni & tanpa Flutter supaya mudah dites dan nanti dipindah ke
/// simulasi game.
class QueueModel {
  const QueueModel({
    required this.houses,
    required this.limits,
    required this.priority,
    required this.capacityMbps,
    required this.cableLabel,
  });

  factory QueueModel.initial() => QueueModel.fromState(
    DummyStates.run(),
    order: DummyStates.queueOrder,
    priority: DummyStates.queuePriority,
  );

  /// Panel untuk kabel paling sesak (rasio beban/kapasitas tertinggi) di
  /// fase jalan; rumah ditampilkan sesuai [order].
  factory QueueModel.fromState(
    GameState state, {
    required List<String> order,
    required Set<String> priority,
  }) {
    final usage = state.frame?.usage ?? const <String, double>{};
    final net = state.network;
    double ratio(Cable c) => net.cableLoad(c, usage) / c.spec.capacityMbps;
    final cable = state.cables.reduce((a, b) => ratio(b) > ratio(a) ? b : a);
    final served = net.housesBelow(cable.stops[1]);
    final level = state.level;
    String name(String id) =>
        id == LevelDef.routerId ? 'Router' : level.house(id).label;
    final houses = [
      for (final id in order)
        QueueHouse(
          id: id,
          name: level.house(id).customer,
          where: level.house(id).place,
          packageMbps: level.house(id).packageMbps,
          usageMbps: usage[id] ?? 0,
          initialLimit: level.house(id).packageMbps,
          onOverloadedCable: served.contains(id),
        ),
    ];
    return QueueModel(
      houses: houses,
      limits: {for (final h in houses) h.id: h.initialLimit},
      priority: {...priority},
      capacityMbps: cable.spec.capacityMbps,
      cableLabel: 'Kabel ${name(cable.from)} → ${name(cable.to)}',
    );
  }

  final List<QueueHouse> houses;
  final Map<String, int> limits;
  final Set<String> priority;
  final int capacityMbps;

  /// "Kabel Router → Rumah 4".
  final String cableLabel;

  double effectiveUse(QueueHouse h) {
    final limit = limits[h.id]!.toDouble();
    return h.usageMbps < limit ? h.usageMbps : limit;
  }

  /// Beban kabel yang penuh (jumlah pemakaian rumah di jalur itu).
  double get load => houses
      .where((h) => h.onOverloadedCable)
      .fold(0, (sum, h) => sum + effectiveUse(h));

  bool get overloaded => load > capacityMbps;

  /// Hampir penuh (> 85% kapasitas).
  bool get tight => !overloaded && load > capacityMbps * 0.85;

  ServiceStatus statusOf(QueueHouse h) {
    if (h.onOverloadedCable && overloaded) {
      return h.id == 'r4' ? ServiceStatus.jam : ServiceStatus.slow;
    }
    // Rumah 3 di prototipe memang selalu "mulai lambat".
    if (h.id == 'r3') return ServiceStatus.slow;
    if (effectiveUse(h) < h.usageMbps * 0.6) return ServiceStatus.slow;
    return ServiceStatus.ok;
  }

  QueueModel withLimit(String id, int limit) => QueueModel(
    houses: houses,
    limits: {...limits, id: limit},
    priority: priority,
    capacityMbps: capacityMbps,
    cableLabel: cableLabel,
  );

  QueueModel togglePriority(String id) => QueueModel(
    houses: houses,
    limits: limits,
    priority: priority.contains(id)
        ? ({...priority}..remove(id))
        : {...priority, id},
    capacityMbps: capacityMbps,
    cableLabel: cableLabel,
  );
}
