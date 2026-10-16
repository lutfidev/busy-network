# Langkah 7 — Tutorial interaktif

Tanggal: 2026-10-16 · Branch: `feat/tutorial-interaktif` · Roadmap: langkah 7.

## Tujuan

Tutorial level 1 dimainkan sungguhan: langkah 2 menunggu pemain benar-benar
menarik kabel Router → Rumah 1, langkah 3 menyorot "Mulai Hari" yang memulai
hari level 1 asli di jaringan buatan pemain. Status tutorial selesai
tersimpan; setelah itu level 1 dibuka di Fase Rancang biasa. Level 1 bisa
mendapat 3★.

**Berhasil bila:** aturan tarikan tutorial (hanya Router → Rumah 1) ada di
`GameState` dan dites tanpa Flutter; widget test alur Peta → tutorial →
tarik kabel → Mulai Hari → Fase Jalan level 1 → 24:00 → Hasil (1★ tercatat,
tutorial selesai tersimpan); setelah tutorial selesai, level 1 dan "Ulangi"
membuka Fase Rancang level 1; deep link `?langkah=1` tetap identik dengan
referensi desain; `flutter analyze` bersih, `flutter test` hijau.

**Di luar cakupan:** data level 2–12 & progres awal mulai dari nol
(langkah 8); reset progres / ulangi tutorial dari Pengaturan (langkah 9);
dukungan pembaca layar untuk menarik kabel (peta Flame memang belum punya).

## Keputusan

1. **Pelajaran tarikan di `GameState`.** Kelas baru `CableLesson
   {from, to, guide}` (model): tarikan yang sedang diajarkan.
   `GameState(lesson: …)` dan `setLesson(CableLesson?)`. Selama ada
   pelajaran:
   - tarikan hanya bisa dimulai dari `from` (`canStartCable`);
   - cincin snap / menempel hanya ke `to` (rumah lain diabaikan);
   - `guide` (getter `CableDraft?`) = kabel putus-putus dipandu
     (titik `guide`, tanpa jari) selama jari tidak menarik dan `to` belum
     tersambung. `SceneBuilder` menggambar `draft ?? guide`.
   Tutorial level 1: `from` router, `to` Rumah 1, `guide`
   `[(105, 315), (255, 165)]` (garis desain). `planDay()` tidak membawa
   pelajaran.
2. **Satu `GameState` sepanjang tutorial.** Langkah 1: level 1 kosong,
   peta tidak interaktif. "Lanjut" → langkah 2: `setLesson(tutorial)`, peta
   interaktif (`NetworkGameView.interactive`). Begitu Rumah 1 tersambung
   (pemain melepas jari di Rumah 1) → langkah 3 otomatis; peta tidak
   interaktif lagi. Anggaran terpotong sungguhan (kabel lurus miring = 4
   segmen LAN = Rp 60.000 → header Rp 140.000; jalur yang berbelok lebih
   mahal).
3. **Kartu langkah 2 tanpa tombol.** "Udah, lanjut" dihapus; judul & teks
   tetap copy desain. Tangan tutorial (js-drag) disembunyikan selama jari
   menarik, muncul lagi bila tarikan batal. Tarikan yang dilepas di luar
   Rumah 1 (atau ditolak karena anggaran kurang — hanya mungkin dengan
   jalur berputar-putar) = tetap langkah 2, kabel panduan muncul lagi.
   Tooltip biaya & banner Fase Rancang tidak dipakai di tutorial (desain
   tutorial tidak punya).
4. **Scrim menahan sentuhan di luar sorotan** (berubah dari langkah
   sebelumnya, yang meniru `pointer-events: none` prototipe). Di dalam
   lubang sorotan sentuhan diteruskan (router/peta di langkah 1–2, "Mulai
   Hari" di langkah 3); kartu tutorial di atas scrim tetap bisa diketuk.
   Jadi "Mulai Hari" tidak bisa ditekan sebelum langkah 3, dan tombol
   kembali di header tertutup (keluar lewat "Lewati" atau back Android).
   "Mulai Hari" juga mengabaikan aktivasi (mis. pembaca layar) sebelum
   langkah 3. Tampilan tombol tidak berubah (bukan gaya nonaktif), jadi
   referensi langkah 1 tetap sama.
5. **"Mulai Hari" langkah 3 = hari asli level 1.** Tutorial menandai
   tutorial selesai, `session.begin(game.planDay())`, lalu membuka Fase
   Jalan level 1. Dengan 1/2 rumah, kepuasan akhir 50% (Rumah 2 = 0) →
   lulus 1★ (batas lulus 40%, target 60%) dengan tips "Masih ada 1 rumah
   yang belum tersambung…". Hari ini dicatat ke progres seperti hari dari
   Fase Rancang.
6. **Status tutorial selesai di `Progress`.** Field `tutorialDone` (default
   `false`), `completeTutorial()` (mengembalikan `this` bila sudah).
   JSON tetap `versi: 1`; kunci `"tutorial": true` ditulis hanya bila
   selesai, jadi data lama terbaca sebagai belum selesai dan `encode`
   progres lama tidak berubah. `"tutorial"` bukan bool → data rusak →
   `null` (progres awal), sama seperti kunci rusak lain. `ProgressBook`
   mendapat `completeTutorial()` (beri tahu pendengar, simpan; gagal simpan
   tidak menghentikan permainan). Progres awal desain: belum selesai.
7. **Kapan selesai.** Menekan "Mulai Hari" di langkah 3, atau "Lewati"
   (pemain memilih tidak ikut tutorial). Tombol kembali / back Android
   tidak menandai selesai.
8. **Level 1 setelah tutorial selesai** dibuka di Fase Rancang level 1:
   `AppRoutes.play(n, tutorialDone: …)` (level 1 → tutorial hanya bila
   belum selesai). Dipakai Peta Babak (label aksesibilitas ", tutorial"
   hanya bila belum selesai), "Ulangi"/"Coba Lagi", dan "Level
   Berikutnya". Layar hasil menerima `ProgressBook` dari router. Deep link
   `/peta/tutorial` tetap membuka tutorial (tidak ada redirect).
9. **Fase Rancang level 1 layak tampil** (baru bisa dicapai di langkah
   ini):
   - catatan "Jam sibuk" memakai `SimClock.defaultRushFrom/To` bila level
     tidak menentukan (sebelumnya `!` → crash di level 1);
   - kabel yang belum terbuka tampil sebagai kartu terkunci "Terbuka di
     level N" seperti tutorial (level 5 tidak berubah: semua terbuka).
10. **Rute Fase Jalan & Panel Antrean membawa `?level=n`**
    (`AppRoutes.runOf(n)`, `queueOf(n)`), dipakai Fase Rancang, Fase
    Jalan, Panel Antrean, dan tutorial. Halaman Fase Rancang di bawahnya
    dibangun dengan level yang benar, jadi back dari hari tutorial membuka
    Fase Rancang level 1 (kosong, Rp 200.000), bukan level 5. Deep link
    tanpa query tetap jalan (level 5), dan deep link Fase Jalan tetap
    potret desain level 5 apa pun query-nya.
11. **`savingsTarget` level 1 = Rp 50.000.** Biaya rancangan level 1
    (LAN Rp 15.000/segmen, segmen dihitung setelah ujung dipotong di tepi
    node): Router → Rumah 1 lurus = 4 segmen, Router → Rumah 2 = 6,
    Rumah 1 ↔ Rumah 2 = 5. Dua rumah tersambung → kepuasan 100% dengan
    sisa Rp 50.000 (dua kabel dari router) atau Rp 65.000 (rantai lewat
    Rumah 1) = 3★; rantai lewat Rumah 2, atau satu segmen terbuang
    (Rp 35.000) → 2★. Sisa hanya bergerak per Rp 15.000. (Rencana awal
    Rp 30.000 dihitung dari jalur uji yang berbelok, 5 segmen.)
    Tips 2★ di level yang fibernya belum terbuka (copy baru, karena tips
    desain menyuruh pakai fiber): "Tarik kabel lewat jalur terpendek. Sisa
    anggarannya buat bintang ketiga."
12. **Deep link langkah 2 & 3 tetap potret.** `?langkah=2` = level 1
    dengan pelajaran (kabel panduan sama dengan desain; sekarang bisa
    dimainkan). `?langkah=3` = potret desain (kabel terpasang, anggaran
    tetap Rp 200.000 seperti desain); "Mulai Hari" dari situ juga memulai
    hari level 1 dari potret itu.
13. **Test.**
    - Unit: `CableLesson` di `GameState` (sumber, tujuan, kabel panduan
      saat diam / menarik / batal / tersambung, `planDay` tanpa pelajaran);
      `Progress` (flag, JSON bolak-balik, data lama, rusak); `ProgressBook.
      completeTutorial`; `AppRoutes.play/runOf/queueOf`; bintang level 1
      (3★ di sisa Rp 50.000/65.000, 2★ di Rp 35.000, 1★ tutorial).
    - Widget: tarik Router → Rumah 1 di langkah 2 → langkah 3 (1/2 rumah,
      Rp 140.000); tarik ke Rumah 2 / lepas di luar → tetap langkah 2;
      langkah 1 peta tidak interaktif & "Mulai Hari" tertahan scrim; tangan
      hilang saat menarik; Mulai Hari → Fase Jalan level 1 → 24:00 →
      Hasil 1★ tercatat & tutorial selesai; back dari hari tutorial → Fase
      Rancang level 1; setelah selesai/Lewati, Peta level 1 & "Ulangi" →
      Fase Rancang level 1 (kartu Fiber terkunci); status tersimpan saat
      aplikasi dipompa ulang dengan store yang sama.
    - Overflow & screenshot: tambah `/peta/rancang?level=1`.
