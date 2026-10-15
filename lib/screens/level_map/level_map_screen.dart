import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../data/dummy_data.dart';
import '../../game/levels/levels.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'boss_level_card.dart';
import 'level_map_layout.dart';
import 'level_map_painter.dart';

/// 2 · Peta Babak 1 – Perumahan Batam.
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  void _open(BuildContext context, int level) {
    // Level 1 = tutorial; level lain memakai layar rancang Gang Melati
    // (data dummy) sampai data level asli tersedia.
    context.go(level == 1 ? AppRoutes.tutorial : AppRoutes.design);
  }

  @override
  Widget build(BuildContext context) {
    const chapter = DummyData.chapter;
    return Scaffold(
      backgroundColor: AppColors.groundMap,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s20,
                AppSpacing.s20,
                0,
              ),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: GameIcons.back,
                    semanticLabel: 'Kembali ke Beranda',
                    onPressed: () => context.go(AppRoutes.home),
                    borderColor: AppColors.surfaceLine,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BABAK ${chapter.number}',
                          style: AppTypography.captionStrong.copyWith(
                            color: AppColors.inkMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(chapter.name, style: AppTypography.titleLarge),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  StarCounterPill(
                    value: chapter.starsEarned,
                    total: chapter.starsTotal,
                  ),
                ],
              ),
            ),
            Expanded(
              child: DesignStage(
                size: LevelMapLayout.size,
                alignment: Alignment.topCenter,
                children: [
                  const Positioned.fill(child: LevelMapBackdrop()),
                  for (final e in LevelMapLayout.entries) ..._entry(context, e),
                  _at(
                    LevelMapLayout.currentChipTopLeft,
                    SizedBox(
                      width: LevelMapLayout.currentChipWidth,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s10,
                            vertical: AppSpacing.s4,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: AppRadius.pillAll,
                          ),
                          child: Text(
                            Levels.level5.name,
                            style: AppTypography.captionStrong.copyWith(
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s4,
                AppSpacing.s20,
                AppSpacing.s24 - AppElevation.chunkyLarge,
              ),
              child: BossLevelCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _at(Offset designTopLeft, Widget child) {
    final p = designTopLeft - LevelMapLayout.origin;
    return Positioned(left: p.dx, top: p.dy, child: child);
  }

  List<Widget> _entry(BuildContext context, LevelMapEntry e) {
    final current = e.state == LevelNodeState.current;
    final locked = e.state == LevelNodeState.locked;
    final node = LevelNode(
      number: e.number,
      state: e.state,
      onPressed: () => _open(context, e.number),
      semanticLabel: switch (e.state) {
        LevelNodeState.locked => 'Level ${e.number} terkunci',
        LevelNodeState.current =>
          'Level ${e.number}, ${Levels.level5.name}, main sekarang',
        LevelNodeState.done =>
          'Level ${e.number}, ${e.stars} bintang'
              '${e.number == 1 ? ', tutorial' : ''}',
      },
    );
    return [
      if (current) _at(e.topLeft, const IgnorePointer(child: _PulseRing())),
      _at(e.topLeft, node),
      if (e.labelTopLeft != null)
        _at(
          e.labelTopLeft!,
          ExcludeSemantics(
            child: locked
                ? SizedBox(
                    width: e.labelBeside ? null : AppSizes.levelNode,
                    child: Text(
                      '${e.number}',
                      textAlign: e.labelBeside
                          ? TextAlign.left
                          : TextAlign.center,
                      style: AppTypography.captionStrong.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  )
                : SizedBox(
                    width: AppSizes.levelNode,
                    child: Center(child: StarRating(earned: e.stars)),
                  ),
          ),
        ),
    ];
  }
}

/// Cincin di sekitar level aktif: membesar 1→1,55 sambil memudar tiap
/// 1,8 s. Diam di [AppMotion.ringStill] bila animasi dimatikan.
class _PulseRing extends StatelessWidget {
  const _PulseRing();

  @override
  Widget build(BuildContext context) {
    return LoopClock(
      still: AppMotion.ringStill,
      builder: (context, clock) => ValueListenableBuilder<double>(
        valueListenable: clock,
        builder: (context, seconds, ring) {
          final t = Keyframes.loop(seconds, AppMotion.ringPulse);
          return Transform.scale(
            scale: AppMotion.ringScale.at(t),
            child: Opacity(opacity: AppMotion.ringOpacity.at(t), child: ring),
          );
        },
        child: Container(
          width: AppSizes.levelNodeCurrent,
          height: AppSizes.levelNodeCurrent,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: AppSizes.levelNodeBorder,
            ),
          ),
        ),
      ),
    );
  }
}
