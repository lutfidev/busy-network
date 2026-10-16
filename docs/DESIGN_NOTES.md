# Catatan desain

## Membaca `design/Jaringan Sibuk.html`
File itu bundel: `<script type="__bundler/manifest">` berisi aset base64
(gzip) dan `<script type="__bundler/template">` berisi halaman induk yang
memuat 9 iframe (8 layar + lembar token). Tiap iframe juga bundel yang
sama. Skrip Python untuk mengekstrak:

```python
import re, json, base64, gzip, sys, os
src = open(sys.argv[1], encoding='utf-8').read()
out = sys.argv[2]; os.makedirs(out, exist_ok=True)
get = lambda t: re.search(r'<script type="__bundler/' + t + r'">(.*?)</script>', src, re.S).group(1)
for uuid, e in json.loads(get('manifest')).items():
    b = base64.b64decode(e['data'])
    if e.get('compressed'): b = gzip.decompress(b)
    ext = {'text/html': 'html', 'text/javascript': 'js'}.get(e['mime'], 'bin')
    open(f'{out}/{uuid}.{ext}', 'wb').write(b)
open(f'{out}/template.html', 'w').write(json.loads(get('template')))
```

Jalankan sekali untuk file utama, lalu sekali lagi untuk tiap `*.html`
hasilnya. `template.html` tiap layar berisi markup + skrip `DCLogic`
(logika interaksi prototipe, mis. langkah tutorial dan hitungan antrean).

Urutan layar: 1 Beranda · 2 Peta Babak 1 · 3 Tutorial Level 1 · 4 Fase
Rancang · 5 Fase Jalan · 6 Panel Atur Antrean · 7 Hasil Berhasil · 8 Hasil
Gagal · Design token & komponen.

## Asumsi yang diambil (desain ambigu)
- **Pengaturan** (ikon di Beranda) belum didesain → sementara membuka galeri
  komponen `/galeri`.
- **Peta Babak dari progres**: progres awal = desain (level 1–4 selesai
  3/2/3/1★, level 5 sekarang) sampai langkah 8. Level 1 membuka tutorial
  (setelah tutorial selesai: Fase Rancang level 1), level 5 Fase Rancang
  Gang Melati; level tanpa data (2–4, 6–11) tampil
  sesuai progres tapi tidak bisa diketuk ("Level 6, belum tersedia");
  level terkunci & bos nonaktif. Posisi node/label/chip diturunkan dari
  pusat node per level, jalur oranye sampai level sekarang.
- **Rute bersarang** (`/peta/rancang/jalan/antrean`) supaya tombol back
  Android mengikuti alur. Back dari Fase Jalan = hari dibatalkan, rancangan
  tetap utuh. Fase Jalan & Panel Antrean membawa `?level=n`
  (`AppRoutes.runOf/queueOf`) supaya Fase Rancang di bawahnya level yang
  benar; back dari hari tutorial membuka Fase Rancang level 1 (kosong).
- **Simulasi hari** (rincian di
  `docs/superpowers/specs/2026-10-15-simulasi-hari-design.md`): 06→24 dalam
  90 detik; tombol percepat = sakelar ×4 (bukan lompat ke hasil). Pemakaian
  = `peakMbps` × kurva (25/35/45%, naik 2 jam ke 100% di jam sibuk, turun
  ke 30% di 24). Rumah macet bila kabel yang langsung menyambungkannya
  penuh dan ia kekurangan; mulai lambat bila sabar atau layanan < 60%.
  Kepuasan = rata-rata sabar semua rumah (belum tersambung = 0), dibulatkan
  ke bawah. 24:00 → Hasil Berhasil bila kepuasan ≥ batas lulus, selain itu
  Hasil Gagal.
- **Hasil & bintang** (rincian di
  `docs/superpowers/specs/2026-10-16-hasil-progres-design.md`): desain
  punya 1★ di 72% (target 80%), jadi gagal = di bawah *batas lulus*
  (level 5: 60%, level 1: 40%). 1★ lulus, 2★ kepuasan ≥ target, 3★ juga
  sisa anggaran ≥ Rp 200.000 (level 1: Rp 50.000 = dua rumah dengan kabel
  lurus; tips 2★ tanpa fiber selama fiber belum terbuka). "Bangkrut" = gagal (anggaran tidak bisa
  minus). Teks gagal tetap "targetnya 80%". Rumah pindah = sabar sempat
  habis + rumah tak tersambung. Biang kerok: kabel paling lama penuh
  ("Kabel ke {blok} kelebihan beban jam {beban terparah}", dua pemakai
  terbesar), atau rumah belum tersambung, atau jatah terlalu ketat (dua
  terakhir copy baru). Hanya hari dari Fase Rancang yang dicatat ke
  progres (`shared_preferences`); bintang hanya naik.
- **Komplain**: sekali per masa macet tiap rumah, paling sering sekali per
  rumah tiap 2 jam (rumah yang macet bersamaan bergiliran; yang macet saat
  masih jeda menyusul begitu jedanya habis). Komplain menjeda hari sampai
  dijawab; jam juga berhenti begitu Panel Antrean mulai meluncur masuk. "Abaikan" menutup pop-up
  dan hari lanjut (bukan ke Hasil Gagal seperti tautan prototipe). Teks
  komplain selain milik Bu Sri adalah copy baru.
- **Panel Atur Antrean** dari hari yang berjalan: "Terapkan" menyimpan,
  "Lanjutkan" juga menyimpan lalu melanjutkan hari. Petunjuk "Turunkan
  batas A atau B." menyebut dua pemakai terbesar di kabel yang disorot.
  Status kartu adalah pratinjau aturan simulasi (Kak Dewi "mulai lambat"
  karena sabarnya 55%, bukan aturan khusus prototipe).
- **Bingkai Fase Jalan** (20:15) dihitung simulasi dari potret: jam, sabar
  tiap rumah, Warung prioritas, komplain Bu Sri 20:14.
- **Deep link layar hasil** (screenshot, tanpa hari yang selesai) memakai
  potret desain: Berhasil `?bintang=1..3` dengan angka logika prototipe
  (72/86%, Rp 120.000/240.000, komplain 7/3/2), Gagal 41% / 11 komplain /
  2 rumah, biang kerok Blok B jam 20:00.
- **Tutorial** (rincian di
  `docs/superpowers/specs/2026-10-16-tutorial-interaktif-design.md`):
  posisi sorotan diukur dari widget target (bukan koordinat absolut)
  supaya tetap pas di layar mana pun. Scrim **menahan sentuhan di luar
  lubang sorotan** (prototipe memakai `pointer-events: none`, tapi
  tutorialnya maju lewat tombol); kartu tutorial tetap bisa diketuk, jadi
  keluar lewat "Lewati" atau back Android. Satu `GameState` dari langkah
  1 sampai 3: langkah 2 tanpa tombol "Udah, lanjut" — peta interaktif
  dengan `CableLesson` (hanya Router → Rumah 1, kabel panduan putus-putus
  selama jari tidak menarik, tangan contoh hilang saat jari menarik);
  begitu Rumah 1 tersambung → langkah 3 (anggaran terpotong sungguhan,
  kabel lurus Rp 60.000). "Mulai Hari" hanya di langkah 3: hari level 1
  asli (1/2 rumah → 50% → 1★, tercatat). "Mulai Hari" atau "Lewati" =
  tutorial selesai (`"tutorial": true` di JSON progres). Deep link
  `?langkah=3` tetap potret desain (Rp 200.000).
- **Fase Rancang level 1**: kabel yang belum terbuka tampil sebagai kartu
  terkunci seperti tutorial; "Jam sibuk" memakai jam bawaan simulasi
  (19–22) bila level tidak menentukan.
- **Tooltip biaya** di Fase Rancang dibuat satu baris (di desain 390 px
  ia terbungkus karena mepet tepi).
- **Kartu kabel** tingginya minimal 88 px dan boleh bertambah supaya
  "Kapasitas 20 Mbps · murah" tidak terpotong (di desain teks itu terpotong).
- **Animasi** yang sudah hidup: trafik Fase Jalan (js-flow/js-jam),
  kedip alarm (js-alarm), cincin level aktif (js-ring), bintang hasil
  (js-star), tangan tutorial (js-bob/js-drag), latar Beranda
  (js-flow, js-drift, js-blink), kabel ditarik & cincin snap (js-march,
  js-snap). Panel antrean naik lewat transisi rute.
  Kecepatan trafik macet mengikuti CSS: titik tiap 9 px, maju 18 px per
  3,2 s. Belum: js-pop (komplain),
  js-float (konfeti), js-twinkle & js-flow di Peta Babak, js-walk/js-drip/
  js-flow di Hasil Gagal.
- **Peta pakai Flame** (`NetworkGame`): komponen menggambar di koordinat
  peta lewat `MapRenderer`, jadi hasilnya sama per piksel dengan
  `MapRenderer.drawScene` (di-test). Penanda sorotan tutorial dan tooltip
  biaya tetap widget di atas peta. Peta diam saat rutenya tertutup rute
  lain (mis. Panel Atur Antrean di atas Fase Jalan).
- **Animasi mati** (`MediaQuery.disableAnimations`): tiap animasi diam di
  pose yang mewakili referensi (cincin sedang membesar, tangan seret di
  titik awal, bintang sudah muncul), bukan pose 0% yang kadang kosong.
- **Glyph**: Fredoka tidak punya `≥` → cadangan Nunito. `→` ("Kabel Router →
  Rumah 4") tidak ada di kedua font; di Android jatuh ke font sistem (sama
  seperti browser di desain), tapi tampil kotak di screenshot `flutter test`.
- **Layar pendek** (< 844 px): peta mengecil seragam; layar hasil & beranda
  bisa di-scroll bila tidak muat.
- **Level 5 sudah punya jaringan** saat dimulai (Rumah 1, Warung, Rumah 3,
  Rumah 4 + junction atas); Rp 850.000 = sisa untuk memperluas.
- **Grid level 5 bergeser 15 px vertikal** dari titik grid yang digambar
  (node di y = 60, 90, 240, …). `LevelDef.gridOrigin` mencatatnya; kabel
  yang ditarik snap ke grid level.
- **Segmen kabel** = panjang dalam langkah grid 30 px (diagonal = 1),
  dibulatkan: kabel yang sedang ditarik di desain = 3 segmen.
- **Tarik kabel** (rincian di
  `docs/superpowers/specs/2026-10-15-tarik-kabel-design.md`): mulai dari
  router, junction, atau rumah yang sudah tersambung (Fase Jalan di desain
  punya kabel Rumah 4 → Rumah 5). Jalur = langkah 8 arah di grid level
  mengikuti jari; ujung kabel dipotong di tepi node (router 24 px, rumah
  20 px), persis kabel level 5 di desain. Cincin snap = rumah belum
  tersambung terdekat dalam 90 px; jari masuk cincin (30 px) → kabel
  menempel, lepas = pasang. Lepas di tempat lain = batal.
- **Tooltip biaya** mengikuti jari (−33, −72) dan dijepit di dalam lebar
  peta: di bingkai desain ia bergeser sedikit ke kiri dari x = 222.
- **Anggaran kurang** (belum ada di desain): tooltip merah, lalu banner
  "Anggaran kurang: kabel ini Rp X, sisa Rp Y." bila dilepas di rumah.
- **Bongkar** berlaku juga untuk kabel bawaan level; uang kembali 50%.
  Kabel hilir tidak ikut dibongkar, rumahnya saja yang putus. Junction yang
  putus (mis. j1 setelah fiber Warung dibongkar) bisa jadi tujuan tarikan
  untuk menyambung hilirnya lagi; cincin snap juga digambar di junction.
- **Fase Rancang mulai kosong** (tanpa tarikan). Screenshot
  `04-fase-rancang` menarik kabel sungguhan lalu memotret sambil jari
  menempel.
- **Bar sabar Rumah 4** di Fase Jalan memakai 15% (sesuai label), bukan
  7/40 seperti gambar desain (beda 1 px).
- **Pelanggan/paket Rumah 1–2 level 1** belum ada di desain; nilainya
  sementara.
