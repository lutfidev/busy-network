import '../map_scene.dart';
import '../model/cable.dart';
import '../model/game_state.dart';
import '../model/level_def.dart';
import '../sim/day_sim.dart';

/// Kenapa kepuasan tidak mencapai target: biang kerok di layar gagal dan
/// tips 1 bintang di layar berhasil. Berisi fakta; teksnya disusun layar.
sealed class Culprit {
  const Culprit();
}

/// Kabel yang paling lama penuh.
class FullCable extends Culprit {
  const FullCable({
    required this.area,
    required this.minute,
    required this.heavyUsers,
    required this.suggestFiber,
  });

  /// Blok yang dialiri kabel ("Blok B"), atau label rumah ("Rumah 4").
  final String area;

  /// Menit beban terparah.
  final int minute;

  /// Pelanggan pemakai terbesar di kabel itu, maksimal dua.
  final List<String> heavyUsers;

  /// Kabelnya LAN dan fiber sudah terbuka di level ini.
  final bool suggestFiber;
}

/// Ada rumah yang tidak tersambung (tidak ada kabel yang pernah penuh).
class Unconnected extends Culprit {
  const Unconnected(this.customers);

  /// Pelanggan rumah yang tidak tersambung, urutan level.
  final List<String> customers;
}

/// Batas antrean memotong pemakaian rumah (tidak ada kabel penuh, semua
/// tersambung).
class TightLimit extends Culprit {
  const TightLimit(this.customers);

  /// Pelanggan yang dibatasi, sabar terendah dulu, maksimal dua.
  final List<String> customers;
}

/// Hasil satu hari level: angka layar hasil, bintang, dan biang kerok.
class LevelResult {
  const LevelResult({
    required this.level,
    required this.satisfaction,
    required this.budgetLeft,
    required this.complaints,
    required this.housesLost,
    this.culprit,
  });

  /// Hasil hari [game] yang sudah sampai 24:00.
  factory LevelResult.of(GameState game) {
    final day = game.day;
    if (day == null || !day.over) {
      throw StateError('Hari belum selesai');
    }
    final level = game.level;
    final unconnected = [
      for (final h in level.houses)
        if (!day.network.connectedHouses.contains(h.id)) h,
    ];
    return LevelResult(
      level: level,
      satisfaction: day.satisfaction,
      budgetLeft: game.budget,
      complaints: day.complaints,
      housesLost: day.exhausted.length + unconnected.length,
      culprit:
          _fullCable(level, day) ??
          (unconnected.isNotEmpty
              ? Unconnected([for (final h in unconnected) h.customer])
              : _tightLimit(level, day)),
    );
  }

  final LevelDef level;

  /// Kepuasan akhir 0..100.
  final int satisfaction;

  /// Sisa anggaran setelah rancangan.
  final int budgetLeft;

  /// Jumlah komplain sepanjang hari.
  final int complaints;

  /// Rumah yang sabarnya sempat habis + rumah yang tidak tersambung.
  final int housesLost;

  /// `null` bila tidak ada yang bisa disalahkan (hanya dari potret).
  final Culprit? culprit;

  /// 0 = gagal (kepuasan di bawah batas lulus), 1 = lulus, 2 = kepuasan ≥
  /// target, 3 = juga sisa anggaran ≥ [LevelDef.savingsTarget].
  static int starsFor(
    LevelDef level, {
    required int satisfaction,
    required int budgetLeft,
  }) {
    if (satisfaction < level.passSatisfaction) return 0;
    if (satisfaction < level.targetSatisfaction) return 1;
    return budgetLeft >= level.savingsTarget ? 3 : 2;
  }

  int get stars =>
      starsFor(level, satisfaction: satisfaction, budgetLeft: budgetLeft);

  bool get passed => stars > 0;

  /// Kabel dengan menit penuh terbanyak; seri → yang lebih dulu penuh, lalu
  /// urutan pemasangan.
  static FullCable? _fullCable(LevelDef level, DaySim day) {
    Cable? worst;
    for (final cable in day.network.cables) {
      final minutes = day.fullMinutes(cable.id);
      if (minutes == 0) continue;
      if (worst == null) {
        worst = cable;
        continue;
      }
      final best = day.fullMinutes(worst.id);
      if (minutes > best ||
          (minutes == best &&
              day.firstFullMinute(cable.id)! <
                  day.firstFullMinute(worst.id)!)) {
        worst = cable;
      }
    }
    if (worst == null) return null;
    final carried = day.network.housesCarried(worst);
    final houses = [
      for (final h in level.houses)
        if (carried.contains(h.id)) h,
    ];
    final heavy = _sorted(
      level,
      houses,
      (a, b) => b.peakMbps.compareTo(a.peakMbps),
    );
    return FullCable(
      area: _area(level, worst, houses),
      minute: day.peakMinute(worst.id)!,
      heavyUsers: [for (final h in heavy.take(2)) h.customer],
      suggestFiber:
          worst.kind == CableKind.lan &&
          level.unlockedCables.any((s) => s.kind == CableKind.fiber),
    );
  }

  /// Blok bersama rumah yang dialiri [cable]; bila beda-beda atau ada yang
  /// tanpa blok: label rumah di ujung kabel, atau rumah pertama yang
  /// dialirinya bila ujungnya junction.
  static String _area(LevelDef level, Cable cable, List<HouseDef> houses) {
    final blocks = {for (final h in houses) h.block};
    if (blocks.length == 1 && blocks.first != null) return blocks.first!;
    for (final h in level.houses) {
      if (h.id == cable.to) return h.label;
    }
    return houses.first.label;
  }

  static TightLimit? _tightLimit(LevelDef level, DaySim day) {
    // Pemakaian terbesar sehari, termasuk lonjakan (level bos).
    final surge = level.surge?.factor ?? 1;
    final limited = [
      for (final h in level.houses)
        if (day.limits[h.id] case final limit? when limit < h.peakMbps * surge)
          h,
    ];
    if (limited.isEmpty) return null;
    final houses = day.frame.houses;
    final sorted = _sorted(
      level,
      limited,
      (a, b) => houses[a.id]!.patience.compareTo(houses[b.id]!.patience),
    );
    return TightLimit([for (final h in sorted.take(2)) h.customer]);
  }

  /// [houses] diurutkan [compare], seri → urutan level (sort Dart tidak
  /// stabil).
  static List<HouseDef> _sorted(
    LevelDef level,
    List<HouseDef> houses,
    int Function(HouseDef a, HouseDef b) compare,
  ) {
    final order = {for (final (i, h) in level.houses.indexed) h.id: i};
    return [...houses]..sort((a, b) {
      final c = compare(a, b);
      return c != 0 ? c : order[a.id]!.compareTo(order[b.id]!);
    });
  }
}
