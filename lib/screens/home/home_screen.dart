import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/progress_book.dart';
import '../../app/routes.dart';
import '../../game/levels/levels.dart';
import '../../game/model/level_def.dart';
import '../../game/progress/progress.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'home_painters.dart';

/// 1 · Beranda, dengan bintang & progres babak dari [progress].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.progress});

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
      backgroundColor: AppColors.groundNight,
      body: NightScope(
        child: Stack(
          children: [
            const Positioned.fill(child: HomeBackdrop()),
            SafeArea(
              child: FillScrollView(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StarCounterPill(
                            value: p.totalStars,
                            total: chapter.starsTotal,
                            tone: CounterTone.night,
                          ),
                          CircleIconButton(
                            icon: GameIcons.settings,
                            semanticLabel: 'Pengaturan',
                            onPressed: () => context.go(AppRoutes.settings),
                            background: AppColors.surfaceNightRaised,
                            borderColor: AppColors.surfaceNightRaisedLine,
                            iconColor: AppColors.inkOnDarkSoft,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 5),
                    const _Hero(),
                    const Spacer(flex: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s24,
                        AppSpacing.s24,
                        AppSpacing.s24,
                        AppSpacing.s40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ChunkyButton(
                            label: 'Main',
                            size: ChunkySize.hero,
                            leadingIcon: GameIcons.play,
                            onPressed: () => context.go(AppRoutes.levelMap),
                          ),
                          const SizedBox(
                            height: AppSpacing.s18 - AppElevation.chunkyLarge,
                          ),
                          _ChapterCard(chapter: chapter, progress: p),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Column(
        children: [
          const HomeLogoTile(),
          const SizedBox(height: AppSpacing.s18),
          Semantics(
            header: true,
            label: 'Jaringan Sibuk',
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  Text(
                    'Jaringan',
                    style: AppTypography.display.copyWith(
                      color: AppColors.inkOnDark,
                    ),
                  ),
                  Text(
                    'Sibuk',
                    style: AppTypography.display.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Tarik kabel, jaga sinyal, tenangkan satu kompleks.',
              textAlign: TextAlign.center,
              style: AppTypography.lead.copyWith(
                color: AppColors.inkOnDarkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.progress});

  final ChapterDef chapter;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final done = progress.levelsDone(chapter.levelCount);
    return AppCard(
      tone: CardTone.night,
      radius: AppRadius.button,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s18,
        vertical: AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BABAK ${chapter.number}',
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.inkOnDarkMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(chapter.name, style: AppTypography.bodyLarge),
                  ],
                ),
              ),
              Text(
                '$done / ${chapter.levelCount} level',
                style: AppTypography.body.copyWith(
                  color: AppColors.inkOnDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          ProgressBar(
            value: done / chapter.levelCount,
            trackColor: AppColors.surfaceNightLine,
            semanticLabel: 'Progres babak',
          ),
        ],
      ),
    );
  }
}
