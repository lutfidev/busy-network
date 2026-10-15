import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../../theme/theme.dart';
import '../map_scene.dart';
import '../network_game.dart';
import '../render/map_renderer.dart';

/// Node peta (router, rumah, junction) yang berpusat di `node.position`
/// (koordinat peta 390×472). Ukurannya = bidang sentuh node; label, bar
/// sabar, dan cincin boleh tergambar di luarnya.
///
/// Digambar lewat [MapRenderer] dengan pusat di tengah komponen.
sealed class MapNodeComponent extends PositionComponent
    with HasGameReference<NetworkGame> {
  MapNodeComponent(MapNode node, {required double extent})
    : _node = node,
      super(
        position: node.position.toVector2(),
        size: Vector2.all(extent),
        anchor: Anchor.center,
      );

  factory MapNodeComponent.of(MapNode node) => switch (node.kind) {
    NodeKind.router => RouterComponent(node),
    NodeKind.house => HouseComponent(node),
    NodeKind.junction => JunctionComponent(node),
  };

  MapNode _node;
  MapNode get node => _node;
  set node(MapNode value) {
    _node = value;
    position.setValues(value.position.dx, value.position.dy);
  }

  /// Pusat node di koordinat lokal komponen.
  Offset get localCenter => (size / 2).toOffset();
}

class RouterComponent extends MapNodeComponent {
  RouterComponent(super.node) : super(extent: AppSizes.routerSize);

  @override
  void render(Canvas canvas) {
    final theme = game.scene.theme;
    MapRenderer.drawRouter(
      canvas,
      localCenter,
      theme,
      alarm: node.routerAlarm,
      alarmOpacity: game.motion.alarmOpacity,
    );
    MapRenderer.drawNodeLabel(canvas, node, theme, center: localCenter);
  }
}

class HouseComponent extends MapNodeComponent {
  HouseComponent(super.node) : super(extent: AppSizes.houseRadius * 2);

  @override
  void render(Canvas canvas) {
    MapRenderer.drawHouse(
      canvas,
      node,
      game.scene.theme,
      center: localCenter,
      snapColor: game.snapColor,
      alarmOpacity: game.motion.alarmOpacity,
    );
  }
}

class JunctionComponent extends MapNodeComponent {
  JunctionComponent(super.node) : super(extent: MapRenderer.junctionRadius * 2);

  @override
  void render(Canvas canvas) {
    MapRenderer.drawJunction(canvas, localCenter, game.scene.theme);
  }
}
