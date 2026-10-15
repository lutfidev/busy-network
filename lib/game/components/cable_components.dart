import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import '../../theme/theme.dart';
import '../map_scene.dart';
import '../network_game.dart';
import '../render/map_renderer.dart';

/// Satu kabel (terpasang, ditarik, atau kelebihan beban) di koordinat peta.
/// Kabel terpasang bisa diketuk (mode Hapus = bongkar).
class CableComponent extends Component
    with HasGameReference<NetworkGame>, TapCallbacks {
  CableComponent(this.cable);

  MapCable cable;

  @override
  bool containsLocalPoint(Vector2 point) {
    if (cable.id == null) return false;
    final p = point.toOffset();
    final points = cable.points;
    for (var i = 1; i < points.length; i++) {
      if (_distanceToSegment(p, points[i - 1], points[i]) <=
          AppSizes.cableTouchSlop) {
        return true;
      }
    }
    return false;
  }

  @override
  void onTapUp(TapUpEvent event) => game.tapCable(cable.id!);

  @override
  void render(Canvas canvas) {
    MapRenderer.drawCable(
      canvas,
      cable,
      game.scene.theme,
      alarmOpacity: game.motion.alarmOpacity,
      marchPhase: game.motion.marchPhase,
    );
  }
}

double _distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final lengthSquared = ab.distanceSquared;
  if (lengthSquared == 0) return (p - a).distance;
  final ap = p - a;
  final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared).clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

/// Titik trafik yang mengalir di atas satu kabel (lapisan di atas semua
/// kabel), digerakkan `NetworkGame.motion`.
class TrafficComponent extends Component with HasGameReference<NetworkGame> {
  TrafficComponent(this.cable);

  MapCable cable;

  @override
  void render(Canvas canvas) {
    MapRenderer.drawCableTraffic(
      canvas,
      cable,
      game.scene.theme,
      motion: game.motion,
    );
  }
}
