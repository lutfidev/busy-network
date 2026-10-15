import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../../theme/theme.dart';
import '../map_scene.dart';
import '../network_game.dart';
import '../render/map_renderer.dart';

/// Node peta (router, rumah, junction). Seperti kabel, digambar dan diuji
/// sentuh langsung di koordinat peta (390×472), jadi [MapRenderer] dipanggil
/// apa adanya dan hasilnya sama persis dengan `drawScene`.
sealed class MapNodeComponent extends Component
    with HasGameReference<NetworkGame> {
  MapNodeComponent(this.node, {required this.hitRadius});

  factory MapNodeComponent.of(MapNode node) => switch (node.kind) {
    NodeKind.router => RouterComponent(node),
    NodeKind.house => HouseComponent(node),
    NodeKind.junction => JunctionComponent(node),
  };

  MapNode node;

  /// Jari-jari bidang sentuh di sekitar `node.position` (untuk tarik kabel).
  final double hitRadius;

  @override
  bool containsLocalPoint(Vector2 point) =>
      (point.toOffset() - node.position).distance <= hitRadius;
}

class RouterComponent extends MapNodeComponent {
  RouterComponent(super.node) : super(hitRadius: AppSizes.routerSize / 2);

  @override
  void render(Canvas canvas) {
    final theme = game.scene.theme;
    MapRenderer.drawRouter(
      canvas,
      node.position,
      theme,
      alarm: node.routerAlarm,
      alarmOpacity: game.motion.alarmOpacity,
    );
    MapRenderer.drawNodeLabel(canvas, node, theme);
  }
}

class HouseComponent extends MapNodeComponent {
  HouseComponent(super.node) : super(hitRadius: AppSizes.houseRadius);

  @override
  void render(Canvas canvas) {
    MapRenderer.drawHouse(
      canvas,
      node,
      game.scene.theme,
      snapColor: game.snapColor,
      alarmOpacity: game.motion.alarmOpacity,
    );
  }
}

class JunctionComponent extends MapNodeComponent {
  JunctionComponent(super.node) : super(hitRadius: MapRenderer.junctionRadius);

  @override
  void render(Canvas canvas) {
    MapRenderer.drawJunction(canvas, node.position, game.scene.theme);
  }
}
