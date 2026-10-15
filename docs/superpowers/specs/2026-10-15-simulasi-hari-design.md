# Langkah 5 — Simulasi hari (fase jalan)

Tanggal: 2026-10-15 · Branch: `feat/simulasi-hari` · Roadmap: langkah 5.

## Tujuan

Jaringan rancangan pemain dimainkan satu hari: jam 06→24, pemakaian tiap
rumah naik-turun, kabel bisa penuh, rumah lancar/lambat/macet, kesabaran
turun, kepuasan dihitung, komplain muncul, dan Panel Atur Antrean
benar-benar mengubah batas & prioritas. Akhir hari → layar hasil.

**Berhasil bila:** simulasi (`lib/game/sim/`) deterministik dan dites tanpa
Flutter; bingkai Fase Jalan di desain (20:15, 62%, "Penuh! 25/20", Bu Sri
macet sabar 15%, Kak Dewi & Pak Rudi mulai lambat) **dihitung** simulasi
dari potret keadaannya, bukan digambar tangan; widget test alur Rancang →
Jalan → Antrean → Jalan → Hasil; `flutter analyze` bersih, `flutter test`
hijau.

**Di luar cakupan:** bintang, angka layar hasil, rumah pindah & progres
(langkah 6); tutorial interaktif — "Mulai Hari" di tutorial tetap membuka
potret Fase Jalan (langkah 7); level lain (langkah 8); suara (langkah 9).

## Keputusan

1. **Jam.** Hari 06:00–24:00 = 1.080 menit permainan dalam 90 detik
   (12 menit/detik). Simulasi maju per **menit utuh** (sisa detik ditabung),
   jadi hasilnya sama berapa pun frame rate-nya. Tombol percepat = sakelar
   ×4. Jam digerakkan `Ticker` di layar Fase Jalan: berhenti sendiri saat
   rute tertutup Panel Antrean (`TickerMode`) dan saat app di latar
   belakang. Satu langkah frame dibatasi 0,1 detik (lompatan setelah jeda
   tidak dihitung). Setelan "hapus animasi" **tidak** menghentikan jam
   (ini permainan, bukan hiasan).
2. **Kurva pemakaian** (sama untuk semua rumah, × `peakMbps`): 06–08 25%,
   08–12 35%, 12–17 45%, naik lurus ke 100% saat jam sibuk mulai (19),
   100% selama jam sibuk (19–22), turun lurus ke 30% di 24. Level tanpa jam
   sibuk (level 1) memakai 19–22. Di jam sibuk pemakaian = `peakMbps`,
   jadi bingkai desain 20:15 = 16 + 9 = 25 Mbps di kabel Rumah 4.
3. **Batas antrean** per rumah (default = paket). Yang masuk jaringan =
   `min(pemakaian, batas)` (= "Pakai sekarang" di panel, = beban kabel di
   badge "Penuh!").
4. **Aliran.** Ditelusuri dari router ke hilir (pohon `Network`). Di hop
   yang bebannya melebihi kapasitas, rumah **prioritas** dilayani dulu,
   sisanya dibagi proporsional. Rumah dapat `terlayani ≤ diminta`.
   Layanan `q = terlayani / pemakaian` (pembatasan juga mengurangi `q`).
5. **Status rumah** (aturan roadmap, cocok dengan desain):
   - **macet** — kabel yang langsung menyambungkan rumah itu penuh (badge
     "Penuh!" ada di kabel yang masuk ke rumah merah);
   - **mulai lambat** — sabar < 60% atau `q` < 60%;
   - **lancar** — selain itu.
   Di bingkai desain Rumah 5 tetap "mulai lambat" walau di hilir kabel
   penuh, karena kabelnya sendiri (Rumah 4 → 5) tidak penuh.
6. **Kesabaran** 0–100%, mulai penuh. Per jam permainan:
   turun `1,0 × (1 − q)`, ditambah 0,30 bila macet atau 0,15 bila hanya
   di hilir kabel penuh; naik 0,10 bila terlayani penuh tanpa kabel penuh
   di jalurnya. Dengan aturan ini jaringan di desain (tanpa diatur) gagal
   target 80%, dan lolos bila Bu Sri dibatasi 11 Mbps atau kabel Rumah 4
   diganti fiber.
7. **Kepuasan** = rata-rata sabar **semua** rumah level, rumah yang belum
   tersambung dihitung 0, dibulatkan ke bawah (desain: 440/7 = 62,9 →
   62%). Tanpa ini level selesai dengan tidak menyambung siapa pun.
   Konsekuensi: tutorial level 1 dengan 1/2 rumah maksimal 50% (< 60%);
   dibereskan di langkah 7.
8. **Komplain** muncul saat rumah **menjadi** macet, paling sering sekali
   per rumah tiap 2 jam permainan. Komplain **menjeda hari** sampai
   dijawab: "Atur antrean" membuka panel, "Abaikan" menutup pop-up dan
   hari lanjut (bukan lagi ke layar gagal). Jumlah komplain dicatat untuk
   langkah 6. Teks komplain per rumah ada di data level; desain hanya
   punya milik Bu Sri, sisanya copy baru.
9. **Panel Atur Antrean** dibangun dari hari yang berjalan: kabel paling
   sesak (beban/kapasitas), urutan rumah = rumah di kabel itu (hulu
   dulu), lalu sisanya macet → lambat → lancar, prioritas dulu, lalu urutan
   level (menghasilkan urutan desain). Urutan dihitung sekali saat panel
   dibuka. Status kartu = pratinjau aturan 5 dengan batas yang sedang
   digeser. Petunjuk "Turunkan batas A atau B." menyebut dua pemakai
   terbesar di kabel itu. "Terapkan" menyimpan ke hari ("Tersimpan");
   "Lanjutkan" juga menyimpan lalu kembali ke peta.
10. **Bingkai desain dihitung simulasi.** `DummyStates.run()` = jaringan
    desain + hari yang dilanjutkan dari potret: jam 20:15, sabar
    90/85/55/15/40/80/75%, Warung prioritas, komplain Bu Sri 20:14.
    Status, beban, badge, dan kepuasan keluar dari aturan di atas;
    `scene_builder_test` tetap membandingkan dengan scene lama. Deep link
    ke Fase Jalan / Panel Antrean (screenshot, test overflow) membuka
    potret ini; karena komplainnya menjeda hari, `pumpAndSettle` aman.
11. **Hari dioper antarrute** lewat `GameSession` (dibuat `JaringanSibukApp`,
    diteruskan `createRouter` ke layar). "Mulai Hari" menyalin rancangan
    jadi state baru fase jalan (`GameState.planDay()`), jadi rancangan tetap
    utuh bila pemain kembali (tombol back = batalkan hari). Fase Jalan &
    Panel Antrean memakai hari yang sama.
12. **Akhir hari** (24:00): `finishDay()`, lalu Hasil Berhasil bila
    kepuasan ≥ target, selain itu Hasil Gagal. Angka di layar hasil masih
    dummy sampai langkah 6.
