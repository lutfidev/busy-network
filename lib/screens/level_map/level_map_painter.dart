import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'level_map_layout.dart';

/// Blok rumah + jalur antar-level di Peta Babak: oranye sampai level
/// [current], putus-putus sesudahnya.
class LevelMapBackdrop extends StatelessWidget {
  const LevelMapBackdrop({super.key, required this.current});

  /// Level sekarang (`Progress.current`).
  final int current;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        painter: SketchPainter(
          _draw,
          designSize: LevelMapLayout.size,
          id: 'level-map-$current',
        ),
      ),
    );
  }

  void _draw(Canvas canvas) {
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
    final paths = LevelMapLayout.paths(current);
    SvgDraw.stroke(
      canvas,
      _svg(paths.locked),
      AppColors.mapPathLocked,
      8,
      dash: const [2, 14],
    );
    if (paths.done.length >= 2) {
      final done = _svg(paths.done);
      SvgDraw.stroke(canvas, done, AppColors.primary, 9);
      SvgDraw.traffic(canvas, done, AppColors.trafficMap, width: 5);
    }
    SvgDraw.circle(
      canvas,
      const Offset(195, 610),
      7,
      fill: AppColors.groundMap,
      stroke: AppColors.mapPathLocked,
      strokeWidth: 4,
    );
  }

  /// Path SVG garis lurus melewati [points].
  static String _svg(List<Offset> points) => [
    for (final (i, p) in points.indexed)
      '${i == 0 ? 'M' : 'L'}${_n(p.dx)} ${_n(p.dy)}',
  ].join(' ');

  static String _n(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}
