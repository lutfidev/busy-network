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
