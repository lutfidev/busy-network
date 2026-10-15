import 'package:flutter/widgets.dart';

import '../../game/map_scene.dart';
import '../../game/render/map_renderer.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Ilustrasi: rumah pindah dari router kamu ke "Net tetangga" (390×250).
class ChurnIllustration extends StatelessWidget {
  const ChurnIllustration({super.key});

  static const _size = Size(390, 250);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Ilustrasi: rumah-rumah pelanggan pindah dari router kamu ke '
          'RT/RW Net tetangga',
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: _size.aspectRatio,
        child: CustomPaint(
          painter: SketchPainter(_draw, designSize: _size, id: 'churn'),
        ),
      ),
    );
  }

  static void _draw(Canvas canvas) {
    SvgDraw.stroke(
      canvas,
      'M80 130 V60 M80 130 H40 M80 130 V200',
      AppColors.nightDead,
      7,
      dash: const [2, 12],
    );
    const theirs = 'M310 130 V70 M310 130 H350 M310 130 V196';
    SvgDraw.stroke(canvas, theirs, AppColors.primary, 7);
    SvgDraw.traffic(canvas, theirs, AppColors.traffic);
    for (final y in const [92.0, 168.0]) {
      SvgDraw.stroke(
        canvas,
        'M140 $y H232',
        AppColors.blockLabelNight,
        3,
        dash: const [6, 8],
      );
      SvgDraw.stroke(
        canvas,
        'M224 ${y - 8} L234 $y L224 ${y + 8}',
        AppColors.blockLabelNight,
        3,
      );
    }

    // Router kamu: mati.
    canvas.save();
    canvas.translate(80, 130);
    SvgDraw.rrect(
      canvas,
      const Rect.fromLTWH(-24, -24, 48, 48),
      14,
      fill: AppColors.nightDead,
    );
    SvgDraw.rrect(
      canvas,
      const Rect.fromLTWH(-12, -10, 24, 6),
      3,
      fill: AppColors.surfaceNightLine,
    );
    SvgDraw.circle(
      canvas,
      const Offset(-9, 7),
      3,
      fill: AppColors.surfaceNightLine,
    );
    SvgDraw.circle(
      canvas,
      const Offset(0, 7),
      3,
      fill: AppColors.surfaceNightLine,
    );
    SvgDraw.circle(canvas, const Offset(9, 7), 3, fill: AppColors.statusJam);
    SvgDraw.fill(canvas, 'M22 -30 q4 6 0 9 q-4 -3 0 -9z', AppColors.traffic);
    canvas.restore();
    for (final c in const [Offset(80, 60), Offset(40, 130), Offset(80, 200)]) {
      SvgDraw.circle(
        canvas,
        c,
        12,
        stroke: AppColors.nightDead,
        dash: const [4, 4],
      );
    }

    // Rumah yang pindah.
    for (final (y, color) in const [
      (92.0, AppColors.statusSlow),
      (168.0, AppColors.statusJam),
    ]) {
      SvgDraw.circle(
        canvas,
        Offset(186, y),
        16,
        fill: color,
        stroke: AppColors.groundNight,
      );
      SvgDraw.stroke(
        canvas,
        'M180 ${y + 0.5} L186 ${y - 5} L192 ${y + 0.5} '
        'M182 ${y - 1} V${y + 6} H190 V${y - 1}',
        AppColors.groundNight,
        2,
      );
      SvgDraw.stroke(
        canvas,
        'M160 ${y - 6} H166 M156 ${y + 2} H164 M160 ${y + 10} H166',
        AppColors.inkOnDarkMuted,
        2.4,
      );
    }

    // Router tetangga.
    MapRenderer.drawRouter(canvas, const Offset(310, 130), MapTheme.night);
    for (final c in const [
      Offset(310, 60),
      Offset(358, 130),
      Offset(310, 206),
    ]) {
      SvgDraw.circle(
        canvas,
        c,
        12,
        fill: AppColors.statusOk,
        stroke: AppColors.groundNight,
      );
    }

    MapRenderer.drawText(
      canvas,
      'Punyamu',
      const Offset(80, 238),
      AppTypography.mapLabel.copyWith(color: AppColors.nightCaption),
    );
    MapRenderer.drawText(
      canvas,
      'Net tetangga',
      const Offset(310, 238),
      AppTypography.mapLabel.copyWith(color: AppColors.primary),
    );
  }
}
