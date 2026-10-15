import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Latar peta kota malam di Beranda (koordinat kanvas 390×844).
class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          child: SizedBox.fromSize(
            size: AppSizes.designCanvas,
            child: CustomPaint(
              painter: SketchPainter(
                _draw,
                designSize: AppSizes.designCanvas,
                id: 'home',
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _draw(Canvas canvas) {
    SvgDraw.stroke(
      canvas,
      'M-20 130 H420 M-20 300 H420 M-20 470 H420 M-20 640 H420 M-20 810 H420 '
      'M40 -20 V900 M195 -20 V900 M350 -20 V900',
      AppColors.nightRoad,
      16,
    );
    for (final d in const [
      'M40 60 V130 L95 185 H195',
      'M350 40 V130 H260 L195 195 V300',
      'M195 470 L120 545 H40 V700',
      'M350 300 V470',
      'M195 640 V760 L250 815 H420',
      'M40 760 H120 L170 810',
    ]) {
      SvgDraw.stroke(canvas, d, AppColors.nightCableIdle, 4);
    }
    const fiberA = 'M-20 300 H120 L195 375 V470 H350 L405 525';
    SvgDraw.stroke(canvas, fiberA, AppColors.primary, 5, opacity: 0.8);
    SvgDraw.stroke(canvas, 'M195 470 V640', AppColors.primary, 5, opacity: 0.8);
    for (final d in const [
      fiberA,
      'M195 470 V640 V760 L250 815 H420',
      'M350 40 V130 H260 L195 195 V300',
      'M195 470 L120 545 H40 V700',
      'M40 60 V130 L95 185 H195',
    ]) {
      SvgDraw.traffic(canvas, d, AppColors.traffic);
    }
    for (final (c, color) in const [
      (Offset(40, 60), AppColors.statusOk),
      (Offset(350, 40), AppColors.statusOk),
      (Offset(350, 300), AppColors.statusOk),
      (Offset(40, 700), AppColors.statusSlow),
      (Offset(170, 810), AppColors.statusOk),
      (Offset(40, 760), AppColors.statusJam),
    ]) {
      SvgDraw.circle(canvas, c, 8, fill: color, stroke: AppColors.groundNight);
    }
    SvgDraw.rrect(
      canvas,
      const Rect.fromLTWH(183, 458, 24, 24),
      7,
      fill: AppColors.primary,
      stroke: AppColors.groundNight,
    );
  }
}

/// Logo kecil di atas judul (router + 3 pelanggan).
class HomeLogoTile extends StatelessWidget {
  const HomeLogoTile({super.key});

  static const _icon = Size(48, 48);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.logoTile,
      height: AppSizes.logoTile,
      decoration: BoxDecoration(
        color: AppColors.surfaceNightRaised,
        borderRadius: AppRadius.buttonLargeAll,
        border: Border.all(color: AppColors.surfaceNightRaisedLine, width: 2),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: _icon,
        painter: SketchPainter(
          (canvas) {
            SvgDraw.stroke(
              canvas,
              'M24 30 V44 M24 30 L8 14 M24 30 L40 14',
              AppColors.nightCableIdle,
              4,
            );
            SvgDraw.stroke(canvas, 'M24 30 L40 14', AppColors.primary, 4);
            SvgDraw.circle(
              canvas,
              const Offset(8, 14),
              5,
              fill: AppColors.statusOk,
            );
            SvgDraw.circle(
              canvas,
              const Offset(40, 14),
              5,
              fill: AppColors.statusOk,
            );
            SvgDraw.circle(
              canvas,
              const Offset(24, 44),
              4,
              fill: AppColors.star,
            );
            SvgDraw.rrect(
              canvas,
              const Rect.fromLTWH(16, 22, 16, 16),
              5,
              fill: AppColors.primary,
              stroke: AppColors.surfaceNightRaised,
              strokeWidth: 2.5,
            );
          },
          designSize: _icon,
          id: 'logo',
        ),
      ),
    );
  }
}
