import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_session.dart';
import '../../app/routes.dart';
import '../../core/format.dart';
import '../../game/levels/levels.dart';
import '../../game/map_scene.dart';
import '../../game/model/model.dart';
import '../../game/network_game_view.dart';
import '../../game/render/map_renderer.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// 4 · Fase Rancang – Level 5. Seret dari router/junction/rumah tersambung
/// ke rumah untuk memasang kabel; mode Hapus: ketuk kabel untuk membongkar.
/// "Mulai Hari" menyerahkan salinan rancangan ke [session] sebagai hari baru.
class DesignPhaseScreen extends StatefulWidget {
  const DesignPhaseScreen({
    super.key,
    required this.session,
    this.initialCable = CableKind.lan,
    this.level = Levels.level5,
  });

  final GameSession session;

  /// Level yang dirancang (`?level=n`).
  final LevelDef level;
  final CableKind initialCable;

  @override
  State<DesignPhaseScreen> createState() => _DesignPhaseScreenState();
}

class _DesignPhaseScreenState extends State<DesignPhaseScreen> {
  late final GameState _game = GameState(
    widget.level,
    selectedCable: widget.initialCable,
  );

  @override
  void initState() {
    super.initState();
    _game.addListener(_onGameChanged);
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  /// "Mulai Hari" sudah diketuk dan Fase Jalan sedang/sudah menutupi rute
  /// ini; ketukan berikutnya diabaikan sampai pemain kembali ke sini.
  bool _dayStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) ?? true) _dayStarted = false;
  }

  void _onGameChanged() => setState(() {});

  void _startDay() {
    if (_dayStarted) return;
    _dayStarted = true;
    _game.cancelCable();
    widget.session.begin(_game.planDay());
    context.go(AppRoutes.run);
  }

  /// Ujung tarikan tempat tooltip menempel: jari, atau rumah/junction yang
  /// ditempeli.
  Offset _tip(CableDraft draft) =>
      draft.handle ??
      (draft.target != null
          ? _game.positionOf(draft.target!)
          : draft.points.last);

  @override
  Widget build(BuildContext context) {
    final level = _game.level;
    final draft = _game.draft;
    final cost = _game.draftCost;
    final connected = _game.connectedCount;
    final refused = _game.refusedCost;
    return Scaffold(
      backgroundColor: AppColors.groundDay,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenGutter),
              child: LevelHeaderCard(
                overline: 'LEVEL ${level.number}',
                title: level.name,
                onBack: () => context.go(AppRoutes.levelMap),
                stats: [
                  HeaderStat(
                    label: 'Sisa anggaran',
                    value: IdFormat.rupiah(_game.budget),
                    note: draft == null
                        ? null
                        : '${IdFormat.rupiah(-cost)} sedang ditarik',
                    noteColor: AppColors.warningStrong,
                  ),
                  HeaderStat(
                    label: 'Target kepuasan',
                    value: '≥ ${IdFormat.percent(level.targetSatisfaction)}',
                    note:
                        'Jam sibuk '
                        '${IdFormat.hourRange(level.rushHourFrom!, level.rushHourTo!)}',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NetworkGameView(
                      state: _game,
                      interactive: true,
                      semanticLabel:
                          'Peta ${level.name}: router pusat, '
                          '$connected rumah tersambung, '
                          '${level.houses.length - connected} belum',
                      overlays: [
                        if (draft != null)
                          Positioned.fill(
                            child: CustomSingleChildLayout(
                              delegate: _TooltipLayout(_tip(draft)),
                              child: _CostTooltip(
                                color: MapRenderer.cableColor(
                                  draft.kind,
                                  MapTheme.day,
                                ),
                                label:
                                    '${draft.segments} segmen · '
                                    '${IdFormat.rupiah(cost)}',
                                overBudget: _game.draftOverBudget,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_game.erasing || refused != null)
                    Positioned(
                      left: AppSpacing.screenGutter,
                      right: AppSpacing.screenGutter,
                      top: 0,
                      child: _game.erasing
                          ? const _MapBanner.erase()
                          : _MapBanner.budget(
                              cost: refused!,
                              budget: _game.budget,
                            ),
                    ),
                ],
              ),
            ),
            BottomPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          'Pilih kabel',
                          style: AppTypography.bodyStrong,
                        ),
                      ),
                      Text(
                        '$connected/${level.houses.length} '
                        'rumah tersambung',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final spec in level.unlockedCables) ...[
                          if (spec.kind == CableKind.fiber)
                            const SizedBox(width: AppSpacing.cardGap),
                          Expanded(
                            child: CableOptionCard(
                              kind: spec.kind,
                              name: spec.name,
                              price:
                                  '${IdFormat.rupiah(spec.pricePerSegment)} '
                                  '/ segmen',
                              capacity:
                                  'Kapasitas ${spec.capacityMbps} Mbps · '
                                  '${spec.tagline}',
                              selected: _game.selectedCable == spec.kind,
                              onPressed: () => _game.selectCable(spec.kind),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EraseToggle(
                        active: _game.erasing,
                        onPressed: () => _game.setErasing(!_game.erasing),
                      ),
                      const SizedBox(width: AppSpacing.s10),
                      Expanded(
                        child: ChunkyButton(
                          label: 'Mulai Hari',
                          leadingIcon: GameIcons.play,
                          onPressed: _startDay,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Letak tooltip biaya: di atas-kiri ujung tarikan seperti desain (jari
/// (255, 360) → tooltip (222, 288)), dijepit di dalam lebar peta; pindah ke
/// bawah lingkaran jari bila tidak muat di atas.
class _TooltipLayout extends SingleChildLayoutDelegate {
  const _TooltipLayout(this.tip);

  final Offset tip;

  /// Koordinat desain: tooltip relatif ke ujung tarikan.
  static const _above = Offset(-33, -72);
  static const _below = MapRenderer.dragHandleRadius + AppSpacing.s10;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final room = size.width - childSize.width;
    final x = (tip.dx + _above.dx).clamp(0.0, room < 0 ? 0.0 : room);
    final above = tip.dy + _above.dy;
    return Offset(x, above >= 0 ? above : tip.dy + _below);
  }

  @override
  bool shouldRelayout(_TooltipLayout oldDelegate) => tip != oldDelegate.tip;
}

class _CostTooltip extends StatelessWidget {
  const _CostTooltip({
    required this.color,
    required this.label,
    this.overBudget = false,
  });

  final Color color;
  final String label;

  /// Biaya melebihi sisa anggaran: tooltip merah.
  final bool overBudget;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: overBudget ? AppColors.statusJamDark : AppColors.ink,
          borderRadius: AppRadius.pillAll,
          boxShadow: AppElevation.tooltip,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.pillAll,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AppTypography.captionStrong.copyWith(
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner di atas peta: mode hapus (desain), atau kabel ditolak karena
/// anggaran kurang (copy baru; desain belum punya keadaan ini).
class _MapBanner extends StatelessWidget {
  const _MapBanner.erase()
    : icon = GameIcons.eraser,
      text = 'Mode hapus: ketuk kabel buat dibongkar. Uangnya balik 50%.',
      background = AppColors.warningBg,
      border = AppColors.primary,
      foreground = AppColors.warningText;

  _MapBanner.budget({required int cost, required int budget})
    : icon = GameIcons.warning,
      text =
          'Anggaran kurang: kabel ini ${IdFormat.rupiah(cost)}, '
          'sisa ${IdFormat.rupiah(budget)}.',
      background = AppColors.dangerBg,
      border = AppColors.statusJam,
      foreground = AppColors.dangerText;

  final GameIconData icon;
  final String text;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s14,
          vertical: AppSpacing.s10,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.bubbleAll,
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          children: [
            GameIcon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodySmallStrong.copyWith(
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EraseToggle extends StatelessWidget {
  const _EraseToggle({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      toggled: active,
      label: 'Hapus',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 96,
          height: AppSizes.buttonLarge,
          decoration: BoxDecoration(
            color: active ? AppColors.warningBg : AppColors.surface,
            borderRadius: AppRadius.buttonAll,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.surfaceLine,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GameIcon(GameIcons.eraser),
              const SizedBox(height: AppSpacing.s2),
              Text('Hapus', style: AppTypography.captionStrong),
            ],
          ),
        ),
      ),
    );
  }
}
