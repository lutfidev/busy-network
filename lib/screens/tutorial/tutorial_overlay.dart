import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'tutorial_steps.dart';

/// Scrim gelap dengan lubang sorotan + garis putih 3 px.
class SpotlightScrim extends StatelessWidget {
  const SpotlightScrim({super.key, required this.spot, required this.radius});

  final Rect spot;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<Rect?>(
        tween: RectTween(end: spot),
        duration: AppMotion.spotlight,
        curve: Curves.ease,
        builder: (context, rect, _) => CustomPaint(
          size: Size.infinite,
          painter: _ScrimPainter(rect ?? spot, radius),
        ),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.spot, this.radius);

  final Rect spot;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(radius.clamp(0, spot.shortestSide / 2));
    final hole = RRect.fromRectAndRadius(spot, r);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(path, Paint()..color = AppColors.scrim);
    canvas.drawRRect(
      hole.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.surface,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.spot != spot || old.radius != radius;
}

/// Kartu dialog tutorial.
class TutorialCard extends StatelessWidget {
  const TutorialCard({
    super.key,
    required this.stepIndex,
    required this.onNext,
    required this.onSkip,
  });

  /// 0-based.
  final int stepIndex;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final step = TutorialSteps.steps[stepIndex];
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: 'Tutorial',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s18,
          vertical: AppSpacing.s16,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.panelAll,
          boxShadow: AppElevation.dialog,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TUTORIAL · ${stepIndex + 1} DARI ${TutorialSteps.count}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primaryShadow,
                    ),
                  ),
                ),
                TextLinkButton(
                  label: 'Lewati',
                  onPressed: onSkip,
                  underline: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s10),
            Text(step.title, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.s10),
            Text(
              step.body,
              style: AppTypography.paragraph.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            if (step.nextLabel != null) ...[
              const SizedBox(height: AppSpacing.s10),
              Align(
                alignment: Alignment.centerRight,
                child: ChunkyButton(
                  label: step.nextLabel!,
                  variant: ChunkyVariant.dark,
                  size: ChunkySize.small,
                  textStyle: AppTypography.buttonCompact,
                  onPressed: onNext,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tangan penunjuk.
class TutorialHand extends StatelessWidget {
  const TutorialHand({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: GameIcon(
        GameIcons.hand,
        size: AppSizes.handPointer,
        color: AppColors.ink,
        secondaryColor: AppColors.surface,
      ),
    );
  }
}
