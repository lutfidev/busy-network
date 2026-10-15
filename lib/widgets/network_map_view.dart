import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../game/map_scene.dart';
import '../game/render/map_motion.dart';
import '../game/render/map_renderer.dart';
import 'design_stage.dart';
import 'loop_clock.dart';

/// Peta jaringan: menggambar [MapScene] lewat [MapRenderer] dan
/// menskalakannya ke ruang yang tersedia. [overlays] diletakkan dengan
/// koordinat desain peta (Positioned di atas 390×472).
///
/// Trafik bergerak mengikuti [LoopClock] (diam bila animasi dimatikan).
class NetworkMapView extends StatelessWidget {
  const NetworkMapView({
    super.key,
    required this.scene,
    this.overlays = const [],
    this.semanticLabel,
    this.alignment = Alignment.center,
  });

  final MapScene scene;
  final List<Widget> overlays;
  final String? semanticLabel;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: DesignStage(
        size: scene.size,
        alignment: alignment,
        children: [
          Positioned.fill(
            child: LoopClock(
              enabled: scene.hasMotion,
              builder: (context, clock) =>
                  CustomPaint(painter: NetworkMapPainter(scene, clock: clock)),
            ),
          ),
          ...overlays,
        ],
      ),
    );
  }
}

class NetworkMapPainter extends CustomPainter {
  const NetworkMapPainter(this.scene, {this.clock}) : super(repaint: clock);

  final MapScene scene;

  /// Detik animasi dari [LoopClock]; `null` = bingkai statis.
  final ValueListenable<double>? clock;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / scene.size.width,
      size.height / scene.size.height,
    );
    final seconds = clock?.value ?? 0;
    MapRenderer.drawScene(canvas, scene, motion: MapMotion.at(seconds));
    canvas.restore();
  }

  @override
  bool shouldRepaint(NetworkMapPainter old) =>
      old.scene != scene || old.clock != clock;
}
