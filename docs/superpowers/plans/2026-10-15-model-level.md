# Model Level & State Game — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Definisi level jadi data (`LevelDef`), state game terpisah dari UI (`GameState`), dan peta Tutorial/Rancang/Jalan digambar lewat `SceneBuilder.fromState` dengan hasil identik dengan sekarang.

**Architecture:** Model murni Dart di `lib/game/model/` (kabel, level, topologi, state). Data level di `lib/game/levels/`. Snapshot per layar (pengganti `DummyScenes`) di `lib/data/dummy_states.dart`. `SceneBuilder` menurunkan `MapScene` (model gambar yang sudah ada) dari state. Renderer dan widget tidak berubah.

**Tech Stack:** Flutter 3 / Dart 3, `flutter_test`, `ChangeNotifier`.

**Spec:** `docs/superpowers/specs/2026-10-15-model-level-design.md`

## Global Constraints

- Jangan hardcode warna/ukuran di widget; angka tampil lewat `IdFormat`.
- Copy teks Bahasa Indonesia persis seperti desain, tanpa `ellipsis`.
- Koordinat peta ditulis sebagai data dalam ruang 390×472, persis seperti `lib/data/dummy_scenes.dart`.
- Model (`lib/game/model/`) tidak mengimpor widget/tema Flutter; `dart:ui` dan `package:flutter/foundation.dart` boleh.
- Identifier bahasa Inggris, doc comment bahasa Indonesia (gaya kode yang ada).
- `flutter analyze` bersih dan `flutter test` hijau di akhir tiap task.
- Commit kecil per task, pesan bahasa Inggris (`feat(model): ...`, `refactor(...)`, `test: ...`, `docs: ...`).
- Satu-satunya beda visual yang boleh: bar sabar Rumah 4 di Fase Jalan (7/40 → 0,15).

## Review Focus

- Fase rancang tanpa draft: peta tanpa kabel putus-putus & tanpa lingkaran jari, header tanpa catatan "sedang ditarik", tidak crash (test di Task 5).
- Frame fase jalan yang tidak memuat semua rumah (mis. tepat setelah `startDay`): rumah tanpa data digambar polos `idle`, tidak crash (test di Task 5).
- Kabel yang membentuk siklus atau mengarah ke router: topologi tetap selesai, router tidak punya induk (test di Task 3).
- Panel antrean saat tidak ada kabel penuh: tetap terbentuk, memakai kabel dengan rasio beban/kapasitas tertinggi (test di Task 7).
- Ganti jenis kabel bolak-balik atau ke jenis yang sama: draft & biaya ikut, tanpa notifikasi kosong (test di Task 4).

---

### Task 0: Baseline screenshot

**Files:** tidak ada (hanya artefak di scratchpad).

- [ ] **Step 1: Ambil screenshot sebelum perubahan**

```bash
flutter test test/screenshots --dart-define=SCREENSHOTS=true
cp -r build/screenshots "$SCRATCHPAD/baseline"
```
Expected: semua PNG di `build/screenshots/{390x844,360x740}/` tersalin. Dipakai di Task 8.

---

### Task 1: `CableSpec`, `Cable`, `CableDraft`

**Files:**
- Create: `lib/game/model/cable.dart`
- Test: `test/game/model/cable_test.dart`

**Interfaces:**
- Consumes: `CableKind` dari `lib/game/map_scene.dart`.
- Produces: `const double gridCell = 30`; `int segmentCount(List<Offset>)`; `bool isGridAngle(Offset, Offset)`; `class CableSpec { kind, name, pricePerSegment, capacityMbps, tagline, unlockLevel; static lan, fiber, all; static CableSpec of(CableKind) }`; `class Cable { id, from, to, kind, points, via, badgeAt; spec, segments, cost, stops, badgeCenter }`; `class CableDraft { from, kind, points, target, handle; segments, cost, withKind(CableKind) }`.

- [ ] **Step 1: Tulis test yang gagal**

```dart
// test/game/model/cable_test.dart
import 'dart:ui';

import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/cable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const designDraft = [Offset(195, 264), Offset(195, 300), Offset(255, 360)];

  group('segmentCount', () {
    test('kabel yang ditarik di desain = 3 segmen', () {
      expect(segmentCount(designDraft), 3);
    });

    test('diagonal tutorial 150 px = 5 segmen', () {
      expect(segmentCount(const [Offset(105, 315), Offset(255, 165)]), 5);
    });

    test('lurus 120 px = 4 segmen', () {
      expect(segmentCount(const [Offset(195, 240), Offset(315, 240)]), 4);
    });

    test('minimal 1 segmen', () {
      expect(segmentCount(const [Offset(0, 0), Offset(5, 0)]), 1);
      expect(segmentCount(const [Offset(0, 0)]), 1);
    });
  });

  group('isGridAngle', () {
    test('0°, 45°, 90° boleh', () {
      expect(isGridAngle(Offset.zero, const Offset(60, 0)), isTrue);
      expect(isGridAngle(Offset.zero, const Offset(0, -60)), isTrue);
      expect(isGridAngle(Offset.zero, const Offset(60, -60)), isTrue);
    });

    test('sudut lain ditolak', () {
      expect(isGridAngle(Offset.zero, const Offset(60, 30)), isFalse);
    });
  });

  group('CableSpec', () {
    test('of sesuai jenis', () {
      expect(CableSpec.of(CableKind.lan), same(CableSpec.lan));
      expect(CableSpec.of(CableKind.fiber), same(CableSpec.fiber));
    });

    test('angka sesuai desain', () {
      expect(CableSpec.lan.pricePerSegment, 15000);
      expect(CableSpec.lan.capacityMbps, 20);
      expect(CableSpec.lan.unlockLevel, 1);
      expect(CableSpec.fiber.pricePerSegment, 60000);
      expect(CableSpec.fiber.capacityMbps, 100);
      expect(CableSpec.fiber.unlockLevel, 3);
    });
  });

  group('Cable', () {
    test('biaya = segmen × harga', () {
      const lan = Cable(id: 'a', from: 'router', to: 'r5', points: designDraft);
      const fiber = Cable(
        id: 'b',
        from: 'router',
        to: 'r5',
        kind: CableKind.fiber,
        points: designDraft,
      );
      expect(lan.segments, 3);
      expect(lan.cost, 45000);
      expect(fiber.cost, 180000);
    });

    test('stops memuat junction yang dilewati', () {
      const c = Cable(
        id: 'c-w',
        from: 'router',
        to: 'w',
        via: ['j1'],
        points: [Offset(195, 216), Offset(195, 80)],
      );
      expect(c.stops, ['router', 'j1', 'w']);
    });

    test('badge default 36 px di bawah titik tengah', () {
      const c = Cable(
        id: 'x',
        from: 'a',
        to: 'b',
        points: [Offset(195, 264), Offset(195, 400)],
      );
      expect(c.badgeCenter, const Offset(195, 368));
    });

    test('badgeAt menimpa default', () {
      const c = Cable(
        id: 'x',
        from: 'a',
        to: 'b',
        points: [Offset(219, 240), Offset(295, 240)],
        badgeAt: Offset(262, 276),
      );
      expect(c.badgeCenter, const Offset(262, 276));
    });
  });

  group('CableDraft', () {
    test('withKind mengganti jenis & biaya, sisanya tetap', () {
      const draft = CableDraft(
        from: 'router',
        kind: CableKind.lan,
        points: designDraft,
        target: 'r5',
        handle: Offset(255, 360),
      );
      expect(draft.segments, 3);
      expect(draft.cost, 45000);
      final fiber = draft.withKind(CableKind.fiber);
      expect(fiber.kind, CableKind.fiber);
      expect(fiber.cost, 180000);
      expect(fiber.target, 'r5');
      expect(fiber.handle, const Offset(255, 360));
      expect(fiber.points, designDraft);
    });
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/game/model/cable_test.dart`
Expected: FAIL, `cable.dart` belum ada.

- [ ] **Step 3: Implementasi**

```dart
// lib/game/model/cable.dart
import 'dart:math' as math;
import 'dart:ui';

import '../map_scene.dart';

/// Ukuran satu langkah grid peta (px desain).
const double gridCell = 30;

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

  /// Rumah yang diberi cincin snap ("lepas jari di sini").
  final String? target;

  /// Posisi jari; `null` = tarikan dipandu (tutorial, jari = gambar tangan).
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
```

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: `flutter test test/game/model/cable_test.dart` → PASS. Lalu `flutter analyze` → bersih.

- [ ] **Step 5: Commit**

```bash
git add lib/game/model/cable.dart test/game/model/cable_test.dart
git commit -m "feat(model): cable specs, cables and drafts with segment cost"
```

---

### Task 2: `LevelDef`, `HouseDef`, data level 1 & 5

**Files:**
- Create: `lib/game/model/level_def.dart`, `lib/game/levels/levels.dart`
- Test: `test/game/model/cable_checks.dart` (helper), `test/game/model/level_def_test.dart`

**Interfaces:**
- Consumes: Task 1 (`Cable`, `CableSpec`, `gridCell`, `isGridAngle`); `MapBlockLabel` dari `map_scene.dart`.
- Produces: `enum MarkSide { below, right, above }`; `class HouseDef { id, label, position, customer, place, packageMbps, peakMbps, labelSide, patienceSide }`; `class Junction { id, position }`; `class LevelDef { static cell, static routerId; number, name, gridOrigin, routerPosition, routerLabel, houses, junctions, cables, budget, targetSatisfaction, rushHourFrom, rushHourTo, blockLabels, nightBlockLabels, unlockedCables, house(id), positionOf(id), onGrid(p) }`; `abstract final class Levels { level1, level5, all }`; helper test `void expectValidCable(LevelDef, Cable, Offset Function(String))`.

- [ ] **Step 1: Tulis helper & test yang gagal**

```dart
// test/game/model/cable_checks.dart
import 'dart:ui';

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
    if (((q - a).distance + (b - q).distance - (b - a).distance).abs() <
        1e-6) {
      return true;
    }
  }
  return false;
}
```

```dart
// test/game/model/level_def_test.dart
import 'dart:ui';

import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/cable.dart';
import 'package:busy_network/game/model/level_def.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cable_checks.dart';

void main() {
  test('sel grid model = sel grid peta', () {
    expect(LevelDef.cell, AppSpacing.mapCell);
  });

  for (final level in Levels.all) {
    group('Level ${level.number}', () {
      test('id node & kabel unik', () {
        final ids = [
          LevelDef.routerId,
          ...level.houses.map((h) => h.id),
          ...level.junctions.map((j) => j.id),
        ];
        expect(ids.toSet(), hasLength(ids.length));
        final cables = level.cables.map((c) => c.id).toList();
        expect(cables.toSet(), hasLength(cables.length));
      });

      test('node di grid level', () {
        expect(level.onGrid(level.routerPosition), isTrue);
        for (final h in level.houses) {
          expect(level.onGrid(h.position), isTrue, reason: h.id);
        }
        for (final j in level.junctions) {
          expect(level.onGrid(j.position), isTrue, reason: j.id);
        }
      });

      test('kabel awal sah', () {
        for (final c in level.cables) {
          expectValidCable(level, c, level.positionOf);
        }
      });
    });
  }

  test('kabel terbuka mengikuti level buka', () {
    expect(Levels.level1.unlockedCables, [CableSpec.lan]);
    expect(Levels.level5.unlockedCables, [CableSpec.lan, CableSpec.fiber]);
  });

  test('tempat default = label', () {
    expect(Levels.level5.house('r4').place, 'Rumah 4');
    expect(Levels.level5.house('w').place, 'Blok A');
  });

  test('positionOf router, rumah, junction', () {
    const l = Levels.level5;
    expect(l.positionOf(LevelDef.routerId), const Offset(195, 240));
    expect(l.positionOf('r5'), const Offset(315, 390));
    expect(l.positionOf('j1'), const Offset(195, 150));
    expect(() => l.positionOf('zz'), throwsArgumentError);
  });

  test('onGrid memakai titik asal level', () {
    expect(Levels.level1.onGrid(const Offset(105, 315)), isTrue);
    expect(Levels.level5.onGrid(const Offset(105, 315)), isFalse);
    expect(Levels.level5.onGrid(const Offset(195, 240)), isTrue);
  });

  test('label blok malam level 1 = siang', () {
    expect(Levels.level1.nightBlockLabels, same(Levels.level1.blockLabels));
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/game/model/level_def_test.dart`
Expected: FAIL, `level_def.dart`/`levels.dart` belum ada.

- [ ] **Step 3: Implementasi model**

```dart
// lib/game/model/level_def.dart
import 'dart:ui';

import '../map_scene.dart';
import 'cable.dart';

/// Sisi tempat label / bar sabar rumah digambar.
enum MarkSide { below, right, above }

/// Rumah pelanggan di sebuah level.
class HouseDef {
  const HouseDef({
    required this.id,
    required this.label,
    required this.position,
    required this.customer,
    String? place,
    required this.packageMbps,
    required this.peakMbps,
    this.labelSide = MarkSide.below,
    this.patienceSide = MarkSide.below,
  }) : _place = place;

  final String id;

  /// Label di peta ("Rumah 4", "Warung").
  final String label;
  final Offset position;

  /// Nama pelanggan ("Bu Sri").
  final String customer;
  final String? _place;

  /// Paket langganan (Mbps).
  final int packageMbps;

  /// Profil pemakaian: pemakaian saat jam sibuk (Mbps). Kurva harian
  /// dibentuk dari sini di langkah 5.
  final double peakMbps;

  /// Fase rancang: [MarkSide.right] = label di kanan rumah, rata kiri.
  final MarkSide labelSide;

  /// Fase jalan: letak bar sabar; [MarkSide.right] = label rata kiri.
  final MarkSide patienceSide;

  /// Tempat di daftar antrean ("Rumah 4", "Blok A"); default [label].
  String get place => _place ?? label;
}

/// Titik cabang kabel.
class Junction {
  const Junction({required this.id, required this.position});

  final String id;
  final Offset position;
}

/// Definisi satu level (statis). Koordinat dalam ruang peta 390×472.
class LevelDef {
  const LevelDef({
    required this.number,
    required this.name,
    required this.gridOrigin,
    required this.routerPosition,
    this.routerLabel,
    required this.houses,
    this.junctions = const [],
    this.cables = const [],
    required this.budget,
    required this.targetSatisfaction,
    this.rushHourFrom,
    this.rushHourTo,
    required this.blockLabels,
    List<MapBlockLabel>? nightBlockLabels,
  }) : _nightBlockLabels = nightBlockLabels;

  static const double cell = gridCell;
  static const routerId = 'router';

  final int number;
  final String name;

  /// Titik grid acuan: node & belokan kabel ada di gridOrigin + (30i, 30j).
  /// Level 5 bergeser 15 px vertikal dari titik grid yang digambar.
  final Offset gridOrigin;
  final Offset routerPosition;
  final String? routerLabel;
  final List<HouseDef> houses;

  /// Jaringan awal level (sudah terpasang saat level dimulai).
  final List<Junction> junctions;
  final List<Cable> cables;

  final int budget;
  final int targetSatisfaction;
  final int? rushHourFrom;
  final int? rushHourTo;

  /// Label blok (siang). Fase jalan memakai [nightBlockLabels].
  final List<MapBlockLabel> blockLabels;
  final List<MapBlockLabel>? _nightBlockLabels;

  List<MapBlockLabel> get nightBlockLabels => _nightBlockLabels ?? blockLabels;

  List<CableSpec> get unlockedCables => [
    for (final spec in CableSpec.all)
      if (spec.unlockLevel <= number) spec,
  ];

  HouseDef house(String id) => houses.firstWhere((h) => h.id == id);

  /// Posisi router, rumah, atau junction awal level.
  Offset positionOf(String nodeId) {
    if (nodeId == routerId) return routerPosition;
    for (final h in houses) {
      if (h.id == nodeId) return h.position;
    }
    for (final j in junctions) {
      if (j.id == nodeId) return j.position;
    }
    throw ArgumentError.value(nodeId, 'nodeId', 'tidak ada di level $number');
  }

  bool onGrid(Offset p) {
    bool aligned(double v) {
      final steps = v / cell;
      return (steps - steps.round()).abs() < 1e-6;
    }

    final d = p - gridOrigin;
    return aligned(d.dx) && aligned(d.dy);
  }
}
```

- [ ] **Step 4: Implementasi data level**

```dart
// lib/game/levels/levels.dart
import 'dart:ui';

import '../map_scene.dart';
import '../model/cable.dart';
import '../model/level_def.dart';

/// Level Babak 1 · Perumahan Batam. Angka & koordinat dari
/// `design/Jaringan Sibuk.html`.
abstract final class Levels {
  static const level1 = LevelDef(
    number: 1,
    name: 'Rumah Pertama',
    gridOrigin: Offset(15, 15),
    routerPosition: Offset(105, 315),
    routerLabel: 'Router',
    houses: [
      // TODO(langkah 5/8): pelanggan, paket & pemakaian belum ada di desain.
      HouseDef(
        id: 'r1',
        label: 'Rumah 1',
        position: Offset(255, 165),
        customer: 'Pak Joko',
        packageMbps: 10,
        peakMbps: 6,
      ),
      HouseDef(
        id: 'r2',
        label: 'Rumah 2',
        position: Offset(315, 345),
        customer: 'Bu Lina',
        packageMbps: 10,
        peakMbps: 4,
      ),
    ],
    budget: 200000,
    targetSatisfaction: 60,
    blockLabels: [
      MapBlockLabel('BLOK A', Offset(255, 112), align: TextAlign.center),
    ],
  );

  static const _j1 = Offset(195, 150);

  static const level5 = LevelDef(
    number: 5,
    name: 'Gang Melati',
    gridOrigin: Offset(15, 0),
    routerPosition: Offset(195, 240),
    houses: [
      HouseDef(
        id: 'r1',
        label: 'Rumah 1',
        position: Offset(75, 90),
        customer: 'Pak Anton',
        packageMbps: 10,
        peakMbps: 4,
      ),
      HouseDef(
        id: 'w',
        label: 'Warung',
        position: Offset(195, 60),
        customer: 'Warung Bu Ijah',
        place: 'Blok A',
        packageMbps: 20,
        peakMbps: 12,
        labelSide: MarkSide.right,
        patienceSide: MarkSide.right,
      ),
      HouseDef(
        id: 'r3',
        label: 'Rumah 3',
        position: Offset(315, 90),
        customer: 'Kak Dewi',
        packageMbps: 10,
        peakMbps: 8.5,
      ),
      HouseDef(
        id: 'r4',
        label: 'Rumah 4',
        position: Offset(315, 240),
        customer: 'Bu Sri',
        packageMbps: 20,
        peakMbps: 16,
        patienceSide: MarkSide.above,
      ),
      HouseDef(
        id: 'r5',
        label: 'Rumah 5',
        position: Offset(315, 390),
        customer: 'Pak Rudi',
        packageMbps: 10,
        peakMbps: 9,
      ),
      HouseDef(
        id: 'r6',
        label: 'Rumah 6',
        position: Offset(195, 420),
        customer: 'Bang Togar',
        packageMbps: 20,
        peakMbps: 11,
        patienceSide: MarkSide.right,
      ),
      HouseDef(
        id: 'r7',
        label: 'Rumah 7',
        position: Offset(75, 330),
        customer: 'Mbak Wulan',
        packageMbps: 10,
        peakMbps: 6,
      ),
    ],
    junctions: [Junction(id: 'j1', position: _j1)],
    cables: [
      Cable(
        id: 'c-r1',
        from: 'j1',
        to: 'r1',
        points: [_j1, Offset(135, 90), Offset(95, 90)],
      ),
      Cable(
        id: 'c-r3',
        from: 'j1',
        to: 'r3',
        points: [_j1, Offset(255, 90), Offset(295, 90)],
      ),
      Cable(
        id: 'c-r4',
        from: LevelDef.routerId,
        to: 'r4',
        points: [Offset(219, 240), Offset(295, 240)],
        badgeAt: Offset(262, 276),
      ),
      Cable(
        id: 'c-w',
        from: LevelDef.routerId,
        to: 'w',
        kind: CableKind.fiber,
        via: ['j1'],
        points: [Offset(195, 216), Offset(195, 80)],
      ),
    ],
    budget: 850000,
    targetSatisfaction: 80,
    rushHourFrom: 19,
    rushHourTo: 22,
    blockLabels: [
      MapBlockLabel('BLOK A', Offset(300, 30), align: TextAlign.center),
      MapBlockLabel('BLOK B', Offset(376, 320), align: TextAlign.right),
      MapBlockLabel('BLOK C', Offset(40, 402)),
    ],
    nightBlockLabels: [
      MapBlockLabel('BLOK A', Offset(300, 24), align: TextAlign.center),
      MapBlockLabel('BLOK B', Offset(376, 452), align: TextAlign.right),
      MapBlockLabel('BLOK C', Offset(40, 402)),
    ],
  );

  static const all = [level1, level5];
}
```

- [ ] **Step 5: Jalankan, pastikan lulus**

Run: `flutter test test/game/model/` → PASS. `flutter analyze` → bersih.

- [ ] **Step 6: Commit**

```bash
git add lib/game/model/level_def.dart lib/game/levels/levels.dart test/game/model/cable_checks.dart test/game/model/level_def_test.dart
git commit -m "feat(model): level definitions for levels 1 and 5"
```

---

### Task 3: Topologi jaringan (`Network`)

**Files:**
- Create: `lib/game/model/network.dart`
- Test: `test/game/model/network_test.dart`

**Interfaces:**
- Consumes: `Cable`, `LevelDef`, `LevelDef.routerId`.
- Produces: `class Hop { Cable cable; String from; String to }`; `class Network { Network({required LevelDef level, required List<Cable> cables}); Set<String> connectedHouses; Hop? parentOf(String); Set<String> housesBelow(String); double hopLoad(Hop, Map<String,double>); double cableLoad(Cable, Map<String,double>); bool isOverloaded(Cable, Map<String,double>); bool isJammed(Cable, Map<String,double>) }`.

- [ ] **Step 1: Tulis test yang gagal**

```dart
// test/game/model/network_test.dart
import 'dart:ui';

import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/cable.dart';
import 'package:busy_network/game/model/level_def.dart';
import 'package:busy_network/game/model/network.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const level = Levels.level5;
  Cable initial(String id) => level.cables.firstWhere((c) => c.id == id);

  // Kabel tambahan di snapshot fase jalan (lihat spec).
  const extra = [
    Cable(
      id: 'c-r6',
      from: LevelDef.routerId,
      to: 'r6',
      via: ['j2'],
      points: [Offset(195, 264), Offset(195, 400)],
    ),
    Cable(
      id: 'c-r7',
      from: 'j2',
      to: 'r7',
      points: [Offset(195, 330), Offset(95, 330)],
    ),
    Cable(
      id: 'c-r5',
      from: 'r4',
      to: 'r5',
      points: [Offset(315, 260), Offset(315, 370)],
    ),
  ];
  const usage = {
    'r1': 4.0,
    'w': 12.0,
    'r3': 8.5,
    'r4': 16.0,
    'r5': 9.0,
    'r6': 11.0,
    'r7': 6.0,
  };
  final runCables = [...level.cables, ...extra];
  Cable runCable(String id) => runCables.firstWhere((c) => c.id == id);

  test('level 5 awal: 4 rumah tersambung', () {
    final net = Network(level: level, cables: level.cables);
    expect(net.connectedHouses, {'r1', 'w', 'r3', 'r4'});
  });

  test('junction mendapat induk dari kabel yang melewatinya', () {
    final net = Network(level: level, cables: level.cables);
    final j1 = net.parentOf('j1')!;
    expect(j1.cable.id, 'c-w');
    expect((j1.from, j1.to), (LevelDef.routerId, 'j1'));
    expect(net.parentOf('w')!.from, 'j1');
    expect(net.parentOf('r1')!.cable.id, 'c-r1');
    expect(net.parentOf(LevelDef.routerId), isNull);
  });

  group('snapshot fase jalan', () {
    final net = Network(level: level, cables: runCables);

    test('semua 7 rumah tersambung', () {
      expect(net.connectedHouses, hasLength(7));
    });

    test('beban Router → Rumah 4 = 16 + 9 = 25', () {
      expect(net.housesBelow('r4'), {'r4', 'r5'});
      expect(net.hopLoad(net.parentOf('r4')!, usage), 25);
      expect(net.cableLoad(initial('c-r4'), usage), 25);
    });

    test('fiber Warung: hop terberat router → j1 = 24,5', () {
      expect(net.cableLoad(initial('c-w'), usage), 24.5);
      expect(net.hopLoad(net.parentOf('w')!, usage), 12);
    });

    test('hanya kabel Rumah 4 yang kelebihan beban', () {
      final overloaded = [
        for (final c in runCables)
          if (net.isOverloaded(c, usage)) c.id,
      ];
      expect(overloaded, ['c-r4']);
    });

    test('macet menular ke hilir', () {
      expect(net.isJammed(runCable('c-r4'), usage), isTrue);
      expect(net.isJammed(runCable('c-r5'), usage), isTrue);
      expect(net.isJammed(runCable('c-r6'), usage), isFalse);
      expect(net.isJammed(runCable('c-r7'), usage), isFalse);
      expect(net.isJammed(runCable('c-r1'), usage), isFalse);
      expect(net.isJammed(runCable('c-w'), usage), isFalse);
    });
  });

  test('rumah tanpa jalur ke router tidak tersambung & tidak berbeban', () {
    final net = Network(level: level, cables: [initial('c-r1')]);
    expect(net.connectedHouses, isEmpty);
    expect(net.cableLoad(initial('c-r1'), usage), 0);
    expect(net.isOverloaded(initial('c-r1'), usage), isFalse);
  });

  test('siklus & kabel ke arah router tidak membuat macet', () {
    const loop = [
      Cable(id: 'a', from: LevelDef.routerId, to: 'r4', points: [Offset.zero, Offset(30, 0)]),
      Cable(id: 'b', from: 'r4', to: 'r5', points: [Offset.zero, Offset(30, 0)]),
      Cable(id: 'c', from: 'r5', to: 'r4', points: [Offset.zero, Offset(30, 0)]),
      Cable(id: 'd', from: 'r5', to: LevelDef.routerId, points: [Offset.zero, Offset(30, 0)]),
    ];
    final net = Network(level: level, cables: loop);
    expect(net.connectedHouses, {'r4', 'r5'});
    expect(net.parentOf('r4')!.cable.id, 'a');
    expect(net.parentOf(LevelDef.routerId), isNull);
    expect(net.cableLoad(loop.first, usage), 25);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/game/model/network_test.dart` → FAIL (`network.dart` belum ada).

- [ ] **Step 3: Implementasi**

```dart
// lib/game/model/network.dart
import 'dart:math' as math;

import 'cable.dart';
import 'level_def.dart';

/// Satu sambungan antar-node di dalam [cable]. Kabel yang lewat junction
/// terdiri dari beberapa hop.
class Hop {
  const Hop(this.cable, this.from, this.to);

  final Cable cable;
  final String from;
  final String to;
}

/// Pohon jaringan: router → kabel → junction/rumah.
///
/// Kabel berarah dari hulu (`from`) ke hilir (`to`). Pohon ditelusuri dari
/// router; node yang sudah punya induk tidak diambil lagi (aman dari
/// siklus). Rumah yang tidak terjangkau router tidak ikut beban.
class Network {
  Network({required LevelDef level, required List<Cable> cables})
    : _houseIds = {for (final h in level.houses) h.id} {
    final out = <String, List<Hop>>{};
    for (final c in cables) {
      final stops = c.stops;
      for (var i = 1; i < stops.length; i++) {
        (out[stops[i - 1]] ??= []).add(Hop(c, stops[i - 1], stops[i]));
      }
    }
    final queue = [LevelDef.routerId];
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      for (final hop in out[node] ?? const <Hop>[]) {
        if (hop.to == LevelDef.routerId || _parent.containsKey(hop.to)) {
          continue;
        }
        _parent[hop.to] = hop;
        (_children[node] ??= []).add(hop.to);
        queue.add(hop.to);
      }
    }
    connectedHouses = {
      for (final id in _parent.keys)
        if (_houseIds.contains(id)) id,
    };
  }

  final Set<String> _houseIds;
  final _parent = <String, Hop>{};
  final _children = <String, List<String>>{};

  /// Rumah yang terjangkau dari router.
  late final Set<String> connectedHouses;

  /// Hop yang memberi [nodeId] internet; `null` untuk router / node lepas.
  Hop? parentOf(String nodeId) => _parent[nodeId];

  /// Rumah tersambung di subpohon [nodeId] (termasuk [nodeId] sendiri).
  Set<String> housesBelow(String nodeId) {
    final result = <String>{};
    final stack = [nodeId];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (connectedHouses.contains(node)) result.add(node);
      stack.addAll(_children[node] ?? const <String>[]);
    }
    return result;
  }

  double hopLoad(Hop hop, Map<String, double> usage) => housesBelow(
    hop.to,
  ).fold(0.0, (sum, id) => sum + (usage[id] ?? 0));

  /// Beban hop terberat di [cable].
  double cableLoad(Cable cable, Map<String, double> usage) =>
      _hops(cable).fold(0.0, (m, hop) => math.max(m, hopLoad(hop, usage)));

  bool isOverloaded(Cable cable, Map<String, double> usage) =>
      _hops(cable).any((hop) => _over(hop, usage));

  /// Kabel ini atau salah satu hop di hulunya kelebihan beban.
  bool isJammed(Cable cable, Map<String, double> usage) {
    if (isOverloaded(cable, usage)) return true;
    for (var hop = _parent[cable.from]; hop != null; hop = _parent[hop.from]) {
      if (_over(hop, usage)) return true;
    }
    return false;
  }

  bool _over(Hop hop, Map<String, double> usage) =>
      hopLoad(hop, usage) > hop.cable.spec.capacityMbps;

  static List<Hop> _hops(Cable cable) {
    final stops = cable.stops;
    return [
      for (var i = 1; i < stops.length; i++)
        Hop(cable, stops[i - 1], stops[i]),
    ];
  }
}
```

Catatan: `hopLoad` untuk hop yang tidak ada di pohon tetap aman karena `housesBelow` hanya menghitung rumah tersambung (test "rumah tanpa jalur").

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: `flutter test test/game/model/network_test.dart` → PASS. `flutter analyze` → bersih (jalankan `dart format` pada file test bila baris loop kepanjangan).

- [ ] **Step 5: Commit**

```bash
git add lib/game/model/network.dart test/game/model/network_test.dart
git commit -m "feat(model): network topology with per-hop load and jam propagation"
```

---

### Task 4: `GameState`

**Files:**
- Create: `lib/game/model/game_state.dart`, `lib/game/model/model.dart` (barrel)
- Test: `test/game/model/game_state_test.dart`

**Interfaces:**
- Consumes: Task 1–3.
- Produces: `enum GamePhase { design, run, result }`; `class HouseLive { state, patience, usageMbps }`; `class SimFrame { houses; Map<String,double> get usage }`; `class GameState extends ChangeNotifier { GameState(LevelDef level, {phase, budget, junctions, cables, selectedCable, draft, frame}); level, phase, budget, junctions, cables, selectedCable, draft, frame, network, connectedHouses, connectedCount, draftCost; selectCable, setDraft, startDay, updateFrame, finishDay }`; barrel `lib/game/model/model.dart` mengekspor `cable.dart`, `game_state.dart`, `level_def.dart`, `network.dart`.

- [ ] **Step 1: Tulis test yang gagal**

```dart
// test/game/model/game_state_test.dart
import 'dart:ui';

import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const draft = CableDraft(
    from: LevelDef.routerId,
    kind: CableKind.lan,
    points: [Offset(195, 264), Offset(195, 300), Offset(255, 360)],
    target: 'r5',
    handle: Offset(255, 360),
  );

  GameState level5({CableDraft? withDraft = draft}) =>
      GameState(Levels.level5, draft: withDraft);

  int countNotifications(GameState s, void Function() action) {
    var n = 0;
    s.addListener(() => n++);
    action();
    return n;
  }

  test('default diambil dari level', () {
    final s = GameState(Levels.level5);
    expect(s.phase, GamePhase.design);
    expect(s.budget, 850000);
    expect(s.cables, Levels.level5.cables);
    expect(s.junctions, Levels.level5.junctions);
    expect(s.selectedCable, CableKind.lan);
    expect(s.connectedCount, 4);
    expect(s.draft, isNull);
    expect(s.draftCost, 0);
    expect(s.frame, isNull);
  });

  test('daftar kabel tidak bisa diubah dari luar', () {
    final s = GameState(Levels.level5);
    expect(() => s.cables.clear(), throwsUnsupportedError);
    expect(() => s.junctions.clear(), throwsUnsupportedError);
  });

  test('biaya draft = segmen × harga kabel', () {
    expect(level5().draftCost, 45000);
  });

  group('selectCable', () {
    test('ganti jenis draft & biaya, beri tahu sekali', () {
      final s = level5();
      final n = countNotifications(s, () => s.selectCable(CableKind.fiber));
      expect(n, 1);
      expect(s.selectedCable, CableKind.fiber);
      expect(s.draft!.kind, CableKind.fiber);
      expect(s.draftCost, 180000);
    });

    test('bolak-balik kembali ke LAN', () {
      final s = level5()
        ..selectCable(CableKind.fiber)
        ..selectCable(CableKind.lan);
      expect(s.draft!.kind, CableKind.lan);
      expect(s.draftCost, 45000);
    });

    test('jenis yang sama tidak memberi tahu', () {
      final s = level5();
      expect(countNotifications(s, () => s.selectCable(CableKind.lan)), 0);
    });

    test('jenis terkunci ditolak', () {
      final s = GameState(Levels.level1);
      expect(() => s.selectCable(CableKind.fiber), throwsArgumentError);
      expect(
        () => GameState(Levels.level1, selectedCable: CableKind.fiber),
        throwsArgumentError,
      );
    });
  });

  test('setDraft memberi tahu & bisa dikosongkan', () {
    final s = level5();
    expect(countNotifications(s, () => s.setDraft(null)), 1);
    expect(s.draft, isNull);
    expect(s.draftCost, 0);
  });

  group('fase', () {
    test('startDay: rancang → jalan, draft dibuang, frame awal', () {
      final s = level5();
      expect(countNotifications(s, s.startDay), 1);
      expect(s.phase, GamePhase.run);
      expect(s.draft, isNull);
      expect(s.frame!.houses.keys.toSet(), {'r1', 'w', 'r3', 'r4'});
      final r1 = s.frame!.houses['r1']!;
      expect(r1.state, HouseState.ok);
      expect(r1.patience, 1);
      expect(r1.usageMbps, 0);
    });

    test('updateFrame hanya di fase jalan', () {
      final s = level5();
      const frame = SimFrame(houses: {});
      expect(() => s.updateFrame(frame), throwsStateError);
      s.startDay();
      expect(countNotifications(s, () => s.updateFrame(frame)), 1);
      expect(s.frame, same(frame));
    });

    test('finishDay: jalan → hasil', () {
      final s = level5()..startDay();
      expect(countNotifications(s, s.finishDay), 1);
      expect(s.phase, GamePhase.result);
    });

    test('transisi tidak sah ditolak', () {
      final s = level5();
      expect(s.finishDay, throwsStateError);
      s
        ..startDay()
        ..finishDay();
      expect(s.startDay, throwsStateError);
      expect(() => s.setDraft(draft), throwsStateError);
    });
  });

  test('SimFrame.usage', () {
    const frame = SimFrame(
      houses: {
        'r4': HouseLive(state: HouseState.jam, patience: 0.15, usageMbps: 16),
      },
    );
    expect(frame.usage, {'r4': 16});
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `flutter test test/game/model/game_state_test.dart` → FAIL (`model.dart` belum ada).

- [ ] **Step 3: Implementasi**

```dart
// lib/game/model/game_state.dart
import 'package:flutter/foundation.dart';

import '../map_scene.dart';
import 'cable.dart';
import 'level_def.dart';
import 'network.dart';

enum GamePhase { design, run, result }

/// Keadaan satu rumah saat hari berjalan.
class HouseLive {
  const HouseLive({
    required this.state,
    required this.patience,
    required this.usageMbps,
  });

  final HouseState state;

  /// Sisa kesabaran 0..1.
  final double patience;
  final double usageMbps;
}

/// Potret simulasi pada satu saat (diisi simulasi di langkah 5).
class SimFrame {
  const SimFrame({required this.houses});

  /// Hanya rumah tersambung.
  final Map<String, HouseLive> houses;

  Map<String, double> get usage => {
    for (final e in houses.entries) e.key: e.value.usageMbps,
  };
}

/// State satu permainan level: fase, anggaran, jaringan, draft, simulasi.
class GameState extends ChangeNotifier {
  GameState(
    this.level, {
    GamePhase phase = GamePhase.design,
    int? budget,
    List<Junction>? junctions,
    List<Cable>? cables,
    CableKind selectedCable = CableKind.lan,
    CableDraft? draft,
    SimFrame? frame,
  }) : _phase = phase,
       _budget = budget ?? level.budget,
       junctions = List.unmodifiable(junctions ?? level.junctions),
       cables = List.unmodifiable(cables ?? level.cables),
       _selectedCable = selectedCable,
       _draft = draft,
       _frame = frame {
    _checkUnlocked(selectedCable);
    if (draft != null) _checkUnlocked(draft.kind);
  }

  final LevelDef level;
  final List<Junction> junctions;
  final List<Cable> cables;

  GamePhase _phase;
  // Belum berubah di langkah 2; langkah 4 (pasang/bongkar) membuatnya
  // non-final.
  final int _budget;
  CableKind _selectedCable;
  CableDraft? _draft;
  SimFrame? _frame;

  GamePhase get phase => _phase;

  /// Sisa anggaran.
  int get budget => _budget;
  CableKind get selectedCable => _selectedCable;
  CableDraft? get draft => _draft;
  SimFrame? get frame => _frame;

  /// Jaringan tetap selama langkah 2 (belum ada tarik/bongkar kabel).
  late final Network network = Network(level: level, cables: cables);

  Set<String> get connectedHouses => network.connectedHouses;
  int get connectedCount => connectedHouses.length;

  /// Biaya kabel yang sedang ditarik (belum dipotong dari [budget]).
  int get draftCost => _draft?.cost ?? 0;

  void selectCable(CableKind kind) {
    _checkUnlocked(kind);
    if (kind == _selectedCable) return;
    _selectedCable = kind;
    _draft = _draft?.withKind(kind);
    notifyListeners();
  }

  void setDraft(CableDraft? draft) {
    _expectPhase(GamePhase.design);
    if (draft != null) _checkUnlocked(draft.kind);
    _draft = draft;
    notifyListeners();
  }

  /// Rancang → jalan. Rumah tersambung mulai lancar dengan sabar penuh.
  void startDay() {
    _expectPhase(GamePhase.design);
    _phase = GamePhase.run;
    _draft = null;
    _frame = SimFrame(
      houses: {
        for (final id in connectedHouses)
          id: const HouseLive(state: HouseState.ok, patience: 1, usageMbps: 0),
      },
    );
    notifyListeners();
  }

  void updateFrame(SimFrame frame) {
    _expectPhase(GamePhase.run);
    _frame = frame;
    notifyListeners();
  }

  /// Jalan → hasil.
  void finishDay() {
    _expectPhase(GamePhase.run);
    _phase = GamePhase.result;
    notifyListeners();
  }

  void _expectPhase(GamePhase expected) {
    if (_phase != expected) {
      throw StateError('Butuh fase ${expected.name}, sekarang ${_phase.name}');
    }
  }

  void _checkUnlocked(CableKind kind) {
    if (!level.unlockedCables.any((s) => s.kind == kind)) {
      throw ArgumentError.value(
        kind,
        'kind',
        'belum terbuka di level ${level.number}',
      );
    }
  }
}
```

```dart
// lib/game/model/model.dart
export 'cable.dart';
export 'game_state.dart';
export 'level_def.dart';
export 'network.dart';
```

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: `flutter test test/game/model/` → PASS. `flutter analyze` → bersih.

- [ ] **Step 5: Commit**

```bash
git add lib/game/model/game_state.dart lib/game/model/model.dart test/game/model/game_state_test.dart
git commit -m "feat(model): game state with phases, cable choice and draft cost"
```

---

### Task 5: `SceneBuilder` + snapshot `DummyStates` + test kesetaraan

**Files:**
- Create: `lib/game/scene_builder.dart`, `lib/data/dummy_states.dart`
- Create (test): `test/game/legacy_scenes.dart` (salinan `DummyScenes`), `test/game/scene_matchers.dart`, `test/game/scene_builder_test.dart`

**Interfaces:**
- Consumes: Task 1–4; `MapScene`, `MapNode`, `MapCable`, `MapBadge` (`map_scene.dart`); `IdFormat` (`core/format.dart`).
- Produces: `abstract final class SceneBuilder { static const rightLabelOffset; static MapScene fromState(GameState) }`; `abstract final class DummyStates { static GameState tutorial(int step); static GameState design(CableKind kind); static GameState run(); static const queueOrder; static const queuePriority }`; test helper `List<String> describeScene(MapScene)`.

- [ ] **Step 1: Salin scene lama menjadi fixture test**

```bash
cp lib/data/dummy_scenes.dart test/game/legacy_scenes.dart
```

Lalu ubah `test/game/legacy_scenes.dart`:
1. Ganti impor jadi:
   ```dart
   import 'dart:ui';

   import 'package:busy_network/game/map_scene.dart';
   ```
   (hapus impor `format.dart` dan `dummy_data.dart`).
2. Ganti doc & nama kelas:
   ```dart
   /// Salinan `DummyScenes` sebelum langkah 2: acuan "tampil identik" untuk
   /// `SceneBuilder.fromState`. Jangan diubah kecuali visual memang berubah.
   abstract final class LegacyScenes {
   ```
3. Ganti badge:
   ```dart
      badges: const [MapBadge('Penuh! 25/20', Offset(262, 276))],
   ```
4. Ganti node Rumah 4 di `run()` menjadi `const` dengan label & sabar literal:
   ```dart
        // Desain: bar 7/40 tapi label "sabar 15%". Model menyimpan satu
        // nilai sabar (0,15), jadi bar menyusut 1 px (spec, keputusan 4).
        const MapNode(
          id: 'r4',
          kind: NodeKind.house,
          position: Offset(315, 240),
          label: 'Rumah 4 · sabar 15%',
          labelEmphasis: true,
          state: HouseState.jam,
          patience: 0.15,
          patiencePlacement: PatiencePlacement.above,
          alarm: true,
        ),
   ```
5. Jalankan `dart format test/game/legacy_scenes.dart`.

- [ ] **Step 2: Helper pembanding scene**

```dart
// test/game/scene_matchers.dart
import 'dart:ui';

import 'package:busy_network/game/map_scene.dart';

/// Uraian lengkap scene (urutan = urutan gambar) supaya selisihnya terbaca.
List<String> describeScene(MapScene s) => [
  'theme=${s.theme} size=${s.size} handle=${_o(s.dragHandle)}',
  for (final l in s.blockLabels) 'block ${l.text} ${_o(l.position)} ${l.align}',
  for (final c in s.cables)
    'cable ${c.points.map(_o).join(' ')} ${c.kind} ${c.state} '
        '${c.traffic} thick=${c.thick}',
  for (final b in s.badges) 'badge ${b.text} ${_o(b.center)} w=${b.width}',
  for (final n in s.nodes)
    'node ${n.id} ${n.kind} ${_o(n.position)} label=${n.label} '
        'offset=${_o(n.labelOffset)} ${n.labelAlign} emph=${n.labelEmphasis} '
        '${n.state} patience=${n.patience} ${n.patiencePlacement} '
        'alarm=${n.alarm} snap=${n.snapTarget} routerAlarm=${n.routerAlarm}',
];

String _o(Offset? o) => o == null ? 'null' : '(${o.dx}, ${o.dy})';
```

- [ ] **Step 3: Tulis test yang gagal**

```dart
// test/game/scene_builder_test.dart
import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/scene_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'legacy_scenes.dart';
import 'scene_matchers.dart';

void main() {
  void expectSame(GameState state, MapScene legacy) {
    expect(
      describeScene(SceneBuilder.fromState(state)),
      describeScene(legacy),
    );
  }

  group('identik dengan scene lama', () {
    test('tutorial langkah 1', () {
      expectSame(
        DummyStates.tutorial(1),
        LegacyScenes.tutorial(dragging: false, linked: false),
      );
    });

    test('tutorial langkah 2', () {
      expectSame(
        DummyStates.tutorial(2),
        LegacyScenes.tutorial(dragging: true, linked: false),
      );
    });

    test('tutorial langkah 3', () {
      expectSame(
        DummyStates.tutorial(3),
        LegacyScenes.tutorial(dragging: false, linked: true),
      );
    });

    for (final kind in CableKind.values) {
      test('fase rancang (${kind.name})', () {
        expectSame(DummyStates.design(kind), LegacyScenes.design(kind));
      });
    }

    test('fase rancang setelah ganti kabel', () {
      final state = DummyStates.design(CableKind.lan)
        ..selectCable(CableKind.fiber);
      expectSame(state, LegacyScenes.design(CableKind.fiber));
    });

    test('fase jalan', () {
      expectSame(DummyStates.run(), LegacyScenes.run());
    });
  });

  test('rancang tanpa draft: tanpa kabel putus-putus & jari', () {
    final scene = SceneBuilder.fromState(GameState(Levels.level5));
    expect(scene.dragHandle, isNull);
    expect(scene.cables.where((c) => c.state == CableState.drafting), isEmpty);
    expect(scene.nodes.where((n) => n.snapTarget), isEmpty);
  });

  test('awal hari: rumah tanpa data frame tampil polos, tanpa trafik', () {
    final state = DummyStates.design(CableKind.lan)..startDay();
    final scene = SceneBuilder.fromState(state);
    expect(scene.theme, MapTheme.night);
    expect(scene.dragHandle, isNull);
    expect(scene.badges, isEmpty);
    expect(scene.hasMotion, isFalse);
    final byId = {for (final n in scene.nodes) n.id: n};
    expect(byId['r1']!.state, HouseState.ok);
    expect(byId['r1']!.patience, 1);
    expect(byId['r5']!.state, HouseState.idle);
    expect(byId['r5']!.patience, isNull);
  });

  test('fase hasil digambar siang tanpa draft', () {
    final state = DummyStates.design(CableKind.lan)
      ..startDay()
      ..finishDay();
    final scene = SceneBuilder.fromState(state);
    expect(scene.theme, MapTheme.day);
    expect(scene.dragHandle, isNull);
  });
}
```

- [ ] **Step 4: Jalankan, pastikan gagal**

Run: `flutter test test/game/scene_builder_test.dart` → FAIL (`dummy_states.dart`, `scene_builder.dart` belum ada).

- [ ] **Step 5: Implementasi `SceneBuilder`**

```dart
// lib/game/scene_builder.dart
import 'dart:ui';

import '../core/format.dart';
import 'map_scene.dart';
import 'model/model.dart';

/// Menurunkan [MapScene] (yang digambar `MapRenderer`) dari [GameState].
abstract final class SceneBuilder {
  /// Label rumah di sisi kanan saat belum ada bar sabar (Warung, fase
  /// rancang).
  static const rightLabelOffset = Offset(44, 5);

  static MapScene fromState(GameState s) {
    final level = s.level;
    final run = s.phase == GamePhase.run;
    final frame = run ? s.frame : null;
    final draft = s.phase == GamePhase.design ? s.draft : null;
    final usage = frame?.usage ?? const <String, double>{};
    final net = s.network;
    final overloaded = {
      if (frame != null)
        for (final c in s.cables)
          if (net.isOverloaded(c, usage)) c.id,
    };
    // Kabel kelebihan beban digambar paling atas.
    final cables = [
      for (final c in s.cables)
        if (!overloaded.contains(c.id)) c,
      for (final c in s.cables)
        if (overloaded.contains(c.id)) c,
    ];

    return MapScene(
      theme: run ? MapTheme.night : MapTheme.day,
      blockLabels: run ? level.nightBlockLabels : level.blockLabels,
      cables: [
        for (final c in cables)
          _cable(c, net, usage, live: frame != null, full: overloaded.contains(c.id)),
        if (draft != null)
          MapCable(
            points: draft.points,
            kind: draft.kind,
            state: CableState.drafting,
          ),
      ],
      badges: [
        for (final c in cables)
          if (overloaded.contains(c.id))
            MapBadge(
              'Penuh! '
              '${IdFormat.ratio(net.cableLoad(c, usage), c.spec.capacityMbps)}',
              c.badgeCenter,
            ),
      ],
      nodes: [
        for (final j in s.junctions)
          MapNode(id: j.id, kind: NodeKind.junction, position: j.position),
        for (final h in level.houses)
          if (frame?.houses[h.id] case final live?)
            _liveHouse(h, live)
          else
            _plainHouse(
              h,
              frame == null && s.connectedHouses.contains(h.id)
                  ? HouseState.connected
                  : HouseState.idle,
              snapTarget: draft?.target == h.id,
            ),
        MapNode(
          id: LevelDef.routerId,
          kind: NodeKind.router,
          position: level.routerPosition,
          label: level.routerLabel,
          routerAlarm: overloaded.isNotEmpty,
        ),
      ],
      dragHandle: draft?.handle,
    );
  }

  static MapCable _cable(
    Cable c,
    Network net,
    Map<String, double> usage, {
    required bool live,
    required bool full,
  }) {
    final traffic = !live
        ? TrafficState.none
        : net.isJammed(c, usage)
        ? TrafficState.jam
        : net.cableLoad(c, usage) > 0
        ? TrafficState.flow
        : TrafficState.none;
    return MapCable(
      points: c.points,
      kind: c.kind,
      state: full ? CableState.overloaded : CableState.normal,
      traffic: traffic,
      thick: full && c.kind == CableKind.lan,
    );
  }

  /// Rumah tanpa data simulasi (fase rancang, atau belum tersambung).
  static MapNode _plainHouse(
    HouseDef h,
    HouseState state, {
    bool snapTarget = false,
  }) {
    final right = h.labelSide == MarkSide.right;
    return MapNode(
      id: h.id,
      kind: NodeKind.house,
      position: h.position,
      label: h.label,
      labelOffset: right ? rightLabelOffset : null,
      labelAlign: right ? TextAlign.left : TextAlign.center,
      state: state,
      snapTarget: snapTarget,
    );
  }

  static MapNode _liveHouse(HouseDef h, HouseLive live) {
    final jam = live.state == HouseState.jam;
    return MapNode(
      id: h.id,
      kind: NodeKind.house,
      position: h.position,
      label: jam
          ? '${h.label} · sabar '
                '${IdFormat.percent(live.patience, fraction: true)}'
          : h.label,
      labelAlign: h.patienceSide == MarkSide.right
          ? TextAlign.left
          : TextAlign.center,
      labelEmphasis: jam,
      state: live.state,
      patience: live.patience,
      patiencePlacement: switch (h.patienceSide) {
        MarkSide.below => PatiencePlacement.below,
        MarkSide.right => PatiencePlacement.right,
        MarkSide.above => PatiencePlacement.above,
      },
      alarm: jam,
    );
  }
}
```

Catatan: `if (frame?.houses[h.id] case final live?)` adalah if-case di collection (Dart 3). Bila analyzer menolak, ganti dengan helper `static MapNode _house(HouseDef h, GameState s, SimFrame? frame, CableDraft? draft)` yang memakai `final live = frame?.houses[h.id]; if (live != null) return _liveHouse(h, live); return _plainHouse(...)`.

- [ ] **Step 6: Implementasi `DummyStates`**

```dart
// lib/data/dummy_states.dart
import 'dart:ui';

import '../game/levels/levels.dart';
import '../game/map_scene.dart';
import '../game/model/model.dart';

/// Snapshot [GameState] per layar, pengganti peta statis. Diganti state
/// game asli di langkah 4 (tarik kabel) dan 5 (simulasi). Koordinat persis
/// dari desain.
abstract final class DummyStates {
  // ── Tutorial level 1 ──────────────────────────────────────────────────
  static const _tutorialCable = [Offset(105, 315), Offset(255, 165)];

  /// Langkah 1 polos, 2 kabel dipandu (tanpa jari, tangan tutorial yang
  /// jadi jarinya), 3 Rumah 1 tersambung. Snapshot belum memotong biaya:
  /// desain tetap menampilkan Rp 200.000.
  static GameState tutorial(int step) {
    assert(step >= 1 && step <= 3, 'langkah tutorial 1..3');
    return switch (step) {
      1 => GameState(Levels.level1),
      2 => GameState(
        Levels.level1,
        draft: const CableDraft(
          from: LevelDef.routerId,
          kind: CableKind.lan,
          points: _tutorialCable,
        ),
      ),
      _ => GameState(
        Levels.level1,
        cables: const [
          Cable(
            id: 'c-r1',
            from: LevelDef.routerId,
            to: 'r1',
            points: _tutorialCable,
          ),
        ],
      ),
    };
  }

  // ── Gang Melati (level 5) ─────────────────────────────────────────────
  /// Fase rancang: sedang menarik kabel [kind] dari router ke Rumah 5.
  static GameState design(CableKind kind) => GameState(
    Levels.level5,
    selectedCable: kind,
    draft: CableDraft(
      from: LevelDef.routerId,
      kind: kind,
      points: const [Offset(195, 264), Offset(195, 300), Offset(255, 360)],
      target: 'r5',
      handle: const Offset(255, 360),
    ),
  );

  /// Fase jalan, jam sibuk: kabel Router → Rumah 4 penuh (16 + 9 Mbps).
  static GameState run() {
    const level = Levels.level5;
    Cable initial(String id) => level.cables.firstWhere((c) => c.id == id);
    HouseLive live(String id, HouseState state, double patience) => HouseLive(
      state: state,
      patience: patience,
      usageMbps: level.house(id).peakMbps,
    );
    return GameState(
      level,
      phase: GamePhase.run,
      junctions: [
        ...level.junctions,
        const Junction(id: 'j2', position: Offset(195, 330)),
      ],
      cables: [
        initial('c-r1'),
        initial('c-r3'),
        const Cable(
          id: 'c-r6',
          from: LevelDef.routerId,
          to: 'r6',
          via: ['j2'],
          points: [Offset(195, 264), Offset(195, 400)],
        ),
        const Cable(
          id: 'c-r7',
          from: 'j2',
          to: 'r7',
          points: [Offset(195, 330), Offset(95, 330)],
        ),
        const Cable(
          id: 'c-r5',
          from: 'r4',
          to: 'r5',
          points: [Offset(315, 260), Offset(315, 370)],
        ),
        initial('c-w'),
        initial('c-r4'),
      ],
      frame: SimFrame(
        houses: {
          'r1': live('r1', HouseState.ok, 36 / 40),
          'w': live('w', HouseState.ok, 34 / 40),
          'r3': live('r3', HouseState.slow, 22 / 40),
          // Desain: bar 7/40 tapi label "sabar 15%"; model memakai 15%.
          'r4': live('r4', HouseState.jam, 0.15),
          'r5': live('r5', HouseState.slow, 16 / 40),
          'r6': live('r6', HouseState.ok, 32 / 40),
          'r7': live('r7', HouseState.ok, 30 / 40),
        },
      ),
    );
  }

  // ── Panel antrean ─────────────────────────────────────────────────────
  /// Urutan kartu di panel antrean (desain).
  static const queueOrder = ['r4', 'r5', 'r3', 'w', 'r1', 'r6', 'r7'];

  /// Rumah yang diprioritaskan saat panel dibuka.
  static const queuePriority = {'w'};
}
```

- [ ] **Step 7: Validasi snapshot jalan dengan helper kabel**

Tambahkan ke `test/game/scene_builder_test.dart` (di dalam `main`), plus impor `'model/cable_checks.dart'` dan `package:busy_network/game/levels/levels.dart` (sudah ada):

```dart
  test('kabel snapshot jalan sah', () {
    final state = DummyStates.run();
    final positions = {
      for (final j in state.junctions) j.id: j.position,
    };
    Offset positionOf(String id) =>
        positions[id] ?? state.level.positionOf(id);
    for (final c in state.cables) {
      expectValidCable(state.level, c, positionOf);
    }
  });
```
(tambahkan `import 'dart:ui';` di file test).

- [ ] **Step 8: Jalankan, pastikan lulus**

Run: `flutter test test/game/` → PASS (termasuk `map_motion_test.dart` lama). `flutter analyze` → bersih.

Bila test kesetaraan gagal, baca selisih baris `describeScene` dan perbaiki `SceneBuilder`/`DummyStates`, **bukan** `legacy_scenes.dart`.

- [ ] **Step 9: Commit**

```bash
git add lib/game/scene_builder.dart lib/data/dummy_states.dart test/game/legacy_scenes.dart test/game/scene_matchers.dart test/game/scene_builder_test.dart
git commit -m "feat(game): derive map scenes from game state, matching old scenes"
```

---

### Task 6: Tutorial, Rancang, Jalan memakai `GameState`

**Files:**
- Modify: `lib/screens/tutorial/tutorial_screen.dart`, `lib/screens/design_phase/design_phase_screen.dart`, `lib/screens/run_phase/run_phase_screen.dart`, `lib/data/dummy_data.dart` (tambah `complaintHouseId`), `test/game/map_motion_test.dart`
- Delete: `lib/data/dummy_scenes.dart`

**Interfaces:**
- Consumes: `DummyStates`, `SceneBuilder.fromState`, `GameState`, `CableSpec`, `Levels`.
- Produces: `DummyData.complaintHouseId = 'r4'`.

Test pengaman: `test/screens/screen_state_test.dart` ("Rp 850.000", "−Rp 45.000 sedang ditarik", "3 segmen · Rp 45.000", versi fiber Rp 180.000) dan `test/screens/navigation_test.dart` ("0/2" → "1/2 rumah tersambung") sudah ada dan harus tetap hijau.

- [ ] **Step 1: Tutorial**

Di `tutorial_screen.dart`:
- Impor: hapus `../../data/dummy_data.dart` dan `../../data/dummy_scenes.dart`; tambah
  ```dart
  import '../../data/dummy_states.dart';
  import '../../game/model/model.dart';
  import '../../game/scene_builder.dart';
  ```
  (`../../game/map_scene.dart` tetap, dipakai `CableKind`).
- Ganti `bool get _linked => _step == 3;` dan `_next` menjadi:
  ```dart
  late GameState _game = DummyStates.tutorial(_step);

  void _next() => setState(() {
    _step = (_step + 1).clamp(1, 3);
    _game.dispose();
    _game = DummyStates.tutorial(_step);
  });

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }
  ```
- Di `build`: ganti `const level = DummyData.level1;` / `const lan = DummyData.lan;` dengan
  ```dart
  final level = _game.level;
  const lan = CableSpec.lan;
  const fiber = CableSpec.fiber;
  ```
- Header: `value: IdFormat.rupiah(level.budget)` → `value: IdFormat.rupiah(_game.budget)`.
- Peta: `scene: DummyScenes.tutorial(dragging: _step == 2, linked: _linked)` → `scene: SceneBuilder.fromState(_game)`.
- Hitungan: `'${_linked ? 1 : 0}/${level.housesTotal} rumah '` → `'${_game.connectedCount}/${level.houses.length} rumah '`.
- Kartu fiber: `name: DummyData.fiber.name` → `name: fiber.name`; `'${DummyData.fiberUnlockLevel}'` → `'${fiber.unlockLevel}'`.

- [ ] **Step 2: Fase Rancang**

Di `design_phase_screen.dart`:
- Impor: hapus `dummy_data.dart`, `dummy_scenes.dart`; tambah `../../data/dummy_states.dart`, `../../game/model/model.dart`, `../../game/scene_builder.dart`.
- Ganti isi `_DesignPhaseScreenState` sebelum `build`:
  ```dart
  late final GameState _game = DummyStates.design(widget.initialCable);
  bool _erase = false;

  @override
  void initState() {
    super.initState();
    _game.addListener(_onGameChanged);
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  void _onGameChanged() => setState(() {});

  void _pick(CableKind kind) {
    setState(() => _erase = false);
    _game.selectCable(kind);
  }
  ```
- Awal `build`: ganti `const level = DummyData.level5;` dengan
  ```dart
  final level = _game.level;
  final draft = _game.draft;
  final cost = _game.draftCost;
  final connected = _game.connectedCount;
  ```
- Header sisa anggaran:
  ```dart
  HeaderStat(
    label: 'Sisa anggaran',
    value: IdFormat.rupiah(_game.budget),
    note: draft == null
        ? null
        : '${IdFormat.rupiah(-cost)} sedang ditarik',
    noteColor: AppColors.warningStrong,
  ),
  ```
- Peta:
  ```dart
  scene: SceneBuilder.fromState(_game),
  semanticLabel:
      'Peta ${level.name}: router pusat, '
      '$connected rumah tersambung, '
      '${level.houses.length - connected} belum',
  overlays: [
    if (draft != null)
      Positioned(
        left: 222,
        top: 288,
        child: _CostTooltip(
          color: MapRenderer.cableColor(draft.kind, MapTheme.day),
          label: '${draft.segments} segmen · ${IdFormat.rupiah(cost)}',
        ),
      ),
  ],
  ```
- `'${level.housesConnected}/${level.housesTotal} '` → `'$connected/${level.houses.length} '`.
- Kartu: `for (final spec in const [DummyData.lan, DummyData.fiber]) ...[` → `for (final spec in level.unlockedCables) ...[`; `selected: _cable == spec.kind` → `selected: _game.selectedCable == spec.kind`.
- Hapus `_cable`, `_spec`, `_draftCost` lama.

- [ ] **Step 3: Fase Jalan**

Di `dummy_data.dart` tambahkan (biarkan `complaintName`/`complaintHouse` dulu, dihapus di Task 7):
```dart
  /// Rumah yang komplain (nama & label diambil dari definisi level).
  static const complaintHouseId = 'r4';
```

Ganti `run_phase_screen.dart` menjadi `StatefulWidget`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../data/dummy_data.dart';
import '../../data/dummy_states.dart';
import '../../game/model/model.dart';
import '../../game/scene_builder.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'complaint_popup.dart';
import 'run_status_card.dart';

/// 5 · Fase Jalan – Level 5, jam sibuk.
class RunPhaseScreen extends StatefulWidget {
  const RunPhaseScreen({super.key});

  @override
  State<RunPhaseScreen> createState() => _RunPhaseScreenState();
}

class _RunPhaseScreenState extends State<RunPhaseScreen> {
  final GameState _game = DummyStates.run();

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complainer = _game.level.house(DummyData.complaintHouseId);
    return Scaffold(
      // … isi lama tidak berubah, kecuali dua bagian di bawah …
    );
  }
}
```
Di dalam isi lama: `scene: DummyScenes.run()` → `scene: SceneBuilder.fromState(_game)`; `name: DummyData.complaintName` → `name: complainer.customer`; `house: DummyData.complaintHouse` → `house: complainer.label`.

- [ ] **Step 4: Hapus `dummy_scenes.dart` & perbarui `map_motion_test.dart`**

```bash
git rm lib/data/dummy_scenes.dart
```
Di `test/game/map_motion_test.dart`: ganti impor `package:busy_network/data/dummy_scenes.dart` dengan
```dart
import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/scene_builder.dart';
```
lalu `DummyScenes.run()` → `SceneBuilder.fromState(DummyStates.run())` (2×) dan `DummyScenes.tutorial(dragging: false, linked: true)` → `SceneBuilder.fromState(DummyStates.tutorial(3))`.

Cek tidak ada sisa: `grep -rn "DummyScenes\|dummy_scenes" lib test` hanya menyisakan `test/game/legacy_scenes.dart` (komentar).

- [ ] **Step 5: Verifikasi**

Run: `flutter analyze` → bersih. `flutter test` → hijau (127 + test baru; ~25 skip).

- [ ] **Step 6: Commit**

```bash
git add -A lib/screens/tutorial lib/screens/design_phase lib/screens/run_phase lib/data test/game/map_motion_test.dart
git commit -m "refactor(screens): tutorial, design and run phases draw from game state"
```

---

### Task 7: Antrean, Peta Babak, Hasil membaca model; bersihkan `DummyData`

**Files:**
- Modify: `lib/screens/queue_panel/queue_logic.dart`, `lib/screens/queue_panel/queue_panel_screen.dart`, `lib/screens/run_phase/run_status_card.dart`, `lib/screens/level_map/level_map_screen.dart`, `lib/screens/result_fail/result_fail_screen.dart`, `lib/screens/result_success/result_success_screen.dart`, `lib/screens/result_success/result_success_data.dart`, `lib/data/dummy_data.dart`
- Test: `test/core/queue_logic_test.dart`

**Interfaces:**
- Consumes: `GameState`, `Network`, `DummyStates.run/queueOrder/queuePriority`, `Levels.level5`.
- Produces: `QueueHouse` (pindah ke `queue_logic.dart`, tanpa `initiallyPrioritized`); `QueueModel.fromState(GameState, {required List<String> order, required Set<String> priority})`; field `QueueModel.cableLabel`.

- [ ] **Step 1: Tulis test yang gagal**

Tambahkan ke `test/core/queue_logic_test.dart` (impor `package:busy_network/data/dummy_states.dart`, `package:busy_network/game/map_scene.dart`, `package:busy_network/game/model/model.dart`, `package:busy_network/game/levels/levels.dart`):

```dart
  group('QueueModel.fromState', () {
    test('diturunkan dari snapshot fase jalan', () {
      final m = QueueModel.initial();
      expect(m.cableLabel, 'Kabel Router → Rumah 4');
      expect(m.capacityMbps, 20);
      expect(m.houses.map((h) => h.id).toList(), DummyStates.queueOrder);
      expect(
        {for (final h in m.houses) if (h.onOverloadedCable) h.id},
        {'r4', 'r5'},
      );
      final w = m.houses.firstWhere((h) => h.id == 'w');
      expect(w.name, 'Warung Bu Ijah');
      expect(w.where, 'Blok A');
      expect(w.packageMbps, 20);
      expect(w.usageMbps, 12);
      expect(m.limits['w'], 20);
    });

    test('tanpa kabel penuh: pakai kabel dengan rasio beban tertinggi', () {
      final state = GameState(
        Levels.level5,
        phase: GamePhase.run,
        frame: const SimFrame(
          houses: {
            'r4': HouseLive(state: HouseState.ok, patience: 1, usageMbps: 10),
            'r1': HouseLive(state: HouseState.ok, patience: 1, usageMbps: 4),
          },
        ),
      );
      final m = QueueModel.fromState(
        state,
        order: const ['r4', 'r1'],
        priority: const {},
      );
      expect(m.cableLabel, 'Kabel Router → Rumah 4');
      expect(m.overloaded, isFalse);
    });

    test('ubah batas mempertahankan judul kabel', () {
      final m = QueueModel.initial().withLimit('r4', 8).togglePriority('r1');
      expect(m.cableLabel, 'Kabel Router → Rumah 4');
    });
  });
```

Run: `flutter test test/core/queue_logic_test.dart` → FAIL (`cableLabel`/`fromState` belum ada).

- [ ] **Step 2: Implementasi `queue_logic.dart`**

Ganti bagian atas file (impor, `QueueHouse`, konstruktor, factory) menjadi:

```dart
import '../../data/dummy_states.dart';
import '../../game/model/model.dart';
import '../../widgets/status_dot.dart';

/// Satu rumah di panel antrean.
class QueueHouse {
  const QueueHouse({
    required this.id,
    required this.name,
    required this.where,
    required this.packageMbps,
    required this.usageMbps,
    required this.initialLimit,
    this.onOverloadedCable = false,
  });

  final String id;
  final String name;
  final String where;
  final int packageMbps;
  final double usageMbps;
  final int initialLimit;

  /// Rumah yang lewat kabel yang disorot panel.
  final bool onOverloadedCable;
}

/// Hitungan panel antrean (port dari logika prototipe HTML).
///
/// Murni & tanpa Flutter supaya mudah dites dan nanti dipindah ke
/// simulasi game.
class QueueModel {
  const QueueModel({
    required this.houses,
    required this.limits,
    required this.priority,
    required this.capacityMbps,
    required this.cableLabel,
  });

  factory QueueModel.initial() => QueueModel.fromState(
    DummyStates.run(),
    order: DummyStates.queueOrder,
    priority: DummyStates.queuePriority,
  );

  /// Panel untuk kabel paling sesak (rasio beban/kapasitas tertinggi) di
  /// fase jalan; rumah ditampilkan sesuai [order].
  factory QueueModel.fromState(
    GameState state, {
    required List<String> order,
    required Set<String> priority,
  }) {
    final usage = state.frame?.usage ?? const <String, double>{};
    final net = state.network;
    double ratio(Cable c) => net.cableLoad(c, usage) / c.spec.capacityMbps;
    final cable = state.cables.reduce((a, b) => ratio(b) > ratio(a) ? b : a);
    final served = net.housesBelow(cable.stops[1]);
    final level = state.level;
    String name(String id) =>
        id == LevelDef.routerId ? 'Router' : level.house(id).label;
    final houses = [
      for (final id in order)
        QueueHouse(
          id: id,
          name: level.house(id).customer,
          where: level.house(id).place,
          packageMbps: level.house(id).packageMbps,
          usageMbps: usage[id] ?? 0,
          initialLimit: level.house(id).packageMbps,
          onOverloadedCable: served.contains(id),
        ),
    ];
    return QueueModel(
      houses: houses,
      limits: {for (final h in houses) h.id: h.initialLimit},
      priority: {...priority},
      capacityMbps: cable.spec.capacityMbps,
      cableLabel: 'Kabel ${name(cable.from)} → ${name(cable.to)}',
    );
  }

  final List<QueueHouse> houses;
  final Map<String, int> limits;
  final Set<String> priority;
  final int capacityMbps;

  /// "Kabel Router → Rumah 4".
  final String cableLabel;
```

Lalu di `withLimit` dan `togglePriority` tambahkan `cableLabel: cableLabel,`. Sisa file (`effectiveUse`, `load`, `overloaded`, `tight`, `statusOf`) tidak berubah.

Catatan: `reduce` memilih kabel pertama bila rasio sama (mis. semua 0). `name()` hanya mengenal router & rumah; kabel yang berpangkal di junction belum pernah disorot di langkah 2 (langkah 5 menggeneralisasi).

- [ ] **Step 3: Layar antrean**

Di `queue_panel_screen.dart`: `DummyData.queueCableLabel` → `m.cableLabel`. Impor `dummy_data.dart` tetap (dipakai `runClockMinutes`).

- [ ] **Step 4: Ganti `DummyData.level5` dengan `Levels.level5`**

Tambahkan `import '../../game/levels/levels.dart';` di tiap file berikut, lalu:
- `run_status_card.dart`: `const level = DummyData.level5;` → `const level = Levels.level5;` (2×).
- `level_map_screen.dart`: `DummyData.level5.name` → `Levels.level5.name` (2×).
- `result_fail_screen.dart`, `result_success_screen.dart`: `const level = DummyData.level5;` → `const level = Levels.level5;`.
- `result_success_data.dart`: `DummyData.level5.targetSatisfaction` → `Levels.level5.targetSatisfaction`.

Hapus impor `dummy_data.dart` di file yang tidak lagi memakainya (analyzer menandai `unused_import`).

- [ ] **Step 5: Bersihkan `DummyData`**

Di `lib/data/dummy_data.dart` hapus: impor `../game/map_scene.dart`, kelas `CableSpec`, `LevelInfo`, `QueueHouse`; konstanta `lan`, `fiber`, `fiberUnlockLevel`, `level1`, `level5`, `draftingSegments`, `overloadedLoad`, `overloadedCapacity`, `overloadedHousePatience`, `complaintName`, `complaintHouse`, `queueCableLabel`, `queueHouses`, dan header bagian "Panel atur antrean". Yang tersisa: `ChapterInfo`, `chapter`, `dayStartHour`, `dayEndHour`, `runClockMinutes`, `runSatisfaction`, `complaintHouseId`, `complaintClockMinutes`, `complaintMessage`, `savingsTarget`, `failSatisfaction`, `failComplaints`, `failHousesLost`. Perbarui doc library:

```dart
/// Data dummy untuk layar yang belum punya logika game: progres babak,
/// jam & kepuasan fase jalan, komplain, dan angka hasil. Level & jaringan
/// ada di `lib/game/`; snapshot state ada di `dummy_states.dart`.
library;
```

- [ ] **Step 6: Verifikasi**

Run: `grep -rn "DummyData\.\(level\|lan\|fiber\|queue\|overloaded\|drafting\|complaintName\|complaintHouse\b\)" lib test` → kosong.
Run: `flutter analyze` → bersih. `flutter test` → hijau.

- [ ] **Step 7: Commit**

```bash
git add -A lib test/core/queue_logic_test.dart
git commit -m "refactor: queue, level map and results read level definitions"
```

---

### Task 8: Verifikasi visual & dokumentasi

**Files:**
- Modify: `CLAUDE.md`, `docs/DESIGN_NOTES.md`

- [ ] **Step 1: Bandingkan screenshot dengan baseline**

```bash
flutter test test/screenshots --dart-define=SCREENSHOTS=true
cd build/screenshots && for f in */*.png; do cmp -s "$f" "$SCRATCHPAD/baseline/$f" || echo "BEDA: $f"; done
```
Expected: hanya PNG Fase Jalan (`05-*`) yang beda. Untuk file itu, ukur selisihnya dengan Python (PIL bila ada) atau buka keduanya dan pastikan bedanya hanya bar sabar Rumah 4 (lebar 7 → 6 px desain). Bila PNG lain beda, cari penyebabnya sebelum lanjut.

- [ ] **Step 2: Perbarui `CLAUDE.md`**

Di bagian Struktur, ganti butir `lib/game/` dan `lib/data/` menjadi:
```markdown
- `lib/game/` — `model/` (`LevelDef`, `HouseDef`, `Cable`/`CableSpec`/
  `CableDraft`, `Network` topologi & beban, `GameState` fase
  rancang/jalan/hasil), `levels/levels.dart` (data level), 
  `scene_builder.dart` (`SceneBuilder.fromState(state)` → `MapScene`),
  `map_scene.dart` (model gambar) dan `render/map_renderer.dart` (gambar
  rumah/router/kabel/trafik di atas `Canvas`; dipakai CustomPainter
  sekarang, dan bisa dipanggil dari `render()` komponen Flame).
- `lib/data/` — `dummy_states.dart` (snapshot `GameState` per layar) dan
  `dummy_data.dart` (angka yang belum dihitung game: progres, jam,
  komplain, hasil).
```
Tambahkan di Aturan:
```markdown
- Peta digambar dari state: ubah data level / `GameState`, bukan
  `MapScene` langsung. `test/game/scene_builder_test.dart` menjaga snapshot
  tetap identik dengan desain.
```

- [ ] **Step 3: Perbarui `docs/DESIGN_NOTES.md`**

Tambahkan butir di "Asumsi yang diambil":
```markdown
- **Level 5 sudah punya jaringan** saat dimulai (Rumah 1, Warung, Rumah 3,
  Rumah 4 + junction atas); Rp 850.000 = sisa untuk memperluas.
- **Grid level 5 bergeser 15 px vertikal** dari titik grid yang digambar
  (node di y = 60, 90, 240, …). `LevelDef.gridOrigin` mencatatnya; snap
  kabel (langkah 4) harus ke grid level.
- **Segmen kabel** = panjang dalam langkah grid 30 px (diagonal = 1),
  dibulatkan: kabel yang sedang ditarik di desain = 3 segmen.
- **Bar sabar Rumah 4** di Fase Jalan memakai 15% (sesuai label), bukan
  7/40 seperti gambar desain (beda 1 px).
- **Pelanggan/paket Rumah 1–2 level 1** belum ada di desain; nilainya
  sementara.
```

- [ ] **Step 4: Verifikasi akhir & commit**

Run: `flutter analyze` → bersih. `flutter test` → hijau.

```bash
git add CLAUDE.md docs/DESIGN_NOTES.md
git commit -m "docs: describe level model, game state and scene builder"
```
