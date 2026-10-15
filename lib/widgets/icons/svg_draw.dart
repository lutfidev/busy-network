import 'package:flutter/rendering.dart';

import '../../game/render/map_renderer.dart';
import 'svg_path.dart';

/// Helper kecil untuk ilustrasi layar yang disalin dari SVG desain.
abstract final class SvgDraw {
  static final Map<String, Path> _cache = {};

  static Path path(String d) => _cache.putIfAbsent(d, () => parseSvgPath(d));

  static void stroke(
    Canvas canvas,
    String d,
    Color color,
    double width, {
    List<double>? dash,
    double opacity = 1,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withValues(alpha: color.a * opacity)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (dash == null) {
      canvas.drawPath(path(d), paint);
    } else {
      MapRenderer.drawDashedPath(canvas, path(d), paint, dash[0], dash[1]);
    }
  }

  static void fill(Canvas canvas, String d, Color color) {
    canvas.drawPath(path(d), Paint()..color = color);
  }

  static void circle(
    Canvas canvas,
    Offset c,
    double r, {
    Color? fill,
    Color? stroke,
    double strokeWidth = 3,
    List<double>? dash,
  }) {
    if (fill != null) canvas.drawCircle(c, r, Paint()..color = fill);
    if (stroke != null) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = stroke
        ..strokeWidth = strokeWidth;
      if (dash == null) {
        canvas.drawCircle(c, r, paint);
      } else {
        MapRenderer.drawDashedPath(
          canvas,
          Path()..addOval(Rect.fromCircle(center: c, radius: r)),
          paint,
          dash[0],
          dash[1],
        );
      }
    }
  }

  static void rrect(
    Canvas canvas,
    Rect rect,
    double radius, {
    Color? fill,
    Color? stroke,
    double strokeWidth = 3,
  }) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    if (fill != null) canvas.drawRRect(rr, Paint()..color = fill);
    if (stroke != null) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  /// Titik trafik sepanjang path SVG.
  static void traffic(
    Canvas canvas,
    String d,
    Color color, {
    double gap = 18,
    double width = 4,
    bool glow = true,
  }) {
    final p = path(d);
    final dots = <Offset>[];
    for (final m in p.computeMetrics()) {
      for (var t = 0.0; t <= m.length; t += gap) {
        final tan = m.getTangentForOffset(t);
        if (tan != null) dots.add(tan.position);
      }
    }
    if (glow) {
      final blur = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      for (final o in dots) {
        canvas.drawCircle(o, width / 2, blur);
      }
    }
    final sharp = Paint()..color = color;
    for (final o in dots) {
      canvas.drawCircle(o, width / 2, sharp);
    }
  }
}

/// Painter dari closure, untuk ilustrasi statis berkoordinat desain.
class SketchPainter extends CustomPainter {
  const SketchPainter(this.draw, {required this.designSize, this.id = ''});

  final void Function(Canvas canvas) draw;

  /// Ukuran viewBox asli; kanvas diskalakan seragam ke ukuran widget.
  final Size designSize;
  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / designSize.width,
      size.height / designSize.height,
    );
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SketchPainter old) =>
      old.id != id || old.designSize != designSize;
}
