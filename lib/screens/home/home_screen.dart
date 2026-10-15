import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../data/dummy_data.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'home_painters.dart';

/// 1 · Beranda.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const chapter = DummyData.chapter;
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
                            value: chapter.starsEarned,
                            total: chapter.starsTotal,
                            tone: CounterTone.night,
                          ),
                          CircleIconButton(
                            icon: GameIcons.settings,
                            semanticLabel: 'Pengaturan',
                            // Asumsi: pengaturan belum didesain → sementara
                            // membuka galeri komponen.
                            onPressed: () => context.go(AppRoutes.gallery),
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
                          const _ChapterCard(chapter: chapter),
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
  const _ChapterCard({required this.chapter});

  final ChapterInfo chapter;

  @override
  Widget build(BuildContext context) {
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
                '${chapter.levelsDone} / ${chapter.levelsTotal} level',
                style: AppTypography.body.copyWith(
                  color: AppColors.inkOnDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          ProgressBar(
            value: chapter.progress,
            trackColor: AppColors.surfaceNightLine,
            semanticLabel: 'Progres babak',
          ),
        ],
      ),
    );
  }
}
