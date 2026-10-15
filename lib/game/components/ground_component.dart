import 'dart:ui';

import 'package:flame/components.dart';

import '../network_game.dart';
import '../render/map_renderer.dart';

/// Lapisan paling bawah: titik grid dan label blok.
class GroundComponent extends Component with HasGameReference<NetworkGame> {
  @override
  void render(Canvas canvas) => MapRenderer.drawGround(canvas, game.scene);
}
