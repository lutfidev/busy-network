import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'png_rgb.dart';

Future<ui.Image> _image(int w, int h, void Function(Canvas) draw) {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  return recorder.endRecording().toImage(w, h);
}

void main() {
  testWidgets('PNG RGB tanpa alfa, piksel sama setelah dibaca ulang', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final source = await _image(3, 2, (c) {
        c.drawRect(
          const Rect.fromLTWH(0, 0, 3, 2),
          Paint()..color = const Color(0xFF0F1726),
        );
        c.drawRect(
          const Rect.fromLTWH(1, 1, 2, 1),
          Paint()..color = const Color(0xFFF2A81D),
        );
      });
      final png = await encodeRgbPng(source);

      // IHDR: lebar, tinggi, 8 bit, tipe warna 2 (RGB).
      final header = ByteData.sublistView(png, 16, 29);
      expect(header.getUint32(0), 3);
      expect(header.getUint32(4), 2);
      expect(header.getUint8(8), 8);
      expect(header.getUint8(9), 2);

      final codec = await ui.instantiateImageCodec(png);
      final decoded = (await codec.getNextFrame()).image;
      final a = (await source.toByteData())!.buffer.asUint8List();
      final b = (await decoded.toByteData())!.buffer.asUint8List();
      expect(b, a);
    });
  });

  testWidgets('menolak gambar tembus pandang', (tester) async {
    await tester.runAsync(() async {
      final source = await _image(1, 1, (_) {});
      await expectLater(encodeRgbPng(source), throwsStateError);
    });
  });
}
