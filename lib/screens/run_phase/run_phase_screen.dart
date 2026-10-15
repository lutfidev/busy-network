import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_session.dart';
import '../../app/routes.dart';
import '../../game/map_scene.dart';
import '../../game/model/model.dart';
import '../../game/network_game_view.dart';
import '../../game/sim/sim.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'complaint_popup.dart';
import 'run_status_card.dart';

/// 5 · Fase Jalan: hari dari [session] berjalan 06:00 → 24:00.
///
/// Jam digerakkan `Ticker` (berhenti sendiri saat Panel Atur Antrean
/// menutupi rute ini atau app di latar belakang). Komplain menjeda hari
/// sampai dijawab. Tombol back = hari dibatalkan, kembali ke Fase Rancang.
/// 24:00 → layar hasil.
class RunPhaseScreen extends StatefulWidget {
  const RunPhaseScreen({super.key, required this.session});

  final GameSession session;

  @override
  State<RunPhaseScreen> createState() => _RunPhaseScreenState();
}

class _RunPhaseScreenState extends State<RunPhaseScreen>
    with SingleTickerProviderStateMixin {
  late final GameState _game = widget.session.running;
  late final Ticker _ticker = createTicker(_tick);
  Duration? _lastTick;
  bool _fastForward = false;
  bool _finished = false;

  DaySim get _day => _game.day!;

  @override
  void initState() {
    super.initState();
    _game.addListener(_onGameChanged);
    _syncClock();
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final seconds = math.min(
      (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond,
      SimClock.maxFrameSeconds,
    );
    _game.advanceDay(seconds * (_fastForward ? SimClock.fastForward : 1));
  }

  void _onGameChanged() {
    _syncClock();
    if (_game.phase == GamePhase.result) _finish();
    setState(() {});
  }

  /// Jam jalan selama hari berjalan dan tidak ada komplain menunggu.
  void _syncClock() {
    final run = _game.phase == GamePhase.run && _day.complaint == null;
    if (run == _ticker.isActive) return;
    if (run) {
      _lastTick = null;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  /// Hari selesai: berhasil bila kepuasan mencapai target.
  void _finish() {
    if (_finished) return;
    _finished = true;
    final passed = _day.satisfaction >= _game.level.targetSatisfaction;
    context.go(passed ? AppRoutes.success : AppRoutes.fail);
  }

  void _manageQueue() {
    _game.dismissComplaint();
    context.go(AppRoutes.queue);
  }

  String _mapLabel() {
    final houses = _day.frame.houses.values;
    int count(HouseState s) => houses.where((h) => h.state == s).length;
    return 'Peta jaringan malam hari: ${count(HouseState.ok)} rumah lancar, '
        '${count(HouseState.slow)} mulai lambat, '
        '${count(HouseState.jam)} macet.';
  }

  @override
  Widget build(BuildContext context) {
    final complaint = _day.complaint;
    final complainer = complaint == null
        ? null
        : _game.level.house(complaint.houseId);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.session.abandon(_game);
      },
      child: Scaffold(
        backgroundColor: AppColors.groundNight,
        body: NightScope(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenGutter),
                  child: RunStatusCard(
                    day: _day,
                    fastForward: _fastForward,
                    onFastForward: () =>
                        setState(() => _fastForward = !_fastForward),
                    onPause: () => context.go(AppRoutes.queue),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: NetworkGameView(
                          state: _game,
                          alignment: Alignment.topCenter,
                          semanticLabel: _mapLabel(),
                        ),
                      ),
                      if (complaint != null && complainer != null)
                        Positioned(
                          left: AppSpacing.screenGutter,
                          right: AppSpacing.screenGutter,
                          bottom: AppSpacing.s18,
                          child: ComplaintPopup(
                            name: complainer.customer,
                            house: complainer.label,
                            clockMinutes: complaint.minute,
                            message: complainer.complaint,
                            onManageQueue: _manageQueue,
                            onIgnore: _game.dismissComplaint,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
