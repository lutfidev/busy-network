# Jaringan Sibuk

Game puzzle mobile (Flutter + Flame) tentang mengelola RT/RW Net satu
kompleks: tarik kabel, jaga sinyal, tenangkan pelanggan saat jam sibuk.

Status: fondasi UI — token desain, komponen, 8 layar prototipe statis
dengan navigasi. Logika game menyusul (lihat `docs/ROADMAP.md`).

```bash
source scripts/setup_flutter.sh   # kalau Flutter belum terpasang
flutter run                       # Android, portrait
flutter analyze && flutter test
```

- Desain: `design/Jaringan Sibuk.html` (render: `design/reference/`)
- Panduan kode & konvensi: `CLAUDE.md`
- Asumsi desain & cara membaca file desain: `docs/DESIGN_NOTES.md`
- Langkah berikutnya (prompt siap tempel untuk Claude CLI): `docs/ROADMAP.md`
