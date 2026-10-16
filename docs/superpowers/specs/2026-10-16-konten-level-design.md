# Langkah 8 — Konten level 2–12 & bos

Tanggal: 2026-10-16 · Branch: `feat/konten-level` · Roadmap: langkah 8.

Pemilik repo menyerahkan rancangan level sepenuhnya ("langsung saja kamu
yg menentukan"); semua angka & copy di bawah keputusan pembuat.

## Tujuan

Babak 1 Perumahan Batam lengkap dimainkan: level 1–11 dan level bos 12
"Malam Final Sepak Bola" (butuh 24 bintang). Permainan mulai dari level 1.

**Berhasil bila:** tiap level punya rancangan acuan yang **ditarik
sungguhan** lewat `GameState` dan mendapat 3★ di simulasi hari; tiap level
punya jebakan yang tercatat di test (rancangan wajar yang tidak 3★);
semua level lolos aturan tata letak & overflow di 360 px (hari sungguhan);
progres awal kosong; level bos terkunci sampai level 11 selesai dan bintang
level 1–11 ≥ 24; `flutter analyze` bersih, `flutter test` hijau.

**Di luar cakupan:** layar Pengaturan / reset progres (langkah 9), suara,
babak 2, tampilan khusus "nobar" di Fase Jalan (badge tetap JAM SIBUK).

## Keputusan

1. **Kurva kesulitan** — tiap level mengajarkan satu ide, angka dicari
   dengan menjalankan simulasi (bukan tebakan):

   | Lv | Nama | Rumah | Anggaran | Lulus / target | Hemat 3★ | Ide |
   |---|---|---|---|---|---|---|
   | 1 | Rumah Pertama | 2 | 200.000 | 40 / 60 | 50.000 | tutorial (langkah 7) |
   | 2 | Gang Sebelah | 3 | 300.000 | 50 / 70 | 100.000 | rantai lebih hemat dari kabel sendiri-sendiri |
   | 3 | Warnet Bang Ucok | 4 | 550.000 | 50 / 85 | 100.000 | fiber terbuka; Warnet 28 Mbps tak muat LAN |
   | 4 | Tiang Baru | 5 | 650.000 | 55 / 75 | 200.000 | tiang (junction) kosong; LAN ke tiang cukup bila rumah bawah langsung dari router |
   | 5 | Gang Melati | 7 | 850.000 | 60 / 80 | 200.000 | desain (tidak diubah) |
   | 6 | Warisan Pak RT | 6 | 150.000 | 60 / 80 | 75.000 | jaringan lama penuh: bongkar (uang balik 50%) & tata ulang |
   | 7 | Kerja dari Rumah | 7 | 600.000 | 60 / 80 | 150.000 | jam sibuk 08–17 (panjang), tiga rumah atas > 20 Mbps |
   | 8 | Ruko Simpang | 8 | 800.000 | 60 / 80 | 150.000 | dua ruko 14 Mbps; Rumah 6 menghalangi jalur ke tiang |
   | 9 | Musim Ujian | 8 | 600.000 | 70 / 85 | 125.000 | jam sibuk 18–22; berpasangan, bukan bertiga |
   | 10 | Perumahan Baru | 9 | 900.000 | 65 / 85 | 100.000 | router di pojok, dua tiang, kabel panjang |
   | 11 | Malam Minggu | 10 | 700.000 | 65 / 85 | 150.000 | jam sibuk 19–23, anggaran ketat |
   | 12 | Malam Final Sepak Bola | 9 | 850.000 | 65 / 85 | 200.000 | nobar 20–22: semua rumah 1,5× serentak |

   Kepuasan akhir = rata-rata sabar, dan kabel LAN yang lewat 20 Mbps
   hampir pasti menghabiskan sabar rumah di hilirnya, jadi teka-tekinya
   adalah membagi rumah ke kabel ≤ 20 Mbps dengan biaya serendah mungkin;
   "hemat 3★" diset supaya rancangan termurah yang terlihat dapat 3★ dan
   rancangan boros/aman 2★. Jam sibuk pagi (09–12) dicoba dan dibuang:
   sabar pulih sendiri sampai malam, jadi kabel penuh nyaris tak berefek.
2. **Lonjakan trafik** — `LevelDef.surge: TrafficSurge(fromHour, toHour,
   factor, name)`. `DaySim` mengalikan pemakaian semua rumah dengan
   `factorAt(menit)`. Level bos: "Nobar" 20–22 ×1,5, di dalam jam sibuk
   19–22. Pemakaian × faktor tidak boleh melewati paket (dites), karena
   permintaan dibatasi paket dan rumah akan kekurangan walau kabelnya
   lega. Jebakan bos: rantai Rumah 7 → Rumah 6 = 18 Mbps (aman) jadi
   27 Mbps saat nobar. Catatan Fase Rancang bos: "Nobar 20–22 · trafik
   1,5×" menggantikan "Jam sibuk 19–22".
3. **Data** — `lib/game/levels/levels.dart` tetap pintu masuk (`Levels.levelN`,
   `all` urut 1–12, `byNumber`), isi level baru di `part` file
   `levels_early.dart` (2–4), `levels_late.dart` (6–11), `level_boss.dart`
   (12). Grid semua level baru `gridOrigin (15, 15)`. Rumah tengah atas yang
   kabelnya datang dari bawah memakai label & bar sabar di kanan (pola
   Warung di level 5) supaya kabel tidak menembus label. Kabel peninggalan
   level 6 masuk rumah dari samping/atas dengan ujung lurus (koordinat
   bulat). `ChapterDef.bossStars = 24`, `bossLevel` = level terakhir.
4. **Progres** — `Progress.empty` (belum ada bintang, tutorial belum)
   menggantikan progres awal desain: `ProgressBook` tanpa data tersimpan
   mulai dari `initial ?? Progress.empty`; `ProgressBook.memory([initial])`.
   Potret desain pindah nama jadi `DummyData.designProgress` dan hanya
   dipakai screenshot & test yang memeriksa layar seperti desain.
   `Progress.canPlay(chapter, n)` = `isOpen(n)` dan, untuk level bos,
   `starsUpTo(11) ≥ 24`; bintang level bos sendiri tidak dihitung.
5. **Peta Babak** — kartu bos tiga keadaan: terkunci (desain, gembok,
   "Satu kompleks nobar. Butuh 24 bintang."), terbuka (tanpa gembok, bisa
   diketuk, "Satu kompleks nobar. Ayo, main!"), selesai (bintang terbaik
   menggantikan keterangan). Label aksesibilitas Level 1 menyebut
   ", tutorial" juga saat level 1 masih level sekarang.
6. **"Level Berikutnya"** membuka level berikut bila ada dan
   `canPlay`; selain itu (setelah bos, atau bintang belum 24) Peta Babak.
7. **Fase Jalan** — judul "LEVEL n · NAMA" mengecil (`FittedBox`), bukan
   dipotong elipsis (nama bos panjang). Label jam sibuk di bawah linimasa:
   untuk jam sibuk yang melewati tengah hari (level 7) labelnya di tengah
   menggantikan "12"; jam sibuk malam tetap tata letak desain.
8. **Test**
   - `test/game/levels/level_plans.dart`: `Pull`/`Plan`, `design()`
     (tarikan sungguhan lewat titik grid), `play()` (hari penuh, komplain
     dijawab), `referencePlans` 1–12.
   - `level_balance_test.dart`: tiap level 3★ dengan rancangan acuan dan
     semua rumah tersambung; jebakan per level; lonjakan penuh hanya
     20:00–21:59.
   - `level_def_test.dart`: semua level — node di grid, di dalam peta
     (30..360 × 30..420, ruang label), jarak antarnode ≥ 90 px, pemakaian ×
     lonjakan ≤ paket, lulus < target; babak 1–12 berurutan, bos di akhir.
   - Progres, Peta (bos terkunci/terbuka/selesai), hasil level 11 → bos /
     peta, alur tutorial & navigasi dengan progres kosong.
   - Overflow: Fase Rancang tiap level; hari sungguhan tiap level (Fase
     Jalan 20:00, Panel Antrean, Hasil) di 360×640 dan 360×800 teks 130%.
   - Screenshot: layar desain memakai `DummyData.designProgress`;
     `level/NN-rancang` & `level/NN-jalan` (21:00, rancangan acuan) untuk
     level 2–4 & 6–12.
