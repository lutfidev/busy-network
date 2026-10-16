import 'dart:ui';

import '../map_scene.dart';
import 'cable.dart';

/// Sisi tempat label / bar sabar rumah digambar.
enum MarkSide { below, right, above }

/// Rumah pelanggan di sebuah level.
class HouseDef {
  const HouseDef({
    required this.id,
    required this.label,
    required this.position,
    required this.customer,
    this.block,
    this._place,
    required this.packageMbps,
    required this.peakMbps,
    this.labelSide = MarkSide.below,
    this.patienceSide = MarkSide.below,
    this.complaint = defaultComplaint,
  });

  /// Komplain untuk pelanggan yang belum punya teks sendiri (copy baru).
  static const defaultComplaint = 'Bang, internetnya kok lemot banget?';

  final String id;

  /// Label di peta ("Rumah 4", "Warung").
  final String label;
  final Offset position;

  /// Nama pelanggan ("Bu Sri").
  final String customer;

  /// Blok tempat rumah ini ("Blok B"): nama area kabel di biang kerok.
  /// `null` bila desain tidak menaruhnya di blok mana pun.
  final String? block;
  final String? _place;

  /// Paket langganan (Mbps).
  final int packageMbps;

  /// Pemakaian saat jam sibuk (Mbps); di luar itu mengikuti `UsageCurve`.
  final double peakMbps;

  /// Isi pop-up komplain saat rumah ini macet.
  final String complaint;

  /// Fase rancang: [MarkSide.right] = label di kanan rumah, rata kiri.
  final MarkSide labelSide;

  /// Fase jalan: letak bar sabar; [MarkSide.right] = label rata kiri.
  final MarkSide patienceSide;

  /// Tempat di daftar antrean ("Rumah 4", "Blok A"); default [label].
  String get place => _place ?? label;
}

/// Titik cabang kabel.
class Junction {
  const Junction({required this.id, required this.position});

  final String id;
  final Offset position;
}

/// Satu babak di Peta Babak.
class ChapterDef {
  const ChapterDef({
    required this.number,
    required this.name,
    required this.levelCount,
  });

  final int number;
  final String name;

  /// Jumlah level termasuk level bos.
  final int levelCount;

  /// Bintang maksimal: 3 per level.
  int get starsTotal => levelCount * 3;
}

/// Definisi satu level (statis). Koordinat dalam ruang peta 390×472.
class LevelDef {
  const LevelDef({
    required this.number,
    required this.name,
    required this.gridOrigin,
    required this.routerPosition,
    this.routerLabel,
    required this.houses,
    this.junctions = const [],
    this.cables = const [],
    required this.budget,
    required this.targetSatisfaction,
    required this.passSatisfaction,
    this.savingsTarget = defaultSavingsTarget,
    this.rushHourFrom,
    this.rushHourTo,
    required this.blockLabels,
    this._nightBlockLabels,
  });

  static const double cell = gridCell;
  static const routerId = 'router';

  /// Sisa anggaran minimal untuk bintang 3 bila level tidak menentukannya.
  static const defaultSavingsTarget = 200000;

  /// Area peta (px desain), sama dengan `AppSizes.mapArea`.
  static const mapSize = Size(390, 472);

  /// Jarak pusat → tepi node tempat kabel mulai/berakhir: router 48×48,
  /// rumah berjari-jari 20 (`AppSizes.routerSize / 2`, `houseRadius`).
  /// Kabel junction mulai dari pusatnya.
  static const double routerReach = 24;
  static const double houseReach = 20;

  final int number;
  final String name;

  /// Titik grid acuan: node & belokan kabel ada di gridOrigin + (30i, 30j).
  /// Level 5 bergeser 15 px vertikal dari titik grid yang digambar.
  final Offset gridOrigin;
  final Offset routerPosition;
  final String? routerLabel;
  final List<HouseDef> houses;

  /// Jaringan awal level (sudah terpasang saat level dimulai).
  final List<Junction> junctions;
  final List<Cable> cables;

  final int budget;
  final int targetSatisfaction;

  /// Kepuasan akhir minimal supaya lulus (1 bintang); di bawahnya gagal.
  final int passSatisfaction;

  /// Sisa anggaran minimal untuk bintang 3 (selain kepuasan ≥ target).
  final int savingsTarget;
  final int? rushHourFrom;
  final int? rushHourTo;

  /// Label blok (siang). Fase jalan memakai [nightBlockLabels].
  final List<MapBlockLabel> blockLabels;
  final List<MapBlockLabel>? _nightBlockLabels;

  List<MapBlockLabel> get nightBlockLabels => _nightBlockLabels ?? blockLabels;

  List<CableSpec> get unlockedCables => [
    for (final spec in CableSpec.all)
      if (spec.unlockLevel <= number) spec,
  ];

  HouseDef house(String id) => houses.firstWhere((h) => h.id == id);

  /// Posisi router, rumah, atau junction awal level.
  Offset positionOf(String nodeId) {
    if (nodeId == routerId) return routerPosition;
    for (final h in houses) {
      if (h.id == nodeId) return h.position;
    }
    for (final j in junctions) {
      if (j.id == nodeId) return j.position;
    }
    throw ArgumentError.value(nodeId, 'nodeId', 'tidak ada di level $number');
  }

  bool onGrid(Offset p) {
    bool aligned(double v) {
      final steps = v / cell;
      return (steps - steps.round()).abs() < 1e-6;
    }

    final d = p - gridOrigin;
    return aligned(d.dx) && aligned(d.dy);
  }

  /// Titik grid terdekat dari [p] (boleh di luar peta).
  Cell cellOf(Offset p) {
    final d = p - gridOrigin;
    return (i: (d.dx / cell).round(), j: (d.dy / cell).round());
  }

  Offset pointOf(Cell c) => gridOrigin + Offset(c.i * cell, c.j * cell);

  /// Titik grid di dalam peta (tidak menempel tepi) yang terdekat dari
  /// jari [p].
  Cell snap(Offset p) {
    int lo(double origin) => (-origin / cell).floor() + 1;
    int hi(double origin, double size) => ((size - origin) / cell).ceil() - 1;
    final c = cellOf(p);
    return (
      i: c.i.clamp(lo(gridOrigin.dx), hi(gridOrigin.dx, mapSize.width)),
      j: c.j.clamp(lo(gridOrigin.dy), hi(gridOrigin.dy, mapSize.height)),
    );
  }
}
