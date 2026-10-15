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
  `LevelHeaderCard`, `BottomPanel`, `NetworkMapView`, `DesignStage`,
  `GameIcon` (path SVG asli dari desain), `FillScrollView`, `LoopClock`
  (jam animasi berulang).
- Animasi: `@keyframes` desain disalin jadi token `Keyframes` di
  `AppMotion` (persen + easing per segmen, persis CSS), digerakkan
  `LoopClock` (detik berjalan → pose). Pose peta di
  `game/render/map_motion.dart`.
- `lib/game/` — `model/` (`LevelDef`, `HouseDef`, `Cable`/`CableSpec`/
  `CableDraft`, `Network` topologi & beban, `GameState` fase
  rancang/jalan/hasil), `levels/levels.dart` (data level),
  `scene_builder.dart` (`SceneBuilder.fromState(state)` → `MapScene`),
  `map_scene.dart` (model gambar) dan `render/map_renderer.dart` (gambar
  rumah/router/kabel/trafik di atas `Canvas`; dipakai CustomPainter
  sekarang, dan bisa dipanggil dari `render()` komponen Flame).
- `lib/screens/<layar>/` — satu folder per layar (8 layar).
- `lib/app/` — `routes.dart` (path), `router.dart` (go_router, bersarang),
  `app.dart`.
- `lib/data/` — `dummy_states.dart` (snapshot `GameState` per layar) dan
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
  Test memompa app lewat `pumpApp`/`disableAnimations` di
  `test/test_helpers.dart`; uji gerakannya di
  `test/screens/animation_test.dart` (tanpa `pumpAndSettle`).
- Peta: koordinat desain diskalakan seragam lewat `DesignStage`
  (padanan `FixedResolutionViewport` Flame).
- Peta digambar dari state: ubah data level / `GameState`, bukan
  `MapScene` langsung. `test/game/scene_builder_test.dart` menjaga snapshot
  tetap identik dengan desain.
- Commit kecil per langkah, pesan bahasa Inggris singkat
  (`feat(scope): ...`, `fix: ...`, `test: ...`).

## Lanjut ke mana
Lihat `docs/ROADMAP.md` — langkah berurutan beserta prompt siap tempel.
