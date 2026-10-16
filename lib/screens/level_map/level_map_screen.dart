import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/progress_book.dart';
import '../../app/routes.dart';
import '../../game/levels/levels.dart';
import '../../game/progress/progress.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'boss_level_card.dart';
import 'level_map_layout.dart';
import 'level_map_painter.dart';

/// 2 · Peta Babak 1 – Perumahan Batam, dari progres pemain.
///
/// Level yang belum punya data (langkah 8) tampil sesuai progres tapi tidak
/// bisa diketuk.
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key, required this.progress});

  final ProgressBook progress;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) => _build(context, progress.progress),
    );
  }

  Widget _build(BuildContext context, Progress p) {
    const chapter = Levels.chapter;
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
                    value: p.totalStars,
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
                  Positioned.fill(child: LevelMapBackdrop(current: p.current)),
                  for (final slot in LevelMapLayout.slots)
                    ..._entry(context, slot, p),
                  if (LevelMapLayout.slotOf(p.current) case final slot?)
                    if (Levels.byNumber(p.current) case final level?)
                      _at(LevelMapLayout.chipTopLeft(slot), _chip(level.name)),
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

  /// Chip nama di atas level sekarang.
  Widget _chip(String name) {
    return SizedBox(
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
            name,
            style: AppTypography.captionStrong.copyWith(
              color: AppColors.surface,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _entry(BuildContext context, LevelSlot slot, Progress p) {
    final n = slot.number;
    final state = LevelMapLayout.stateOf(p, n);
    final level = Levels.byNumber(n);
    final current = state == LevelNodeState.current;
    final locked = state == LevelNodeState.locked;
    final topLeft = LevelMapLayout.nodeTopLeft(slot, state);
    final node = LevelNode(
      number: n,
      state: state,
      onPressed: locked || level == null
          ? null
          : () => context.go(AppRoutes.play(n, tutorialDone: p.tutorialDone)),
      semanticLabel: switch (state) {
        LevelNodeState.locked => 'Level $n terkunci',
        LevelNodeState.current when level != null =>
          'Level $n, ${level.name}, main sekarang',
        LevelNodeState.current => 'Level $n, belum tersedia',
        LevelNodeState.done =>
          'Level $n, ${p.starsOf(n)} bintang'
              '${n == 1 && !p.tutorialDone ? ', tutorial' : ''}',
      },
    );
    return [
      if (current) _at(topLeft, const IgnorePointer(child: _PulseRing())),
      _at(topLeft, node),
      _at(
        LevelMapLayout.labelTopLeft(slot, state),
        ExcludeSemantics(
          child: locked
              ? SizedBox(
                  width: slot.labelBeside ? null : AppSizes.levelNode,
                  child: Text(
                    '$n',
                    textAlign: slot.labelBeside
                        ? TextAlign.left
                        : TextAlign.center,
                    style: AppTypography.captionStrong.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                )
              : SizedBox(
                  width: AppSizes.levelNode,
                  child: Center(child: StarRating(earned: p.starsOf(n))),
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
