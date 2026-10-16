# Langkah 6 — Hasil, bintang & progres

Tanggal: 2026-10-16 · Branch: `feat/hasil-progres` · Roadmap: langkah 6.

## Tujuan

Akhir hari menghasilkan hasil level yang **dihitung**: bintang dari aturan,
angka hasil (kepuasan, sisa anggaran, komplain), dan untuk hari yang gagal
"biang kerok" + jumlah rumah pindah. Bintang tersimpan di perangkat
(`shared_preferences`); Beranda & Peta Babak membaca progres asli; Ulangi /
Coba Lagi memulai level dari awal; Level Berikutnya membuka level baru.

**Berhasil bila:** aturan bintang, biang kerok, rumah pindah, dan progres
murni & dites tanpa Flutter; layar hasil menampilkan angka hari yang baru
dimainkan; deep link layar hasil, Beranda, dan Peta tetap identik dengan
referensi desain; progres bertahan setelah aplikasi dibuka ulang; widget
test alur Rancang → Jalan → Hasil → Peta; `flutter analyze` bersih,
`flutter test` hijau.

**Di luar cakupan:** tutorial interaktif & menyelesaikan level 1 (langkah
7); data level 2–4 & 6–12, level bos, dan progres awal "mulai dari nol"
(langkah 8); reset progres di Pengaturan (langkah 9); animasi layar hasil
yang belum hidup (js-float, js-walk, dll.).

## Keputusan

1. **Batas lulus terpisah dari target.** Desain punya hasil 1 bintang di
   kepuasan 72% (target 80%) dan layar gagal di 41%, jadi gagal ≠ "di
   bawah target". `LevelDef` mendapat `passSatisfaction` (level 5: 60,
   level 1: 40) dan `savingsTarget` (default Rp 200.000).
   - kepuasan < `passSatisfaction` → **gagal** (0 bintang);
   - lulus → 1★ ("Selesai · Hari lewat tanpa bangkrut");
   - kepuasan ≥ `targetSatisfaction` → 2★;
   - kepuasan ≥ target **dan** sisa anggaran ≥ `savingsTarget` → 3★.

   "Bangkrut" = gagal (pelanggan kabur); anggaran memang tidak bisa minus
   karena tarikan yang kemahalan ditolak. Baris bintang 1 di layar berhasil
   selalu ✓. Teks gagal tetap "Kepuasan cuma X%, targetnya
   {targetSatisfaction}%." seperti desain. Akibatnya: jaringan desain tanpa
   diatur (75%) kini **berhasil 1★**; rancangan awal level 5 (4/7 rumah,
   57%) tetap gagal. Level 1 (anggaran Rp 200.000) belum bisa 3★; disetel
   di langkah 7.
2. **Statistik hari di `DaySim`**, dicatat tiap langkah menit (setelah
   status dihitung), mulai dari menit hari dimulai/dilanjutkan:
   - menit **penuh** tiap kabel = `Network.isOverloaded` dengan permintaan
     menit itu (aturan badge "Penuh!");
   - menit **beban terparah** tiap kabel = menit pertama dengan rasio
     beban/kapasitas tertinggi selama kabel itu penuh;
   - rumah yang sabarnya **sempat habis** (≤ 0%), termasuk yang sudah 0%
     sejak potret.
   Untuk jaringan desain tanpa diatur: kabel Rumah 4 penuh 258 menit
   (18:17–22:35), terparah 19:00; Rumah 4 & Rumah 5 sabarnya sempat habis.
3. **`LevelResult`** (murni, `lib/game/result/`), dibuat dari `GameState`
   yang harinya sudah 24:00: level, kepuasan akhir, sisa anggaran
   (`GameState.budget`), jumlah komplain, bintang, lulus/gagal, rumah
   pindah, biang kerok. Bisa juga dibuat langsung dari angka (potret
   desain, keputusan 8).
4. **Rumah pindah** = rumah yang sabarnya sempat habis + rumah yang tidak
   tersambung (kepuasan juga menghitungnya 0). Jaringan desain tanpa
   diatur → 2 rumah, sama dengan desain. Ditampilkan "N rumah".
5. **Biang kerok** dipilih berurutan; berisi fakta (nama, jam), teksnya
   disusun layar:
   1. **Kabel penuh** — kabel dengan menit penuh terbanyak (seri: yang
      lebih dulu penuh, lalu urutan kabel). Isi: area, menit beban
      terparah, dua pemakai terbesar, dan apakah fiber disarankan.
      - *Area* = blok bersama semua rumah yang dialiri kabel itu
        (`Network.housesCarried`), dari field baru `HouseDef.block`
        (level 5: Rumah 1/Warung/Rumah 3 "Blok A", Rumah 4/5 "Blok B",
        Rumah 6/7 "Blok C"; level 1: Rumah 1 "Blok A"). Bila bloknya
        beda-beda atau ada rumah tanpa blok: label rumah di ujung kabel
        (`Cable.to`); bila ujungnya junction: label rumah pertama yang
        dialirinya (urutan level).
      - *Pemakai terbesar* = nama pelanggan rumah yang dialiri, urut
        `peakMbps` terbesar lalu urutan level, maksimal dua.
      - *Fiber disarankan* bila kabelnya LAN dan fiber sudah terbuka di
        level itu.
   2. **Rumah belum tersambung** (tidak ada kabel yang pernah penuh): nama
      pelanggan rumah yang tak tersambung, urutan level.
   3. **Jatah terlalu ketat** (tidak ada keduanya): rumah tersambung yang
      batas antreannya di bawah `peakMbps`, urut sabar akhir terendah,
      maksimal dua.
   4. Tidak ada satu pun (hanya mungkin dari potret) → tanpa biang kerok.
6. **Teks biang kerok & tips.** Copy desain dipakai sebagai pola; varian
   lain copy baru.
   - Layar gagal, kartu "BIANG KEROKNYA":
     - kabel penuh: "Kabel ke {area} kelebihan beban jam {HH:MM}." +
       "Ganti kabel utamanya ke fiber, atau batasi jatah {A} dan {B}
       sebelum jam sibuk." (tanpa fiber: "Batasi jatah {A} dan {B}
       sebelum jam sibuk."; satu pemakai: "jatah {A}");
     - belum tersambung: "{n} rumah belum tersambung." + "Tarik kabel ke
       {A} dan {B} sebelum mulai hari." (satu rumah: "ke {A}");
     - jatah ketat: "Jatah {A} dan {B} dibatasi terlalu ketat." (satu
       rumah: "Jatah {A} dibatasi terlalu ketat.") + "Naikkan batas
       antreannya, kabelnya masih kuat.";
     - tanpa biang kerok: kartu tidak tampil.
   - Tips layar berhasil: 3★ tanpa tips; 2★ teks desain ("Pakai LAN di
     jalur yang sepi. …"); 1★ dari biang kerok:
     - kabel penuh: "Jalur {area} penuh pas jam sibuk. Coba fiber di kabel
       utama, atau batasi jatah sebelum jam {jam mulai sibuk}." (tanpa
       fiber: "Jalur {area} penuh pas jam sibuk. Batasi jatah sebelum jam
       {jam}.");
     - belum tersambung: "Masih ada {n} rumah yang belum tersambung.
       Sambungkan biar kepuasan naik.";
     - jatah ketat: "Jatah {A} kebatasan. Naikkan batasnya, kabelnya masih
       kuat.";
     - tanpa biang kerok: tanpa tips.
   Jam mulai sibuk = `rushHourFrom ?? SimClock.defaultRushFrom`, ditulis
   angka jam saja ("19").
7. **Progres.** `Progress` (murni, `lib/game/progress/`) = bintang terbaik
   per nomor level. Level terbuka **diturunkan**, tidak disimpan: level n
   terbuka bila n = 1 atau level n−1 berbintang; *level sekarang* = level
   pertama yang belum berbintang. Mencatat hasil hanya menaikkan bintang
   (yang terbaik dipakai); gagal tidak mengubah apa pun. Babak 1 =
   `Levels.chapter` (nomor 1, "Perumahan Batam", 12 level → 36 bintang);
   Beranda/Peta menghitung bintang, "x / 12 level", dan bar progres dari
   sini.
   - **Progres awal seperti desain** (`DummyData.progress`): level 1–4
     selesai dengan 3/2/3/1★ (9 bintang), level 5 sekarang. Langkah 8
     menggantinya jadi mulai dari level 1.
8. **Potret desain untuk deep link.** Tanpa hasil di sesi (deep link,
   screenshot, test overflow) layar hasil memakai `DummyData`:
   - berhasil `?bintang=1..3` (default 2): kepuasan 72/86/86%, sisa
     Rp 120.000/120.000/240.000, komplain 7/3/2 (logika prototipe;
     bintangnya keluar dari aturan keputusan 1);
   - gagal: kepuasan 41%, 11 komplain, 2 rumah pindah;
   - biang kerok keduanya: kabel penuh, area "Blok B", jam 20:00, Bu Sri &
     Pak Rudi, fiber disarankan.
   Hasilnya teks desain persis, jadi referensi tidak berubah.
9. **Penyimpanan.** `ProgressStore` (antarmuka `load()` → `Progress?`,
   `save(Progress)`), dua implementasi: `PrefsProgressStore`
   (`SharedPreferencesWithCache`, satu kunci `progres`, JSON
   `{"versi":1,"bintang":{"1":3,…}}`) dan `MemoryProgressStore` (test &
   default). Data kosong, rusak, atau versi lain → `null` → progres awal.
   `ProgressBook` (`ChangeNotifier`, `lib/app/`) memegang progres: mencatat
   di memori, memberi tahu pendengar, lalu menyimpan; gagal simpan tidak
   menghentikan permainan (progres di memori tetap berlaku). `main()`
   membuka store sebelum `runApp`.
10. **Mencatat hasil.** `GameSession` memegang `ProgressBook` (default
    memori). `begin(day)` menandai hari **asli**; hari potret dari
    `currentDay()` (deep link, tutorial sampai langkah 7) tidak.
    `finish()` (dipanggil Fase Jalan saat 24:00) membuat `LevelResult`
    sekali per hari, mencatatnya ke progres bila hari asli & lulus, lalu
    Fase Jalan membuka Berhasil/Gagal sesuai `passed`. `result` = hasil
    hari terakhir yang selesai (`last` tetap = hari terakhir yang dimainkan). Layar Berhasil
    memakai `session.result` bila lulus, layar Gagal bila gagal; selain itu
    potret (keputusan 8).
11. **Tombol hasil.** "Ulangi" / "Coba Lagi" → `AppRoutes.play(level)`:
    level 1 → tutorial, lainnya → `/peta/rancang?level=n` dengan
    `GameState` baru (anggaran & kabel awal level). "Level Berikutnya" →
    `AppRoutes.play(n + 1)` bila level itu ada datanya, selain itu Peta
    Babak (level baru sudah berdenyut di sana). "Balik ke peta" tetap.
    Fase Rancang membaca `?level=` (`Levels.byNumber`; kosong/tak dikenal
    → level 5).
12. **Peta Babak dari progres.** Tata letak jadi *pusat* node per level
    (level 1–11) + penanda "angka di samping" (level 11); posisi node &
    label diturunkan dari statusnya, dengan progres awal hasilnya persis
    koordinat desain:
    - selesai (60 px): kiri-atas = pusat − 30; bintang di (pusat.x − 30,
      pusat.y + 36);
    - sekarang (72 px): pusat − 36; bintang kosong di (pusat.x − 30,
      pusat.y + 42); chip nama level di (pusat.x − 59, pusat.y − 76),
      hanya bila levelnya ada datanya;
    - terkunci (48 px): pusat − 24; angka di (pusat.x − 30, pusat.y + 28),
      atau di samping (pusat.x + 30, pusat.y − 10).
    Jalur oranye (+ titik trafik) = garis pusat level 1 → level sekarang;
    jalur putus-putus = level sekarang → level 11 → (75, 700). Titik segaris
    dibuang, jadi dengan progres awal path-nya sama dengan desain. Bulatan
    di (195, 610) dan kartu bos tidak berubah (bos tetap terkunci).
13. **Level tanpa data** (2–4, 6–11) tampil sesuai progres tapi tidak bisa
    diketuk (`LevelNode` nonaktif bila `onPressed` null). Label
    aksesibilitas: selesai tetap "Level n, s bintang"; sekarang tanpa data
    "Level n, belum tersedia"; sekarang dengan data tetap "Level n, {nama},
    main sekarang". Level 1 → tutorial, level 5 → Fase Rancang level 5.
14. **Test.**
    - Unit: statistik `DaySim` (menit penuh, beban terparah, sabar habis),
      `LevelResult` (ambang 0–3★, pilihan biang kerok & seri, area,
      pemakai terbesar, saran fiber, rumah pindah), `Progress` (catat
      terbaik, terbuka, level sekarang, JSON bolak-balik, data rusak),
      `PrefsProgressStore` (platform di memori), `GameSession.finish`
      (potret tidak dicatat, gagal tidak dicatat, tidak dicatat dua kali),
      tata letak Peta (progres awal = koordinat desain; setelah level 5
      selesai, level 6 sekarang).
    - Widget: Rancang → Jalan → 24:00 → Hasil dengan angka hitungan; Peta
      & Beranda berubah setelah menang; Ulangi = level dari awal; Level
      Berikutnya → Peta dengan level 6 berdenyut & tak bisa diketuk;
      progres bertahan saat aplikasi dipompa ulang dengan store yang sama.
    - Daftar rute screenshot & overflow tidak berubah; test lama yang
      mengandalkan aturan lulus lama disesuaikan.
