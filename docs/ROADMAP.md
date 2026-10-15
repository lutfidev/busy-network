# Roadmap — lanjut di sesi lokal (Claude CLI)

Fondasi sudah ada: token tema, komponen, 8 layar statis, navigasi, test.
Langkah berikut berurutan; tiap langkah = satu sesi/PR kecil. Jalankan
`claude` di root repo lalu tempel prompt-nya. Claude akan membaca
`CLAUDE.md` otomatis.

Sebelum mulai tiap langkah:
```bash
git checkout main && git pull
git checkout -b feat/<nama-langkah>
flutter pub get && flutter analyze && flutter test
```
Setelah selesai: `/check` (lihat `.claude/commands/`), commit, PR.

---

## 1. Animasi hidup (tanpa logika game)
**Hasil:** trafik mengalir, cincin level aktif berdenyut, kabel penuh
berkedip, bintang hasil "pop", tangan tutorial bergerak, panel naik.

> Baca `design/Jaringan Sibuk.html` bagian `@keyframes` tiap layar dan token
> di `lib/theme/app_motion.dart`. Hidupkan animasi yang sekarang statis:
> fase trafik di `NetworkMapPainter` (titik maju 36 px/1,4 s, macet 9 px/3,2 s),
> cincin level 5 di `level_map_screen.dart` (skala 1→1,55, 1,8 s), kedip
> alarm 0,7 s, `js-star` di hasil berhasil, `js-bob`/`js-drag` tangan
> tutorial, garis latar Beranda. Matikan semua animasi bila
> `MediaQuery.disableAnimations` true, dan pastikan `flutter test` tetap
> hijau (test memakai `pumpAndSettle`; aktifkan disableAnimations di
> `test/test_helpers.dart`). Commit per animasi.

## 2. Model level & state game
**Hasil:** definisi level sebagai data, state game terpisah dari UI.

> Buat `lib/game/model/`: `LevelDef` (grid 30 px, node router/rumah/junction,
> paket Mbps & profil pemakaian tiap rumah, anggaran, target kepuasan, jam
> sibuk, kabel yang terbuka), `Cable` (polyline, jenis, kapasitas, harga per
> segmen), `GameState` (`ChangeNotifier`, fase rancang/jalan/hasil). Pindahkan
> data level 1 & 5 dari `lib/data/` ke definisi ini (koordinat sama persis
> dengan `dummy_scenes.dart`) dan buat fungsi `MapScene fromState(GameState)`
> supaya layar tetap tampil identik. Tambahkan unit test model. Jangan ubah
> visual.

## 3. Peta pakai Flame
**Hasil:** `NetworkMapView` diganti `GameWidget` di Tutorial/Rancang/Jalan.

> Buat `lib/game/network_game.dart` (`FlameGame`) dengan kamera
> `CameraComponent.withFixedResolution(width: 390, height: 472)`. Komponen:
> `RouterComponent`, `HouseComponent`, `JunctionComponent`, `CableComponent`,
> `TrafficComponent` — semuanya menggambar lewat `MapRenderer` yang sudah ada
> (jangan menulis ulang gaya gambar). Overlay Flutter (tooltip biaya, banner
> hapus, pop-up komplain) tetap widget. Bandingkan screenshot dengan
> `design/reference/04-*.png` dan `05-*.png`. Pastikan widget test tetap jalan
> (pakai `GameWidget` dengan game yang bisa di-pause di test).

## 4. Tarik kabel (fase rancang)
**Hasil:** pemain bisa menarik kabel dari router/junction ke rumah.

> Implementasikan drag di `NetworkGame`: mulai dari router atau junction,
> ujung kabel snap ke grid 30 px, segmen hanya 0°/45°/90°, tampilkan kabel
> putus-putus + lingkaran jari + cincin snap di rumah target + tooltip
> "N segmen · Rp X". Lepas di rumah → kabel tersambung (rumah jadi
> `connected`), kurangi anggaran, update "x/7 rumah tersambung". Pilih
> LAN/Fiber dari `CableOptionCard`. Mode Hapus: ketuk kabel → bongkar, uang
> kembali 50%. Tolak tarikan bila anggaran kurang. Unit test untuk snapping &
> biaya, widget test untuk alur.

## 5. Simulasi hari (fase jalan)
**Hasil:** jam berjalan 06→24, trafik & status rumah dihitung.

> Buat `lib/game/sim/`: jam (1 hari ≈ 90 detik, bisa dipercepat), kurva
> pemakaian tiap rumah (puncak jam sibuk 19–22), aliran per kabel di pohon
> jaringan (jumlah pemakaian anak, dibatasi kapasitas & batas antrean),
> status rumah lancar/lambat/macet (≥60%/<60%/kabel penuh), bar kesabaran,
> kepuasan pelanggan rata-rata, komplain saat macet (pop-up seperti desain),
> kabel penuh → badge "Penuh! a/b" + kedip. Tombol jeda → Panel Atur Antrean
> yang benar-benar mengubah batas & prioritas (logika awal ada di
> `queue_logic.dart`). Akhir hari → hasil. Simulasi harus deterministik dan
> dites tanpa Flutter.

## 6. Hasil, bintang & progres
**Hasil:** bintang dihitung dari aturan, progres tersimpan.

> Hitung bintang: 1 = selesai tanpa bangkrut, 2 = kepuasan ≥ target,
> 3 = kepuasan ≥ target & sisa anggaran ≥ Rp 200.000. Gagal bila kepuasan
> < target → layar gagal dengan "biang kerok" (kabel yang paling lama penuh)
> dan jumlah rumah pindah. Simpan progres (bintang per level, level terbuka)
> dengan `shared_preferences`; Peta Babak & Beranda membaca progres asli.
> "Ulangi"/"Coba Lagi" mereset level, "Level Berikutnya" membuka level baru.

## 7. Tutorial interaktif
> Ubah tutorial level 1: langkah 2 menunggu pemain benar-benar menarik kabel
> router → Rumah 1 (bukan tombol "Udah, lanjut"), langkah 3 menyorot
> "Mulai Hari". Simpan status tutorial selesai.

## 8. Konten level 2–12 & bos
> Rancang level 2–11 Perumahan Batam berdasarkan pola level 5 (makin banyak
> rumah, fiber terbuka di level 3, anggaran makin ketat) dan level bos 12
> "Malam Final Sepak Bola" (butuh 24 bintang, semua rumah lonjakan trafik
> serentak). Simpan sebagai data `LevelDef`.

## 9. Polish & rilis
> Layar Pengaturan (suara, getar, reset progres) menggantikan tautan ke galeri;
> efek suara & haptic; ikon launcher & splash dari palet; `applicationId`
> final (bukan `com.example`); signing release; `flutter build appbundle`.
