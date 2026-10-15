import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format.dart';
import '../../data/dummy_data.dart';
import '../../data/dummy_scenes.dart';
import '../../game/map_scene.dart';
import '../../game/render/map_renderer.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// 4 · Fase Rancang – Level 5 (sedang menarik kabel ke Rumah 5).
class DesignPhaseScreen extends StatefulWidget {
  const DesignPhaseScreen({super.key, this.initialCable = CableKind.lan});

  final CableKind initialCable;

  @override
  State<DesignPhaseScreen> createState() => _DesignPhaseScreenState();
}

class _DesignPhaseScreenState extends State<DesignPhaseScreen> {
  late CableKind _cable = widget.initialCable;
  bool _erase = false;

  CableSpec get _spec =>
      _cable == CableKind.lan ? DummyData.lan : DummyData.fiber;

  int get _draftCost => DummyData.draftingSegments * _spec.pricePerSegment;

  void _pick(CableKind kind) => setState(() {
    _cable = kind;
    _erase = false;
  });

  @override
  Widget build(BuildContext context) {
    const level = DummyData.level5;
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
                    value: IdFormat.rupiah(level.budget),
                    note: '${IdFormat.rupiah(-_draftCost)} sedang ditarik',
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
                    child: NetworkMapView(
                      scene: DummyScenes.design(_cable),
                      semanticLabel:
                          'Peta ${level.name}: router pusat, '
                          '${level.housesConnected} rumah tersambung, '
                          '${level.housesTotal - level.housesConnected} belum',
                      overlays: [
                        Positioned(
                          left: 222,
                          top: 288,
                          child: _CostTooltip(
                            color: MapRenderer.cableColor(_cable, MapTheme.day),
                            label:
                                '${DummyData.draftingSegments} segmen · '
                                '${IdFormat.rupiah(_draftCost)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_erase)
                    const Positioned(
                      left: AppSpacing.screenGutter,
                      right: AppSpacing.screenGutter,
                      top: 0,
                      child: _EraseBanner(),
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
                        '${level.housesConnected}/${level.housesTotal} '
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
                        for (final spec in const [
                          DummyData.lan,
                          DummyData.fiber,
                        ]) ...[
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
                              selected: _cable == spec.kind,
                              onPressed: () => _pick(spec.kind),
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
                        active: _erase,
                        onPressed: () => setState(() => _erase = !_erase),
                      ),
                      const SizedBox(width: AppSpacing.s10),
                      Expanded(
                        child: ChunkyButton(
                          label: 'Mulai Hari',
                          leadingIcon: GameIcons.play,
                          onPressed: () => context.go(AppRoutes.run),
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

class _CostTooltip extends StatelessWidget {
  const _CostTooltip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.ink,
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

class _EraseBanner extends StatelessWidget {
  const _EraseBanner();

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
          color: AppColors.warningBg,
          borderRadius: AppRadius.bubbleAll,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Row(
          children: [
            const GameIcon(
              GameIcons.eraser,
              size: 18,
              color: AppColors.warningText,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                'Mode hapus: ketuk kabel buat dibongkar. Uangnya balik 50%.',
                style: AppTypography.bodySmallStrong.copyWith(
                  color: AppColors.warningText,
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
