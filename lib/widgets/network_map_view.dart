import 'package:flutter/widgets.dart';

import '../game/map_scene.dart';
import '../game/render/map_renderer.dart';
import 'design_stage.dart';

/// Peta jaringan statis: menggambar [MapScene] lewat [MapRenderer] dan
/// menskalakannya ke ruang yang tersedia. [overlays] diletakkan dengan
/// koordinat desain peta (Positioned di atas 390×472).
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
            child: CustomPaint(painter: NetworkMapPainter(scene)),
          ),
          ...overlays,
        ],
      ),
    );
  }
}

class NetworkMapPainter extends CustomPainter {
  const NetworkMapPainter(this.scene, {this.phase = 0});

  final MapScene scene;

  /// Fase animasi trafik (px). Statis = 0; game loop nanti menggesernya.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / scene.size.width,
      size.height / scene.size.height,
    );
    MapRenderer.drawScene(canvas, scene, phase: phase);
    canvas.restore();
  }

  @override
  bool shouldRepaint(NetworkMapPainter old) =>
      old.scene != scene || old.phase != phase;
}
