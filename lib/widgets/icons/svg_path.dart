import 'dart:ui';

/// Parser mini untuk atribut `d` SVG (M L H V C S Q T A Z, absolut &
/// relatif). Cukup untuk ikon & ilustrasi di file desain, jadi tidak perlu
/// dependency `flutter_svg`.
Path parseSvgPath(String data) {
  final path = Path();
  final tokens = _tokenize(data);
  var i = 0;
  var cmd = '';
  var cur = Offset.zero;
  var start = Offset.zero;
  Offset? lastCubicCtrl;
  Offset? lastQuadCtrl;

  bool isCmd(String t) => RegExp(r'^[a-zA-Z]$').hasMatch(t);
  double next() => double.parse(tokens[i++]);
  bool nextFlag() => tokens[i++] != '0';

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
    } else if (cmd.isEmpty) {
      throw FormatException('Path harus diawali perintah', data);
    }
    final rel = cmd == cmd.toLowerCase();
    final base = rel ? cur : Offset.zero;
    switch (cmd.toUpperCase()) {
      case 'M':
        cur = base + Offset(next(), next());
        start = cur;
        path.moveTo(cur.dx, cur.dy);
        // Pasangan koordinat berikutnya diperlakukan sebagai L/l.
        cmd = rel ? 'l' : 'L';
        lastCubicCtrl = lastQuadCtrl = null;
      case 'L':
        cur = base + Offset(next(), next());
        path.lineTo(cur.dx, cur.dy);
        lastCubicCtrl = lastQuadCtrl = null;
      case 'H':
        final x = next();
        cur = Offset(rel ? cur.dx + x : x, cur.dy);
        path.lineTo(cur.dx, cur.dy);
        lastCubicCtrl = lastQuadCtrl = null;
      case 'V':
        final y = next();
        cur = Offset(cur.dx, rel ? cur.dy + y : y);
        path.lineTo(cur.dx, cur.dy);
        lastCubicCtrl = lastQuadCtrl = null;
      case 'C':
        final c1 = base + Offset(next(), next());
        final c2 = base + Offset(next(), next());
        final end = base + Offset(next(), next());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastCubicCtrl = c2;
        lastQuadCtrl = null;
        cur = end;
      case 'S':
        final c1 = lastCubicCtrl == null ? cur : cur * 2 - lastCubicCtrl;
        final c2 = base + Offset(next(), next());
        final end = base + Offset(next(), next());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastCubicCtrl = c2;
        lastQuadCtrl = null;
        cur = end;
      case 'Q':
        final c = base + Offset(next(), next());
        final end = base + Offset(next(), next());
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastQuadCtrl = c;
        lastCubicCtrl = null;
        cur = end;
      case 'T':
        final c = lastQuadCtrl == null ? cur : cur * 2 - lastQuadCtrl;
        final end = base + Offset(next(), next());
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastQuadCtrl = c;
        lastCubicCtrl = null;
        cur = end;
      case 'A':
        final rx = next();
        final ry = next();
        final rotation = next();
        final largeArc = nextFlag();
        final sweep = nextFlag();
        final end = base + Offset(next(), next());
        path.arcToPoint(
          end,
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: sweep,
        );
        lastCubicCtrl = lastQuadCtrl = null;
        cur = end;
      case 'Z':
        path.close();
        cur = start;
        lastCubicCtrl = lastQuadCtrl = null;
      default:
        throw FormatException('Perintah path tidak dikenal: $cmd', data);
    }
  }
  return path;
}

List<String> _tokenize(String data) {
  // Angka boleh menempel: "a2 2 0 0 0-4 0", "1.5.86", "-.5". Flag arc
  // ("0 0 0" atau "001") sudah dipisah spasi di file desain.
  final re = RegExp(r'[a-zA-Z]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?');
  return re.allMatches(data).map((m) => m.group(0)!).toList();
}
