import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Latar peta kota malam di Beranda (koordinat kanvas 390×844): trafik
/// mengalir, peta bergeser pelan, rumah macet berkedip.
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
            child: LoopClock(
              builder: (context, clock) => CustomPaint(
                painter: SketchPainter(
                  (canvas) => _draw(canvas, clock.value),
                  designSize: AppSizes.designCanvas,
                  id: 'home',
                  repaint: clock,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Trafik maju (px) pada [seconds] untuk siklus [period].
  static double _flow(double seconds, Duration period) =>
      AppMotion.trafficAdvance * Keyframes.loop(seconds, period);

  static void _draw(Canvas canvas, double seconds) {
    final drift =
        AppMotion.homeDriftOffset *
        AppMotion.homeDriftAmount.at(
          Keyframes.alternate(seconds, AppMotion.homeDrift),
        );
    canvas.translate(drift.dx, drift.dy);
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
    final flow = _flow(seconds, AppMotion.homeFlow);
    final slow = _flow(seconds, AppMotion.homeFlowSlow);
    for (final (d, phase) in [
      (fiberA, flow),
      ('M195 470 V640 V760 L250 815 H420', flow),
      ('M350 40 V130 H260 L195 195 V300', slow),
      ('M195 470 L120 545 H40 V700', slow),
      ('M40 60 V130 L95 185 H195', slow),
    ]) {
      SvgDraw.traffic(canvas, d, AppColors.traffic, phase: phase);
    }
    for (final (c, color) in const [
      (Offset(40, 60), AppColors.statusOk),
      (Offset(350, 40), AppColors.statusOk),
      (Offset(350, 300), AppColors.statusOk),
      (Offset(40, 700), AppColors.statusSlow),
      (Offset(170, 810), AppColors.statusOk),
    ]) {
      SvgDraw.circle(canvas, c, 8, fill: color, stroke: AppColors.groundNight);
    }
    // Rumah macet berkedip. Opasitas dipasang ke satu lapis (isi + garis
    // sekaligus, seperti `opacity` CSS); dari warna lapis hanya alfanya
    // yang dipakai.
    const jam = Offset(40, 760);
    final blink = AppMotion.homeBlinkOpacity.at(
      Keyframes.loop(seconds, AppMotion.homeBlink),
    );
    canvas.saveLayer(
      Rect.fromCircle(center: jam, radius: 10),
      Paint()..color = AppColors.statusJam.withValues(alpha: blink),
    );
    SvgDraw.circle(
      canvas,
      jam,
      8,
      fill: AppColors.statusJam,
      stroke: AppColors.groundNight,
    );
    canvas.restore();
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
