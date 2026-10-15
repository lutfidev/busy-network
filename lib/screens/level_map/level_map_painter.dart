import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'level_map_layout.dart';

/// Blok rumah + jalur antar-level di Peta Babak.
class LevelMapBackdrop extends StatelessWidget {
  const LevelMapBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        painter: SketchPainter(
          _draw,
          designSize: LevelMapLayout.size,
          id: 'level-map',
        ),
      ),
    );
  }

  static void _draw(Canvas canvas) {
    canvas.translate(-LevelMapLayout.origin.dx, -LevelMapLayout.origin.dy);
    for (final r in const [
      Rect.fromLTWH(16, 112, 110, 46),
      Rect.fromLTWH(140, 112, 110, 46),
      Rect.fromLTWH(264, 112, 110, 46),
      Rect.fromLTWH(16, 246, 358, 40),
      Rect.fromLTWH(16, 386, 358, 40),
      Rect.fromLTWH(16, 526, 358, 40),
    ]) {
      SvgDraw.rrect(canvas, r, 14, fill: AppColors.mapBlock);
    }
    SvgDraw.stroke(
      canvas,
      'M195 330 H75 V470 H315 V610 H75 V700',
      AppColors.mapPathLocked,
      8,
      dash: const [2, 14],
    );
    const done = 'M75 190 H315 V330 H195';
    SvgDraw.stroke(canvas, done, AppColors.primary, 9);
    SvgDraw.traffic(canvas, done, AppColors.trafficMap, width: 5);
    SvgDraw.circle(
      canvas,
      const Offset(195, 610),
      7,
      fill: AppColors.groundMap,
      stroke: AppColors.mapPathLocked,
      strokeWidth: 4,
    );
  }
}
