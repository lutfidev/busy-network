import 'dart:math' as math;
import 'dart:ui';

import 'cable.dart';

/// Jalur kabel yang sedang ditarik: deret titik grid dari node sumber,
/// tiap langkah ke salah satu dari 8 tetangga, jadi ruasnya selalu
/// 0°/45°/90°.
///
/// Jari pindah ke titik grid lain → [moveTo] memanjangkan jalur langkah demi
/// langkah (miring dulu, lalu lurus). Kembali ke titik yang sudah dilewati
/// memotong jalur sampai situ (undo dengan menelusur balik).
class CableWalk {
  CableWalk(Cell start, {this.blocked = const {}}) : _cells = [start];

  /// Pusat node lain. Tidak bisa dilewati; hanya boleh jadi ujung jalur
  /// saat menempel ke rumah tujuan (`dock`).
  final Set<Cell> blocked;

  final List<Cell> _cells;

  List<Cell> get cells => List.unmodifiable(_cells);
  Cell get start => _cells.first;
  Cell get end => _cells.last;

  /// Bawa ujung jalur ke [goal]. Dengan [dock], [goal] (pusat rumah tujuan)
  /// boleh jadi ujung walau termasuk [blocked]. Langkah miring yang
  /// terhalang diganti langkah lurus; tidak ada jalan → jalur berhenti di
  /// depan penghalang.
  void moveTo(Cell goal, {bool dock = false}) {
    if (goal == end) return;
    // Lepas dari rumah yang tadi ditempeli: pusat node hanya boleh di ujung.
    if (blocked.contains(end)) _cells.removeLast();
    if (_cutTo(goal)) return;
    var at = end;
    while (at != goal) {
      final next = _step(at, goal, dock: dock);
      if (next == null) return;
      if (!_cutTo(next)) _cells.add(next);
      at = next;
    }
  }

  /// Langkah berikut dari [at] menuju [goal]: miring, atau lurus di sumbu
  /// yang masih jauh bila langkah miring terhalang.
  Cell? _step(Cell at, Cell goal, {required bool dock}) {
    final di = goal.i - at.i;
    final dj = goal.j - at.j;
    final steps = [
      (di.sign, dj.sign),
      if (di != 0 && dj != 0)
        ...(di.abs() >= dj.abs()
            ? [(di.sign, 0), (0, dj.sign)]
            : [(0, dj.sign), (di.sign, 0)]),
    ];
    for (final (si, sj) in steps) {
      final next = (i: at.i + si, j: at.j + sj);
      if (!blocked.contains(next) || (dock && next == goal)) return next;
    }
    return null;
  }

  /// [cell] sudah ada di jalur → potong jalur sampai di situ.
  bool _cutTo(Cell cell) {
    final seen = _cells.indexOf(cell);
    if (seen < 0) return false;
    _cells.length = seen + 1;
    return true;
  }
}

/// Polyline kabel dari jalur titik pusat [path] (berurutan, bertetangga di
/// grid): titik segaris dibuang, lalu ujung awal dipotong [startTrim] px dan
/// ujung akhir [endTrim] px (tepi node, lihat `LevelDef.routerReach`).
List<Offset> cablePolyline(
  List<Offset> path, {
  double startTrim = 0,
  double endTrim = 0,
}) {
  final points = [
    for (var i = 0; i < path.length; i++)
      if (i == 0 ||
          i == path.length - 1 ||
          _heading(path[i - 1], path[i]) != _heading(path[i], path[i + 1]))
        path[i],
  ];
  if (points.length < 2) return points;
  final n = points.length;
  var head = math.min(startTrim, (points[1] - points[0]).distance);
  var tail = math.min(endTrim, (points[n - 1] - points[n - 2]).distance);
  // Satu ruas dipotong di dua ujung: jangan sampai terbalik.
  final length = (points[1] - points[0]).distance;
  if (n == 2 && head + tail > length) {
    final k = length / (head + tail);
    head *= k;
    tail *= k;
  }
  Offset cut(Offset from, Offset toward, double trim) {
    final d = toward - from;
    return trim == 0 ? from : from + d * (trim / d.distance);
  }

  return [
    cut(points[0], points[1], head),
    ...points.sublist(1, n - 1),
    cut(points[n - 1], points[n - 2], tail),
  ];
}

(int, int) _heading(Offset a, Offset b) =>
    ((b.dx - a.dx).sign.toInt(), (b.dy - a.dy).sign.toInt());
