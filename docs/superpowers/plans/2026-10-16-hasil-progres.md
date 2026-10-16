# Hasil, Bintang & Progres — Rencana Implementasi

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Akhir hari menghasilkan hasil level yang dihitung (bintang, biang kerok, rumah pindah), progres bintang tersimpan dengan `shared_preferences`, dan Beranda/Peta membaca progres asli.

**Architecture:** `DaySim` mencatat statistik hari; `LevelResult` (murni) menurunkan bintang & biang kerok dari `GameState` yang sudah 24:00; `Progress` (murni) = bintang terbaik per level, disimpan lewat `ProgressStore` dan dipegang `ProgressBook` (`ChangeNotifier`) di dalam `GameSession`. Layar hasil membaca `session.result` atau potret desain (`DummyData`) untuk deep link.

**Tech Stack:** Flutter, Dart 3, go_router, `shared_preferences` (`SharedPreferencesWithCache`), flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-16-hasil-progres-design.md`

## Global Constraints

- Jangan hardcode warna/ukuran di widget; koordinat peta/ilustrasi desain boleh sebagai data.
- Angka selalu lewat `IdFormat` (`Rp 850.000`, `75%`, `19:00`).
- Copy Bahasa Indonesia persis desain; jangan `ellipsis`.
- Bebas overflow 360 px; daftar rute `overflow_test` & `screenshots` tidak berubah.
- Tombol/kontrol kustom: `Semantics(container: true, button: true, label: ...)`.
- Logika di `lib/game/` murni (tanpa widget), dites tanpa Flutter.
- `flutter analyze` bersih, `flutter test` hijau di akhir tiap task.
- Commit kecil per task, pesan bahasa Inggris (`feat(scope): ...`).

## Review Focus

1. Data progres di perangkat rusak / tipe lain / versi lain → progres awal, aplikasi tidak crash (Task 5).
2. Menang ulang dengan bintang lebih sedikit atau gagal → bintang tersimpan tidak turun (Task 4, Task 6).
3. Hari potret (deep link, tutorial) dimainkan sampai 24:00 → hasil tampil tapi bintang tidak dicatat (Task 6).
4. `finish()` dipanggil dua kali untuk hari yang sama → dicatat sekali, hasil yang sama (Task 6).
5. Semua level 1–11 selesai (level sekarang = 12) → Peta tetap tampil tanpa node berdenyut, jalur lengkap (Task 8).

---

### Task 1: Data level — batas lulus, hemat, blok, babak

**Files:**
- Modify: `lib/game/model/level_def.dart`
- Modify: `lib/game/levels/levels.dart`
- Modify: `lib/game/model/network.dart`
- Test: `test/game/model/level_def_test.dart`, `test/game/model/network_test.dart`

**Interfaces:**
- Produces: `HouseDef.block` (`String?`), `LevelDef.passSatisfaction` (`int`, required), `LevelDef.savingsTarget` (`int`, default `LevelDef.defaultSavingsTarget = 200000`), `ChapterDef {number, name, levelCount, starsTotal}`, `Levels.chapter`, `Levels.byNumber(int) → LevelDef?`, `Network.cables` (`List<Cable>`, urutan pemasangan).

- [ ] **Step 1: Test gagal** — tambah di `level_def_test.dart`:

```dart
  group('aturan lulus, blok & babak', () {
    test('batas lulus di bawah target; hemat default Rp 200.000', () {
      expect(Levels.level5.passSatisfaction, 60);
      expect(Levels.level5.targetSatisfaction, 80);
      expect(Levels.level1.passSatisfaction, 40);
      expect(Levels.level5.savingsTarget, LevelDef.defaultSavingsTarget);
      expect(LevelDef.defaultSavingsTarget, 200000);
    });

    test('blok rumah level 5', () {
      expect({for (final h in Levels.level5.houses) h.id: h.block}, {
        'r1': 'Blok A',
        'w': 'Blok A',
        'r3': 'Blok A',
        'r4': 'Blok B',
        'r5': 'Blok B',
        'r6': 'Blok C',
        'r7': 'Blok C',
      });
      expect(Levels.level1.house('r1').block, 'Blok A');
      expect(Levels.level1.house('r2').block, isNull);
    });

    test('byNumber: hanya level yang ada datanya', () {
      expect(Levels.byNumber(1), same(Levels.level1));
      expect(Levels.byNumber(5), same(Levels.level5));
      expect(Levels.byNumber(6), isNull);
      expect(Levels.byNumber(0), isNull);
    });

    test('babak 1: 12 level, 36 bintang', () {
      expect(Levels.chapter.number, 1);
      expect(Levels.chapter.name, 'Perumahan Batam');
      expect(Levels.chapter.levelCount, 12);
      expect(Levels.chapter.starsTotal, 36);
    });
  });
```

Di `network_test.dart`:

```dart
  test('cables: semua kabel terpasang, urutan pemasangan', () {
    final net = Network(level: Levels.level5, cables: designCables);
    expect(net.cables, designCables);
  });
```

- [ ] **Step 2:** `flutter test test/game/model` → FAIL (getter belum ada).
- [ ] **Step 3: Implementasi.** `HouseDef`: parameter `this.block,` setelah `customer`, field:

```dart
  /// Blok tempat rumah ini ("Blok B"): nama area kabel di biang kerok.
  /// `null` bila desain tidak menaruhnya di blok mana pun.
  final String? block;
```

`LevelDef`: parameter `required this.passSatisfaction, this.savingsTarget = defaultSavingsTarget,` setelah `targetSatisfaction`, lalu:

```dart
  /// Sisa anggaran minimal untuk bintang 3 bila level tidak menentukannya.
  static const defaultSavingsTarget = 200000;

  /// Kepuasan akhir minimal supaya lulus (1 bintang); di bawahnya gagal.
  final int passSatisfaction;

  /// Sisa anggaran minimal untuk bintang 3 (selain kepuasan ≥ target).
  final int savingsTarget;
```

Kelas baru di `level_def.dart`:

```dart
/// Satu babak di Peta Babak.
class ChapterDef {
  const ChapterDef({
    required this.number,
    required this.name,
    required this.levelCount,
  });

  final int number;
  final String name;

  /// Jumlah level termasuk level bos.
  final int levelCount;

  /// Bintang maksimal: 3 per level.
  int get starsTotal => levelCount * 3;
}
```

`levels.dart`: level 1 `passSatisfaction: 40`, Rumah 1 `block: 'Blok A'`; level 5 `passSatisfaction: 60`, blok sesuai test. Tambah:

```dart
  static const chapter = ChapterDef(
    number: 1,
    name: 'Perumahan Batam',
    levelCount: 12,
  );

  /// Level bernomor [number]; `null` bila datanya belum ada (langkah 8).
  static LevelDef? byNumber(int number) {
    for (final level in all) {
      if (level.number == number) return level;
    }
    return null;
  }
```

`Network`: initializer `cables = List.unmodifiable(cables),` dan field `/// Kabel terpasang, urutan pemasangan. final List<Cable> cables;`.

- [ ] **Step 4:** `flutter test test/game` → PASS; `flutter analyze` bersih.
- [ ] **Step 5:** `git commit -m "feat(game): pass threshold, savings target, house blocks and chapter data"`

---

### Task 2: Statistik hari di `DaySim`

**Files:**
- Modify: `lib/game/sim/day_sim.dart`
- Test: `test/game/sim/day_sim_test.dart`

**Interfaces:**
- Consumes: `Network.cables` (Task 1).
- Produces: `DaySim.fullMinutes(String cableId) → int`, `DaySim.firstFullMinute(String) → int?`, `DaySim.peakMinute(String) → int?`, `DaySim.exhausted → Set<String>`.

- [ ] **Step 1: Test gagal** — grup baru di `day_sim_test.dart`:

```dart
  group('statistik hari', () {
    test('jaringan desain: kabel Rumah 4 penuh 258 menit mulai 18:17, '
        'terparah 19:00; sabar Rumah 4 & 5 sempat habis', () {
      final sim = _sim(designCables);
      _playDay(sim);
      expect(sim.fullMinutes('c-r4'), 258);
      expect(sim.firstFullMinute('c-r4'), 18 * 60 + 17);
      expect(sim.peakMinute('c-r4'), 19 * 60);
      for (final c in designCables.where((c) => c.id != 'c-r4')) {
        expect(sim.fullMinutes(c.id), 0, reason: c.id);
        expect(sim.firstFullMinute(c.id), isNull, reason: c.id);
        expect(sim.peakMinute(c.id), isNull, reason: c.id);
      }
      expect(sim.exhausted, {'r4', 'r5'});
    });

    test('kabel Rumah 4 fiber: tidak ada yang penuh atau habis sabar', () {
      final sim = _sim(designFiberCables);
      _playDay(sim);
      for (final c in designFiberCables) {
        expect(sim.fullMinutes(c.id), 0, reason: c.id);
      }
      expect(sim.exhausted, isEmpty);
    });

    test('sabar 0% dari potret langsung tercatat habis', () {
      final sim = _sim(designCables, minute: 20 * 60, patience: {'r7': 0});
      expect(sim.exhausted, {'r7'});
    });

    test('tidak bertambah selama hari dijeda komplain', () {
      final sim = _sim(
        designCables,
        minute: 20 * 60,
        complaint: const Complaint(houseId: 'r4', minute: 20 * 60),
      );
      sim.advance(30);
      expect(sim.fullMinutes('c-r4'), 0);
    });
  });
```

- [ ] **Step 2:** `flutter test test/game/sim/day_sim_test.dart` → FAIL.
- [ ] **Step 3: Implementasi.** Field baru:

```dart
  final _fullMinutes = <String, int>{};
  final _firstFull = <String, int>{};
  final _peak = <String, ({double ratio, int minute})>{};
  final _exhausted = <String>{};
```

Di akhir body konstruktor: `_recordExhausted();`. Di `_step()` setelah `_frame = _assess(...)`: `_recordStats();` lalu `_raiseComplaint();`. Getter & bantuan:

```dart
  /// Menit kabel [cableId] penuh (badge "Penuh!") sepanjang hari.
  int fullMinutes(String cableId) => _fullMinutes[cableId] ?? 0;

  /// Menit pertama kabel [cableId] penuh; `null` bila tidak pernah.
  int? firstFullMinute(String cableId) => _firstFull[cableId];

  /// Menit pertama beban kabel [cableId] paling berat (beban/kapasitas)
  /// selama penuh; `null` bila tidak pernah penuh.
  int? peakMinute(String cableId) => _peak[cableId]?.minute;

  /// Rumah tersambung yang sabarnya sempat habis (0%).
  Set<String> get exhausted => Set.unmodifiable(_exhausted);

  /// Catat kabel penuh & sabar habis pada menit [_minute].
  void _recordStats() {
    final demand = _frame.demand;
    for (final cable in network.cables) {
      if (!network.isOverloaded(cable, demand)) continue;
      _fullMinutes[cable.id] = fullMinutes(cable.id) + 1;
      _firstFull[cable.id] ??= _minute;
      final ratio = network.cableLoad(cable, demand) / cable.spec.capacityMbps;
      final peak = _peak[cable.id];
      if (peak == null || ratio > peak.ratio + 1e-9) {
        _peak[cable.id] = (ratio: ratio, minute: _minute);
      }
    }
    _recordExhausted();
  }

  void _recordExhausted() {
    for (final MapEntry(key: id, value: patience) in _patience.entries) {
      if (patience <= 0) _exhausted.add(id);
    }
  }
```

(`_patience` dideklarasikan sebelum field statistik; `network.cables` dari Task 1.)

- [ ] **Step 4:** `flutter test test/game/sim` → PASS.
- [ ] **Step 5:** `git commit -m "feat(sim): record full cable minutes, peak load and exhausted houses"`

---

### Task 3: `LevelResult` — bintang, biang kerok, rumah pindah

**Files:**
- Create: `lib/game/result/level_result.dart`
- Modify: `test/game/sim/sim_fixtures.dart` (helper `playDay`, `designDay`)
- Test: `test/game/result/level_result_test.dart`

**Interfaces:**
- Consumes: statistik `DaySim` (Task 2), `LevelDef.passSatisfaction/savingsTarget`, `HouseDef.block` (Task 1).
- Produces:
  - `sealed class Culprit`; `FullCable({required String area, required int minute, required List<String> heavyUsers, required bool suggestFiber})`; `Unconnected(List<String> customers)`; `TightLimit(List<String> customers)` — semua `const`.
  - `LevelResult({required LevelDef level, required int satisfaction, required int budgetLeft, required int complaints, required int housesLost, Culprit? culprit})` (`const`), `factory LevelResult.of(GameState game)`, `static int starsFor(LevelDef, {required int satisfaction, required int budgetLeft})`, getter `stars`, `passed`.
  - Fixture test: `GameState playDay(GameState game)`, `GameState designDay(List<Cable> cables, {Map<String, int> limits})`.

- [ ] **Step 1: Fixture** — tambah ke `sim_fixtures.dart` (import `package:busy_network/game/sim/sim.dart` tidak perlu):

```dart
/// Hari level 5 di jaringan [cables] (junction desain), mulai 06:00,
/// batas antrean [limits].
GameState designDay(List<Cable> cables, {Map<String, int> limits = const {}}) {
  final game = GameState(
    Levels.level5,
    junctions: DummyStates.run().junctions,
    cables: cables,
  )..startDay();
  if (limits.isNotEmpty) game.setQueue(limits: limits, priority: const {});
  return game;
}

/// Mainkan [game] sampai 24:00; komplain langsung dijawab.
GameState playDay(GameState game) {
  while (game.phase == GamePhase.run) {
    game.dismissComplaint();
    game.advanceDay(1);
  }
  return game;
}
```

- [ ] **Step 2: Test gagal** — `test/game/result/level_result_test.dart`:

```dart
import 'dart:ui';

import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/result/level_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sim/sim_fixtures.dart';

const _level5 = Levels.level5;
Cable _initial(String id) => _level5.cables.firstWhere((c) => c.id == id);
Cable _lan(String id, String from, String to) => Cable(
  id: id,
  from: from,
  to: to,
  points: const [Offset(0, 0), Offset(30, 0)],
);

/// Level uji tanpa fiber (nomor 1), rumah 15 Mbps di jam sibuk.
LevelDef _testLevel(Map<String, String?> blocks) => LevelDef(
  number: 1,
  name: 'Uji',
  gridOrigin: Offset.zero,
  routerPosition: Offset.zero,
  houses: [
    for (final MapEntry(key: id, value: block) in blocks.entries)
      HouseDef(
        id: id,
        label: 'Rumah $id',
        position: Offset.zero,
        customer: 'Pelanggan $id',
        block: block,
        packageMbps: 20,
        peakMbps: 15,
      ),
  ],
  budget: 200000,
  targetSatisfaction: 60,
  passSatisfaction: 40,
  blockLabels: const [],
);

LevelResult _result(GameState game) => LevelResult.of(playDay(game));

void main() {
  group('starsFor', () {
    int stars(LevelDef level, int satisfaction, [int budget = 0]) =>
        LevelResult.starsFor(
          level,
          satisfaction: satisfaction,
          budgetLeft: budget,
        );

    test('level 5: gagal < 60, 1★ < 80, 2★, 3★ dengan sisa Rp 200.000', () {
      expect(stars(_level5, 59, 999999), 0);
      expect(stars(_level5, 60), 1);
      expect(stars(_level5, 79, 999999), 1);
      expect(stars(_level5, 80, 199999), 2);
      expect(stars(_level5, 80, 200000), 3);
      expect(stars(_level5, 100, 850000), 3);
    });

    test('level 1: lulus mulai 40%', () {
      expect(stars(Levels.level1, 39), 0);
      expect(stars(Levels.level1, 40), 1);
    });
  });

  group('dari hari yang dimainkan', () {
    test('jaringan desain tanpa diatur: 75% → 1★, Blok B biang keroknya', () {
      final r = _result(designDay(designCables));
      expect(r.satisfaction, 75);
      expect(r.stars, 1);
      expect(r.passed, isTrue);
      expect(r.budgetLeft, 850000);
      expect(r.complaints, 1);
      expect(r.housesLost, 2);
      expect(
        r.culprit,
        isA<FullCable>()
            .having((c) => c.area, 'area', 'Blok B')
            .having((c) => c.minute, 'minute', 19 * 60)
            .having((c) => c.heavyUsers, 'heavyUsers', ['Bu Sri', 'Pak Rudi'])
            .having((c) => c.suggestFiber, 'suggestFiber', isTrue),
      );
    });

    test('kabel Rumah 4 fiber: 100%, 3★, tanpa biang kerok', () {
      final r = _result(designDay(designFiberCables));
      expect(r.satisfaction, 100);
      expect(r.stars, 3);
      expect(r.housesLost, 0);
      expect(r.culprit, isNull);
    });

    test('rancangan awal 4/7: 57% gagal, 3 rumah belum tersambung', () {
      final r = _result(designDay(_level5.cables));
      expect(r.satisfaction, 57);
      expect(r.stars, 0);
      expect(r.passed, isFalse);
      expect(r.housesLost, 3);
      expect(
        r.culprit,
        isA<Unconnected>().having((c) => c.customers, 'customers', [
          'Pak Rudi',
          'Bang Togar',
          'Mbak Wulan',
        ]),
      );
    });

    test('kabel penuh didahulukan dari rumah belum tersambung', () {
      final r5 = designCables.firstWhere((c) => c.id == 'c-r5');
      final r = _result(designDay([..._level5.cables, r5]));
      expect(r.satisfaction, 46);
      expect(r.stars, 0);
      expect(r.housesLost, 4);
      expect(r.culprit, isA<FullCable>().having((c) => c.area, 'area', 'Blok B'));
    });

    test('Bu Sri dibatasi 11 Mbps: jatah terlalu ketat', () {
      final r = _result(designDay(designCables, limits: {'r4': 11}));
      expect(r.satisfaction, 87);
      expect(r.housesLost, 1);
      expect(
        r.culprit,
        isA<TightLimit>().having((c) => c.customers, 'customers', ['Bu Sri']),
      );
    });

    test('hari belum selesai → StateError', () {
      expect(() => LevelResult.of(designDay(designCables)), throwsStateError);
    });
  });

  group('area biang kerok', () {
    test('kabel campur blok → label rumah di ujung kabel', () {
      final r = _result(
        designDay([
          ..._level5.cables,
          _lan('c-r6', 'r4', 'r6'),
        ]),
      );
      expect(
        r.culprit,
        isA<FullCable>()
            .having((c) => c.area, 'area', 'Rumah 4')
            .having((c) => c.heavyUsers, 'heavyUsers', ['Bu Sri', 'Bang Togar']),
      );
    });

    test('kabel ke junction, satu blok → blok', () {
      final r = _result(
        designDay([
          _lan('c-j1', LevelDef.routerId, 'j1'),
          _initial('c-r1'),
          _initial('c-r3'),
          _lan('c-w', 'j1', 'w'),
        ]),
      );
      expect(
        r.culprit,
        isA<FullCable>()
            .having((c) => c.area, 'area', 'Blok A')
            .having((c) => c.heavyUsers, 'heavyUsers', [
              'Warung Bu Ijah',
              'Kak Dewi',
            ]),
      );
    });

    test('kabel ke junction, campur blok → rumah pertama yang dialiri', () {
      final r = _result(
        designDay([
          _lan('c-j1', LevelDef.routerId, 'j1'),
          _initial('c-r1'),
          _initial('c-r3'),
          _lan('c-r4', 'j1', 'r4'),
        ]),
      );
      expect(r.culprit, isA<FullCable>().having((c) => c.area, 'area', 'Rumah 1'));
    });

    test('rumah tanpa blok → label rumah di ujung kabel', () {
      final level = _testLevel({'a': null, 'b': 'Blok X'});
      final r = _result(
        GameState(
          level,
          cables: [_lan('c-a', LevelDef.routerId, 'a'), _lan('c-b', 'a', 'b')],
        )..startDay(),
      );
      expect(r.culprit, isA<FullCable>().having((c) => c.area, 'area', 'Rumah a'));
    });

    test('fiber belum terbuka → tidak menyarankan fiber; jam sibuk default', () {
      final level = _testLevel({'a': 'Blok X', 'b': 'Blok X'});
      final r = _result(
        GameState(
          level,
          cables: [_lan('c-a', LevelDef.routerId, 'a'), _lan('c-b', 'a', 'b')],
        )..startDay(),
      );
      expect(
        r.culprit,
        isA<FullCable>()
            .having((c) => c.suggestFiber, 'suggestFiber', isFalse)
            .having((c) => c.minute, 'minute', 19 * 60),
      );
    });

    test('seri lama penuh → kabel yang lebih dulu dipasang', () {
      final level = _testLevel({
        'a': 'Blok X',
        'b': 'Blok X',
        'c': 'Blok Y',
        'd': 'Blok Y',
      });
      final r = _result(
        GameState(
          level,
          cables: [
            _lan('c-a', LevelDef.routerId, 'a'),
            _lan('c-b', 'a', 'b'),
            _lan('c-c', LevelDef.routerId, 'c'),
            _lan('c-d', 'c', 'd'),
          ],
        )..startDay(),
      );
      expect(r.culprit, isA<FullCable>().having((c) => c.area, 'area', 'Blok X'));
    });
  });
}
```

- [ ] **Step 3:** `flutter test test/game/result` → FAIL (file belum ada).
- [ ] **Step 4: Implementasi** `lib/game/result/level_result.dart`:

```dart
import '../model/cable.dart';
import '../model/game_state.dart';
import '../model/level_def.dart';
import '../model/network.dart';
import '../sim/day_sim.dart';

/// Kenapa kepuasan tidak mencapai target: biang kerok di layar gagal dan
/// tips 1 bintang di layar berhasil. Berisi fakta; teksnya disusun layar.
sealed class Culprit {
  const Culprit();
}

/// Kabel yang paling lama penuh.
class FullCable extends Culprit {
  const FullCable({
    required this.area,
    required this.minute,
    required this.heavyUsers,
    required this.suggestFiber,
  });

  /// Blok yang dialiri kabel ("Blok B"), atau label rumah ("Rumah 4").
  final String area;

  /// Menit beban terparah.
  final int minute;

  /// Pelanggan pemakai terbesar di kabel itu, maksimal dua.
  final List<String> heavyUsers;

  /// Kabelnya LAN dan fiber sudah terbuka di level ini.
  final bool suggestFiber;
}

/// Ada rumah yang tidak tersambung (tidak ada kabel yang pernah penuh).
class Unconnected extends Culprit {
  const Unconnected(this.customers);

  /// Pelanggan rumah yang tidak tersambung, urutan level.
  final List<String> customers;
}

/// Batas antrean memotong pemakaian rumah (tidak ada kabel penuh, semua
/// tersambung).
class TightLimit extends Culprit {
  const TightLimit(this.customers);

  /// Pelanggan yang dibatasi, sabar terendah dulu, maksimal dua.
  final List<String> customers;
}

/// Hasil satu hari level: angka layar hasil, bintang, dan biang kerok.
class LevelResult {
  const LevelResult({
    required this.level,
    required this.satisfaction,
    required this.budgetLeft,
    required this.complaints,
    required this.housesLost,
    this.culprit,
  });

  /// Hasil hari [game] yang sudah sampai 24:00.
  factory LevelResult.of(GameState game) {
    final day = game.day;
    if (day == null || !day.over) {
      throw StateError('Hari belum selesai');
    }
    final level = game.level;
    final unconnected = [
      for (final h in level.houses)
        if (!day.network.connectedHouses.contains(h.id)) h,
    ];
    return LevelResult(
      level: level,
      satisfaction: day.satisfaction,
      budgetLeft: game.budget,
      complaints: day.complaints,
      housesLost: day.exhausted.length + unconnected.length,
      culprit:
          _fullCable(level, day) ??
          (unconnected.isNotEmpty
              ? Unconnected([for (final h in unconnected) h.customer])
              : _tightLimit(level, day)),
    );
  }

  final LevelDef level;

  /// Kepuasan akhir 0..100.
  final int satisfaction;

  /// Sisa anggaran setelah rancangan.
  final int budgetLeft;

  /// Jumlah komplain sepanjang hari.
  final int complaints;

  /// Rumah yang sabarnya sempat habis + rumah yang tidak tersambung.
  final int housesLost;

  /// `null` bila tidak ada yang bisa disalahkan (hanya dari potret).
  final Culprit? culprit;

  /// 0 = gagal (kepuasan di bawah batas lulus), 1 = lulus, 2 = kepuasan ≥
  /// target, 3 = juga sisa anggaran ≥ [LevelDef.savingsTarget].
  static int starsFor(
    LevelDef level, {
    required int satisfaction,
    required int budgetLeft,
  }) {
    if (satisfaction < level.passSatisfaction) return 0;
    if (satisfaction < level.targetSatisfaction) return 1;
    return budgetLeft >= level.savingsTarget ? 3 : 2;
  }

  int get stars => starsFor(
    level,
    satisfaction: satisfaction,
    budgetLeft: budgetLeft,
  );

  bool get passed => stars > 0;

  /// Kabel dengan menit penuh terbanyak; seri → yang lebih dulu penuh, lalu
  /// urutan pemasangan.
  static FullCable? _fullCable(LevelDef level, DaySim day) {
    Cable? worst;
    for (final cable in day.network.cables) {
      final minutes = day.fullMinutes(cable.id);
      if (minutes == 0) continue;
      if (worst == null) {
        worst = cable;
        continue;
      }
      final best = day.fullMinutes(worst.id);
      if (minutes > best ||
          (minutes == best &&
              day.firstFullMinute(cable.id)! <
                  day.firstFullMinute(worst.id)!)) {
        worst = cable;
      }
    }
    if (worst == null) return null;
    final carried = day.network.housesCarried(worst);
    final houses = [
      for (final h in level.houses)
        if (carried.contains(h.id)) h,
    ];
    final heavy = _sorted(
      level,
      houses,
      (a, b) => b.peakMbps.compareTo(a.peakMbps),
    );
    return FullCable(
      area: _area(level, worst, houses),
      minute: day.peakMinute(worst.id)!,
      heavyUsers: [for (final h in heavy.take(2)) h.customer],
      suggestFiber:
          worst.kind == CableKind.lan &&
          level.unlockedCables.any((s) => s.kind == CableKind.fiber),
    );
  }

  /// Blok bersama rumah yang dialiri [cable]; bila beda-beda atau ada yang
  /// tanpa blok: label rumah di ujung kabel, atau rumah pertama yang
  /// dialirinya bila ujungnya junction.
  static String _area(LevelDef level, Cable cable, List<HouseDef> houses) {
    final blocks = {for (final h in houses) h.block};
    if (blocks.length == 1 && blocks.first != null) return blocks.first!;
    for (final h in level.houses) {
      if (h.id == cable.to) return h.label;
    }
    return houses.first.label;
  }

  static TightLimit? _tightLimit(LevelDef level, DaySim day) {
    final limited = [
      for (final h in level.houses)
        if (day.limits[h.id] case final limit? when limit < h.peakMbps) h,
    ];
    if (limited.isEmpty) return null;
    final houses = day.frame.houses;
    final sorted = _sorted(
      level,
      limited,
      (a, b) => houses[a.id]!.patience.compareTo(houses[b.id]!.patience),
    );
    return TightLimit([for (final h in sorted.take(2)) h.customer]);
  }

  /// [houses] diurutkan [compare], seri → urutan level (sort Dart tidak
  /// stabil).
  static List<HouseDef> _sorted(
    LevelDef level,
    List<HouseDef> houses,
    int Function(HouseDef a, HouseDef b) compare,
  ) {
    final order = {for (final (i, h) in level.houses.indexed) h.id: i};
    return [...houses]..sort((a, b) {
      final c = compare(a, b);
      return c != 0 ? c : order[a.id]!.compareTo(order[b.id]!);
    });
  }
}
```

(Import `network.dart` dibuang bila tidak terpakai; `day.network` bertipe `Network`.)

- [ ] **Step 5:** `flutter test test/game` → PASS; `flutter analyze` bersih.
- [ ] **Step 6:** `git commit -m "feat(game): level result with stars, culprit and houses lost"`

---

### Task 4: Model `Progress`

**Files:**
- Create: `lib/game/progress/progress.dart`
- Test: `test/game/progress/progress_test.dart`

**Interfaces:**
- Produces: `Progress(Map<int, int> stars)`, `starsOf(int)`, `isDone(int)`, `isOpen(int)`, `current`, `totalStars`, `levelsDone(int levelCount)`, `record(int level, int stars) → Progress` (mengembalikan `this` bila tidak berubah), `encode() → String`, `static Progress? decode(String?)`, `==`/`hashCode`.

- [ ] **Step 1: Test gagal:**

```dart
import 'package:busy_network/game/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';

final _design = Progress(const {1: 3, 2: 2, 3: 3, 4: 1});

void main() {
  test('kosong: hanya level 1 terbuka & sekarang', () {
    final p = Progress(const {});
    expect(p.current, 1);
    expect(p.isOpen(1), isTrue);
    expect(p.isOpen(2), isFalse);
    expect(p.totalStars, 0);
  });

  test('progres desain: 9 bintang, 4 level, level 5 sekarang', () {
    expect(_design.totalStars, 9);
    expect(_design.levelsDone(12), 4);
    expect(_design.current, 5);
    expect(_design.isOpen(5), isTrue);
    expect(_design.isOpen(6), isFalse);
    expect(_design.starsOf(2), 2);
    expect(_design.starsOf(5), 0);
  });

  test('record: bintang terbaik dipakai; tidak turun', () {
    final won = _design.record(5, 2);
    expect(won.starsOf(5), 2);
    expect(won.current, 6);
    expect(won.record(5, 1), same(won));
    expect(won.record(5, 0), same(won));
    expect(won.record(5, 3).starsOf(5), 3);
    expect(_design.starsOf(5), 0, reason: 'tidak mengubah aslinya');
  });

  test('bintang di luar 0..3 atau level < 1 ditolak', () {
    expect(() => Progress(const {1: 4}), throwsArgumentError);
    expect(() => Progress(const {0: 1}), throwsArgumentError);
    expect(() => _design.record(5, 4), throwsArgumentError);
  });

  test('encode/decode bolak-balik', () {
    final p = _design.record(5, 3);
    expect(p.encode(), '{"versi":1,"bintang":{"1":3,"2":2,"3":3,"4":1,"5":3}}');
    expect(Progress.decode(p.encode()), p);
  });

  test('data kosong, rusak, atau versi lain → null', () {
    for (final s in [
      null,
      '',
      'bukan json',
      '[]',
      '{"versi":2,"bintang":{}}',
      '{"versi":1}',
      '{"versi":1,"bintang":{"x":1}}',
      '{"versi":1,"bintang":{"1":"3"}}',
      '{"versi":1,"bintang":{"1":9}}',
    ]) {
      expect(Progress.decode(s), isNull, reason: '$s');
    }
  });
}
```

- [ ] **Step 2:** `flutter test test/game/progress` → FAIL.
- [ ] **Step 3: Implementasi:**

```dart
import 'dart:convert';

/// Progres pemain: bintang terbaik tiap nomor level. Level terbuka & level
/// sekarang diturunkan dari sini, tidak disimpan.
class Progress {
  Progress(Map<int, int> stars)
    : _stars = Map.unmodifiable({
        for (final MapEntry(key: level, value: count) in stars.entries)
          if (_checked(level, count) > 0) level: count,
      });

  static const version = 1;

  final Map<int, int> _stars;

  int starsOf(int level) => _stars[level] ?? 0;

  /// Level sudah selesai (berbintang).
  bool isDone(int level) => starsOf(level) > 0;

  /// Level 1 selalu terbuka; level lain bila level sebelumnya selesai.
  bool isOpen(int level) => level == 1 || isDone(level - 1);

  /// Level terbuka pertama yang belum selesai.
  int get current {
    var level = 1;
    while (isDone(level)) {
      level++;
    }
    return level;
  }

  int get totalStars => _stars.values.fold(0, (sum, s) => sum + s);

  /// Level 1..[levelCount] yang sudah selesai.
  int levelsDone(int levelCount) => [
    for (var n = 1; n <= levelCount; n++)
      if (isDone(n)) n,
  ].length;

  /// Catat [stars] bintang di [level]; bintang terbaik yang dipakai.
  /// Mengembalikan `this` bila tidak ada yang berubah.
  Progress record(int level, int stars) {
    _checked(level, stars);
    if (stars <= starsOf(level)) return this;
    return Progress({..._stars, level: stars});
  }

  String encode() => jsonEncode({
    'versi': version,
    'bintang': {
      for (final level in _stars.keys.toList()..sort())
        '$level': _stars[level],
    },
  });

  /// Kebalikan [encode]; `null` bila kosong, rusak, atau versi lain.
  static Progress? decode(String? source) {
    if (source == null) return null;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return null;
    }
    if (json is! Map || json['versi'] != version) return null;
    final stars = json['bintang'];
    if (stars is! Map) return null;
    final parsed = <int, int>{};
    for (final MapEntry(:key, :value) in stars.entries) {
      final level = key is String ? int.tryParse(key) : null;
      if (level == null || level < 1 || value is! int || value < 0 || value > 3) {
        return null;
      }
      parsed[level] = value;
    }
    return Progress(parsed);
  }

  static int _checked(int level, int stars) {
    if (level < 1) throw ArgumentError.value(level, 'level', 'mulai dari 1');
    if (stars < 0 || stars > 3) {
      throw ArgumentError.value(stars, 'stars', '0..3');
    }
    return stars;
  }

  @override
  bool operator ==(Object other) =>
      other is Progress &&
      other._stars.length == _stars.length &&
      _stars.entries.every((e) => other._stars[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    _stars.entries.map((e) => Object.hash(e.key, e.value)),
  );
}
```

- [ ] **Step 4:** `flutter test test/game/progress` → PASS.
- [ ] **Step 5:** `git commit -m "feat(game): progress model with best stars and derived unlocks"`

---

### Task 5: Penyimpanan progres & `ProgressBook`

**Files:**
- Modify: `pubspec.yaml` (`shared_preferences`, dev `shared_preferences_platform_interface`)
- Create: `lib/data/progress_store.dart`, `lib/app/progress_book.dart`
- Modify: `lib/data/dummy_data.dart` (`DummyData.progress`)
- Test: `test/data/progress_store_test.dart`, `test/app/progress_book_test.dart`

**Interfaces:**
- Consumes: `Progress` (Task 4).
- Produces: `abstract interface class ProgressStore { Progress? load(); Future<void> save(Progress) }`, `MemoryProgressStore([Progress? saved])`, `PrefsProgressStore.open() → Future<PrefsProgressStore>`, `PrefsProgressStore.key = 'progres'`, `ProgressBook(ProgressStore)`, `ProgressBook.memory()`, `ProgressBook.progress`, `Future<void> ProgressBook.record(int level, int stars)`, `DummyData.progress`.

- [ ] **Step 1:** `flutter pub add shared_preferences` lalu `flutter pub add dev:shared_preferences_platform_interface`.
- [ ] **Step 2: Test gagal** — `test/data/progress_store_test.dart`:

```dart
import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void usePrefs(Map<String, Object> data) {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(data);
  }

  test('kosong → null; simpan lalu buka ulang → progres yang sama', () async {
    usePrefs({});
    final store = await PrefsProgressStore.open();
    expect(store.load(), isNull);
    final p = Progress(const {1: 3, 5: 2});
    await store.save(p);
    final reopened = await PrefsProgressStore.open();
    expect(reopened.load(), p);
  });

  test('isi rusak atau bertipe lain → null', () async {
    for (final value in <Object>['{rusak', 42, true]) {
      usePrefs({PrefsProgressStore.key: value});
      final store = await PrefsProgressStore.open();
      expect(store.load(), isNull, reason: '$value');
    }
  });

  test('memori: menyimpan untuk load berikutnya', () async {
    final store = MemoryProgressStore();
    expect(store.load(), isNull);
    await store.save(Progress(const {1: 1}));
    expect(store.load(), Progress(const {1: 1}));
  });
}
```

(Bila `types.dart` tidak dibutuhkan, hapus import-nya.)

`test/app/progress_book_test.dart`:

```dart
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenStore implements ProgressStore {
  @override
  Progress? load() => null;

  @override
  Future<void> save(Progress progress) async => throw StateError('disk penuh');
}

void main() {
  test('store kosong → progres awal desain', () {
    expect(ProgressBook.memory().progress, DummyData.progress);
    expect(DummyData.progress.current, 5);
    expect(DummyData.progress.totalStars, 9);
  });

  test('record: memberi tahu & menyimpan; bintang lebih rendah diabaikan', () async {
    final store = MemoryProgressStore();
    final book = ProgressBook(store);
    var notified = 0;
    book.addListener(() => notified++);
    await book.record(5, 2);
    expect(book.progress.starsOf(5), 2);
    expect(store.load()!.starsOf(5), 2);
    expect(notified, 1);
    await book.record(5, 1);
    expect(book.progress.starsOf(5), 2);
    expect(notified, 1);
  });

  test('memuat progres yang tersimpan', () {
    final book = ProgressBook(MemoryProgressStore(Progress(const {1: 1})));
    expect(book.progress, Progress(const {1: 1}));
  });

  test('gagal simpan: progres di memori tetap berlaku', () async {
    final book = ProgressBook(_BrokenStore());
    await book.record(5, 3);
    expect(book.progress.starsOf(5), 3);
  });
}
```

- [ ] **Step 3:** `flutter test test/data test/app` → FAIL.
- [ ] **Step 4: Implementasi.** `lib/data/progress_store.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../game/progress/progress.dart';

/// Tempat progres disimpan di antara sesi.
abstract interface class ProgressStore {
  /// Progres tersimpan; `null` bila belum ada atau tidak terbaca.
  Progress? load();

  Future<void> save(Progress progress);
}

/// Progres di memori saja (test, dan cadangan bila perangkat menolak).
class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([this._saved]);

  Progress? _saved;

  @override
  Progress? load() => _saved;

  @override
  Future<void> save(Progress progress) async => _saved = progress;
}

/// Progres di `shared_preferences`: satu kunci [key] berisi JSON
/// `Progress.encode`.
class PrefsProgressStore implements ProgressStore {
  PrefsProgressStore._(this._prefs);

  static const key = 'progres';

  static Future<PrefsProgressStore> open() async => PrefsProgressStore._(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {key}),
    ),
  );

  final SharedPreferencesWithCache _prefs;

  @override
  Progress? load() {
    final value = _prefs.get(key);
    return value is String ? Progress.decode(value) : null;
  }

  @override
  Future<void> save(Progress progress) =>
      _prefs.setString(key, progress.encode());
}
```

`lib/app/progress_book.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../data/dummy_data.dart';
import '../data/progress_store.dart';
import '../game/progress/progress.dart';

/// Progres pemain selama aplikasi berjalan: dibaca Beranda & Peta Babak,
/// ditulis saat level selesai ([record]). Belum ada yang tersimpan →
/// progres awal desain ([DummyData.progress]).
class ProgressBook extends ChangeNotifier {
  ProgressBook(this._store) : _progress = _store.load() ?? DummyData.progress;

  /// Progres di memori saja (default aplikasi di test).
  ProgressBook.memory() : this(MemoryProgressStore());

  final ProgressStore _store;
  Progress _progress;

  Progress get progress => _progress;

  /// Catat [stars] bintang level [level] (yang terbaik dipakai), beri tahu
  /// pendengar, lalu simpan. Gagal simpan tidak menghentikan permainan:
  /// progres di memori tetap berlaku.
  Future<void> record(int level, int stars) async {
    final next = _progress.record(level, stars);
    if (identical(next, _progress)) return;
    _progress = next;
    notifyListeners();
    try {
      await _store.save(next);
    } on Object catch (error) {
      debugPrint('Progres gagal disimpan: $error');
    }
  }
}
```

`dummy_data.dart`: import `../game/progress/progress.dart`, tambah di `DummyData`:

```dart
  /// Progres awal seperti Peta Babak di desain: level 1–4 selesai
  /// (3/2/3/1 bintang), level 5 sekarang. Langkah 8: mulai dari level 1.
  static final progress = Progress(const {1: 3, 2: 2, 3: 3, 4: 1});
```

- [ ] **Step 5:** `flutter test test/data test/app` → PASS; `flutter analyze` bersih.
- [ ] **Step 6:** `git commit -m "feat(data): persist progress with shared_preferences"`

---

### Task 6: `GameSession.finish` — catat hasil hari asli

**Files:**
- Modify: `lib/app/game_session.dart`, `lib/screens/run_phase/run_phase_screen.dart`, `lib/data/dummy_data.dart` (potret hasil)
- Modify: `test/screens/navigation_test.dart` (`session.last` → `session.result`)
- Test: `test/app/game_session_test.dart`

**Interfaces:**
- Consumes: `LevelResult` (Task 3), `ProgressBook` (Task 5).
- Produces: `GameSession({ProgressBook? progress})`, `GameSession.progress`, `GameSession.result → LevelResult?`, `GameSession.finish() → LevelResult`; `DummyData.success(int stars) → LevelResult`, `DummyData.fail` (`LevelResult`). `GameSession.last` dihapus.

- [ ] **Step 1: Test gagal** — `test/app/game_session_test.dart`:

```dart
import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/sim/sim.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/sim/sim_fixtures.dart';
import '../screens/run_fixtures.dart';

void main() {
  test('hari asli lulus → bintang dicatat ke progres', () {
    final session = GameSession();
    final day = winningDay(minute: SimClock.dayStart);
    session.begin(day);
    playDay(day);
    final result = session.finish();
    expect(result.stars, 3);
    expect(session.result, same(result));
    expect(session.progress.progress.starsOf(5), 3);
    expect(session.progress.progress.current, 6);
  });

  test('finish dua kali: hasil sama, dicatat sekali', () {
    final book = ProgressBook.memory();
    var notified = 0;
    book.addListener(() => notified++);
    final session = GameSession(progress: book);
    final day = winningDay(minute: 23 * 60);
    session.begin(day);
    playDay(day);
    expect(session.finish(), same(session.finish()));
    expect(notified, 1);
  });

  test('hari gagal tidak mengubah progres', () {
    final session = GameSession();
    final day = designDay(Levels.level5.cables);
    session.begin(day);
    playDay(day);
    expect(session.finish().passed, isFalse);
    expect(session.progress.progress.starsOf(5), 0);
  });

  test('hari potret (deep link) tidak dicatat walau lulus', () {
    final session = GameSession();
    final day = session.currentDay();
    playDay(day);
    final result = session.finish();
    expect(result.passed, isTrue);
    expect(session.progress.progress.starsOf(5), 0);
  });

  test('hari belum selesai → StateError; hari baru menghapus hasil lama', () {
    final session = GameSession();
    expect(session.finish, throwsStateError);
    final day = winningDay(minute: 23 * 60);
    session.begin(day);
    expect(session.finish, throwsStateError);
    playDay(day);
    session.finish();
    session.begin(winningDay(minute: 23 * 60));
    expect(session.result, isNull);
  });
}
```

- [ ] **Step 2:** `flutter test test/app/game_session_test.dart` → FAIL.
- [ ] **Step 3: Implementasi** `game_session.dart` (seluruh kelas):

```dart
import 'dart:async';

import '../data/dummy_states.dart';
import '../game/model/model.dart';
import '../game/result/level_result.dart';
import 'progress_book.dart';

/// Hari yang sedang dimainkan, dioper antarrute: Fase Rancang menaruhnya
/// saat "Mulai Hari" ([begin]), Fase Jalan & Panel Atur Antrean memakai
/// hari yang sama ([currentDay]), Fase Jalan menutupnya di 24:00
/// ([finish]) dan layar hasil membaca [result]. Dibuat sekali oleh
/// aplikasi dan diteruskan router ke layar, bersama [progress].
///
/// Hari milik sesi (dibuat `GameState.planDay`) tidak di-`dispose`: layar
/// lain bisa masih mendengarkannya saat rutenya keluar; cukup dilepas.
class GameSession {
  GameSession({ProgressBook? progress})
    : progress = progress ?? ProgressBook.memory();

  /// Progres pemain (Beranda, Peta Babak, bintang hasil).
  final ProgressBook progress;

  GameState? _day;

  /// Hari dimulai dari Fase Rancang (bukan potret desain): hasilnya
  /// dicatat ke [progress].
  bool _real = false;
  LevelResult? _result;

  /// Hasil hari terakhir yang selesai ([finish]); `null` sampai ada.
  LevelResult? get result => _result;

  /// Mulai hari baru dari rancangan (state fase jalan).
  void begin(GameState day) {
    if (day.phase != GamePhase.run) {
      throw ArgumentError.value(day.phase, 'day.phase', 'harus fase jalan');
    }
    _day = day;
    _real = true;
    _result = null;
  }

  /// Hari untuk layar Fase Jalan & Panel Antrean: hari yang sedang
  /// berjalan, atau — bila tidak ada (deep link, tutorial sampai langkah 7,
  /// hari sebelumnya sudah selesai) — bingkai Fase Jalan di desain, yang
  /// lalu menjadi hari sekarang. Hari potret tidak dicatat ke progres.
  GameState currentDay() {
    final day = _day;
    if (day != null && day.phase == GamePhase.run) return day;
    _real = false;
    _result = null;
    return _day = DummyStates.run();
  }

  /// Pemain meninggalkan [day] sebelum selesai (kembali ke Fase Rancang).
  void abandon(GameState day) {
    if (identical(day, _day)) _day = null;
  }

  /// Tutup hari yang sudah 24:00: hitung hasilnya sekali, dan bila hari
  /// asli & lulus, catat bintangnya ke [progress].
  LevelResult finish() {
    final day = _day;
    if (day == null || day.phase != GamePhase.result) {
      throw StateError('Belum ada hari yang selesai');
    }
    if (_result case final result?) return result;
    final result = _result = LevelResult.of(day);
    if (_real && result.passed) {
      unawaited(progress.record(result.level.number, result.stars));
    }
    return result;
  }
}
```

`run_phase_screen.dart` `_finish()`:

```dart
  /// Hari selesai: catat hasilnya, lalu layar berhasil bila lulus.
  void _finish() {
    if (_finished) return;
    _finished = true;
    final result = widget.session.finish();
    context.go(result.passed ? AppRoutes.success : AppRoutes.fail);
  }
```

`dummy_data.dart` — tambah potret hasil (import `../game/levels/levels.dart`, `../game/result/level_result.dart`):

```dart
  /// Biang kerok di potret hasil desain.
  static const _blockB = FullCable(
    area: 'Blok B',
    minute: 20 * 60,
    heavyUsers: ['Bu Sri', 'Pak Rudi'],
    suggestFiber: true,
  );

  /// Hasil Berhasil di desain (`?bintang=1..3`, angka logika prototipe;
  /// bintangnya keluar dari aturan).
  static LevelResult success(int stars) => LevelResult(
    level: Levels.level5,
    satisfaction: stars >= 2 ? 86 : 72,
    budgetLeft: stars >= 3 ? 240000 : 120000,
    complaints: stars >= 3 ? 2 : (stars == 2 ? 3 : 7),
    housesLost: 0,
    culprit: _blockB,
  );

  /// Hasil Gagal di desain.
  static const fail = LevelResult(
    level: Levels.level5,
    satisfaction: 41,
    budgetLeft: 120000,
    complaints: 11,
    housesLost: 2,
    culprit: _blockB,
  );
```

Tambah test kecil di `game_session_test.dart`:

```dart
  test('potret hasil desain: bintang keluar dari aturan', () {
    expect([for (final n in [1, 2, 3]) DummyData.success(n).stars], [1, 2, 3]);
    expect(DummyData.fail.passed, isFalse);
  });
```

`navigation_test.dart`: ganti `expect(session.last!.phase, GamePhase.result);` dengan `expect(session.result!.stars, 3);` (hapus import model bila tak terpakai).

- [ ] **Step 4:** `flutter test` → PASS; `flutter analyze` bersih.
- [ ] **Step 5:** `git commit -m "feat(app): finish the day into a level result and record real days"`

---

### Task 7: Layar hasil dari `LevelResult`, tombol & rute level

**Files:**
- Modify: `lib/app/routes.dart`, `lib/app/router.dart`
- Modify: `lib/screens/result_success/result_success_data.dart`, `lib/screens/result_success/result_success_screen.dart`
- Create: `lib/screens/result_fail/fail_cause.dart`
- Modify: `lib/screens/result_fail/result_fail_screen.dart`, `lib/screens/design_phase/design_phase_screen.dart`
- Modify: `lib/data/dummy_data.dart` (hapus `savingsTarget`, `failSatisfaction`, `failComplaints`, `failHousesLost`)
- Test: `test/screens/result_copy_test.dart`, `test/screens/result_test.dart`, `test/screens/navigation_test.dart`

**Interfaces:**
- Consumes: `LevelResult`, `Culprit` (Task 3), `GameSession.result/finish` (Task 6), `Levels.byNumber` (Task 1).
- Produces: `AppRoutes.levelParam = 'level'`, `AppRoutes.play(int number) → String`, `SuccessSummary(LevelResult)` (`rules`, `tip`), `FailCause failCause(Culprit)` (`({String title, String hint})`), `ResultSuccessScreen({required LevelResult result})`, `ResultFailScreen({required LevelResult result})`, `DesignPhaseScreen({..., LevelDef level = Levels.level5})`.

- [ ] **Step 1: Test copy (gagal)** — `test/screens/result_copy_test.dart`:

```dart
import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/result/level_result.dart';
import 'package:busy_network/screens/result_fail/fail_cause.dart';
import 'package:busy_network/screens/result_success/result_success_data.dart';
import 'package:flutter_test/flutter_test.dart';

LevelResult _oneStar(Culprit? culprit, {int level = 5}) => LevelResult(
  level: Levels.byNumber(level)!,
  satisfaction: level == 5 ? 70 : 50,
  budgetLeft: 0,
  complaints: 0,
  housesLost: 0,
  culprit: culprit,
);

void main() {
  group('biang kerok layar gagal', () {
    test('kabel penuh (teks desain)', () {
      final cause = failCause(DummyData.fail.culprit!);
      expect(cause.title, 'Kabel ke Blok B kelebihan beban jam 20:00.');
      expect(
        cause.hint,
        'Ganti kabel utamanya ke fiber, atau batasi jatah Bu Sri dan Pak '
        'Rudi sebelum jam sibuk.',
      );
    });

    test('kabel penuh tanpa saran fiber, satu pemakai', () {
      final cause = failCause(
        const FullCable(
          area: 'Rumah 2',
          minute: 19 * 60 + 5,
          heavyUsers: ['Bu Lina'],
          suggestFiber: false,
        ),
      );
      expect(cause.title, 'Kabel ke Rumah 2 kelebihan beban jam 19:05.');
      expect(cause.hint, 'Batasi jatah Bu Lina sebelum jam sibuk.');
    });

    test('rumah belum tersambung', () {
      final cause = failCause(
        const Unconnected(['Pak Rudi', 'Bang Togar', 'Mbak Wulan']),
      );
      expect(cause.title, '3 rumah belum tersambung.');
      expect(
        cause.hint,
        'Tarik kabel ke Pak Rudi dan Bang Togar sebelum mulai hari.',
      );
      expect(
        failCause(const Unconnected(['Pak Rudi'])).hint,
        'Tarik kabel ke Pak Rudi sebelum mulai hari.',
      );
    });

    test('jatah terlalu ketat', () {
      expect(
        failCause(const TightLimit(['Bu Sri', 'Pak Rudi'])).title,
        'Jatah Bu Sri dan Pak Rudi dibatasi terlalu ketat.',
      );
      final one = failCause(const TightLimit(['Bu Sri']));
      expect(one.title, 'Jatah Bu Sri dibatasi terlalu ketat.');
      expect(one.hint, 'Naikkan batas antreannya, kabelnya masih kuat.');
    });
  });

  group('tips layar berhasil', () {
    test('3★ tanpa tips; 2★ teks desain', () {
      expect(SuccessSummary(DummyData.success(3)).tip, isNull);
      expect(
        SuccessSummary(DummyData.success(2)).tip,
        'Pakai LAN di jalur yang sepi. Fiber cukup buat kabel utama, '
        'sisanya buat bintang ketiga.',
      );
    });

    test('1★ kabel penuh (teks desain) & tanpa fiber', () {
      expect(
        SuccessSummary(DummyData.success(1)).tip,
        'Jalur Blok B penuh pas jam sibuk. Coba fiber di kabel utama, atau '
        'batasi jatah sebelum jam 19.',
      );
      expect(
        SuccessSummary(
          _oneStar(
            const FullCable(
              area: 'Rumah 2',
              minute: 19 * 60,
              heavyUsers: ['Bu Lina'],
              suggestFiber: false,
            ),
            level: 1,
          ),
        ).tip,
        'Jalur Rumah 2 penuh pas jam sibuk. Batasi jatah sebelum jam 19.',
      );
    });

    test('1★ belum tersambung, jatah ketat, tanpa biang kerok', () {
      expect(
        SuccessSummary(_oneStar(const Unconnected(['A', 'B']))).tip,
        'Masih ada 2 rumah yang belum tersambung. Sambungkan biar kepuasan '
        'naik.',
      );
      expect(
        SuccessSummary(_oneStar(const TightLimit(['Bu Sri']))).tip,
        'Jatah Bu Sri kebatasan. Naikkan batasnya, kabelnya masih kuat.',
      );
      expect(SuccessSummary(_oneStar(null)).tip, isNull);
    });

    test('syarat bintang dari level & hasil', () {
      final rules = SuccessSummary(DummyData.success(1)).rules;
      expect([for (final r in rules) r.passed], [true, false, false]);
      expect(rules[1].detail, 'Kepuasan akhir ≥ 80% · kamu 72%');
      expect(rules[2].detail, 'Sisa anggaran ≥ Rp 200.000 · kamu Rp 120.000');
    });
  });
}
```

- [ ] **Step 2:** `flutter test test/screens/result_copy_test.dart` → FAIL.
- [ ] **Step 3: Implementasi copy.** `result_success_data.dart`:

```dart
import '../../core/format.dart';
import '../../game/result/level_result.dart';
import '../../game/sim/sim.dart';

/// Satu syarat bintang di daftar hasil.
class StarRule { /* tidak berubah */ }

/// Isi layar Hasil Berhasil dari [result]: syarat bintang & tips.
class SuccessSummary {
  const SuccessSummary(this.result);

  final LevelResult result;

  List<StarRule> get rules {
    final level = result.level;
    return [
      const StarRule(
        stars: 1,
        title: 'Selesai',
        detail: 'Hari lewat tanpa bangkrut',
        passed: true,
      ),
      StarRule(
        stars: 2,
        title: 'Kepuasan tinggi',
        detail:
            'Kepuasan akhir ≥ ${IdFormat.percent(level.targetSatisfaction)} · '
            'kamu ${IdFormat.percent(result.satisfaction)}',
        passed: result.stars >= 2,
      ),
      StarRule(
        stars: 3,
        title: 'Kepuasan tinggi & hemat',
        detail:
            'Sisa anggaran ≥ ${IdFormat.rupiah(level.savingsTarget)} · '
            'kamu ${IdFormat.rupiah(result.budgetLeft)}',
        passed: result.stars >= 3,
      ),
    ];
  }

  /// Tips; `null` bila sudah 3 bintang atau tidak ada biang kerok.
  String? get tip => switch (result.stars) {
    >= 3 => null,
    2 =>
      'Pakai LAN di jalur yang sepi. Fiber cukup buat kabel utama, '
          'sisanya buat bintang ketiga.',
    _ => switch (result.culprit) {
      FullCable(:final area, suggestFiber: true) =>
        'Jalur $area penuh pas jam sibuk. Coba fiber di kabel utama, atau '
            'batasi jatah sebelum jam $_rushFrom.',
      FullCable(:final area) =>
        'Jalur $area penuh pas jam sibuk. Batasi jatah sebelum jam '
            '$_rushFrom.',
      Unconnected(:final customers) =>
        'Masih ada ${customers.length} rumah yang belum tersambung. '
            'Sambungkan biar kepuasan naik.',
      TightLimit(:final customers) =>
        'Jatah ${customers.first} kebatasan. Naikkan batasnya, kabelnya '
            'masih kuat.',
      null => null,
    },
  };

  int get _rushFrom => result.level.rushHourFrom ?? SimClock.defaultRushFrom;
}
```

`fail_cause.dart`:

```dart
import '../../core/format.dart';
import '../../game/result/level_result.dart';

/// Isi kartu "BIANG KEROKNYA": kalimat tebal + saran.
typedef FailCause = ({String title, String hint});

FailCause failCause(Culprit culprit) => switch (culprit) {
  FullCable(:final area, :final minute, :final heavyUsers, :final suggestFiber) => (
    title: 'Kabel ke $area kelebihan beban jam ${IdFormat.clock(minute)}.',
    hint: suggestFiber
        ? 'Ganti kabel utamanya ke fiber, atau batasi jatah '
              '${_and(heavyUsers)} sebelum jam sibuk.'
        : 'Batasi jatah ${_and(heavyUsers)} sebelum jam sibuk.',
  ),
  Unconnected(:final customers) => (
    title: '${customers.length} rumah belum tersambung.',
    hint: 'Tarik kabel ke ${_and(customers.take(2))} sebelum mulai hari.',
  ),
  TightLimit(:final customers) => (
    title: 'Jatah ${_and(customers)} dibatasi terlalu ketat.',
    hint: 'Naikkan batas antreannya, kabelnya masih kuat.',
  ),
};

/// "A" / "A dan B" (paling banyak dua nama).
String _and(Iterable<String> names) => names.join(' dan ');
```

- [ ] **Step 4:** `flutter test test/screens/result_copy_test.dart` → PASS.
- [ ] **Step 5: Test layar (gagal)** — `test/screens/result_test.dart`:

```dart
import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/screens/design_phase/design_phase_screen.dart';
import 'package:busy_network/screens/level_map/level_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/sim/sim_fixtures.dart';
import '../test_helpers.dart';

/// Sesi dengan [game] yang sudah dimainkan sampai 24:00 dan ditutup.
GameSession _finished(GameState game) {
  final session = GameSession()..begin(game);
  playDay(game);
  session.finish();
  return session;
}

void main() {
  setUpFonts();

  testWidgets('berhasil 1★ dari hari asli: angka & tips biang kerok', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final session = _finished(designDay(designCables));
    await pumpApp(tester, location: AppRoutes.success, session: session);
    expect(find.text('LEVEL 5 · GANG MELATI'), findsOneWidget);
    expect(find.bySemanticsLabel('Dapat 1 dari 3 bintang'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Rp 850.000'), findsOneWidget);
    expect(find.text('Kepuasan akhir ≥ 80% · kamu 75%'), findsOneWidget);
    expect(
      find.text(
        'Jalur Blok B penuh pas jam sibuk. Coba fiber di kabel utama, atau '
        'batasi jatah sebelum jam 19.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('gagal dari hari asli: kabel Blok B, 4 rumah pindah', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final r5 = designCables.firstWhere((c) => c.id == 'c-r5');
    final session = _finished(designDay([...Levels.level5.cables, r5]));
    await pumpApp(tester, location: AppRoutes.fail, session: session);
    expect(
      find.text('Kepuasan cuma 46%, targetnya 80%. Nggak apa, besok coba lagi.'),
      findsOneWidget,
    );
    expect(find.text('4 rumah'), findsOneWidget);
    expect(find.text('Kabel ke Blok B kelebihan beban jam 19:00.'), findsOneWidget);
    expect(
      find.text(
        'Ganti kabel utamanya ke fiber, atau batasi jatah Bu Sri dan Pak '
        'Rudi sebelum jam sibuk.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('deep link gagal = potret desain', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await pumpApp(tester, location: AppRoutes.fail);
    expect(find.text('41%'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('2 rumah'), findsOneWidget);
    expect(find.text('Kabel ke Blok B kelebihan beban jam 20:00.'), findsOneWidget);
  });

  testWidgets('Ulangi memulai level dari awal', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final session = _finished(designDay(designCables));
    await pumpApp(tester, location: AppRoutes.success, session: session);
    await tester.tap(find.text('Ulangi'));
    await tester.pumpAndSettle();
    expect(find.byType(DesignPhaseScreen), findsOneWidget);
    expect(find.text('4/7 rumah tersambung'), findsOneWidget);
    expect(find.text('Rp 850.000'), findsOneWidget);
  });

  testWidgets('Level Berikutnya: level 6 belum ada → Peta', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final session = _finished(designDay(designCables));
    await pumpApp(tester, location: AppRoutes.success, session: session);
    await tester.tap(find.text('Level Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);
  });

  test('play: level 1 tutorial, lainnya Fase Rancang ber-level', () {
    expect(AppRoutes.play(1), AppRoutes.tutorial);
    expect(AppRoutes.play(5), '/peta/rancang?level=5');
  });
}
```

Di test "alur utama" `navigation_test.dart`, setelah `expect(find.byType(ResultFailScreen), findsOneWidget);` tambah:

```dart
    expect(find.text('3 rumah belum tersambung.'), findsOneWidget);
    expect(find.text('3 rumah'), findsOneWidget);
```

- [ ] **Step 6:** `flutter test test/screens/result_test.dart` → FAIL.
- [ ] **Step 7: Implementasi layar & rute.** `routes.dart`:

```dart
  /// Query `?level=n` di Fase Rancang.
  static const levelParam = 'level';

  /// Mulai level [number] dari awal: level 1 = tutorial, lainnya Fase
  /// Rancang level itu.
  static String play(int number) =>
      number == 1 ? tutorial : '$design?$levelParam=$number';
```

`router.dart` — import `../data/dummy_data.dart`, `../game/levels/levels.dart`; rute:

```dart
              GoRoute(
                path: 'rancang',
                builder: (context, state) => DesignPhaseScreen(
                  session: play,
                  level:
                      Levels.byNumber(
                        _intParam(state, AppRoutes.levelParam) ?? 0,
                      ) ??
                      Levels.level5,
                ),
                // routes tidak berubah
              ),
              GoRoute(
                path: 'hasil/berhasil',
                builder: (context, state) => ResultSuccessScreen(
                  result: switch (play.result) {
                    final result? when result.passed => result,
                    _ => DummyData.success(
                      (_intParam(state, AppRoutes.starsParam) ?? 2).clamp(1, 3),
                    ),
                  },
                ),
              ),
              GoRoute(
                path: 'hasil/gagal',
                builder: (context, state) => ResultFailScreen(
                  result: switch (play.result) {
                    final result? when !result.passed => result,
                    _ => DummyData.fail,
                  },
                ),
              ),
```

`design_phase_screen.dart`: parameter `this.level = Levels.level5,` + field `final LevelDef level;` dan `GameState(widget.level, selectedCable: widget.initialCable)`.

`result_success_screen.dart`: `const ResultSuccessScreen({super.key, required this.result}); final LevelResult result;`; di `build`: `final summary = SuccessSummary(result); final level = result.level; final stars = result.stars;`, nilai `StatTile` dari `result.satisfaction`, `result.budgetLeft`, `result.complaints`; tombol:

```dart
  /// Level berikutnya bila datanya ada; selain itu Peta Babak (level baru
  /// sudah terbuka di sana).
  void _next(BuildContext context) {
    final next = result.level.number + 1;
    context.go(
      Levels.byNumber(next) != null ? AppRoutes.play(next) : AppRoutes.levelMap,
    );
  }
```

"Ulangi" → `context.go(AppRoutes.play(result.level.number))`, "Level Berikutnya" → `_next(context)`. `StatelessWidget` tetap (`_StarTrio(stars: stars)`).

`result_fail_screen.dart`: `const ResultFailScreen({super.key, required this.result}); final LevelResult result;`; `level = result.level`; teks & `StatTile` dari `result.satisfaction`, `result.complaints`, `'${result.housesLost} rumah'`; "Coba Lagi" → `context.go(AppRoutes.play(level.number))`; kartu:

```dart
                        if (result.culprit case final culprit?) ...[
                          const SizedBox(height: AppSpacing.s20),
                          _CauseCard(cause: failCause(culprit)),
                        ],
```

`_CauseCard({required this.cause})` dengan `final FailCause cause;`, `Text(cause.title, ...)` dan `Text(cause.hint, ...)` menggantikan dua teks lama (gaya tidak berubah). Hapus konstanta hasil lama dari `DummyData` dan import yang tak terpakai.

- [ ] **Step 8:** `flutter test` → PASS (termasuk `screen_state_test` 1–3★, overflow, animation); `flutter analyze` bersih.
- [ ] **Step 9:** `git commit -m "feat(screens): result screens show the played day; retry and next level routes"`

---

### Task 8: Beranda & Peta Babak dari progres

**Files:**
- Modify: `lib/screens/level_map/level_map_layout.dart`, `level_map_painter.dart`, `level_map_screen.dart`
- Modify: `lib/screens/home/home_screen.dart`, `lib/widgets/level_node.dart`, `lib/app/router.dart`
- Modify: `lib/data/dummy_data.dart` (hapus `ChapterInfo` & `chapter`)
- Test: `test/screens/level_map_layout_test.dart`, `test/screens/progress_screens_test.dart`

**Interfaces:**
- Consumes: `Progress` (Task 4), `ProgressBook`/`GameSession.progress` (Task 5–6), `Levels.chapter/byNumber` (Task 1).
- Produces: `LevelSlot(number, center, {labelBeside})`, `LevelMapLayout.slots`, `.pathEnd`, `.slotOf(int) → LevelSlot?`, `.stateOf(Progress, int) → LevelNodeState`, `.nodeTopLeft(LevelSlot, LevelNodeState)`, `.labelTopLeft(LevelSlot, LevelNodeState)`, `.chipTopLeft(LevelSlot)`, `.paths(int current) → ({List<Offset> done, List<Offset> locked})`; `LevelMapBackdrop({required int current})`; `LevelMapScreen({required ProgressBook progress})`; `HomeScreen({required ProgressBook progress})`.

- [ ] **Step 1: Test tata letak (gagal)** — `test/screens/level_map_layout_test.dart`:

```dart
import 'dart:ui';

import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:busy_network/screens/level_map/level_map_layout.dart';
import 'package:busy_network/widgets/level_node.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kiri-atas node & label tiap level di desain (kanvas 390×844).
const _design = <int, (Offset, Offset)>{
  1: (Offset(45, 160), Offset(45, 226)),
  2: (Offset(165, 160), Offset(165, 226)),
  3: (Offset(285, 160), Offset(285, 226)),
  4: (Offset(285, 300), Offset(285, 366)),
  5: (Offset(159, 294), Offset(165, 372)),
  6: (Offset(51, 306), Offset(45, 358)),
  7: (Offset(51, 446), Offset(45, 498)),
  8: (Offset(171, 446), Offset(165, 498)),
  9: (Offset(291, 446), Offset(285, 498)),
  10: (Offset(291, 586), Offset(285, 638)),
  11: (Offset(51, 586), Offset(105, 600)),
};

void main() {
  test('progres awal = koordinat & status desain', () {
    final p = DummyData.progress;
    for (final slot in LevelMapLayout.slots) {
      final state = LevelMapLayout.stateOf(p, slot.number);
      final (node, label) = _design[slot.number]!;
      expect(LevelMapLayout.nodeTopLeft(slot, state), node, reason: '${slot.number}');
      expect(LevelMapLayout.labelTopLeft(slot, state), label, reason: '${slot.number}');
    }
    expect([
      for (final s in LevelMapLayout.slots) LevelMapLayout.stateOf(p, s.number),
    ], [
      ...List.filled(4, LevelNodeState.done),
      LevelNodeState.current,
      ...List.filled(6, LevelNodeState.locked),
    ]);
    expect(
      LevelMapLayout.chipTopLeft(LevelMapLayout.slotOf(5)!),
      const Offset(136, 254),
    );
  });

  test('jalur progres awal = path desain', () {
    final paths = LevelMapLayout.paths(5);
    expect(paths.done, const [
      Offset(75, 190),
      Offset(315, 190),
      Offset(315, 330),
      Offset(195, 330),
    ]);
    expect(paths.locked, const [
      Offset(195, 330),
      Offset(75, 330),
      Offset(75, 470),
      Offset(315, 470),
      Offset(315, 610),
      Offset(75, 610),
      Offset(75, 700),
    ]);
  });

  test('level 5 selesai → level 6 sekarang', () {
    final p = DummyData.progress.record(5, 2);
    final five = LevelMapLayout.slotOf(5)!;
    final six = LevelMapLayout.slotOf(6)!;
    expect(LevelMapLayout.stateOf(p, 5), LevelNodeState.done);
    expect(LevelMapLayout.nodeTopLeft(five, LevelNodeState.done), const Offset(165, 300));
    expect(LevelMapLayout.labelTopLeft(five, LevelNodeState.done), const Offset(165, 366));
    expect(LevelMapLayout.stateOf(p, 6), LevelNodeState.current);
    expect(LevelMapLayout.nodeTopLeft(six, LevelNodeState.current), const Offset(39, 294));
    expect(LevelMapLayout.labelTopLeft(six, LevelNodeState.current), const Offset(45, 372));
    expect(LevelMapLayout.chipTopLeft(six), const Offset(16, 254));
    expect(LevelMapLayout.paths(6).done.last, const Offset(75, 330));
    expect(LevelMapLayout.paths(6).locked.first, const Offset(75, 330));
  });

  test('belum ada yang selesai: jalur oranye satu titik', () {
    final paths = LevelMapLayout.paths(Progress(const {}).current);
    expect(paths.done, const [Offset(75, 190)]);
    expect(paths.locked.first, const Offset(75, 190));
  });

  test('semua level 1–11 selesai: jalur lengkap, tanpa level sekarang', () {
    final p = Progress({for (var n = 1; n <= 11; n++) n: 1});
    expect(p.current, 12);
    expect(LevelMapLayout.slotOf(12), isNull);
    final paths = LevelMapLayout.paths(12);
    expect(paths.done.last, const Offset(75, 610));
    expect(paths.locked, const [Offset(75, 610), Offset(75, 700)]);
  });
}
```

- [ ] **Step 2:** `flutter test test/screens/level_map_layout_test.dart` → FAIL.
- [ ] **Step 3: Implementasi tata letak** — `level_map_layout.dart` (ganti `LevelMapEntry` & `entries`):

```dart
import 'dart:ui';

import '../../game/progress/progress.dart';
import '../../theme/theme.dart';
import '../../widgets/level_node.dart';

/// Tempat satu level di Peta Babak: pusat node di kanvas desain (390×844).
class LevelSlot {
  const LevelSlot(this.number, this.center, {this.labelBeside = false});

  final int number;
  final Offset center;

  /// Angka level terkunci ditulis di samping (level 11), bukan di bawah.
  final bool labelBeside;
}

/// Tata letak Peta Babak 1 – Perumahan Batam. Posisi node & label
/// diturunkan dari status level; dengan progres awal hasilnya persis
/// koordinat desain.
abstract final class LevelMapLayout {
  /// Potongan kanvas desain yang berisi peta (di bawah header, di atas
  /// kartu bos). Semua koordinat di bawah dikurangi [origin].
  static const Offset origin = Offset(0, 100);
  static const Size size = Size(390, 590);

  static const currentChipWidth = 118.0;

  static const slots = <LevelSlot>[
    LevelSlot(1, Offset(75, 190)),
    LevelSlot(2, Offset(195, 190)),
    LevelSlot(3, Offset(315, 190)),
    LevelSlot(4, Offset(315, 330)),
    LevelSlot(5, Offset(195, 330)),
    LevelSlot(6, Offset(75, 330)),
    LevelSlot(7, Offset(75, 470)),
    LevelSlot(8, Offset(195, 470)),
    LevelSlot(9, Offset(315, 470)),
    LevelSlot(10, Offset(315, 610)),
    LevelSlot(11, Offset(75, 610), labelBeside: true),
  ];

  /// Ujung jalur setelah level 11 (menuju kartu bos).
  static const pathEnd = Offset(75, 700);

  static LevelSlot? slotOf(int number) {
    for (final slot in slots) {
      if (slot.number == number) return slot;
    }
    return null;
  }

  static LevelNodeState stateOf(Progress progress, int number) {
    if (progress.isDone(number)) return LevelNodeState.done;
    if (progress.isOpen(number)) return LevelNodeState.current;
    return LevelNodeState.locked;
  }

  static Offset nodeTopLeft(LevelSlot slot, LevelNodeState state) {
    final radius = switch (state) {
          LevelNodeState.done => AppSizes.levelNode,
          LevelNodeState.current => AppSizes.levelNodeCurrent,
          LevelNodeState.locked => AppSizes.levelNodeLocked,
        } /
        2;
    return slot.center - Offset(radius, radius);
  }

  /// Bintang (selesai/sekarang) atau angka (terkunci), lebar
  /// `AppSizes.levelNode` dan rata tengah di bawah node.
  static Offset labelTopLeft(LevelSlot slot, LevelNodeState state) =>
      slot.center +
      switch (state) {
        LevelNodeState.done => const Offset(-30, 36),
        LevelNodeState.current => const Offset(-30, 42),
        LevelNodeState.locked when slot.labelBeside => const Offset(30, -10),
        LevelNodeState.locked => const Offset(-30, 28),
      };

  /// Chip nama di atas level sekarang.
  static Offset chipTopLeft(LevelSlot slot) =>
      slot.center + const Offset(-currentChipWidth / 2, -76);

  /// Jalur oranye level 1 → level [current] dan jalur putus-putus level
  /// [current] → level 11 → [pathEnd]; titik segaris dibuang.
  static ({List<Offset> done, List<Offset> locked}) paths(int current) {
    final reached = current.clamp(1, slots.length);
    final centers = [for (final s in slots) s.center];
    return (
      done: _straight(centers.sublist(0, reached)),
      locked: _straight([...centers.sublist(reached - 1), pathEnd]),
    );
  }

  static List<Offset> _straight(List<Offset> points) {
    final result = <Offset>[];
    for (final p in points) {
      if (result.length >= 2) {
        final a = result[result.length - 2];
        final b = result.last;
        final cross =
            (b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx);
        if (cross.abs() < 1e-9) result.removeLast();
      }
      result.add(p);
    }
    return result;
  }
}
```

(`-currentChipWidth / 2` dalam `const Offset` → pakai `Offset(-currentChipWidth / 2, -76)` tanpa `const` bila analyzer menolak.)

- [ ] **Step 4:** `flutter test test/screens/level_map_layout_test.dart` → PASS.
- [ ] **Step 5: Test layar (gagal)** — `test/screens/progress_screens_test.dart`:

```dart
import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:busy_network/game/sim/sim.dart';
import 'package:busy_network/screens/design_phase/design_phase_screen.dart';
import 'package:busy_network/screens/level_map/level_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/sim/sim_fixtures.dart';
import '../test_helpers.dart';
import 'run_fixtures.dart';

GameSession _with(Progress progress) =>
    GameSession(progress: ProgressBook(MemoryProgressStore(progress)));

void main() {
  setUpFonts();

  testWidgets('Peta: level 5 selesai, level 6 sekarang tapi belum tersedia', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      location: AppRoutes.levelMap,
      session: _with(Progress(const {1: 3, 2: 2, 3: 3, 4: 1, 5: 3})),
    );
    expect(find.bySemanticsLabel('Bintang terkumpul 12 dari 36'), findsOneWidget);
    expect(find.bySemanticsLabel('Level 5, 3 bintang'), findsOneWidget);
    expect(find.text('Gang Melati'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Level 6, belum tersedia'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelMapScreen), findsOneWidget);
    expect(find.byType(DesignPhaseScreen), findsNothing);
    semantics.dispose();
  });

  testWidgets('Beranda membaca progres', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      session: _with(Progress(const {1: 3, 2: 2, 3: 3, 4: 1, 5: 3})),
    );
    expect(find.text('5 / 12 level'), findsOneWidget);
    expect(find.bySemanticsLabel('Bintang terkumpul 12 dari 36'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('menang level 5 → Level Berikutnya → peta berubah', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    final session = GameSession()..begin(winningDay(minute: 23 * 60));
    await pumpApp(tester, location: AppRoutes.run, session: session, settle: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Level Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Level 5, 3 bintang'), findsOneWidget);
    expect(find.bySemanticsLabel('Level 6, belum tersedia'), findsOneWidget);
    expect(find.bySemanticsLabel('Bintang terkumpul 12 dari 36'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('progres bertahan saat aplikasi dibuka ulang', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    final store = MemoryProgressStore();
    final first = GameSession(progress: ProgressBook(store));
    final day = winningDay(minute: SimClock.dayStart);
    first.begin(day);
    playDay(day);
    first.finish();
    await pumpApp(
      tester,
      location: AppRoutes.levelMap,
      session: GameSession(progress: ProgressBook(store)),
    );
    expect(find.bySemanticsLabel('Level 5, 3 bintang'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('semua level 1–11 selesai: peta tetap tampil', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      location: AppRoutes.levelMap,
      session: _with(Progress({for (var n = 1; n <= 11; n++) n: 1})),
    );
    expect(find.bySemanticsLabel('Level 11, 1 bintang'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('main sekarang|belum tersedia')), findsNothing);
    semantics.dispose();
  });
}
```

- [ ] **Step 6:** `flutter test test/screens/progress_screens_test.dart` → FAIL.
- [ ] **Step 7: Implementasi layar.**
  - `level_node.dart`: `enabled: !locked && onPressed != null,` (onTap tetap).
  - `level_map_painter.dart`: `LevelMapBackdrop({super.key, required this.current})`, `final int current;`, painter `id: 'level-map-$current'`, `_draw` jadi metode instance yang memakai `LevelMapLayout.paths(current)`:

```dart
    final paths = LevelMapLayout.paths(current);
    SvgDraw.stroke(
      canvas,
      _svg(paths.locked),
      AppColors.mapPathLocked,
      8,
      dash: const [2, 14],
    );
    if (paths.done.length >= 2) {
      final done = _svg(paths.done);
      SvgDraw.stroke(canvas, done, AppColors.primary, 9);
      SvgDraw.traffic(canvas, done, AppColors.trafficMap, width: 5);
    }
```

dengan

```dart
  /// Path SVG garis lurus melewati [points].
  static String _svg(List<Offset> points) => [
    for (final (i, p) in points.indexed)
      '${i == 0 ? 'M' : 'L'}${_n(p.dx)} ${_n(p.dy)}',
  ].join(' ');

  static String _n(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';
```

  - `level_map_screen.dart`: `const LevelMapScreen({super.key, required this.progress}); final ProgressBook progress;`; `build` dibungkus `ListenableBuilder(listenable: progress, builder: (context, _) => _build(context, progress.progress))`. Header: `Levels.chapter.number`, `Levels.chapter.name`, `StarCounterPill(value: p.totalStars, total: Levels.chapter.starsTotal)`. Stage:

```dart
                children: [
                  Positioned.fill(child: LevelMapBackdrop(current: p.current)),
                  for (final slot in LevelMapLayout.slots)
                    ..._entry(context, slot, p),
                  if (LevelMapLayout.slotOf(p.current) case final slot?)
                    if (Levels.byNumber(p.current) case final level?)
                      _at(LevelMapLayout.chipTopLeft(slot), _chip(level.name)),
                ],
```

  `_chip(String name)` = isi chip lama (SizedBox lebar `currentChipWidth` + Container ink + Text). `_entry`:

```dart
  List<Widget> _entry(BuildContext context, LevelSlot slot, Progress p) {
    final n = slot.number;
    final state = LevelMapLayout.stateOf(p, n);
    final level = Levels.byNumber(n);
    final current = state == LevelNodeState.current;
    final locked = state == LevelNodeState.locked;
    final topLeft = LevelMapLayout.nodeTopLeft(slot, state);
    final node = LevelNode(
      number: n,
      state: state,
      onPressed: locked || level == null
          ? null
          : () => context.go(AppRoutes.play(n)),
      semanticLabel: switch (state) {
        LevelNodeState.locked => 'Level $n terkunci',
        LevelNodeState.current when level != null =>
          'Level $n, ${level.name}, main sekarang',
        LevelNodeState.current => 'Level $n, belum tersedia',
        LevelNodeState.done =>
          'Level $n, ${p.starsOf(n)} bintang${n == 1 ? ', tutorial' : ''}',
      },
    );
    return [
      if (current) _at(topLeft, const IgnorePointer(child: _PulseRing())),
      _at(topLeft, node),
      _at(
        LevelMapLayout.labelTopLeft(slot, state),
        ExcludeSemantics(
          child: locked
              ? SizedBox(
                  width: slot.labelBeside ? null : AppSizes.levelNode,
                  child: Text(
                    '$n',
                    textAlign: slot.labelBeside ? TextAlign.left : TextAlign.center,
                    style: AppTypography.captionStrong.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                )
              : SizedBox(
                  width: AppSizes.levelNode,
                  child: Center(child: StarRating(earned: p.starsOf(n))),
                ),
        ),
      ),
    ];
  }
```

  Hapus `_open` dan komentar lama soal Gang Melati dummy.
  - `home_screen.dart`: `const HomeScreen({super.key, required this.progress}); final ProgressBook progress;`, `ListenableBuilder` di sekitar `Scaffold`; `StarCounterPill(value: p.totalStars, total: Levels.chapter.starsTotal, ...)`; `_ChapterCard(chapter: Levels.chapter, progress: p)` dengan `'${progress.levelsDone(chapter.levelCount)} / ${chapter.levelCount} level'` dan `ProgressBar(value: progress.levelsDone(chapter.levelCount) / chapter.levelCount, ...)`.
  - `router.dart`: `HomeScreen(progress: play.progress)`, `LevelMapScreen(progress: play.progress)`.
  - `dummy_data.dart`: hapus `ChapterInfo` & `chapter`; perbarui doc library.

- [ ] **Step 8:** `flutter test` → PASS (animation_test cincin level, navigation, overflow); `flutter analyze` bersih.
- [ ] **Step 9:** `git commit -m "feat(screens): home and level map read saved progress"`

---

### Task 9: `main()`, dokumentasi, verifikasi akhir

**Files:**
- Modify: `lib/main.dart`, `CLAUDE.md`, `docs/DESIGN_NOTES.md`, `docs/ROADMAP.md`

- [ ] **Step 1:** `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font dibundel di assets/google_fonts → tidak perlu unduh saat runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final progress = await _openProgress();
  runApp(JaringanSibukApp(session: GameSession(progress: progress)));
}

/// Progres tersimpan di perangkat; bila penyimpanannya tidak bisa dibuka,
/// permainan tetap jalan dengan progres di memori.
Future<ProgressBook> _openProgress() async {
  try {
    return ProgressBook(await PrefsProgressStore.open());
  } on Object catch (error) {
    debugPrint('Progres tidak bisa dibuka: $error');
    return ProgressBook.memory();
  }
}
```

- [ ] **Step 2: Dokumentasi.**
  - `CLAUDE.md` › Struktur: tambah `lib/game/result/` (`LevelResult`: bintang dari batas lulus/target/hemat, biang kerok `Culprit`, rumah pindah) dan `lib/game/progress/` (`Progress`: bintang terbaik per level, terbuka diturunkan, JSON); `lib/app/` + `progress_book.dart` (`ProgressBook`), `GameSession` kini juga `finish()`/`result`/`progress`; `lib/data/` + `progress_store.dart` (`PrefsProgressStore`, `MemoryProgressStore`), `dummy_data.dart` = progres awal & potret hasil. Aturan: test memakai progres memori (default `GameSession`); deep link layar hasil = potret `DummyData`; hanya hari dari Fase Rancang yang dicatat.
  - `DESIGN_NOTES.md`: ganti butir "Level 2–5 di peta…" (level tanpa data tidak bisa diketuk; progres awal seperti desain), butir "Hasil Berhasil menerima ?bintang…" (potret hanya untuk deep link; hasil asli dari hari), dan "24:00 → Hasil Berhasil bila kepuasan ≥ target" → batas lulus; tambah ringkasan aturan bintang/biang kerok/rumah pindah dengan rujukan spec.
  - `ROADMAP.md`: langkah 7 + "atur `savingsTarget` level 1 supaya 3★ mungkin"; langkah 8 + "ganti `DummyData.progress` jadi mulai dari level 1".
- [ ] **Step 3:** `flutter analyze` → bersih; `flutter test` → hijau.
- [ ] **Step 4:** `flutter test test/screenshots --dart-define=SCREENSHOTS=true`, bandingkan `01`, `02`, `07-*`, `08` dengan `design/reference/` (harus identik dengan sebelum langkah ini).
- [ ] **Step 5:** `git commit -m "docs: results, stars and saved progress"`
