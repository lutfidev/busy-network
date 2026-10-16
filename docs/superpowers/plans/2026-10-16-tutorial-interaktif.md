# Tutorial Interaktif — Rencana Implementasi

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tutorial level 1 dimainkan sungguhan (tarik Router → Rumah 1, lalu Mulai Hari = hari level 1 asli), status tutorial selesai tersimpan, dan level 1 bisa 3★.

**Architecture:** `CableLesson` di `GameState` membatasi tarikan & memberi kabel panduan (logika murni); `Progress.tutorialDone` disimpan di JSON progres yang sama; `TutorialScreen` memegang satu `GameState` dari langkah 1 sampai 3 dan menyerahkan `planDay()` ke `GameSession`. Rute Fase Jalan/Antrean membawa `?level=n`.

**Tech Stack:** Flutter, Dart 3, Flame, go_router 18, `shared_preferences`, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-16-tutorial-interaktif-design.md`

## Global Constraints

- Jangan hardcode warna/ukuran di widget; koordinat peta desain boleh sebagai data.
- Angka lewat `IdFormat`; copy Bahasa Indonesia persis desain, tanpa `ellipsis`.
- Bebas overflow 360 px; rute baru/varian → `overflow_test` & `screenshots`.
- Kontrol kustom: `Semantics(container: true, button: true, label: ...)`.
- Logika di `lib/game/` murni, dites tanpa Flutter.
- `flutter analyze` bersih, `flutter test` hijau di akhir tiap task; commit per task (`feat(scope): ...`).

## Review Focus

1. Tarikan tutorial dilepas di luar Rumah 1 / ke Rumah 2 → tetap langkah 2, kabel panduan & tangan muncul lagi (Task 1, Task 5).
2. "Mulai Hari" ditekan di langkah 1/2 (sentuhan atau aktivasi semantik) → tidak terjadi apa-apa (Task 5).
3. `"tutorial"` di JSON tersimpan bukan bool → progres awal, tidak crash (Task 2).
4. Back dari hari tutorial → Fase Rancang level 1, bukan level 5 (Task 3, Task 5).
5. Fase Rancang level 1 (tanpa jam sibuk di data, fiber terkunci) tampil tanpa crash/overflow di 360 px (Task 3).

---

### Task 1: `CableLesson` di `GameState`

**Files:**
- Modify: `lib/game/model/cable.dart` (kelas `CableLesson`), `lib/game/model/game_state.dart`, `lib/game/scene_builder.dart`, `lib/game/levels/levels.dart`, `lib/data/dummy_states.dart`
- Test: `test/game/model/game_state_test.dart` (atau file tarik kabel yang ada), `test/game/scene_builder_test.dart` (sudah ada: tutorial langkah 2 = scene legacy)

**Interfaces:**
- Produces: `class CableLesson {const CableLesson({required String from, required String to, required List<Offset> guide})}`; `GameState({..., CableLesson? lesson})`, `CableLesson? get lesson`, `void setLesson(CableLesson? lesson)`, `CableDraft? get guide`; `Levels.tutorialLesson` (`from: LevelDef.routerId, to: 'r1', guide: [Offset(105, 315), Offset(255, 165)]`).

- [ ] **Step 1: Test gagal** — grup `'pelajaran tarikan'`:
  - hanya `from` yang bisa jadi sumber: state level 1 dengan kabel router→r2 + pelajaran → `canStartCable(LevelDef.routerId)` true, `canStartCable('r2')` false (tanpa pelajaran true).
  - menarik dari router ke dekat Rumah 2 `(315, 345)` → `draft?.target` null; `endCable()` → `CableDrop.missed`, `connectedCount` 0.
  - menarik ke Rumah 1 → `CableDrop.connected`, `budget` 125000.
  - `guide`: diam → `points == Levels.tutorialLesson.guide`, `handle` null, `target` null; setelah `beginCable` → null; setelah tarikan batal → muncul lagi; setelah Rumah 1 tersambung → null; tanpa pelajaran → null.
  - `planDay().lesson` null; `setLesson` memberi tahu pendengar.
- [ ] **Step 2: Jalankan** `flutter test test/game/model` → FAIL (`CableLesson` belum ada).
- [ ] **Step 3: Implementasi** — `canStartCable` + `(lesson == null || nodeId == lesson.from)`; `_snapTarget` lewati id selain `lesson.to`; `guide` = `CableDraft(from, kind: selectedCable, points: guide)` bila `lesson != null && _pull == null && !isConnected(lesson.to)`. `SceneBuilder`: `s.draft ?? s.guide` (fase rancang). `DummyStates.tutorial(2)` = `GameState(Levels.level1, lesson: Levels.tutorialLesson)`.
- [ ] **Step 4: Jalankan** `flutter test test/game` → PASS (termasuk `scene_builder_test` & `network_game_test` tutorial 2 identik).
- [ ] **Step 5: Commit** `feat(game): cable lesson guides and limits the tutorial pull`

### Task 2: Tutorial selesai di progres

**Files:**
- Modify: `lib/game/progress/progress.dart`, `lib/app/progress_book.dart`
- Test: `test/game/progress/progress_test.dart`, `test/app/progress_book_test.dart`, `test/data/progress_store_test.dart`

**Interfaces:**
- Produces: `Progress(Map<int, int> stars, {bool tutorialDone = false})`, `bool get tutorialDone`, `Progress completeTutorial()`; `ProgressBook.completeTutorial() → Future<void>`.

- [ ] **Step 1: Test gagal**:
  - default `tutorialDone` false; `completeTutorial()` → true, bintang tetap; dipanggil lagi → `identical`.
  - `record` mempertahankan flag; `==` membedakan flag.
  - `encode()` progres desain tetap `'{"versi":1,"bintang":{"1":3,"2":2,"3":3,"4":1}}'`; selesai → `'{"versi":1,"bintang":{...},"tutorial":true}'`; bolak-balik.
  - `decode('{"versi":1,"bintang":{},"tutorial":"ya"}')` → null; tanpa kunci → `tutorialDone` false.
  - `ProgressBook.completeTutorial()`: memberi tahu sekali, tersimpan di store, kedua kali tidak memberi tahu.
- [ ] **Step 2: Jalankan** → FAIL.
- [ ] **Step 3: Implementasi** — `ProgressBook` memakai satu `_update(Progress next)` untuk `record` & `completeTutorial`.
- [ ] **Step 4: Jalankan** `flutter test test/game/progress test/app test/data` → PASS.
- [ ] **Step 5: Commit** `feat(progress): remember when the tutorial is done`

### Task 3: Rute berlevel & Fase Rancang level 1

**Files:**
- Modify: `lib/app/routes.dart`, `lib/app/router.dart`, `lib/screens/design_phase/design_phase_screen.dart`, `lib/screens/run_phase/run_phase_screen.dart`, `lib/screens/queue_panel/queue_panel_screen.dart`, `lib/screens/level_map/level_map_screen.dart`, `lib/screens/result_success/result_success_screen.dart`, `lib/screens/result_fail/result_fail_screen.dart`
- Test: `test/screens/result_test.dart`, `test/screens/progress_screens_test.dart`, `test/screens/overflow_test.dart`, `test/screenshots/screenshot_test.dart`

**Interfaces:**
- Consumes: `Progress.tutorialDone` (Task 2).
- Produces: `AppRoutes.play(int number, {required bool tutorialDone})`, `AppRoutes.runOf(int level)` = `'/peta/rancang/jalan?level=n'`, `AppRoutes.queueOf(int level)`; `ResultSuccessScreen({required LevelResult result, required ProgressBook progress})`, `ResultFailScreen` sama.

- [ ] **Step 1: Test gagal**:
  - `play(1, tutorialDone: false)` = `AppRoutes.tutorial`; `play(1, tutorialDone: true)` = `'/peta/rancang?level=1'`; `play(5, tutorialDone: false)` = `'/peta/rancang?level=5'`; `runOf(1)` / `queueOf(5)`.
  - widget: progres dengan tutorial selesai → ketuk "Level 1, 3 bintang" (label tanpa ", tutorial") → `DesignPhaseScreen` judul "Rumah Pertama", teks "Jam sibuk 19–22", "Terbuka di level 3"; Mulai Hari → back → tetap Fase Rancang level 1.
  - Ulangi dari hasil level 1 (sesi dengan hasil level 1, tutorial selesai) → Fase Rancang level 1.
- [ ] **Step 2: Jalankan** → FAIL.
- [ ] **Step 3: Implementasi** — Fase Rancang: `rushHourFrom ?? SimClock.defaultRushFrom` (dan `To`); kartu kabel untuk `CableSpec.all`, yang `unlockLevel > level.number` jadi `CableOptionCard(lockedLabel: 'Terbuka di level N', price: '', capacity: '')`; `_startDay` → `runOf(level.number)`. Fase Jalan `_openQueue` → `queueOf`, Panel Antrean → `runOf`. Router meneruskan `play.progress` ke layar hasil.
- [ ] **Step 4: Tambah** `'${AppRoutes.design}?${AppRoutes.levelParam}=1'` ke `overflow_test` dan `'04-fase-rancang-level-1'` ke screenshot; jalankan `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(app): level-aware run routes; level 1 opens the design phase after the tutorial`

### Task 4: 3★ level 1

**Files:**
- Modify: `lib/game/levels/levels.dart`
- Test: `test/game/result/level_result_test.dart`

- [ ] **Step 1: Test gagal** — grup `'level 1'` (tarikan sungguhan lewat `GameState`, main sampai 24:00 dengan `playDay`):
  - Router → Rumah 1 saja: kepuasan 50, 1★.
  - Router → Rumah 1 + Router → Rumah 2: kepuasan 100, sisa 35000, 3★.
  - Router → Rumah 1 + Router → Rumah 2 lewat jalur memutar 7 segmen: sisa 20000 → 2★.
  - Router → Rumah 1 + Rumah 1 → Rumah 2: sisa 50000 → 3★.
  - `Levels.level1.savingsTarget` 30000.
- [ ] **Step 2: Jalankan** → FAIL (bintang 2).
- [ ] **Step 3: Implementasi** — `savingsTarget: 30000` di `Levels.level1`.
- [ ] **Step 4: Jalankan** `flutter test test/game` → PASS.
- [ ] **Step 5: Commit** `feat(levels): level 1 can earn three stars`

### Task 5: Tutorial interaktif

**Files:**
- Modify: `lib/screens/tutorial/tutorial_screen.dart`, `lib/screens/tutorial/tutorial_steps.dart`, `lib/screens/tutorial/tutorial_overlay.dart`, `lib/app/router.dart`, `lib/app/game_session.dart` (doc)
- Test: `test/screens/tutorial_test.dart` (baru), `test/screens/navigation_test.dart`, `test/screens/animation_test.dart`

**Interfaces:**
- Consumes: `CableLesson`/`Levels.tutorialLesson` (Task 1), `ProgressBook.completeTutorial` (Task 2), `AppRoutes.runOf` (Task 3).
- Produces: `TutorialScreen({required GameSession session, int initialStep = 1})`.

- [ ] **Step 1: Test gagal** (`tutorial_test.dart`, 390×844, `pumpApp`):
  - langkah 2 tanpa "Udah, lanjut"; `dragOnMap` router `(105, 315)` → `(180, 240)` → Rumah 1 `(255, 165)` → "Mantap, Rumah 1 nyala!", "1/2 rumah tersambung", "Rp 125.000".
  - langkah 2: seret ke Rumah 2 `(315, 345)` → tetap "Tarik kabel ke rumah", "0/2 rumah tersambung"; selama jari menempel `find.byType(TutorialHand)` kosong, setelah lepas ada lagi.
  - langkah 1: seret router → Rumah 1 → tetap "0/2"; ketuk "Mulai Hari" → tetap `TutorialScreen`.
  - alur penuh (store memori `Progress({})`): Peta → Level 1 → Lanjut → seret → Mulai Hari → `RunPhaseScreen` level 1 → `pumpAndSettle` → `ResultSuccessScreen`, "50%"; `progress.starsOf(1)` 1, `tutorialDone` true.
  - back Android dari Fase Jalan tutorial (`settle: false`, `tester.binding.handlePopRoute()`) → `DesignPhaseScreen` "Rumah Pertama".
  - Lewati → `tutorialDone` true, Peta; ketuk Level 1 → `DesignPhaseScreen`.
  - store yang sama dipompa ulang → Level 1 membuka Fase Rancang.
- [ ] **Step 2: Jalankan** → FAIL.
- [ ] **Step 3: Implementasi**:
  - `TutorialSteps.steps[1].nextLabel` = null.
  - `SpotlightScrim`: tanpa `IgnorePointer`; `_ScrimPainter.hitTest(p)` = `!hole.contains(p)`.
  - `TutorialScreen`: satu `_game` (`DummyStates.tutorial(initialStep)`), listener: langkah 2 & `isConnected(lesson.to)` → langkah 3. `_next` (1→2) = `setLesson(Levels.tutorialLesson)`. `NetworkGameView(interactive: _step == 2)`. Tangan hanya bila `!_game.pulling`. Mulai Hari: `if (_step != 3) return;` → `completeTutorial`, `session.begin(_game.planDay())`, `go(runOf(1))`. Lewati: `completeTutorial` lalu Peta.
- [ ] **Step 4: Perbarui** `navigation_test` (alur lama "Udah, lanjut") & `animation_test` bila perlu; `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(tutorial): pull the cable for real and start a real level 1 day`

### Task 6: Dokumen

**Files:** `docs/DESIGN_NOTES.md`, `CLAUDE.md`

- [ ] **Step 1:** DESIGN_NOTES: scrim kini menahan sentuhan di luar sorotan; tutorial interaktif & selesai (Mulai Hari/Lewati); Fase Jalan dari tutorial = hari asli (bukan potret); rute `?level=`; `savingsTarget` level 1; Fase Rancang level 1 (kartu terkunci, jam sibuk bawaan). CLAUDE.md: `CableLesson`, `Progress.tutorialDone`, `TutorialScreen` + sesi.
- [ ] **Step 2:** `flutter analyze` bersih, `flutter test` hijau, screenshot (`flutter test test/screenshots --dart-define=SCREENSHOTS=true`) dicek terhadap referensi 03.
- [ ] **Step 3: Commit** `docs: interactive tutorial`
