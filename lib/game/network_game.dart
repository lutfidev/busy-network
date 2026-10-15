import 'package:flame/components.dart';
import 'package:flame/game.dart' hide RouterComponent;
import 'package:flutter/painting.dart';

import '../theme/theme.dart';
import 'components/components.dart';
import 'map_scene.dart';
import 'model/model.dart';
import 'render/map_motion.dart';
import 'render/map_renderer.dart';
import 'scene_builder.dart';

/// Peta jaringan sebagai game Flame. Menggambar [state] (lewat
/// [SceneBuilder]) dengan satu komponen per bagian scene; tiap komponen
/// memanggil [MapRenderer], jadi gambarnya sama dengan
/// [MapRenderer.drawScene].
///
/// Kamera beresolusi tetap 390×472 (koordinat desain) dengan (0, 0) di kiri
/// atas, diskalakan seragam ke ukuran widget.
///
/// Mesin hanya jalan bila ada yang bergerak (trafik, alarm) dan [animate]
/// aktif. Selain itu tiap perubahan digambar satu bingkai lalu mesin
/// berhenti sendiri, jadi `pumpAndSettle` di test tidak macet.
class NetworkGame extends FlameGame {
  NetworkGame({required this._state, this._animate = true})
    : super(
        camera: CameraComponent.withFixedResolution(
          width: AppSizes.mapArea.width,
          height: AppSizes.mapArea.height,
        ),
      ) {
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GroundComponent()..priority = _Layer.ground);
  }

  GameState _state;
  bool _animate;
  bool _listening = false;

  late MapScene _scene;
  Color? _snapColor;
  double _seconds = 0;
  MapMotion _motion = MapMotion.still;

  final _cables = <CableComponent>[];
  final _traffic = <TrafficComponent>[];
  final _nodes = <String, MapNodeComponent>{};
  final _badges = <BadgeComponent>[];
  final _handles = <DragHandleComponent>[];

  GameState get state => _state;
  set state(GameState value) {
    if (identical(value, _state)) return;
    if (_listening) {
      _state.removeListener(_onStateChanged);
      value.addListener(_onStateChanged);
    }
    _state = value;
    _onStateChanged();
  }

  /// `false` = diam di pose [MapMotion.still] (setelan "hapus animasi").
  bool get animate => _animate;
  set animate(bool value) {
    if (value == _animate) return;
    _animate = value;
    _invalidate();
  }

  /// Scene yang sedang digambar (ada sejak game terpasang).
  MapScene get scene => _scene;

  /// Warna cincin snap rumah target (warna kabel yang sedang ditarik).
  Color? get snapColor => _snapColor;

  /// Detik animasi berjalan; 0 saat diam.
  double get seconds => _seconds;

  /// Pose animasi bingkai ini.
  MapMotion get motion => _motion;

  bool get _moving => _animate && _scene.hasMotion;

  @override
  Color backgroundColor() => AppColors.transparent;

  /// Scene pertama diturunkan di sini (bukan di konstruktor): state bisa
  /// berubah selama game belum terpasang.
  @override
  void onMount() {
    super.onMount();
    _listening = true;
    _state.addListener(_onStateChanged);
    _onStateChanged();
  }

  @override
  void onRemove() {
    _state.removeListener(_onStateChanged);
    _listening = false;
    super.onRemove();
  }

  /// Label digambar `TextPainter` di dalam game: begitu font selesai
  /// dimuat, gambar ulang (seperti `RenderParagraph`).
  @override
  void onAttach() {
    super.onAttach();
    PaintingBinding.instance.systemFonts.addListener(_invalidate);
  }

  @override
  void onDetach() {
    PaintingBinding.instance.systemFonts.removeListener(_invalidate);
    super.onDetach();
  }

  @override
  void update(double dt) {
    final moving = _moving;
    _seconds = moving ? _seconds + dt : 0;
    _motion = moving ? MapMotion.at(_seconds) : MapMotion.still;
    super.update(dt);
    if (!moving) pauseEngine();
  }

  /// Minta satu bingkai baru; [update] menghentikan mesin lagi bila diam.
  void _invalidate() {
    if (paused) resumeEngine();
  }

  void _onStateChanged() => _show(SceneBuilder.fromState(_state));

  void _show(MapScene scene) {
    _scene = scene;
    _snapColor = MapRenderer.snapColor(scene);
    _syncList(
      _cables,
      scene.cables,
      _Layer.cables,
      CableComponent.new,
      (piece, cable) => piece.cable = cable,
    );
    _syncList(
      _traffic,
      [
        for (final c in scene.cables)
          if (c.traffic != TrafficState.none) c,
      ],
      _Layer.traffic,
      TrafficComponent.new,
      (piece, cable) => piece.cable = cable,
    );
    _syncNodes(scene.nodes);
    _syncList(
      _badges,
      scene.badges,
      _Layer.badges,
      BadgeComponent.new,
      (piece, badge) => piece.badge = badge,
    );
    _syncList(
      _handles,
      [?scene.dragHandle],
      _Layer.dragHandle,
      DragHandleComponent.new,
      (piece, center) => piece.center = center,
    );
    _invalidate();
  }

  /// Samakan [pieces] dengan [items] menurut urutan: komponen yang ada
  /// dipakai ulang (datanya diganti), kekurangannya dibuat, kelebihannya
  /// dibuang. Prioritas = lapisan + urutan, sama dengan `drawScene`.
  void _syncList<T, C extends Component>(
    List<C> pieces,
    List<T> items,
    int layer,
    C Function(T item) create,
    void Function(C piece, T item) assign,
  ) {
    for (var i = 0; i < items.length; i++) {
      if (i < pieces.length) {
        assign(pieces[i], items[i]);
      } else {
        pieces.add(create(items[i]));
        world.add(pieces[i]);
      }
      pieces[i].priority = layer + i;
    }
    while (pieces.length > items.length) {
      pieces.removeLast().removeFromParent();
    }
  }

  /// Node dipasangkan menurut id, supaya komponen rumah/router/junction
  /// tetap sama selama level (penting untuk tarik kabel).
  void _syncNodes(List<MapNode> nodes) {
    final ids = <String>{};
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      ids.add(node.id);
      var piece = _nodes[node.id];
      if (piece != null && piece.node.kind == node.kind) {
        piece.node = node;
      } else {
        piece?.removeFromParent();
        piece = _nodes[node.id] = MapNodeComponent.of(node);
        world.add(piece);
      }
      piece.priority = _Layer.nodes + i;
    }
    _nodes.removeWhere((id, piece) {
      if (ids.contains(id)) return false;
      piece.removeFromParent();
      return true;
    });
  }
}

/// Prioritas lapisan peta, urutan [MapRenderer.drawScene]. Bagian dalam satu
/// lapisan mendapat tambahan sesuai urutannya di scene.
abstract final class _Layer {
  static const ground = 0;
  static const cables = 1000;
  static const traffic = 2000;
  static const nodes = 3000;
  static const badges = 4000;
  static const dragHandle = 5000;
}
