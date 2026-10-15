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
- **Level 2–5** di peta membuka Fase Rancang Gang Melati (satu-satunya level
  yang didesain); level 1 membuka tutorial; level terkunci & bos nonaktif.
- **Rute bersarang** (`/peta/rancang/jalan/antrean`) supaya tombol back
  Android mengikuti alur. Tombol "Percepat" ke Hasil Berhasil (2 bintang),
  "Abaikan" komplain ke Hasil Gagal (seperti tautan prototipe).
- **Hasil Berhasil** menerima `?bintang=1..3`; angka mengikuti logika
  prototipe (72/86%, Rp 120.000/240.000, komplain 7/3/2).
- **Tutorial**: posisi sorotan diukur dari widget target (bukan koordinat
  absolut) supaya tetap pas di layar mana pun. Scrim tidak memblokir sentuhan
  (sama seperti `pointer-events: none` di prototipe).
- **Tooltip biaya** di Fase Rancang dibuat satu baris (di desain 390 px
  ia terbungkus karena mepet tepi).
- **Kartu kabel** tingginya minimal 88 px dan boleh bertambah supaya
  "Kapasitas 20 Mbps · murah" tidak terpotong (di desain teks itu terpotong).
- **Animasi** yang sudah hidup: trafik Fase Jalan (js-flow/js-jam),
  kedip alarm (js-alarm), cincin level aktif (js-ring), bintang hasil
  (js-star), tangan tutorial (js-bob/js-drag), latar Beranda
  (js-flow, js-drift, js-blink). Panel antrean naik lewat transisi rute.
  Kecepatan trafik macet mengikuti CSS: titik tiap 9 px, maju 18 px per
  3,2 s. Belum: js-march & js-snap (kabel ditarik), js-pop (komplain),
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
  (node di y = 60, 90, 240, …). `LevelDef.gridOrigin` mencatatnya; snap
  kabel (langkah 4) harus ke grid level.
- **Segmen kabel** = panjang dalam langkah grid 30 px (diagonal = 1),
  dibulatkan: kabel yang sedang ditarik di desain = 3 segmen.
- **Bar sabar Rumah 4** di Fase Jalan memakai 15% (sesuai label), bukan
  7/40 seperti gambar desain (beda 1 px).
- **Pelanggan/paket Rumah 1–2 level 1** belum ada di desain; nilainya
  sementara.
