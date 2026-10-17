import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// PNG 24-bit (RGB, tanpa alfa) dari [image] yang buram penuh. Play Console
/// meminta feature graphic & screenshot tanpa kanal alfa, sedangkan
/// `ui.Image.toByteData(png)` selalu menulis RGBA.
Future<Uint8List> encodeRgbPng(ui.Image image) async {
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
      .buffer
      .asUint8List();
  final w = image.width;
  final h = image.height;
  // Tiap baris: byte filter 0 (None) lalu R, G, B per piksel.
  final raw = Uint8List(h * (1 + w * 3));
  var o = 0;
  for (var y = 0; y < h; y++) {
    raw[o++] = 0;
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      if (rgba[i + 3] != 255) {
        throw StateError('Piksel ($x, $y) tembus pandang; latar harus buram.');
      }
      raw[o++] = rgba[i];
      raw[o++] = rgba[i + 1];
      raw[o++] = rgba[i + 2];
    }
  }
  final header = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8) // bit per kanal
    ..setUint8(9, 2) // tipe warna: RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  return (BytesBuilder(copy: false)
        ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(_chunk('IDAT', ZLibEncoder(level: 9).convert(raw)))
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

List<int> _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  final out = ByteData(12 + data.length)..setUint32(0, data.length);
  final bytes = out.buffer.asUint8List()..setAll(4, body);
  out.setUint32(8 + data.length, _crc32(body));
  return bytes;
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
