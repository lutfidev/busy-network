# Jaringan Sibuk — panduan untuk Claude

Game puzzle mobile (Flutter + Flame, Android, portrait). Pemain jadi
pengelola RT/RW Net: tarik kabel dari router ke rumah, jaga trafik tetap
lancar saat jam sibuk.

## Sumber kebenaran visual
- `design/Jaringan Sibuk.html` — export desain (8 layar + "Design token &
  komponen"). Ukuran, warna, font, jarak, dan copy teks **ambil persis**
  dari sini. File ini bundel terkompres; untuk membacanya ekstrak dulu
  (lihat `docs/DESIGN_NOTES.md`).
- `design/reference/*.png` — render tiap layar 390×844 untuk dibandingkan.

## Perintah
```bash
flutter pub get
flutter analyze                 # harus bersih
flutter test                    # harus hijau (test screenshot di-skip)
flutter test test/screenshots --dart-define=SCREENSHOTS=true
                                # → build/screenshots/{390x844,360x740}/*.png
flutter run                     # perangkat/emulator Android
```
Belum ada Flutter? `source scripts/setup_flutter.sh`.

## Struktur
- `lib/theme/` — token: `AppColors`, `AppTypography` (Fredoka/Nunito,
  tabular figures), `AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion`,
  `AppSizes`, `AppTheme`. Import lewat `theme/theme.dart`.
- `lib/widgets/` — komponen reusable (barrel `widgets/widgets.dart`):
  `ChunkyButton`, `CircleIconButton`, badge/pill, `StarRating`, `AppCard`,
  `StatTile`, `ProgressBar`, `LevelNode`, `CableOptionCard`,
  `LevelHeaderCard`, `BottomPanel`, `DesignStage`,
  `GameIcon` (path SVG asli dari desain), `FillScrollView`, `LoopClock`
  (jam animasi berulang).
- Animasi: `@keyframes` desain disalin jadi token `Keyframes` di
  `AppMotion` (persen + easing per segmen, persis CSS), digerakkan
  `LoopClock` (detik berjalan → pose). Pose peta di
  `game/render/map_motion.dart`, digerakkan `update(dt)` `NetworkGame`.
- `lib/game/` — `model/` (`LevelDef` + geometri grid (`snap`, `Cell`),
  `HouseDef`, `Cable`/`CableSpec`/`CableDraft`, `CableWalk` +
  `cablePolyline` (jalur tarikan di grid), `Network` topologi & beban,
  `GameState` fase rancang/jalan/hasil, anggaran, tarik kabel
  `beginCable`/`dragCable`/`endCable`, `removeCable`, mode hapus),
  `levels/levels.dart` (data level),
  `scene_builder.dart` (`SceneBuilder.fromState(state)` → `MapScene`),
  `map_scene.dart` (model gambar), `render/map_renderer.dart` (gambar
  rumah/router/kabel/trafik di atas `Canvas`, per lapisan),
  `network_game.dart` (`NetworkGame`: `FlameGame`, kamera
  `withFixedResolution(390, 472)`, mendengarkan `GameState` dan
  menyamakan komponen; bila `interactive`, node menerima drag = tarik
  kabel dan kabel menerima ketuk = bongkar), `components/` (`GroundComponent`,
  `CableComponent`, `TrafficComponent`, `RouterComponent`/`HouseComponent`/
  `JunctionComponent`, `BadgeComponent`, `DragHandleComponent`; semuanya
  menggambar lewat `MapRenderer`), `network_game_view.dart`
  (`NetworkGameView`: `GameWidget` + overlay widget berkoordinat peta;
  dipakai Tutorial/Rancang/Jalan; hanya Rancang yang `interactive`).
- `lib/screens/<layar>/` — satu folder per layar (8 layar).
- `lib/app/` — `routes.dart` (path), `router.dart` (go_router, bersarang),
  `app.dart`.
- `lib/data/` — `dummy_states.dart` (snapshot `GameState` Tutorial &
  Jalan; Rancang memakai state asli) dan
  `dummy_data.dart` (angka yang belum dihitung game: progres, jam,
  komplain, hasil).
- `lib/core/format.dart` — `IdFormat`: `Rp 850.000`, `8,5 Mbps`, `20:15`.
- `lib/gallery/` — galeri komponen (rute `/galeri`, tombol pengaturan di
  Beranda).

## Aturan
- **Jangan hardcode warna/ukuran di widget.** Tambah token di `lib/theme/`
  kalau butuh nilai baru. Koordinat peta/ilustrasi dari desain boleh
  ditulis sebagai data (kanvas 390×844 atau area peta 390×472).
- Angka selalu lewat `IdFormat` (format Indonesia).
- Copy teks Bahasa Indonesia persis seperti desain; jangan dipotong
  (`ellipsis`) — pakai wrap atau `FittedBox(scaleDown)`.
- Wajib bebas overflow di lebar 360 px: `test/screens/overflow_test.dart`
  mengecek semua rute di 360×640 s.d. 412×915 dan teks 130%. Rute baru →
  tambahkan ke daftar di test itu dan di `test/screenshots/`.
- Tombol/kontrol kustom: bungkus `Semantics(container: true, button: true,
  label: ...)`.
- Animasi tak berujung membuat `pumpAndSettle` macet. Animasi berulang
  wajib lewat `LoopClock` (berhenti di pose `still` bila
  `MediaQuery.disableAnimations`); animasi sekali jalan langsung ke akhir.
  Peta Flame: mesin `NetworkGame` hanya jalan bila scene bergerak dan
  animasi boleh; selain itu tiap perubahan digambar satu bingkai lalu
  mesin berhenti sendiri (`pumpAndSettle` aman).
  Test memompa app lewat `pumpApp`/`disableAnimations` di
  `test/test_helpers.dart`; uji gerakannya di
  `test/screens/animation_test.dart` (tanpa `pumpAndSettle`).
- Peta: kamera Flame beresolusi tetap 390×472 (koordinat desain, (0, 0)
  kiri atas). Overlay Flutter di atas peta (tooltip, banner, pop-up) tetap
  widget, diletakkan dengan koordinat peta lewat `NetworkGameView.overlays`
  (`DesignStage`). Gaya gambar hanya di `MapRenderer`;
  `test/game/network_game_test.dart` membandingkan piksel game dengan
  `MapRenderer.drawScene`.
- Peta digambar dari state: ubah data level / `GameState`, bukan
  `MapScene` atau komponen langsung. `test/game/scene_builder_test.dart` menjaga snapshot
  tetap identik dengan desain (Fase Rancang: tarikan sungguhan
  `test/game/design_pull.dart`).
- Input peta: logika (snap, rute, biaya, bongkar) di `GameState`, diuji
  tanpa Flutter; komponen Flame hanya uji sentuh lalu memanggil API
  berbasis id. Widget test menyeret peta lewat `dragOnMap`/`mapToScreen`
  di `test/test_helpers.dart`.
- Commit kecil per langkah, pesan bahasa Inggris singkat
  (`feat(scope): ...`, `fix: ...`, `test: ...`).

## Alur git per langkah roadmap
Pemilik repo biasanya `/clear` setelah tiap sesi, jadi aturan ini yang
berlaku, bukan ingatan percakapan. Kerjakan sendiri tanpa bertanya dan
tanpa menyuruh pemilik repo menjalankan perintah:
- **Awal langkah:** `git fetch`, pastikan PR langkah sebelumnya sudah
  di-merge ke `origin/main`, lalu `git checkout main && git pull --ff-only`,
  buat `feat/<nama-langkah>`, hapus branch lokal yang sudah di-merge,
  `flutter pub get && flutter analyze && flutter test`. Kalau PR sebelumnya
  belum di-merge, jangan bercabang dari `main` lama; beri tahu pemilik repo.
- **Akhir langkah** (analyze bersih, test hijau, temuan review sudah
  diperbaiki): `git push -u origin <branch>` lalu `gh pr create --base main`
  langsung, tanpa menu pilihan. Kirim link PR-nya. Badan PR berbahasa
  Indonesia, gaya PR #2/#3: daftar perubahan, lalu baris "Verifikasi:".
- **Merge PR** dilakukan pemilik repo di GitHub; jangan merge sendiri
  kecuali diminta.
- Kesepakatan baru soal alur kerja langsung dicatat di file ini, jangan
  hanya diucapkan di chat.

## Lanjut ke mana
Lihat `docs/ROADMAP.md` — langkah berurutan beserta prompt siap tempel.
