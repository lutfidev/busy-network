import '../../data/dummy_data.dart';
import '../../widgets/status_dot.dart';

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
  });

  factory QueueModel.initial() => QueueModel(
    houses: DummyData.queueHouses,
    limits: {for (final h in DummyData.queueHouses) h.id: h.initialLimit},
    priority: {
      for (final h in DummyData.queueHouses)
        if (h.initiallyPrioritized) h.id,
    },
    capacityMbps: DummyData.overloadedCapacity,
  );

  final List<QueueHouse> houses;
  final Map<String, int> limits;
  final Set<String> priority;
  final int capacityMbps;

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
  );

  QueueModel togglePriority(String id) => QueueModel(
    houses: houses,
    limits: limits,
    priority: priority.contains(id)
        ? ({...priority}..remove(id))
        : {...priority, id},
    capacityMbps: capacityMbps,
  );
}
