import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import '../../theme/theme.dart';
import '../map_scene.dart';
import '../network_game.dart';
import '../render/map_renderer.dart';

/// Node peta (router, rumah, junction). Seperti kabel, digambar dan diuji
/// sentuh langsung di koordinat peta (390×472), jadi [MapRenderer] dipanggil
/// apa adanya dan hasilnya sama persis dengan `drawScene`.
///
/// Tarikan kabel dimulai dengan menyeret node; `NetworkGame` yang
/// meneruskannya ke `GameState`.
sealed class MapNodeComponent extends Component
    with HasGameReference<NetworkGame>, DragCallbacks {
  MapNodeComponent(this.node, {required double radius})
    : hitRadius = math.max(radius, AppSizes.mapTouchRadius);

  factory MapNodeComponent.of(MapNode node) => switch (node.kind) {
    NodeKind.router => RouterComponent(node),
    NodeKind.house => HouseComponent(node),
    NodeKind.junction => JunctionComponent(node),
  };

  MapNode node;

  /// Jari-jari bidang sentuh di sekitar `node.position`: sebesar gambarnya,
  /// minimal [AppSizes.mapTouchRadius].
  final double hitRadius;

  @override
  bool containsLocalPoint(Vector2 point) =>
      (point.toOffset() - node.position).distance <= hitRadius;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.startPull(node.id, event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) => game.movePull(event);

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.endPull(event.pointerId);
  }

  /// Batal dulu: bawaan mixin meneruskan batal sebagai [onDragEnd], yang
  /// akan memasang kabel bila sedang menempel.
  @override
  void onDragCancel(DragCancelEvent event) {
    game.cancelPull(event.pointerId);
    super.onDragCancel(event);
  }
}

class RouterComponent extends MapNodeComponent {
  RouterComponent(super.node) : super(radius: AppSizes.routerSize / 2);

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
  HouseComponent(super.node) : super(radius: AppSizes.houseRadius);

  @override
  void render(Canvas canvas) {
    MapRenderer.drawHouse(
      canvas,
      node,
      game.scene.theme,
      snapColor: game.snapColor,
      alarmOpacity: game.motion.alarmOpacity,
      snapOpacity: game.motion.snapOpacity,
    );
  }
}

class JunctionComponent extends MapNodeComponent {
  JunctionComponent(super.node) : super(radius: MapRenderer.junctionRadius);

  @override
  void render(Canvas canvas) {
    MapRenderer.drawJunction(canvas, node.position, game.scene.theme);
  }
}
