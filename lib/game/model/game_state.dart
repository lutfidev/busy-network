import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../map_scene.dart';
import '../sim/sim.dart';
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

/// Tarikan yang sedang berjalan (jari masih menempel).
class _Pull {
  _Pull(this.from, this.walk);

  final String from;
  final CableWalk walk;

  /// Rumah/junction bercincin snap.
  String? target;

  /// Ujung jalur sudah di pusat [target]: lepas = pasang.
  bool docked = false;
}

/// State satu permainan level: fase, anggaran, jaringan, draft, simulasi.
class GameState extends ChangeNotifier {
  GameState(
    this.level, {
    int? budget,
    List<Junction>? junctions,
    List<Cable>? cables,
    CableKind selectedCable = CableKind.lan,
    CableDraft? draft,
    this._lesson,
  }) : _budget = budget ?? level.budget,
       junctions = List.unmodifiable(junctions ?? level.junctions),
       _cables = List.unmodifiable(cables ?? level.cables),
       _selectedCable = selectedCable,
       _draft = draft {
    _checkUnlocked(selectedCable);
    if (draft != null) _checkUnlocked(draft.kind);
  }

  /// Tujuan terdekat dari jari dalam jarak ini mendapat cincin snap.
  static const double snapRadius = 90;

  /// Jari sedekat ini dari pusat tujuan (= jari-jari cincin snap,
  /// `MapRenderer.snapRingRadius`) → kabel menempel ke situ.
  static const double dockRadius = 30;

  /// Bagian biaya yang kembali saat kabel dibongkar.
  static const refundShare = 0.5;

  final LevelDef level;
  final List<Junction> junctions;

  GamePhase _phase = GamePhase.design;
  int _budget;
  List<Cable> _cables;
  CableKind _selectedCable;
  CableDraft? _draft;
  DaySim? _day;
  bool _erasing = false;
  _Pull? _pull;
  int? _refusedCost;
  Network? _network;
  CableLesson? _lesson;

  GamePhase get phase => _phase;

  /// Sisa anggaran.
  int get budget => _budget;

  /// Kabel terpasang (tidak bisa diubah dari luar).
  List<Cable> get cables => _cables;
  CableKind get selectedCable => _selectedCable;
  CableDraft? get draft => _draft;

  /// Hari yang dimainkan (sejak [startDay]).
  DaySim? get day => _day;

  /// Potret hari pada menit ini; `null` sebelum hari dimulai.
  SimFrame? get frame => _day?.frame;

  /// Mode Hapus: ketuk kabel = bongkar.
  bool get erasing => _erasing;

  /// Jari sedang menarik kabel.
  bool get pulling => _pull != null;

  /// Biaya kabel terakhir yang ditolak karena anggaran kurang; hilang saat
  /// pemain melakukan aksi berikutnya.
  int? get refusedCost => _refusedCost;

  /// Tarikan yang diajarkan tutorial (membatasi sumber & tujuan).
  CableLesson? get lesson => _lesson;

  /// Kabel panduan pelajaran: tampil selama jari tidak menarik dan tujuan
  /// pelajaran belum tersambung.
  CableDraft? get guide {
    final lesson = _lesson;
    if (lesson == null || _pull != null || isConnected(lesson.to)) {
      return null;
    }
    return CableDraft(
      from: lesson.from,
      kind: _selectedCable,
      points: lesson.guide,
    );
  }

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

  /// Tarikan bisa dimulai dari router, atau junction/rumah yang tersambung;
  /// selama ada [lesson] hanya dari sumbernya.
  bool canStartCable(String nodeId) =>
      _phase == GamePhase.design &&
      !_erasing &&
      _hasNode(nodeId) &&
      isConnected(nodeId) &&
      (_lesson == null || nodeId == _lesson!.from);

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

  void setLesson(CableLesson? lesson) {
    if (identical(lesson, _lesson)) return;
    _lesson = lesson;
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

  /// Jari (koordinat peta) bergerak selama tarikan. Hanya memberi tahu bila
  /// jalur, tujuan, atau status menempel berubah (bukan tiap geseran).
  void dragCable(Offset finger) {
    final pull = _pull;
    if (pull == null) return;
    (int, Cell, String?, bool) shape() =>
        (pull.walk.cells.length, pull.walk.end, pull.target, pull.docked);
    final before = shape();
    final target = _snapTarget(finger);
    final targetCell = target == null ? null : level.cellOf(target.$2);
    final dock = target != null && (finger - target.$2).distance <= dockRadius;
    pull.walk.moveTo(dock ? targetCell! : level.snap(finger), dock: dock);
    pull
      ..target = target?.$1
      ..docked = dock && pull.walk.end == targetCell;
    if (shape() == before) return;
    _draft = _draftOf(pull);
    notifyListeners();
  }

  /// Jari dilepas. Menempel di tujuan & anggaran cukup → kabel terpasang.
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
  /// Rancang → jalan: hari dimulai 06:00 di jaringan ini, rumah tersambung
  /// lancar dengan sabar penuh.
  ///
  /// Parameter lain melanjutkan hari dari potret (bingkai Fase Jalan di
  /// desain): jam, sabar tiap rumah, prioritas antrean, komplain yang
  /// sedang tampil, dan jumlah komplain sejauh ini.
  void startDay({
    int minute = SimClock.dayStart,
    Map<String, double> patience = const {},
    Set<String> priority = const {},
    Complaint? complaint,
    int complaints = 0,
  }) {
    _expectPhase(GamePhase.design);
    _phase = GamePhase.run;
    _draft = null;
    _pull = null;
    _erasing = false;
    _refusedCost = null;
    _day = DaySim(
      level: level,
      network: network,
      minute: minute,
      patience: patience,
      priority: priority,
      complaint: complaint,
      complaints: complaints,
    );
    notifyListeners();
  }

  /// Rancangan ini sebagai hari baru di state terpisah (fase jalan), supaya
  /// rancangan tetap utuh bila pemain kembali ke Fase Rancang.
  GameState planDay() => GameState(
    level,
    budget: _budget,
    junctions: junctions,
    cables: _cables,
    selectedCable: _selectedCable,
  )..startDay();

  /// Majukan hari [seconds] detik nyata (sudah dikali kecepatan). Memberi
  /// tahu bila jam berubah; sampai 24:00 → fase hasil.
  void advanceDay(double seconds) {
    _expectPhase(GamePhase.run);
    final day = _day!;
    if (!day.advance(seconds * SimClock.minutesPerSecond)) return;
    if (day.over) _phase = GamePhase.result;
    notifyListeners();
  }

  /// Simpan batas & prioritas dari Panel Atur Antrean.
  void setQueue({
    required Map<String, int> limits,
    required Set<String> priority,
  }) {
    _expectPhase(GamePhase.run);
    _day!.setQueue(limits: limits, priority: priority);
    notifyListeners();
  }

  /// Komplain dijawab ("Abaikan" / "Atur antrean"); hari bisa lanjut.
  void dismissComplaint() {
    _expectPhase(GamePhase.run);
    if (_day!.complaint == null) return;
    _day!.dismissComplaint();
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

  /// Tujuan terdekat dari [finger] dalam [snapRadius]: rumah, atau junction
  /// yang putus (supaya kabel di hilirnya bisa tersambung lagi), yang belum
  /// tersambung. Sumber tarikan selalu tersambung, jadi tidak ikut. Selama
  /// ada [lesson] hanya tujuannya.
  (String, Offset)? _snapTarget(Offset finger) {
    (String, Offset)? best;
    var bestDistance = snapRadius;
    for (final (id, position) in [
      for (final h in level.houses) (h.id, h.position),
      for (final j in junctions) (j.id, j.position),
    ]) {
      if (isConnected(id)) continue;
      if (_lesson != null && id != _lesson!.to) continue;
      final d = (finger - position).distance;
      if (d <= bestDistance) {
        best = (id, position);
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
        endTrim: pull.docked ? _reach(pull.target!) : 0,
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
