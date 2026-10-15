import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../theme/theme.dart';
import '../../widgets/icons/svg_path.dart';
import '../map_scene.dart';
import 'map_motion.dart';

/// Primitif gambar peta jaringan, murni di atas [Canvas].
///
/// Dipakai `NetworkMapPainter` (Flutter) sekarang, dan bisa dipanggil dari
/// `render(Canvas)` komponen Flame nanti tanpa perubahan.
abstract final class MapRenderer {
  // ── Ukuran dari desain ────────────────────────────────────────────────
  static const double lanWidth = 7;
  static const double fiberWidth = 9;
  static const double trafficWidth = 5;
  static const double houseStroke = 3;
  static const double glyphStroke = 2.4;
  static const double patienceWidth = 40;
  static const double patienceHeight = 6;
  static const double junctionRadius = 6;
  static const double dotRadiusDay = 1.6;
  static const double dotRadiusNight = 1.5;
  static const double glowSigma = 2.4;

  static final Path _houseGlyph = parseSvgPath(
    'M-8 1 L0 -7 L8 1 M-5.5 -1 V8 H5.5 V-1',
  );

  // ── Latar ─────────────────────────────────────────────────────────────
  static void drawDotGrid(Canvas canvas, Size size, MapTheme theme) {
    final paint = Paint()
      ..color = theme == MapTheme.day
          ? AppColors.groundDayDot
          : AppColors.groundNightDot;
    final r = theme == MapTheme.day ? dotRadiusDay : dotRadiusNight;
    const cell = AppSpacing.mapCell;
    for (var y = cell / 2; y < size.height; y += cell) {
      for (var x = cell / 2; x < size.width; x += cell) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  static void drawBlockLabel(
    Canvas canvas,
    MapBlockLabel label,
    MapTheme theme,
  ) {
    drawText(
      canvas,
      label.text,
      label.position,
      AppTypography.mapBlock.copyWith(
        color: theme == MapTheme.day
            ? AppColors.blockLabel
            : AppColors.blockLabelNight,
      ),
      align: label.align,
    );
  }

  // ── Kabel ─────────────────────────────────────────────────────────────
  static Path polyline(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  static Color cableColor(CableKind kind, MapTheme theme) {
    if (kind == CableKind.fiber) return AppColors.cableFiber;
    return theme == MapTheme.day ? AppColors.cableLan : AppColors.cableLanNight;
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static void drawCable(Canvas canvas, MapCable cable, MapTheme theme) {
    final path = polyline(cable.points);
    final width = cable.kind == CableKind.fiber || cable.thick
        ? fiberWidth
        : lanWidth;
    final color = cableColor(cable.kind, theme);
    switch (cable.state) {
      case CableState.normal:
        canvas.drawPath(path, _stroke(color, width));
      case CableState.drafting:
        drawDashedPath(canvas, path, _stroke(color, lanWidth), 10, 8);
      case CableState.overloaded:
        canvas.drawPath(path, _stroke(color, width));
        canvas.drawPath(path, _stroke(AppColors.statusJam, width));
    }
  }

  /// Titik trafik: `stroke-dasharray="0 gap"` dengan ujung bulat →
  /// lingkaran berdiameter [trafficWidth] tiap [gap] px.
  static void drawTraffic(
    Canvas canvas,
    List<Offset> points, {
    required Color color,
    double gap = AppMotion.trafficGap,
    double phase = 0,
    bool glow = true,
  }) {
    final path = polyline(points);
    final dots = <Offset>[];
    for (final metric in path.computeMetrics()) {
      var d = phase % gap;
      while (d <= metric.length) {
        final t = metric.getTangentForOffset(d);
        if (t != null) dots.add(t.position);
        d += gap;
      }
    }
    if (glow) {
      final blur = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, glowSigma);
      for (final p in dots) {
        canvas.drawCircle(p, trafficWidth / 2, blur);
      }
    }
    final sharp = Paint()..color = color;
    for (final p in dots) {
      canvas.drawCircle(p, trafficWidth / 2, sharp);
    }
  }

  static void drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dash,
    double gap,
  ) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = math.min(d + dash, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  static void _dashedCircle(
    Canvas canvas,
    Offset c,
    double r,
    Paint paint,
    double dash,
    double gap,
  ) {
    drawDashedPath(
      canvas,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      paint,
      dash,
      gap,
    );
  }

  // ── Node ──────────────────────────────────────────────────────────────
  static void drawJunction(Canvas canvas, Offset c, MapTheme theme) {
    final day = theme == MapTheme.day;
    canvas.drawCircle(
      c,
      junctionRadius,
      Paint()..color = day ? AppColors.surface : AppColors.groundNight,
    );
    canvas.drawCircle(
      c,
      junctionRadius,
      _stroke(day ? AppColors.ink : AppColors.inkOnDark, houseStroke),
    );
  }

  static Color houseFill(HouseState state) => switch (state) {
    HouseState.idle => AppColors.groundDay,
    HouseState.connected => AppColors.surface,
    HouseState.ok => AppColors.statusOk,
    HouseState.slow => AppColors.statusSlow,
    HouseState.jam => AppColors.statusJam,
  };

  static void drawHouse(
    Canvas canvas,
    MapNode node,
    MapTheme theme, {
    Color? snapColor,
  }) {
    final c = node.position;
    final day = theme == MapTheme.day;
    final r = AppSizes.houseRadius;

    if (node.snapTarget) {
      _dashedCircle(
        canvas,
        c,
        30,
        _stroke(snapColor ?? AppColors.cableLan, houseStroke),
        4,
        5,
      );
    }
    if (node.alarm) {
      canvas.drawCircle(
        c,
        30,
        Paint()..color = AppColors.statusJam.withValues(alpha: 0.25),
      );
    }

    final idle = node.state == HouseState.idle;
    final strokeColor = idle
        ? AppColors.houseIdle
        : (day ? AppColors.ink : AppColors.groundNight);
    canvas.drawCircle(c, r, Paint()..color = houseFill(node.state));
    final ring = _stroke(strokeColor, houseStroke);
    if (idle) {
      _dashedCircle(canvas, c, r, ring, 5, 4);
    } else {
      canvas.drawCircle(c, r, ring);
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawPath(_houseGlyph, _stroke(strokeColor, glyphStroke));
    canvas.restore();

    if (node.patience != null) {
      final origin = c + _patienceOffset(node.patiencePlacement);
      drawPatienceBar(
        canvas,
        origin,
        node.patience!,
        houseFill(node.state),
        day ? AppColors.track : AppColors.surfaceNightLine,
      );
    }
    _drawNodeLabel(canvas, node, theme);
  }

  static Offset _patienceOffset(PatiencePlacement p) => switch (p) {
    PatiencePlacement.below => const Offset(-20, 27),
    PatiencePlacement.right => const Offset(28, -3),
    PatiencePlacement.above => const Offset(-20, -40),
  };

  static void drawPatienceBar(
    Canvas canvas,
    Offset topLeft,
    double value,
    Color fill,
    Color track,
  ) {
    const radius = Radius.circular(patienceHeight / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        topLeft & const Size(patienceWidth, patienceHeight),
        radius,
      ),
      Paint()..color = track,
    );
    final w = (patienceWidth * value.clamp(0, 1)).clamp(
      patienceHeight,
      patienceWidth,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topLeft & Size(w, patienceHeight), radius),
      Paint()..color = fill,
    );
  }

  static void drawRouter(
    Canvas canvas,
    Offset c,
    MapTheme theme, {
    bool alarm = false,
  }) {
    final day = theme == MapTheme.day;
    final body = day ? AppColors.ink : AppColors.inkOnDark;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final antenna = _stroke(body, 4);
    canvas.drawLine(const Offset(-10, -24), const Offset(-14, -34), antenna);
    canvas.drawLine(const Offset(10, -24), const Offset(14, -34), antenna);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-24, -24, 48, 48),
        const Radius.circular(14),
      ),
      Paint()..color = body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -10, 24, 6),
        const Radius.circular(3),
      ),
      Paint()
        ..color = day ? AppColors.routerScreen : AppColors.routerScreenLight,
    );
    final leds = [
      day ? AppColors.traffic : AppColors.trafficDay,
      AppColors.statusOk,
      alarm ? AppColors.statusJam : AppColors.primary,
    ];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(-9.0 + 9 * i, 7), 3, Paint()..color = leds[i]);
    }
    canvas.restore();
  }

  static void _drawNodeLabel(Canvas canvas, MapNode node, MapTheme theme) {
    final label = node.label;
    if (label == null) return;
    final day = theme == MapTheme.day;
    final Offset offset;
    if (node.labelOffset != null) {
      offset = node.labelOffset!;
    } else if (node.kind == NodeKind.router) {
      offset = const Offset(0, 42);
    } else if (node.patience != null) {
      offset = switch (node.patiencePlacement) {
        PatiencePlacement.below => const Offset(0, 48),
        PatiencePlacement.right => const Offset(28, 18),
        PatiencePlacement.above => const Offset(0, -48),
      };
    } else {
      offset = Offset(0, node.snapTarget ? 46 : 38);
    }
    final Color color;
    if (node.labelEmphasis) {
      color = AppColors.dangerOnDark;
    } else if (node.kind == NodeKind.router) {
      color = day ? AppColors.ink : AppColors.inkOnDarkMuted;
    } else {
      color = day ? AppColors.inkMuted : AppColors.inkOnDarkMuted;
    }
    final style = (day ? AppTypography.mapLabel : AppTypography.micro).copyWith(
      color: color,
    );
    drawText(
      canvas,
      label,
      node.position + offset,
      style,
      align: node.labelAlign,
    );
  }

  static void drawBadge(Canvas canvas, MapBadge badge) {
    final rect = Rect.fromLTWH(
      badge.center.dx - badge.width / 2,
      badge.center.dy - 13,
      badge.width,
      24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = AppColors.statusJamDark,
    );
    drawText(
      canvas,
      badge.text,
      badge.center + const Offset(0, 4),
      AppTypography.mapLabel.copyWith(color: AppColors.surface),
    );
  }

  static void drawDragHandle(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      26,
      Paint()..color = AppColors.ink.withValues(alpha: 0.10),
    );
    canvas.drawCircle(c, 26, _stroke(AppColors.ink.withValues(alpha: 0.3), 2));
    canvas.drawCircle(c, 9, Paint()..color = AppColors.ink);
  }

  /// Teks dengan [baseline] di titik [anchor] (seperti `<text x y>` SVG).
  static void drawText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    TextAlign align = TextAlign.center,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final dx = switch (align) {
      TextAlign.center => anchor.dx - tp.width / 2,
      TextAlign.right || TextAlign.end => anchor.dx - tp.width,
      _ => anchor.dx,
    };
    tp.paint(canvas, Offset(dx, anchor.dy - baseline));
    tp.dispose();
  }

  // ── Scene ─────────────────────────────────────────────────────────────
  static void drawScene(
    Canvas canvas,
    MapScene scene, {
    MapMotion motion = MapMotion.still,
  }) {
    final theme = scene.theme;
    drawDotGrid(canvas, scene.size, theme);
    for (final label in scene.blockLabels) {
      drawBlockLabel(canvas, label, theme);
    }
    for (final cable in scene.cables) {
      drawCable(canvas, cable, theme);
    }
    for (final cable in scene.cables) {
      if (cable.traffic == TrafficState.none) continue;
      drawTraffic(
        canvas,
        cable.points,
        color: theme == MapTheme.day ? AppColors.trafficMap : AppColors.traffic,
        gap: cable.state == CableState.overloaded
            ? AppMotion.trafficJamGap
            : AppMotion.trafficGap,
        phase: cable.traffic == TrafficState.jam
            ? motion.jamPhase
            : motion.flowPhase,
      );
    }
    final drafting = scene.cables
        .where((c) => c.state == CableState.drafting)
        .map((c) => cableColor(c.kind, theme))
        .firstOrNull;
    for (final node in scene.nodes) {
      switch (node.kind) {
        case NodeKind.junction:
          drawJunction(canvas, node.position, theme);
        case NodeKind.router:
          drawRouter(canvas, node.position, theme, alarm: node.routerAlarm);
          _drawNodeLabel(canvas, node, theme);
        case NodeKind.house:
          drawHouse(canvas, node, theme, snapColor: drafting);
      }
    }
    for (final badge in scene.badges) {
      drawBadge(canvas, badge);
    }
    if (scene.dragHandle != null) drawDragHandle(canvas, scene.dragHandle!);
  }
}
