# Langkah 2 — Model level & state game

Tanggal: 2026-10-15 · Branch: `feat/model-level` · Roadmap: langkah 2.

## Tujuan

Definisi level menjadi data (`LevelDef`), state permainan terpisah dari UI
(`GameState`), dan peta di Tutorial / Fase Rancang / Fase Jalan digambar
dari state lewat `SceneBuilder.fromState(state)` alih-alih `DummyScenes`.

**Berhasil bila:**
- Layar tampil identik. Test membandingkan `MapScene` hasil `fromState`
  dengan scene lama (salinan `DummyScenes` di test) field demi field:
  posisi, urutan gambar, label, status, badge.
- Ada unit test model (grid, sudut kabel, topologi, beban, biaya, fase).
- `flutter analyze` bersih, `flutter test` hijau.

**Di luar cakupan:** tarik kabel & bongkar (langkah 4), simulasi & logika
antrean (5), bintang & progres (6), berbagi state antar-layar (4/5),
Flame (3).

## Keputusan

1. **Level 5 mulai dengan jaringan yang sudah ada**: junction atas `j1`,
   kabel ke Rumah 1, Rumah 3 (lewat `j1`), Rumah 4, dan fiber ke Warung
   (lewat `j1`). Anggaran Rp 850.000 adalah sisa untuk memperluas. Ini
   tafsiran dari desain: "4/7 rumah tersambung" dengan "Sisa anggaran
   Rp 850.000" di Fase Rancang.
2. **Grid 30 px dengan titik asal per level.** Titik grid yang digambar
   (`drawDotGrid`) ada di (15 + 30i, 15 + 30j). Level 1 pas di titik itu;
   level 5 bergeser 15 px vertikal (node di y = 60, 90, 240, …). Koordinat
   tidak diubah; `LevelDef.gridOrigin` = (15, 15) untuk level 1 dan
   (15, 0) untuk level 5. Langkah 4 harus snap ke grid level.
3. **Hitungan segmen kabel** = jumlah panjang tiap ruas dalam jarak
   Chebyshev (`max(|dx|, |dy|)`, jadi langkah diagonal = 1) dibagi 30,
   dibulatkan, minimal 1. Kabel yang sedang ditarik di desain
   (195,264)→(195,300)→(255,360) = (36 + 60) / 30 = 3,2 → **3 segmen**,
   cocok dengan "3 segmen · Rp 45.000". Langkah 4 boleh menyempurnakan.
4. **Satu-satunya beda visual yang disengaja:** bar sabar Rumah 4 di
   desain lebarnya 7/40 (17,5%) padahal labelnya "sabar 15%". Model
   menyimpan satu nilai sabar (0,15) dan label diturunkan darinya, jadi bar
   menyusut 1 px (7 → 6, batas minimum bar). Scene lama di test ikut
   disesuaikan dengan komentar.
5. **Data pengisi yang dikarang** (tidak ada di desain): pelanggan, paket,
   dan pemakaian puncak Rumah 1–2 level 1. Ditandai `// TODO(langkah 5/8)`.
6. **Snapshot belum memotong anggaran.** Tutorial langkah 3 tetap
   Rp 200.000 seperti desain; pemotongan biaya baru di langkah 4.
7. **Kabel lewat junction** (`via`). Di desain, fiber ke Warung digambar
   sebagai satu polyline yang melewati `j1`, dan kabel ke Rumah 6 melewati
   `j2`. Supaya gambar identik (fase titik trafik satu polyline), satu
   `Cable` menyimpan polyline utuh plus daftar junction yang dilewatinya.
   Topologi memecahnya menjadi *hop* antar-node.
8. **Data antrean diturunkan dari model** (nama pelanggan, tempat, paket,
   pemakaian, rumah di kabel penuh, kapasitas, judul "Kabel Router →
   Rumah 4"). Logika `QueueModel` (termasuk keanehan prototipe: Rumah 4
   macet, Rumah 3 selalu lambat) tetap sampai langkah 5. Jam, kepuasan,
   pesan komplain, dan angka hasil tetap di `DummyData`.
9. **`GameState` dibuat per layar** dari snapshot di `lib/data/`. Berbagi
   satu state Rancang → Jalan → Hasil menunggu langkah 4/5.

## Struktur

```
lib/game/model/
  cable.dart        CableSpec, Cable, CableDraft
  level_def.dart    LevelDef, HouseDef, Junction, MarkSide
  network.dart      Network, Hop (topologi & beban)
  game_state.dart   GameState, GamePhase, SimFrame, HouseLive
  model.dart        barrel
lib/game/levels/levels.dart    Levels.level1, Levels.level5
lib/game/scene_builder.dart    SceneBuilder.fromState
lib/data/dummy_states.dart     snapshot GameState per layar (ganti dummy_scenes.dart)
```

Model memakai enum yang sudah ada di `map_scene.dart` (`CableKind`,
`HouseState`, `PatiencePlacement`) dan `MapBlockLabel`. Model tidak boleh
mengimpor Flutter widget/tema; `dart:ui` (`Offset`) boleh.

### `cable.dart`

```dart
class CableSpec {            // pindah dari dummy_data.dart
  kind, name, pricePerSegment, capacityMbps, tagline, unlockLevel
  static const lan   = CableSpec(lan,   'LAN',   15000,  20, 'murah',  unlockLevel: 1);
  static const fiber = CableSpec(fiber, 'Fiber', 60000, 100, 'ngebut', unlockLevel: 3);
  static const all = [lan, fiber];
  static CableSpec of(CableKind kind);
}

/// Jumlah segmen polyline (keputusan 3).
int segmentCount(List<Offset> points);

/// Ruas 0°/45°/90°?
bool isGridAngle(Offset a, Offset b);

class Cable {
  id, from, to, kind, points, via = const [], badgeAt (Offset?)
  CableSpec get spec;
  int get segments => segmentCount(points);
  int get cost => segments * spec.pricePerSegment;
  List<String> get stops => [from, ...via, to];
  /// Letak badge "Penuh!": [badgeAt] atau titik tengah polyline (menurut
  /// panjang) + (0, 36).
  Offset get badgeCenter;
}

class CableDraft {
  from, kind, points,
  target (String?)   // rumah bercincin snap
  handle (Offset?)   // posisi jari; null = tarikan dipandu (tutorial)
  int get segments; CableDraft withKind(CableKind);
}
```

### `level_def.dart`

```dart
enum MarkSide { below, right, above }

class HouseDef {
  id, label, position, customer, place (default = label),
  packageMbps (int), peakMbps (double, pemakaian saat jam sibuk),
  labelSide = below,      // fase rancang: right → label di kanan (44, 5), rata kiri
  patienceSide = below,   // fase jalan: letak bar sabar; right → label rata kiri
}

class Junction { id, position }

class LevelDef {
  static const cell = 30.0;          // == AppSpacing.mapCell (dites)
  static const routerId = 'router';
  number, name, gridOrigin, routerPosition, routerLabel (String?),
  houses, junctions = [], cables = [] (jaringan awal),
  budget, targetSatisfaction, rushHourFrom?, rushHourTo?,
  blockLabels, nightBlockLabels? (default = blockLabels)
  List<CableSpec> get unlockedCables;  // unlockLevel <= number
  HouseDef house(String id);
  Offset positionOf(String nodeId);    // router, rumah, atau junction level
  bool onGrid(Offset p);
}
```

### `network.dart`

```dart
class Hop { Cable cable; String from; String to; }

class Network {
  Network({required LevelDef level, required List<Junction> junctions,
           required List<Cable> cables});
  Set<String> get connectedHouses;  // terjangkau dari router
  Hop? parentOf(String nodeId);
  Set<String> housesBelow(String nodeId);   // termasuk node itu bila rumah
  double hopLoad(Hop hop, Map<String, double> usage);
  double cableLoad(Cable c, Map<String, double> usage);  // hop terberat
  bool isOverloaded(Cable c, Map<String, double> usage); // ada hop > kapasitas
  /// Ada hop milik kabel ini atau di hulunya yang kelebihan beban.
  bool isJammed(Cable c, Map<String, double> usage);
}
```

Penelusuran dari router lewat hop; node yang sudah dikunjungi diabaikan
(aman dari siklus). Rumah tidak tersambung tidak ikut beban.

### `game_state.dart`

```dart
enum GamePhase { design, run, result }

class HouseLive { HouseState state; double patience; double usageMbps; }
class SimFrame { Map<String, HouseLive> houses; Map<String, double> get usage; }

class GameState extends ChangeNotifier {
  GameState(LevelDef level, {phase = design, budget (default level.budget),
    junctions (default level.junctions), cables (default level.cables),
    selectedCable = CableKind.lan, draft, frame});
  level, phase, budget, junctions, cables (unmodifiable), selectedCable,
  draft, frame;
  Network get network;
  Set<String> get connectedHouses; int get connectedCount;
  int get draftCost;                 // 0 bila tanpa draft
  void selectCable(CableKind kind);  // ArgumentError bila belum terbuka;
                                     // draft ikut berganti jenis
  void setDraft(CableDraft? draft);  // hanya fase rancang
  void startDay();                   // rancang → jalan; buang draft; frame awal:
                                     // rumah tersambung ok, sabar 1, pakai 0
  void updateFrame(SimFrame frame);  // hanya fase jalan
  void finishDay();                  // jalan → hasil
}
```

Transisi tidak sah → `StateError`. Tiap mutasi memanggil
`notifyListeners()`.

### `SceneBuilder.fromState(GameState s) → MapScene`

- **Tema:** `run` → malam, lainnya siang. Label blok malam pakai
  `nightBlockLabels ?? blockLabels`.
- **Beban** hanya dihitung di fase jalan dengan `frame` (pemakaian dari
  `frame.usage`); di fase lain tidak ada kabel kelebihan beban/trafik.
- **Kabel:** urutan `s.cables`, kabel kelebihan beban dipindah ke akhir
  (digambar di atas, urutan stabil). Lalu draft (status `drafting`, jenis
  draft) paling akhir.
  - Fase jalan: `overloaded` → state `overloaded`, LAN jadi `thick`;
    trafik `jam` bila `isJammed`, `flow` bila beban > 0, selain itu `none`.
- **Badge:** tiap kabel kelebihan beban → `"Penuh! ${ratio(beban, kapasitas)}"`
  di `badgeCenter`.
- **Node:** junction (urutan `s.junctions`), rumah (urutan level), router.
  - Rancang: rumah tersambung → `connected`, lainnya `idle`;
    `snapTarget` = `draft.target`; `labelSide == right` → `labelOffset`
    (44, 5), rata kiri.
  - Jalan: rumah dengan `HouseLive` → status & sabar dari frame,
    `patiencePlacement` dari `patienceSide`, rata kiri bila `right`.
    Status `jam` → label `"<label> · sabar <persen>"`, `labelEmphasis`,
    `alarm`.
  - Router: `routerLabel`; `routerAlarm` = ada kabel kelebihan beban.
- **`dragHandle`** = `draft.handle`.

## Data level (persis dari `dummy_scenes.dart` / `dummy_data.dart`)

**Level 1 · Rumah Pertama** — anggaran 200.000, target 60, tanpa jam
sibuk, grid asal (15, 15), router (105,315) label "Router", Rumah 1
(255,165), Rumah 2 (315,345), label blok "BLOK A" (255,112) tengah.
Data pengisi (keputusan 5): Rumah 1 "Pak Joko" paket 10, puncak 6;
Rumah 2 "Bu Lina" paket 10, puncak 4.

**Level 5 · Gang Melati** — anggaran 850.000, target 80, jam sibuk 19–22,
grid asal (15, 0), router (195,240) tanpa label, `j1` (195,150).

| id | label | posisi | pelanggan | tempat | paket | puncak | labelSide | patienceSide |
|----|-------|--------|-----------|--------|-------|--------|-----------|--------------|
| r1 | Rumah 1 | 75,90 | Pak Anton | – | 10 | 4 | below | below |
| w | Warung | 195,60 | Warung Bu Ijah | Blok A | 20 | 12 | right | right |
| r3 | Rumah 3 | 315,90 | Kak Dewi | – | 10 | 8,5 | below | below |
| r4 | Rumah 4 | 315,240 | Bu Sri | – | 20 | 16 | below | above |
| r5 | Rumah 5 | 315,390 | Pak Rudi | – | 10 | 9 | below | below |
| r6 | Rumah 6 | 195,420 | Bang Togar | – | 20 | 11 | below | right |
| r7 | Rumah 7 | 75,330 | Mbak Wulan | – | 10 | 6 | below | below |

Kabel awal: `c-r1` j1→r1 [(195,150),(135,90),(95,90)]; `c-r3` j1→r3
[(195,150),(255,90),(295,90)]; `c-r4` router→r4 [(219,240),(295,240)],
badge (262,276); `c-w` fiber router→w via j1 [(195,216),(195,80)].

Label blok siang: BLOK A (300,30) tengah, BLOK B (376,320) kanan,
BLOK C (40,402). Malam: BLOK A (300,24), BLOK B (376,452), BLOK C (40,402).

## Snapshot (`lib/data/dummy_states.dart`)

- `tutorial(step)`: 1 → level 1 polos; 2 → draft LAN router→Rumah 1
  [(105,315),(255,165)] tanpa target & tanpa jari; 3 → kabel `c-r1` dengan
  titik yang sama.
- `design(kind)`: level 5, `selectedCable` = kind, draft dari router
  [(195,264),(195,300),(255,360)], target r5, jari (255,360).
- `run()`: level 5 fase jalan, junction j1 + `j2` (195,330), kabel dengan
  urutan c-r1, c-r3, `c-r6` router→r6 via j2 [(195,264),(195,400)],
  `c-r7` j2→r7 [(195,330),(95,330)], `c-r5` r4→r5 [(315,260),(315,370)],
  c-w, c-r4. Frame: pemakaian = `peakMbps`, status & sabar r1 ok 36/40,
  w ok 34/40, r3 slow 22/40, r4 jam 0,15, r5 slow 16/40, r6 ok 32/40,
  r7 ok 30/40.
- Antrean: urutan r4, r5, r3, w, r1, r6, r7; prioritas awal {w};
  `QueueHouse` dibangun dari `HouseDef` + frame; `onOverloadedCable` =
  rumah di bawah kabel kelebihan beban; kapasitas & judul dari kabel itu.

## Perubahan layar

- **Tutorial:** state = `DummyStates.tutorial(step)`; header & "x/2 rumah
  tersambung" dari state; kartu kabel dari `CableSpec`.
- **Fase Rancang:** memegang `GameState` (`ListenableBuilder`, dispose);
  pilih kabel → `selectCable`; anggaran, catatan "−Rp … sedang ditarik",
  tooltip "N segmen · Rp X", "4/7 rumah tersambung", dan label semantik
  dari state. Mode hapus tetap state lokal UI.
- **Fase Jalan:** jadi `StatefulWidget` yang memegang `DummyStates.run()`.
  Komplain mengambil nama & label rumah dari `HouseDef` (`complaintHouseId`).
- **Kartu status jalan, Peta Babak, Hasil:** `DummyData.level5` →
  `Levels.level5`.
- **Antrean:** `QueueModel.initial()` & judul kabel dari snapshot.
- `DummyData`: hapus `CableSpec`, `LevelInfo`, `lan`, `fiber`,
  `fiberUnlockLevel`, `level1`, `level5`, `draftingSegments`,
  `overloaded*`, `queue*`, `complaintName`, `complaintHouse`. `QueueHouse`
  pindah ke `queue_logic.dart`. `dummy_scenes.dart` dihapus.

## Test

- `test/game/model/cable_test.dart`: `segmentCount` (draft desain = 3,
  tutorial = 5, lurus 120 px = 4, minimal 1), `isGridAngle`, biaya,
  `CableSpec.of`.
- `test/game/model/level_def_test.dart`: tiap level di `Levels.all` punya
  id unik, node di grid, titik belok kabel di grid, ruas 0/45/90°,
  junction `via` terletak di polyline, ujung kabel ≤ 24 px dari node
  asal/tujuan; kabel terbuka (level 1 LAN, level 5 LAN + Fiber);
  `cell == AppSpacing.mapCell`.
- `test/game/model/network_test.dart`: level 5 awal tersambung {r1, w, r3,
  r4}; snapshot jalan: semua 7 tersambung, beban hop router→r4 = 25,
  hanya `c-r4` kelebihan beban, `c-r5` macet, `c-r6` & `c-w` lancar; rumah
  tanpa kabel tidak tersambung; siklus tidak membuat hang.
- `test/game/model/game_state_test.dart`: default dari level; `selectCable`
  ganti jenis draft + notify; jenis terkunci → `ArgumentError`;
  `draftCost` 45.000 / 180.000; transisi fase & `StateError`;
  `startDay` membuang draft & membuat frame.
- `test/game/scene_builder_test.dart` + `test/game/legacy_scenes.dart`
  (salinan `DummyScenes` dengan sabar Rumah 4 = 0,15): tutorial 1–3,
  rancang LAN & Fiber, jalan → identik.
- `test/game/map_motion_test.dart` memakai `SceneBuilder.fromState`.
- Test layar, overflow, navigasi, animasi, antrean yang sudah ada tetap
  hijau tanpa diubah (kecuali impor).
