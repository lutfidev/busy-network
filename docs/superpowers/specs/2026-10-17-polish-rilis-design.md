# Langkah 9 — Polish & rilis

Roadmap: layar Pengaturan (suara, getar, reset progres) menggantikan tautan
ke galeri; efek suara & haptic; ikon launcher & splash dari palet;
`applicationId` final; signing release; `flutter build appbundle`.

Desain tidak punya layar Pengaturan, suara, ikon, atau splash. Semua yang di
bawah adalah keputusan sendiri (pemilik repo minta langsung kerja tanpa
tanya-jawab), memakai token & komponen yang sudah ada.

## Pengaturan
- `Settings` (murni): `sound`, `vibration` (default nyala), `encode`/`decode`
  JSON; `SettingsBook` (`ChangeNotifier`, pola `ProgressBook`): baca dari
  `SettingsStore`, ubah → beri tahu → simpan; gagal simpan tidak
  menghentikan permainan. `PrefsSettingsStore` = kunci `pengaturan` di
  `shared_preferences`, `MemorySettingsStore` untuk test.
- `ProgressBook.reset()` → `Progress.empty` (tutorial ikut diulang).
- Rute `/pengaturan` (ikon di Beranda). Galeri pindah ke
  `/pengaturan/galeri`; barisnya hanya tampil di build non-release.
- Layar terang seperti Peta Babak: tombol kembali + judul "Pengaturan";
  kartu "Suara & getar" berisi dua baris sakelar ("Efek suara", "Getar");
  kartu "Progres" dengan bintang terkumpul dan tombol "Reset progres" (mati
  bila progres masih kosong). Reset minta konfirmasi lewat dialog bergaya
  pop-up komplain: "Reset progres?" · "Semua bintang hilang dan permainan
  mulai lagi dari tutorial level 1." · "Batal" / "Reset".
- Komponen baru `ToggleSwitch` (pill 52×32, kenop putih; nyala = hijau
  `statusOk`), `Semantics(toggled:)`, ikut galeri.

## Suara & getar
- `Cue`: `tap` (tombol), `connect` (kabel terpasang), `refuse` (anggaran
  kurang), `remove` (bongkar), `complaint` (komplain muncul), `win`/`fail`
  (hari selesai, sebelum pindah ke layar hasil).
- `GameFeedback.cue(Cue)`: suara bila `settings.sound`, getar bila
  `settings.vibration`. Keluaran disuntik: `SoundOut` (`AudioSoundOut` =
  `audioplayers` mode `lowLatency`/SoundPool, dua pemain bergiliran per cue,
  dimuat paralel di latar belakang, campur dengan musik lain; default
  diam) dan `HapticOut` (`SystemHaptics` = `HapticFeedback`: tap →
  selectionClick, connect/remove → light, complaint/win → medium,
  refuse/fail → heavy). Test memakai perekam.
- Disediakan `GameSession.feedback`; widget membacanya lewat
  `FeedbackScope.of(context)` (tanpa scope = diam). `NetworkGame` menerima
  callback `onCableDrop` / `onCableRemoved` dari `NetworkGameView`.
- Suara disintesis `tool/make_sounds.py` (sinus + envelope, WAV 16-bit mono
  22,05 kHz) → `assets/audio/*.wav`. Tanpa aset berlisensi.

## Ikon & splash
- Gambar dari glyph logo Beranda (`HomeLogoGlyph`, dipakai juga
  `HomeLogoTile`) di atas `groundNight`. Dirender test
  `test/tool/brand_test.dart` (`--dart-define=BRAND=true`) ke
  `assets/brand/`: `icon.png` (1024, penuh), `icon_foreground.png` (adaptif,
  glyph di zona aman 66%), `splash.png` (ubin logo). Lalu
  `flutter_launcher_icons` & `flutter_native_splash` (konfigurasi di
  `pubspec.yaml`) membuat resource Android. Latar ikon adaptif & splash =
  `groundNight` (#0F1726).

## Android & rilis
- `applicationId` & `namespace` = `dev.lutfidev.jaringansibuk`; label
  "Jaringan Sibuk"; versi `1.0.0+1`.
- Signing: `android/key.properties` (di-`.gitignore`) menunjuk keystore
  upload di luar repo. Tanpa file itu, release ditandatangani kunci debug
  (dengan peringatan) supaya `flutter run --release` tetap jalan.
- `flutter build appbundle` → `build/app/outputs/bundle/release/app-release.aab`.

## Test
- Unit: `Settings` encode/decode, `SettingsBook`, `PrefsSettingsStore`,
  `ProgressBook.reset`, `GameFeedback` mematuhi setelan.
- Widget: Beranda → Pengaturan; sakelar mengubah & menyimpan setelan; reset
  (batal / ya) → Beranda 0 bintang; galeri dari Pengaturan; cue saat tarik
  kabel, gagal anggaran, bongkar, komplain, hari selesai.
- Overflow & screenshot: rute `/pengaturan` dan dialog reset.
