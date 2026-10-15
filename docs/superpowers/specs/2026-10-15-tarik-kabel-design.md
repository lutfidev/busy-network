# Langkah 4 — Tarik kabel (fase rancang)

Tanggal: 2026-10-15 · Branch: `feat/tarik-kabel` · Roadmap: langkah 4.

## Tujuan

Di Fase Rancang pemain menarik kabel dari router/junction ke rumah,
membongkar kabel di mode Hapus, dan anggaran ikut berubah. Bingkai desain
(`design/reference/04-fase-rancang.png`) harus bisa dihasilkan dari tarikan
sungguhan: router → (195, 300) → (255, 360), jari masih menempel.

**Berhasil bila:** unit test snapping, rute, biaya, bongkar; widget test
alur tarik → tersambung → bongkar; scene dari tarikan sungguhan identik
dengan desain; `flutter analyze` bersih, `flutter test` hijau.

**Di luar cakupan:** tutorial interaktif (langkah 7), membuat junction baru
dengan bercabang di tengah kabel, membawa state Rancang → Jalan (langkah 5),
suara/getar (langkah 9).

## Keputusan

1. **Sumber tarikan**: router, serta junction atau rumah yang sudah
   tersambung ke router. Rumah ikut boleh karena Fase Jalan di desain punya
   kabel Rumah 4 → Rumah 5 (inilah yang membuat kabel Router → Rumah 4
   penuh).
2. **Rute = jalan di grid.** Jalur adalah deret titik grid level
   (`gridOrigin` + 30 px), tiap langkah ke 8 tetangga, jadi ruas selalu
   0°/45°/90°. Jari pindah ke titik grid lain → jalur memanjang langkah demi
   langkah (miring dulu, lalu lurus). Kembali ke titik yang sudah dilewati →
   jalur dipotong sampai situ (undo dengan menelusur balik). Pusat node lain
   menghalangi; titik di luar peta tidak dipakai.
3. **Polyline kabel** = jalur tanpa titik segaris, ujungnya dipotong di tepi
   node: router 24 px, rumah 20 px, junction 0. Aturan ini menghasilkan
   persis semua kabel level 5 di desain (mis. Router → Rumah 4 =
   (219, 240)→(295, 240)).
4. **Biaya** tetap `segmentCount` dari langkah 2 (panjang polyline terpotong
   dalam langkah grid, dibulatkan, min 1) × harga per segmen. Tarikan di
   desain = 3 segmen.
5. **Cincin snap** = tujuan terdekat dari jari dalam 90 px (desain: jari
   67 px dari Rumah 5): rumah yang belum tersambung, atau junction yang
   putus. Jari masuk cincin (≤ 30 px dari pusatnya) → jalur menempel: kabel putus-putus masuk rumah,
   lingkaran jari hilang, tooltip = biaya yang akan dibayar. Lepas saat
   menempel → kabel terpasang; lepas di tempat lain → tarikan batal.
6. **Anggaran kurang**: selama menarik, tooltip merah bila biaya > sisa.
   Lepas di rumah dengan anggaran kurang → kabel tidak dipasang dan banner
   "Anggaran kurang: kabel ini Rp X, sisa Rp Y." tampil sampai aksi
   berikutnya. (Copy baru; desain belum punya keadaan ini.)
7. **Mode Hapus**: ketuk kabel (pita ±12 px dari garisnya) → kabel dibongkar,
   uang kembali `biaya ~/ 2`. Rumah di hilirnya ikut putus; kabel hilir
   tidak ikut dibongkar. Junction yang putus bisa jadi tujuan tarikan, jadi
   kabel hilirnya tersambung lagi (tanpa ini junction itu buntu selamanya).
   Uang kembali berlaku juga untuk kabel bawaan level (dianggap investasi
   pemain sebelumnya), jadi infrastruktur bisa "dijual" dengan mengorbankan
   rumah yang putus. Bila ini merusak keseimbangan bintang, ubah di
   langkah 6.
8. **Input lewat Flame.** Node & kabel di `NetworkGame` menerima drag/ketuk
   (`DragCallbacks`/`TapCallbacks`, uji sentuh di koordinat peta). Bidang
   sentuh node minimal 24 px (48 px diameter). Posisi jari dilacak dengan
   menjumlah delta (Flame memberi posisi `NaN` di luar komponen). API model
   berbasis id: `beginCable(nodeId)`, `dragCable(jari)`, `endCable()`,
   `removeCable(id)`. Hanya Fase Rancang yang interaktif
   (`NetworkGameView.interactive`).
9. **Mode hapus pindah ke `GameState`** (`erasing`) supaya game tahu ketukan
   berarti bongkar. Pilih kabel mematikan mode hapus (seperti prototipe).
10. **Fase Rancang mulai kosong** (`GameState(Levels.level5)`). Snapshot
    `DummyStates.design` dihapus; test scene & screenshot `04-fase-rancang`
    memakai tarikan sungguhan.
11. **Tooltip** ikut jari: (−33, −72) dari ujung tarikan (desain: jari
    (255, 360) → tooltip (222, 288)), dijepit di dalam peta. Saat menempel,
    acuannya pusat rumah.
12. **Animasi** kabel ditarik dari desain sekarang hidup: `js-march` (garis
    putus-putus maju 36 px/s) dan `js-snap` (cincin 0,9 ↔ 0,25, 1,1 s). Pose
    diam = gambar desain. Kabel dipandu di tutorial langkah 2 juga
    `js-march` di desain, jadi peta tutorial ikut bergerak.
13. **Id kabel baru** `c-<rumah>`, ditambah `-2`, `-3`, … bila sudah dipakai.
