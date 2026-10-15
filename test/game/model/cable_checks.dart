import 'package:busy_network/game/model/cable.dart';
import 'package:busy_network/game/model/level_def.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kabel sah: ruas 0/45/90°, belokan di grid level, ujung ≤ 24 px dari
/// node asal/tujuan, dan junction `via` terletak di polyline.
void expectValidCable(
  LevelDef level,
  Cable c,
  Offset Function(String id) positionOf,
) {
  final p = c.points;
  expect(p.length, greaterThanOrEqualTo(2), reason: c.id);
  for (var i = 1; i < p.length; i++) {
    expect(isGridAngle(p[i - 1], p[i]), isTrue, reason: '${c.id} ruas $i');
  }
  for (var i = 1; i < p.length - 1; i++) {
    expect(level.onGrid(p[i]), isTrue, reason: '${c.id} belokan $i');
  }
  expect(
    (p.first - positionOf(c.from)).distance,
    lessThanOrEqualTo(24),
    reason: '${c.id} pangkal',
  );
  expect(
    (p.last - positionOf(c.to)).distance,
    lessThanOrEqualTo(24),
    reason: '${c.id} ujung',
  );
  for (final j in c.via) {
    expect(_onPolyline(p, positionOf(j)), isTrue, reason: '${c.id} via $j');
  }
}

bool _onPolyline(List<Offset> p, Offset q) {
  for (var i = 1; i < p.length; i++) {
    final a = p[i - 1];
    final b = p[i];
    if (((q - a).distance + (b - q).distance - (b - a).distance).abs() < 1e-6) {
      return true;
    }
  }
  return false;
}
