import 'dart:ui';

import 'package:flame/components.dart';

import '../map_scene.dart';
import '../render/map_renderer.dart';

/// Lencana di atas peta (mis. "Penuh! 25/20").
class BadgeComponent extends Component {
  BadgeComponent(this.badge);

  MapBadge badge;

  @override
  void render(Canvas canvas) => MapRenderer.drawBadge(canvas, badge);
}

/// Lingkaran jari di ujung kabel yang sedang ditarik.
class DragHandleComponent extends Component {
  DragHandleComponent(this.center);

  Offset center;

  @override
  void render(Canvas canvas) => MapRenderer.drawDragHandle(canvas, center);
}
