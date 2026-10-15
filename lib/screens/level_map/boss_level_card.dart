import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Kartu level 12 (bos) – terkunci.
class BossLevelCard extends StatelessWidget {
  const BossLevelCard({super.key});

  static const _ball = GameIconData([
    IconShape.circle(
      Offset(24, 24),
      20,
      mode: IconPaintMode.fill,
      role: IconColorRole.secondary,
    ),
    IconShape.path(
      'M24 15 L32 21 L29 31 H19 L16 21 Z',
      mode: IconPaintMode.fill,
    ),
    IconShape.path(
      'M24 15 V5 M32 21 L42 17 M29 31 L35 40 M19 31 L13 40 M16 21 L6 17',
    ),
    IconShape.circle(Offset(24, 24), 20),
  ], viewBox: 48);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: false,
      label: 'Level 12, level bos Malam Final Sepak Bola, terkunci',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        decoration: BoxDecoration(
          color: AppColors.surfaceNightDeep,
          borderRadius: AppRadius.heroAll,
          border: Border.all(color: AppColors.primary, width: 3),
          boxShadow: AppElevation.solid(
            AppColors.primaryShadow,
            AppElevation.chunkyLarge,
          ),
        ),
        margin: const EdgeInsets.only(bottom: AppElevation.chunkyLarge),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              width: 120,
              height: 128,
              child: CustomPaint(
                painter: SketchPainter(
                  (canvas) {
                    for (final (x, y, r) in const [
                      (92.0, 22.0, 3.0),
                      (106.0, 34.0, 2.5),
                      (78.0, 40.0, 2.0),
                      (102.0, 104.0, 2.5),
                      (86.0, 96.0, 2.0),
                    ]) {
                      SvgDraw.circle(
                        canvas,
                        Offset(x, y),
                        r,
                        fill: AppColors.traffic,
                      );
                    }
                  },
                  designSize: const Size(120, 128),
                  id: 'twinkle',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s18 - 3,
                vertical: AppSpacing.s16 - 3,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSizes.bossTile,
                    height: AppSizes.bossTile,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceNightTile,
                            borderRadius: AppRadius.panelAll,
                          ),
                          alignment: Alignment.center,
                          child: const GameIcon(
                            _ball,
                            size: 48,
                            color: AppColors.ink,
                            secondaryColor: AppColors.inkOnDark,
                          ),
                        ),
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Container(
                            width: AppSizes.chip,
                            height: AppSizes.chip,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surfaceNightDeep,
                                width: 3,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const GameIcon(
                              GameIcons.lock,
                              size: 14,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LEVEL 12 · BOS',
                          style: AppTypography.label.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Malam Final Sepak Bola',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.inkOnDark,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Satu kompleks nobar. Butuh 24 bintang.',
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.inkOnDarkMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
