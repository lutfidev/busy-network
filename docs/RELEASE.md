# Rilis Android

## Identitas
- `applicationId` / `namespace`: `dev.lutfidev.jaringansibuk`. Play Store
  tidak mengizinkan ID ini berubah setelah rilis pertama.
- Nama aplikasi: "Jaringan Sibuk" (`android:label`).
- Versi diambil dari `version:` di `pubspec.yaml` (`1.0.0+1` = versionName
  1.0.0, versionCode 1). Naikkan angka setelah `+` tiap kali mengunggah.

## Kunci upload
`android/app/build.gradle.kts` membaca `android/key.properties`. File itu
tidak masuk git (`android/.gitignore`):

```properties
storeFile=C:/Users/<nama>/.android-keys/jaringan-sibuk-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Keystore-nya disimpan di luar repo. **Cadangkan keystore dan
password-nya** (misalnya di pengelola password). Bila Play App Signing
aktif, kunci yang hilang bisa di-reset lewat Play Console, tapi prosesnya
lama. Tanpa `key.properties`, build release ditandatangani kunci debug
(Gradle menulis peringatan) dan Play Console menolaknya.

Membuat keystore baru (bila perlu):
```bash
keytool -genkeypair -v -keystore ~/.android-keys/jaringan-sibuk-upload.jks \
  -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## Build
```bash
flutter analyze && flutter test
flutter build appbundle        # → build/app/outputs/bundle/release/app-release.aab
```

Cek tanda tangan bundle:
```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

## Ikon, splash, suara
- Ikon & splash digambar dari `LogoGlyph` (glyph logo Beranda) di atas
  `groundNight`:
  ```bash
  flutter test test/tool/brand_test.dart --dart-define=BRAND=true
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  git checkout android/app/src/main/AndroidManifest.xml
  ```
  Baris terakhir perlu karena generator splash menulis ulang manifest dan
  membuang `screenOrientation="portrait"`.
- Efek suara: `python tool/make_sounds.py` → `assets/audio/*.wav`.

## Materi Play Store
Teks listing, kebijakan privasi, dan gambar ada di `store/`
(`store/listing.md` = teks siap salin + daftar gambar). Gambar dirender
dari app sendiri, jadi render ulang setiap tampilan berubah:

```bash
flutter test test/tool/store_test.dart --dart-define=STORE=true
```

Hasilnya: 6 screenshot 1080×1920 (layar app 390×844 dalam bingkai ponsel,
judul dua baris di atasnya), `feature-graphic.png` 1024×500, dan
`icon-512.png`. Screenshot & feature graphic ditulis sebagai PNG 24-bit
tanpa alfa (syarat Play Console). Font bundel tidak punya "→", jadi tool
ini memuat font sistem mesin (Arial/DejaVu) sebagai
`AppTypography.systemFallback`, seperti ponsel yang jatuh ke font
sistemnya.

## Checklist Play Console
1. **Buat aplikasi**: nama "Jaringan Sibuk", bahasa default Indonesia
   (id-ID), jenis Game, gratis.
2. **Akun pribadi baru** (dibuat setelah 13 November 2023): sebelum bisa
   rilis produksi, wajib uji tertutup minimal 12 penguji yang ikut
   (opt-in) selama 14 hari berturut-turut (angka per akhir 2024; Play
   Console menampilkan syarat yang berlaku). Unggah `app-release.aab` ke
   jalur **Pengujian tertutup** dulu.
3. **Play App Signing**: terima (default). Kunci upload = keystore di
   atas.
4. **Listing utama**: salin teks dari `store/listing.md`, unggah ikon,
   feature graphic, dan 6 screenshot ponsel dari `store/`. Kategori Game →
   Puzzle.
5. **Kebijakan privasi**: URL publik ke `store/privacy-policy.md`, mis.
   `https://github.com/lutfidev/busy-network-app/blob/main/store/privacy-policy.md`
   (repo publik; link aktif setelah PR ini di-merge ke `main`).
6. **Akses aplikasi**: semua fungsi tersedia tanpa akses khusus.
7. **Iklan**: tidak, aplikasi tidak berisi iklan.
8. **Rating konten** (kuesioner IARC, kategori Game): kekerasan, rasa
   takut, konten seksual, bahasa kasar, narkoba/alkohol/rokok, judi
   (termasuk simulasi): semua **tidak**. Interaksi antarpengguna, berbagi
   lokasi, pembelian digital: **tidak**. Perkiraan hasil: Semua umur /
   PEGI 3 / IARC 3+.
9. **Target audiens**: 13–15, 16–17, 18+. Kelompok di bawah 13 tidak
   dipilih supaya tidak masuk program Keluarga (aturannya lebih ketat);
   isinya tetap aman untuk anak. Tidak menarik khusus untuk anak: ya.
10. **Keamanan Data**:
    - Mengumpulkan atau membagikan data pengguna? **Tidak.** Release tidak
      meminta izin `INTERNET` (cek `uses-permission` di manifest gabungan
      `build/app/intermediates/merged_manifests/release/`); progres &
      setelan hanya di `shared_preferences` perangkat.
    - Karena tidak ada data yang dikumpulkan, pertanyaan enkripsi &
      penghapusan data tidak muncul.
11. **Aplikasi berita / pemerintah / keuangan / kesehatan / COVID-19**:
    bukan.
12. **Rilis**: tiap unggahan naikkan angka setelah `+` di `pubspec.yaml`,
    `flutter build appbundle`, unggah ke jalur pengujian, lalu promosikan
    ke produksi setelah syarat poin 2 terpenuhi.

Persyaratan teknis yang sudah terpenuhi: `targetSdk` 36 (default Flutter
3.47), `minSdk` 24, App Bundle, tanda tangan upload.
