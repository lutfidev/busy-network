import 'dart:ui' as ui;

import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/render/map_renderer.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kolom piksel terkiri & terkanan yang tergambar oleh label [node], dalam
/// koordinat peta (kanvas diberi ruang [_pad] di kiri-kanan peta).
const _pad = 120;

Future<(int, int)> _inkColumns(MapNode node) async {
  final width = AppSizes.mapArea.width.toInt() + 2 * _pad;
  final height = AppSizes.mapArea.height.toInt();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..translate(_pad.toDouble(), 0);
  MapRenderer.drawNodeLabel(canvas, node, MapTheme.night);
  final image = await recorder.endRecording().toImage(width, height);
  final rgba = (await image.toByteData())!.buffer.asUint8List();
  var left = width;
  var right = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (rgba[(y * width + x) * 4 + 3] != 0) {
        if (x < left) left = x;
        if (x > right) right = x;
      }
    }
  }
  return (left - _pad, right - _pad);
}

MapNode _jammed(double x) => MapNode(
  id: 'r7',
  kind: NodeKind.house,
  position: Offset(x, 240),
  label: 'Rumah 7 · sabar 44%',
  labelEmphasis: true,
  state: HouseState.jam,
  patience: 0.44,
);

void main() {
  final bounds = MapRenderer.labelBounds;

  testWidgets('label panjang rumah di tepi tetap di dalam peta', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Node paling pinggir yang diizinkan level_def_test: x 30 & 360.
      for (final x in [30.0, 360.0]) {
        final (left, right) = await _inkColumns(_jammed(x));
        // 1 px = tepi antialias.
        expect(left, greaterThanOrEqualTo(bounds.left - 1), reason: '$x');
        expect(right, lessThanOrEqualTo(bounds.right + 1), reason: '$x');
      }
    });
  });

  testWidgets('label yang sudah muat tidak bergeser', (tester) async {
    await tester.runAsync(() async {
      final (left, right) = await _inkColumns(_jammed(195));
      expect((left + right) / 2, closeTo(195, 1));
    });
  });
}
