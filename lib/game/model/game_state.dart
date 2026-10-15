import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../map_scene.dart';
import 'cable.dart';
import 'cable_walk.dart';
import 'level_def.dart';
import 'network.dart';

enum GamePhase { design, run, result }

/// Hasil melepas jari saat menarik kabel.
enum CableDrop {
  /// Kabel terpasang dan anggaran terpotong.
  connected,

  /// Dilepas di luar rumah tujuan: tarikan batal.
  missed,

  /// Sampai di rumah tapi anggaran kurang: kabel tidak dipasang.
  overBudget,
}

/// Keadaan satu rumah saat hari berjalan.
class HouseLive {
  const HouseLive({
    required this.state,
    required this.patience,
    required this.usageMbps,
  });

  final HouseState state;

  /// Sisa kesabaran 0..1.
  final double patience;
  final double usageMbps;
}

/// Potret simulasi pada satu saat (diisi simulasi di langkah 5).
class SimFrame {
  const SimFrame({required this.houses});

  /// Hanya rumah tersambung.
  final Map<String, HouseLive> houses;

  Map<String, double> get usage => {
    for (final e in houses.entries) e.key: e.value.usageMbps,
  };
}

/// Tarikan yang sedang berjalan (jari masih menempel).
class _Pull {
  _Pull(this.from, this.walk);

  final String from;
  final CableWalk walk;

  /// Rumah bercincin snap.
  String? target;

  /// Ujung jalur sudah di pusat [target]: lepas = pasang.
  bool docked = false;
}

/// State satu permainan level: fase, anggaran, jaringan, draft, simulasi.
class GameState extends ChangeNotifier {
  GameState(
    this.level, {
    this._phase = GamePhase.design,
    int? budget,
    List<Junction>? junctions,
    List<Cable>? cables,
    CableKind selectedCable = CableKind.lan,
    CableDraft? draft,
    this._frame,
  }) : _budget = budget ?? level.budget,
       junctions = List.unmodifiable(junctions ?? level.junctions),
       _cables = List.unmodifiable(cables ?? level.cables),
       _selectedCable = selectedCable,
       _draft = draft {
    _checkUnlocked(selectedCable);
    if (draft != null) _checkUnlocked(draft.kind);
  }

  /// Rumah terdekat dari jari dalam jarak ini mendapat cincin snap.
  static const double snapRadius = 90;

  /// Jari sedekat ini dari pusat rumah (= jari-jari cincin snap) →
  /// kabel menempel ke rumah itu.
  static const double dockRadius = 30;

  /// Bagian biaya yang kembali saat kabel dibongkar.
  static const refundShare = 0.5;

  final LevelDef level;
  final List<Junction> junctions;

  GamePhase _phase;
  int _budget;
  List<Cable> _cables;
  CableKind _selectedCable;
  CableDraft? _draft;
  SimFrame? _frame;
  bool _erasing = false;
  _Pull? _pull;
  int? _refusedCost;
  Network? _network;

  GamePhase get phase => _phase;

  /// Sisa anggaran.
  int get budget => _budget;

  /// Kabel terpasang (tidak bisa diubah dari luar).
  List<Cable> get cables => _cables;
  CableKind get selectedCable => _selectedCable;
  CableDraft? get draft => _draft;
  SimFrame? get frame => _frame;

  /// Mode Hapus: ketuk kabel = bongkar.
  bool get erasing => _erasing;

  /// Jari sedang menarik kabel.
  bool get pulling => _pull != null;

  /// Biaya kabel terakhir yang ditolak karena anggaran kurang; hilang saat
  /// pemain melakukan aksi berikutnya.
  int? get refusedCost => _refusedCost;

  Network get network => _network ??= Network(level: level, cables: _cables);

  Set<String> get connectedHouses => network.connectedHouses;
  int get connectedCount => connectedHouses.length;

  /// Biaya kabel yang sedang ditarik (belum dipotong dari [budget]).
  int get draftCost => _draft?.cost ?? 0;

  /// Kabel yang sedang ditarik lebih mahal dari sisa anggaran.
  bool get draftOverBudget => draftCost > _budget;

  /// Router, rumah, atau junction (termasuk junction tambahan state ini).
  Offset positionOf(String nodeId) {
    for (final j in junctions) {
      if (j.id == nodeId) return j.position;
    }
    return level.positionOf(nodeId);
  }

  /// Node yang sudah dapat internet dari router.
  bool isConnected(String nodeId) =>
      nodeId == LevelDef.routerId || network.parentOf(nodeId) != null;

  /// Tarikan bisa dimulai dari router, atau junction/rumah yang tersambung.
  bool canStartCable(String nodeId) =>
      _phase == GamePhase.design &&
      !_erasing &&
      _hasNode(nodeId) &&
      isConnected(nodeId);

  void selectCable(CableKind kind) {
    _checkUnlocked(kind);
    if (kind == _selectedCable && !_erasing) return;
    _selectedCable = kind;
    _erasing = false;
    _refusedCost = null;
    _draft = _draft?.withKind(kind);
    notifyListeners();
  }

  void setDraft(CableDraft? draft) {
    _expectPhase(GamePhase.design);
    if (draft != null) _checkUnlocked(draft.kind);
    _draft = draft;
    notifyListeners();
  }

  void setErasing(bool on) {
    _expectPhase(GamePhase.design);
    if (on == _erasing) return;
    _erasing = on;
    _refusedCost = null;
    if (on) {
      _pull = null;
      _draft = null;
    }
    notifyListeners();
  }

  // ── Tarik kabel ─────────────────────────────────────────────────────
  /// Jari menekan node [nodeId]. `false` bila tarikan tidak bisa dimulai
  /// dari situ (lihat [canStartCable]).
  bool beginCable(String nodeId) {
    if (!canStartCable(nodeId)) return false;
    final source = level.cellOf(positionOf(nodeId));
    _pull = _Pull(
      nodeId,
      CableWalk(
        source,
        blocked: {for (final p in _nodePositions()) level.cellOf(p)}
          ..remove(source),
      ),
    );
    _draft = null;
    _refusedCost = null;
    notifyListeners();
    return true;
  }

  /// Jari (koordinat peta) bergerak selama tarikan.
  void dragCable(Offset finger) {
    final pull = _pull;
    if (pull == null) return;
    final target = _snapTarget(finger, exclude: pull.from);
    final targetCell = target == null ? null : level.cellOf(target.$2);
    final dock = target != null && (finger - target.$2).distance <= dockRadius;
    pull.walk.moveTo(dock ? targetCell! : level.snap(finger), dock: dock);
    pull
      ..target = target?.$1
      ..docked = dock && pull.walk.end == targetCell;
    _draft = _draftOf(pull);
    notifyListeners();
  }

  /// Jari dilepas. Menempel di rumah & anggaran cukup → kabel terpasang.
  CableDrop endCable() {
    final pull = _pull;
    final draft = _draft;
    _pull = null;
    _draft = null;
    var drop = CableDrop.missed;
    if (pull != null && pull.docked && draft != null) {
      if (draft.cost > _budget) {
        drop = CableDrop.overBudget;
        _refusedCost = draft.cost;
      } else {
        drop = CableDrop.connected;
        _budget -= draft.cost;
        _setCables([
          ..._cables,
          Cable(
            id: _newCableId(pull.target!),
            from: pull.from,
            to: pull.target!,
            kind: draft.kind,
            points: draft.points,
          ),
        ]);
      }
    }
    if (pull != null) notifyListeners();
    return drop;
  }

  /// Tarikan dibatalkan sistem (mis. gestur direbut).
  void cancelCable() {
    if (_pull == null) return;
    _pull = null;
    _draft = null;
    notifyListeners();
  }

  // ── Bongkar ─────────────────────────────────────────────────────────
  /// Uang kembali bila kabel [cable] dibongkar.
  static int refundOf(Cable cable) => (cable.cost * refundShare).floor();

  /// Bongkar kabel [cableId]; uang kembali [refundOf]. Rumah di hilirnya
  /// ikut putus. Mengembalikan uang yang kembali.
  int removeCable(String cableId) {
    _expectPhase(GamePhase.design);
    final cable = _cables.firstWhere(
      (c) => c.id == cableId,
      orElse: () => throw ArgumentError.value(cableId, 'cableId', 'tidak ada'),
    );
    final refund = refundOf(cable);
    _budget += refund;
    _refusedCost = null;
    _setCables([
      for (final c in _cables)
        if (c.id != cableId) c,
    ]);
    notifyListeners();
    return refund;
  }

  // ── Fase ────────────────────────────────────────────────────────────
  /// Rancang → jalan. Rumah tersambung mulai lancar dengan sabar penuh.
  void startDay() {
    _expectPhase(GamePhase.design);
    _phase = GamePhase.run;
    _draft = null;
    _pull = null;
    _erasing = false;
    _refusedCost = null;
    _frame = SimFrame(
      houses: {
        for (final id in connectedHouses)
          id: const HouseLive(state: HouseState.ok, patience: 1, usageMbps: 0),
      },
    );
    notifyListeners();
  }

  void updateFrame(SimFrame frame) {
    _expectPhase(GamePhase.run);
    _frame = frame;
    notifyListeners();
  }

  /// Jalan → hasil.
  void finishDay() {
    _expectPhase(GamePhase.run);
    _phase = GamePhase.result;
    notifyListeners();
  }

  // ── Bantuan ─────────────────────────────────────────────────────────
  void _setCables(List<Cable> cables) {
    _cables = List.unmodifiable(cables);
    _network = null;
  }

  bool _hasNode(String nodeId) =>
      nodeId == LevelDef.routerId ||
      level.houses.any((h) => h.id == nodeId) ||
      junctions.any((j) => j.id == nodeId);

  Iterable<Offset> _nodePositions() => [
    level.routerPosition,
    for (final h in level.houses) h.position,
    for (final j in junctions) j.position,
  ];

  /// Rumah belum tersambung terdekat dari [finger] dalam [snapRadius].
  (String, Offset)? _snapTarget(Offset finger, {required String exclude}) {
    (String, Offset)? best;
    var bestDistance = snapRadius;
    for (final h in level.houses) {
      if (h.id == exclude || connectedHouses.contains(h.id)) continue;
      final d = (finger - h.position).distance;
      if (d <= bestDistance) {
        best = (h.id, h.position);
        bestDistance = d;
      }
    }
    return best;
  }

  CableDraft? _draftOf(_Pull pull) {
    final cells = pull.walk.cells;
    if (cells.length < 2) return null;
    return CableDraft(
      from: pull.from,
      kind: _selectedCable,
      points: cablePolyline(
        [for (final c in cells) level.pointOf(c)],
        startTrim: _reach(pull.from),
        endTrim: pull.docked ? LevelDef.houseReach : 0,
      ),
      target: pull.target,
      handle: pull.docked ? null : level.pointOf(pull.walk.end),
    );
  }

  double _reach(String nodeId) {
    if (nodeId == LevelDef.routerId) return LevelDef.routerReach;
    if (level.houses.any((h) => h.id == nodeId)) return LevelDef.houseReach;
    return 0;
  }

  String _newCableId(String to) {
    final ids = {for (final c in _cables) c.id};
    var id = 'c-$to';
    for (var n = 2; ids.contains(id); n++) {
      id = 'c-$to-$n';
    }
    return id;
  }

  void _expectPhase(GamePhase expected) {
    if (_phase != expected) {
      throw StateError('Butuh fase ${expected.name}, sekarang ${_phase.name}');
    }
  }

  void _checkUnlocked(CableKind kind) {
    if (!level.unlockedCables.any((s) => s.kind == kind)) {
      throw ArgumentError.value(
        kind,
        'kind',
        'belum terbuka di level ${level.number}',
      );
    }
  }
}
