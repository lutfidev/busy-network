import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/progress_book.dart';
import '../../app/routes.dart';
import '../../core/format.dart';
import '../../game/result/level_result.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'churn_illustration.dart';
import 'fail_cause.dart';

/// 8 · Hasil Level – Gagal.
class ResultFailScreen extends StatelessWidget {
  const ResultFailScreen({
    super.key,
    required this.result,
    required this.progress,
  });

  final LevelResult result;

  /// Menentukan level 1 dibuka di tutorial atau Fase Rancang.
  final ProgressBook progress;

  @override
  Widget build(BuildContext context) {
    final level = result.level;
    return Scaffold(
      backgroundColor: AppColors.groundNight,
      body: NightScope(
        child: SafeArea(
          child: FillScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.s48),
                Text(
                  'LEVEL ${level.number} · ${level.name.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: AppTypography.captionStrong.copyWith(
                    color: AppColors.inkOnDarkMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                const ChurnIllustration(),
                const SizedBox(height: AppSpacing.s6),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s24,
                  ),
                  child: Column(
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Pelanggan pada kabur ke tetangga...',
                          textAlign: TextAlign.center,
                          style: AppTypography.h2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Kepuasan cuma '
                        '${IdFormat.percent(result.satisfaction)}, '
                        'targetnya ${IdFormat.percent(level.targetSatisfaction)}. '
                        'Nggak apa, besok coba lagi.',
                        textAlign: TextAlign.center,
                        style: AppTypography.paragraph.copyWith(
                          color: AppColors.inkOnDarkMuted,
                          height: null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenGutter,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, label, value, color) in [
                                (
                                  0,
                                  'Kepuasan',
                                  IdFormat.percent(result.satisfaction),
                                  AppColors.dangerOnDark,
                                ),
                                (1, 'Komplain', '${result.complaints}', null),
                                (
                                  2,
                                  'Pindah',
                                  '${result.housesLost} rumah',
                                  null,
                                ),
                              ]) ...[
                                if (i > 0) const SizedBox(width: AppSpacing.s8),
                                Expanded(
                                  child: StatTile(
                                    label: label,
                                    value: value,
                                    tone: CardTone.night,
                                    centered: true,
                                    valueStyle: AppTypography.titleLarge,
                                    valueColor: color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (result.culprit case final culprit?) ...[
                          const SizedBox(height: AppSpacing.s20),
                          _CauseCard(cause: failCause(culprit)),
                        ],
                        const Spacer(),
                        const SizedBox(height: AppSpacing.s20),
                        ChunkyButton(
                          label: 'Coba Lagi',
                          leadingIcon: GameIcons.retry,
                          height: AppSizes.buttonTall,
                          onPressed: () => context.go(
                            AppRoutes.play(
                              level.number,
                              tutorialDone: progress.progress.tutorialDone,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: AppSpacing.s8 - AppElevation.chunky,
                        ),
                        TextLinkButton(
                          label: 'Balik ke peta',
                          height: AppSizes.textButton,
                          color: AppColors.inkOnDarkSoft,
                          style: AppTypography.bodyStrong,
                          onPressed: () => context.go(AppRoutes.levelMap),
                        ),
                        const SizedBox(height: AppSpacing.s14),
                      ],
                    ),
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

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause});

  final FailCause cause;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.buttonAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.dangerSoftBg,
              borderRadius: AppRadius.iconTileAll,
            ),
            alignment: Alignment.center,
            child: const GameIcon(
              GameIcons.warning,
              size: AppSizes.iconLg,
              color: AppColors.statusJamDark,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIANG KEROKNYA',
                  style: AppTypography.label.copyWith(
                    color: AppColors.dangerText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  cause.title,
                  style: AppTypography.emphasis.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  cause.hint,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
