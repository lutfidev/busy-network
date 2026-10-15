import 'dart:ui';

import 'package:flame/components.dart';

import '../map_scene.dart';
import '../network_game.dart';
import '../render/map_renderer.dart';

/// Satu kabel (terpasang, ditarik, atau kelebihan beban) di koordinat peta.
class CableComponent extends Component with HasGameReference<NetworkGame> {
  CableComponent(this.cable);

  MapCable cable;

  @override
  void render(Canvas canvas) {
    MapRenderer.drawCable(
      canvas,
      cable,
      game.scene.theme,
      alarmOpacity: game.motion.alarmOpacity,
    );
  }
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
