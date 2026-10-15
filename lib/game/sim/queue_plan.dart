import '../map_scene.dart';
import '../model/cable.dart';
import '../model/level_def.dart';
import 'day_sim.dart';
import 'sim_frame.dart';

/// Satu rumah di Panel Atur Antrean.
class QueueHouse {
  const QueueHouse({
    required this.id,
    required this.name,
    required this.where,
    required this.packageMbps,
    required this.usageMbps,
    required this.onCable,
  });

  final String id;

  /// Nama pelanggan ("Bu Sri").
  final String name;

  /// Tempat ("Rumah 4", "Blok A").
  final String where;
  final int packageMbps;

  /// Pemakaian yang diinginkan sekarang (sebelum dibatasi).
  final double usageMbps;

  /// Rumah dilayani kabel yang disorot panel.
  final bool onCable;
}

/// Isi Panel Atur Antrean untuk hari [day]: kabel paling sesak, daftar
/// rumah tersambung, batas & prioritas yang sedang digeser, dan pratinjau
/// status bila antrean itu disimpan.
///
/// Urutan rumah dihitung sekali saat panel dibuka: rumah di kabel yang
/// disorot (hulu dulu), lalu sisanya macet → mulai lambat → lancar,
/// prioritas dulu, lalu urutan level.
class QueuePlan {
  QueuePlan._(
    this._day, {
    required this.houses,
    required this.cable,
    required this.cableLabel,
    required Map<String, int> limits,
    required Set<String> priority,
  }) : limits = Map.unmodifiable(limits),
       priority = Set.unmodifiable(priority),
       _preview = _day.preview(limits: limits, priority: priority);

  factory QueuePlan.of(DaySim day) {
    final net = day.network;
    final level = day.level;
    final frame = day.frame;
    final demand = frame.demand;

    double ratio(Cable c) => net.cableLoad(c, demand) / c.spec.capacityMbps;
    Cable? cable;
    for (final hop in net.treeHops) {
      if (cable == null || ratio(hop.cable) > ratio(cable)) cable = hop.cable;
    }
    final onCable = cable == null ? const <String>{} : net.housesCarried(cable);

    final order = {for (final (i, h) in level.houses.indexed) h.id: i};
    int rank(String id) => switch (frame.houses[id]!.state) {
      HouseState.jam => 0,
      HouseState.slow => 1,
      _ => 2,
    };
    int byLevel(String a, String b) => order[a]!.compareTo(order[b]!);
    final ids = frame.houses.keys;
    final upstream = ids.where(onCable.contains).toList()
      ..sort((a, b) {
        final depth = net.depthOf(a).compareTo(net.depthOf(b));
        return depth != 0 ? depth : byLevel(a, b);
      });
    final rest = ids.where((id) => !onCable.contains(id)).toList()
      ..sort((a, b) {
        final status = rank(a).compareTo(rank(b));
        if (status != 0) return status;
        final prio = (day.priority.contains(a) ? 0 : 1).compareTo(
          day.priority.contains(b) ? 0 : 1,
        );
        return prio != 0 ? prio : byLevel(a, b);
      });

    // Junction tidak bernama: pakai router/rumah terdekat di hulunya.
    String name(String id) {
      var node = id;
      while (node != LevelDef.routerId && !order.containsKey(node)) {
        final up = net.parentOf(node);
        if (up == null) return 'Router';
        node = up.from;
      }
      return node == LevelDef.routerId ? 'Router' : level.house(node).label;
    }

    return QueuePlan._(
      day,
      houses: [
        for (final id in [...upstream, ...rest])
          QueueHouse(
            id: id,
            name: level.house(id).customer,
            where: level.house(id).place,
            packageMbps: level.house(id).packageMbps,
            usageMbps: frame.houses[id]!.usageMbps,
            onCable: onCable.contains(id),
          ),
      ],
      cable: cable,
      cableLabel: cable == null
          ? ''
          : 'Kabel ${name(cable.from)} → ${name(cable.to)}',
      limits: day.limits,
      priority: day.priority,
    );
  }

  final DaySim _day;
  final List<QueueHouse> houses;

  /// Kabel yang disorot; `null` bila tidak ada kabel.
  final Cable? cable;

  /// "Kabel Router → Rumah 4".
  final String cableLabel;
  final Map<String, int> limits;
  final Set<String> priority;
  final Map<String, HouseLive> _preview;

  /// Hampir penuh di atas bagian kapasitas ini.
  static const tightShare = 0.85;

  int get capacityMbps => cable?.spec.capacityMbps ?? 0;

  /// "Pakai sekarang": pemakaian dipotong batas.
  double useOf(String id) => _preview[id]!.demandMbps;

  /// Beban kabel yang disorot dengan batas ini.
  double get load =>
      houses.where((h) => h.onCable).fold(0.0, (sum, h) => sum + useOf(h.id));

  bool get overloaded => load > capacityMbps;

  /// Pas-pasan: belum penuh tapi di atas [tightShare] kapasitas.
  bool get tight => !overloaded && load > capacityMbps * tightShare;

  /// Status rumah bila antrean ini disimpan sekarang.
  HouseState statusOf(String id) => _preview[id]!.state;

  /// Pemakai terbesar di kabel yang disorot (paling banyak dua), untuk
  /// petunjuk "Turunkan batas …".
  List<QueueHouse> get heaviest {
    final users = houses.where((h) => h.onCable).toList()
      ..sort((a, b) => useOf(b.id).compareTo(useOf(a.id)));
    return users.take(2).toList();
  }

  QueuePlan withLimit(String id, int limit) =>
      _copy(limits: {...limits, id: limit});

  QueuePlan togglePriority(String id) => _copy(
    priority: priority.contains(id)
        ? ({...priority}..remove(id))
        : {...priority, id},
  );

  QueuePlan _copy({Map<String, int>? limits, Set<String>? priority}) =>
      QueuePlan._(
        _day,
        houses: houses,
        cable: cable,
        cableLabel: cableLabel,
        limits: limits ?? this.limits,
        priority: priority ?? this.priority,
      );
}
