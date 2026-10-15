import 'package:flutter/foundation.dart';

import '../map_scene.dart';
import 'cable.dart';
import 'level_def.dart';
import 'network.dart';

enum GamePhase { design, run, result }

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
       cables = List.unmodifiable(cables ?? level.cables),
       _selectedCable = selectedCable,
       _draft = draft {
    _checkUnlocked(selectedCable);
    if (draft != null) _checkUnlocked(draft.kind);
  }

  final LevelDef level;
  final List<Junction> junctions;
  final List<Cable> cables;

  GamePhase _phase;
  // Belum berubah di langkah 2; langkah 4 (pasang/bongkar) membuatnya
  // non-final.
  final int _budget;
  CableKind _selectedCable;
  CableDraft? _draft;
  SimFrame? _frame;

  GamePhase get phase => _phase;

  /// Sisa anggaran.
  int get budget => _budget;
  CableKind get selectedCable => _selectedCable;
  CableDraft? get draft => _draft;
  SimFrame? get frame => _frame;

  /// Jaringan tetap selama langkah 2 (belum ada tarik/bongkar kabel).
  late final Network network = Network(level: level, cables: cables);

  Set<String> get connectedHouses => network.connectedHouses;
  int get connectedCount => connectedHouses.length;

  /// Biaya kabel yang sedang ditarik (belum dipotong dari [budget]).
  int get draftCost => _draft?.cost ?? 0;

  void selectCable(CableKind kind) {
    _checkUnlocked(kind);
    if (kind == _selectedCable) return;
    _selectedCable = kind;
    _draft = _draft?.withKind(kind);
    notifyListeners();
  }

  void setDraft(CableDraft? draft) {
    _expectPhase(GamePhase.design);
    if (draft != null) _checkUnlocked(draft.kind);
    _draft = draft;
    notifyListeners();
  }

  /// Rancang → jalan. Rumah tersambung mulai lancar dengan sabar penuh.
  void startDay() {
    _expectPhase(GamePhase.design);
    _phase = GamePhase.run;
    _draft = null;
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
