import 'package:flutter/widgets.dart';

import '../game/map_scene.dart';
import '../game/render/map_renderer.dart';
import '../theme/theme.dart';

/// Rumah tunggal (untuk galeri / legenda), digambar dengan [MapRenderer].
class HouseGlyph extends StatelessWidget {
  const HouseGlyph({
    super.key,
    required this.state,
    this.patience,
    this.label,
    this.alarm = false,
    this.theme = MapTheme.day,
  });

  final HouseState state;
  final double? patience;
  final String? label;
  final bool alarm;
  final MapTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 120,
      child: CustomPaint(
        painter: _GlyphPainter((canvas, _) {
          MapRenderer.drawHouse(
            canvas,
            MapNode(
              id: 'glyph',
              kind: NodeKind.house,
              position: const Offset(36, 44),
              state: state,
              patience: patience,
              alarm: alarm,
              label: label,
              labelOffset: const Offset(0, 56),
            ),
            theme,
          );
        }, '$state$patience$label$alarm$theme'),
      ),
    );
  }
}

/// Router pusat tunggal.
class RouterGlyph extends StatelessWidget {
  const RouterGlyph({
    super.key,
    this.theme = MapTheme.day,
    this.alarm = false,
    this.label,
  });

  final MapTheme theme;
  final bool alarm;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 120,
      child: CustomPaint(
        painter: _GlyphPainter((canvas, _) {
          const c = Offset(36, 44);
          MapRenderer.drawRouter(canvas, c, theme, alarm: alarm);
          if (label != null) {
            MapRenderer.drawText(
              canvas,
              label!,
              c + const Offset(0, 56),
              AppTypography.micro.copyWith(color: AppColors.inkMuted),
            );
          }
        }, '$theme$alarm$label'),
      ),
    );
  }
}

/// Contoh kabel + trafik di atas latar malam (seperti lembar token).
class CableSample extends StatelessWidget {
  const CableSample({super.key});

  static const _size = Size(300, 168);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Contoh kabel LAN, fiber, trafik, dan kabel kelebihan beban',
      image: true,
      child: AspectRatio(
        aspectRatio: _size.width / _size.height,
        child: CustomPaint(
          painter: _GlyphPainter((canvas, size) {
            canvas.scale(size.width / _size.width);
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Offset.zero & _size,
                const Radius.circular(AppRadius.card),
              ),
              Paint()..color = AppColors.groundNight,
            );
            const lan = [
              Offset(24, 34),
              Offset(150, 34),
              Offset(180, 64),
              Offset(276, 64),
            ];
            const fiber = [Offset(24, 84), Offset(276, 84)];
            const jam = [Offset(24, 134), Offset(276, 134)];
            MapRenderer.drawCable(
              canvas,
              const MapCable(points: lan),
              MapTheme.night,
            );
            MapRenderer.drawCable(
              canvas,
              const MapCable(points: fiber, kind: CableKind.fiber),
              MapTheme.night,
            );
            MapRenderer.drawTraffic(
              canvas,
              fiber,
              color: AppColors.traffic,
              glow: false,
            );
            MapRenderer.drawCable(
              canvas,
              const MapCable(
                points: jam,
                state: CableState.overloaded,
                thick: true,
              ),
              MapTheme.night,
            );
            MapRenderer.drawTraffic(
              canvas,
              jam,
              color: AppColors.traffic,
              gap: AppMotion.trafficJamGap,
              glow: false,
            );
            final style = AppTypography.micro.copyWith(
              color: AppColors.inkOnDarkMuted,
            );
            for (final (text, y) in [
              ('LAN · 7 px · 20 Mbps', 22.0),
              ('Fiber · 9 px · 100 Mbps + trafik', 108.0),
              ('Kelebihan beban', 158.0),
            ]) {
              MapRenderer.drawText(
                canvas,
                text,
                Offset(24, y),
                style,
                align: TextAlign.left,
              );
            }
          }, 'cable-sample'),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.draw, this.key);

  final void Function(Canvas canvas, Size size) draw;
  final String key;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size);

  @override
  bool shouldRepaint(_GlyphPainter old) => old.key != key;
}
