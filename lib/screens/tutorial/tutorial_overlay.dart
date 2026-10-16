import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'tutorial_steps.dart';

/// Scrim gelap dengan lubang sorotan + garis putih 3 px. Sentuhan di luar
/// lubang ditahan; di dalam lubang diteruskan ke yang disorot.
class SpotlightScrim extends StatelessWidget {
  const SpotlightScrim({super.key, required this.spot, required this.radius});

  final Rect spot;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Rect?>(
      tween: RectTween(end: spot),
      duration: AppMotion.spotlight,
      curve: Curves.ease,
      builder: (context, rect, _) => CustomPaint(
        size: Size.infinite,
        painter: _ScrimPainter(rect ?? spot, radius),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.spot, this.radius);

  final Rect spot;
  final double radius;

  RRect get _hole => RRect.fromRectAndRadius(
    spot,
    Radius.circular(radius.clamp(0, spot.shortestSide / 2)),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final hole = _hole;
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

  /// `true` = sentuhan ditahan scrim.
  @override
  bool hitTest(Offset position) => !_hole.contains(position);

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

enum HandMotion {
  /// Mengangguk di tempat (menunjuk sesuatu).
  bob,

  /// Menyeret dari router ke Rumah 1.
  drag,
}

/// Tangan penunjuk yang bergerak (diam bila animasi dimatikan).
class TutorialHand extends StatelessWidget {
  const TutorialHand({super.key, this.motion = HandMotion.bob, this.scale = 1});

  final HandMotion motion;

  /// Skala peta di layar: jarak gerak dari desain ikut diskalakan.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final drag = motion == HandMotion.drag;
    return IgnorePointer(
      child: LoopClock(
        key: ValueKey(motion),
        still: drag ? AppMotion.handDragStill : Duration.zero,
        builder: (context, clock) => ValueListenableBuilder<double>(
          valueListenable: clock,
          builder: (context, seconds, hand) =>
              drag ? _drag(seconds, hand!) : _bob(seconds, hand!),
          child: const GameIcon(
            GameIcons.hand,
            size: AppSizes.handPointer,
            color: AppColors.ink,
            secondaryColor: AppColors.surface,
          ),
        ),
      ),
    );
  }

  Widget _bob(double seconds, Widget hand) {
    final t = Keyframes.loop(seconds, AppMotion.handBob);
    return Transform.translate(
      offset: AppMotion.handBobOffset * AppMotion.handBobAmount.at(t) * scale,
      child: hand,
    );
  }

  Widget _drag(double seconds, Widget hand) {
    final t = Keyframes.loop(seconds, AppMotion.handDrag);
    return Opacity(
      opacity: AppMotion.handDragOpacity.at(t),
      child: Transform.translate(
        offset:
            AppMotion.handDragOffset * AppMotion.handDragAmount.at(t) * scale,
        child: hand,
      ),
    );
  }
}
