import 'dart:math' as math;
import 'dart:ui';

import '../map_scene.dart';

/// Ukuran satu langkah grid peta (px desain).
const double gridCell = 30;

/// Titik grid level dalam satuan langkah: `gridOrigin + (30i, 30j)`.
typedef Cell = ({int i, int j});

/// Jumlah segmen kabel: panjang tiap ruas dalam langkah grid (diagonal
/// dihitung satu langkah), dijumlah, dibulatkan, minimal 1.
///
/// Kabel yang ditarik di desain (195,264)→(195,300)→(255,360) = 3,2 → 3.
int segmentCount(List<Offset> points) {
  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    final d = points[i] - points[i - 1];
    length += math.max(d.dx.abs(), d.dy.abs());
  }
  return math.max(1, (length / gridCell).round());
}

/// Ruas [a]→[b] lurus 0°/90° atau miring 45°?
bool isGridAngle(Offset a, Offset b) {
  const eps = 1e-6;
  final dx = (b.dx - a.dx).abs();
  final dy = (b.dy - a.dy).abs();
  return dx < eps || dy < eps || (dx - dy).abs() < eps;
}

/// Spesifikasi jenis kabel.
class CableSpec {
  const CableSpec({
    required this.kind,
    required this.name,
    required this.pricePerSegment,
    required this.capacityMbps,
    required this.tagline,
    required this.unlockLevel,
  });

  final CableKind kind;
  final String name;
  final int pricePerSegment;
  final int capacityMbps;

  /// "murah" / "ngebut".
  final String tagline;

  /// Level pertama tempat kabel ini bisa dipakai.
  final int unlockLevel;

  static const lan = CableSpec(
    kind: CableKind.lan,
    name: 'LAN',
    pricePerSegment: 15000,
    capacityMbps: 20,
    tagline: 'murah',
    unlockLevel: 1,
  );

  static const fiber = CableSpec(
    kind: CableKind.fiber,
    name: 'Fiber',
    pricePerSegment: 60000,
    capacityMbps: 100,
    tagline: 'ngebut',
    unlockLevel: 3,
  );

  static const all = [lan, fiber];

  static CableSpec of(CableKind kind) => switch (kind) {
    CableKind.lan => lan,
    CableKind.fiber => fiber,
  };
}

/// Kabel terpasang, berarah dari hulu [from] ke hilir [to].
///
/// [points] adalah polyline persis seperti digambar (ujungnya boleh
/// terpotong di tepi node). Kabel yang melewati junction (mis. fiber ke
/// Warung lewat `j1`) tetap satu polyline; junction-nya dicatat di [via].
class Cable {
  const Cable({
    required this.id,
    required this.from,
    required this.to,
    this.kind = CableKind.lan,
    required this.points,
    this.via = const [],
    this.badgeAt,
  });

  final String id;
  final String from;
  final String to;
  final CableKind kind;
  final List<Offset> points;
  final List<String> via;

  /// Letak badge "Penuh!" dari desain; `null` = [badgeCenter] default.
  final Offset? badgeAt;

  /// Jarak badge default di bawah titik tengah kabel.
  static const badgeDrop = Offset(0, 36);

  CableSpec get spec => CableSpec.of(kind);
  int get segments => segmentCount(points);
  int get cost => segments * spec.pricePerSegment;

  /// Node yang dilalui berurutan: [from], junction [via], [to].
  List<String> get stops => [from, ...via, to];

  Offset get badgeCenter => badgeAt ?? _midpoint(points) + badgeDrop;
}

/// Kabel yang sedang ditarik di fase rancang.
class CableDraft {
  const CableDraft({
    required this.from,
    required this.kind,
    required this.points,
    this.target,
    this.handle,
  });

  final String from;
  final CableKind kind;
  final List<Offset> points;

  /// Rumah/junction yang diberi cincin snap ("lepas jari di sini").
  final String? target;

  /// Ujung tarikan di titik grid bawah jari (lingkaran jari). `null` = kabel
  /// sudah menempel ke [target], atau tarikan dipandu (tutorial, jari =
  /// gambar tangan).
  final Offset? handle;

  int get segments => segmentCount(points);
  int get cost => segments * CableSpec.of(kind).pricePerSegment;

  CableDraft withKind(CableKind kind) => CableDraft(
    from: from,
    kind: kind,
    points: points,
    target: target,
    handle: handle,
  );
}

/// Titik tengah polyline menurut panjangnya.
Offset _midpoint(List<Offset> points) {
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += (points[i] - points[i - 1]).distance;
  }
  var rest = total / 2;
  for (var i = 1; i < points.length; i++) {
    final length = (points[i] - points[i - 1]).distance;
    if (length > 0 && rest <= length) {
      return Offset.lerp(points[i - 1], points[i], rest / length)!;
    }
    rest -= length;
  }
  return points.first;
}
