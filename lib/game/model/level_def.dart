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
    this._place,
    required this.packageMbps,
    required this.peakMbps,
    this.labelSide = MarkSide.below,
    this.patienceSide = MarkSide.below,
  });

  final String id;

  /// Label di peta ("Rumah 4", "Warung").
  final String label;
  final Offset position;

  /// Nama pelanggan ("Bu Sri").
  final String customer;
  final String? _place;

  /// Paket langganan (Mbps).
  final int packageMbps;

  /// Profil pemakaian: pemakaian saat jam sibuk (Mbps). Kurva harian
  /// dibentuk dari sini di langkah 5.
  final double peakMbps;

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
    this.rushHourFrom,
    this.rushHourTo,
    required this.blockLabels,
    this._nightBlockLabels,
  });

  static const double cell = gridCell;
  static const routerId = 'router';

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
}
