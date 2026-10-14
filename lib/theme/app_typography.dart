import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

/// Skala tipografi "Jaringan Sibuk".
///
/// Fredoka → judul, angka besar, tombol. Nunito → teks & label.
/// Semua gaya memakai *tabular figures* supaya angka (jam, rupiah, Mbps)
/// tidak "goyang" saat nilainya berubah.
///
/// Gaya tidak membawa warna; warna diwarisi dari [DefaultTextStyle] atau
/// ditambahkan lewat `copyWith(color: AppColors.x)`.
abstract final class AppTypography {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle _fredoka(
    double size, {
    FontWeight weight = FontWeight.w600,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: _tabular,
    );
  }

  static TextStyle _nunito(
    double size,
    FontWeight weight, {
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: _tabular,
    );
  }

  // ── Fredoka ────────────────────────────────────────────────────────────
  /// display · 66/600 — "Jaringan Sibuk" di Beranda.
  static final display = _fredoka(66, height: 0.95, letterSpacing: -0.5);

  /// h1 · 42/600 — "Hari beres!".
  static final h1 = _fredoka(42, height: 1.1);

  /// clock · 36/600 — jam di Fase Jalan.
  static final clock = _fredoka(36, height: 1);

  /// h2 · 30/600 — judul layar gagal, tombol "Main".
  static final h2 = _fredoka(30, height: 1.15);

  /// headline · 26/600 — judul panel ("Atur Antrean").
  static final headline = _fredoka(26);

  /// 24/600 — judul header peta, angka statistik.
  static final titleLarge = _fredoka(24, height: 1.1);

  /// title · 22/600 — tombol utama, angka anggaran.
  static final title = _fredoka(22);

  /// 21/600 — judul kartu tutorial & kartu bos.
  static final titleMedium = _fredoka(21, height: 1.2);

  /// 19/600 — judul level di bar atas, tombol sekunder besar.
  static final titleSmall = _fredoka(19, height: 1.1);

  /// 18/600 — nama kabel, angka kecil, tombol outline.
  static final subtitle = _fredoka(18);

  /// 16–17/600 — tombol kecil.
  static final buttonSmall = _fredoka(16);
  static final buttonCompact = _fredoka(17);

  /// Angka nomor level di peta (bold untuk level aktif).
  static final levelNumber = _fredoka(24);
  static final levelNumberCurrent = _fredoka(30, weight: FontWeight.w700);

  // ── Nunito ─────────────────────────────────────────────────────────────
  /// 17/800 — nama babak di kartu Beranda.
  static final bodyLarge = _nunito(17, FontWeight.w800);

  /// 16/600 — tagline Beranda (lh 1.45).
  static final lead = _nunito(16, FontWeight.w600, height: 1.45);

  /// 16/800 — judul kartu "Biang keroknya".
  static final emphasis = _nunito(16, FontWeight.w800, height: 1.35);

  /// body · 15/700 — teks utama / gelembung komplain.
  static final body = _nunito(15, FontWeight.w700);

  /// 15/600 — paragraf tutorial (lh 1.45).
  static final paragraph = _nunito(15, FontWeight.w600, height: 1.45);

  /// 15/800 — judul baris daftar, label "Pilih kabel".
  static final bodyStrong = _nunito(15, FontWeight.w800);

  /// 14/600 — subjudul panel.
  static final bodySmall = _nunito(14, FontWeight.w600);

  /// 14/800 — nama di kartu komplain, tombol teks.
  static final bodySmallStrong = _nunito(14, FontWeight.w800);

  /// 13/600 — paragraf kecil.
  static final caption = _nunito(13, FontWeight.w600, height: 1.4);

  /// 13/700 — keterangan kecil.
  static final captionBold = _nunito(13, FontWeight.w700);

  /// 13/800 — label tebal kecil ("BABAK 1", chip nama level).
  static final captionStrong = _nunito(13, FontWeight.w800);

  /// 12/700 — label tile statistik.
  static final small = _nunito(12, FontWeight.w700);

  /// label · 12/800 — "LEVEL 5 · GANG MELATI".
  static final label = _nunito(12, FontWeight.w800, letterSpacing: 0.5);

  /// 11/800 — label sumbu linimasa, label peta.
  static final micro = _nunito(11, FontWeight.w800);

  /// 11/800 + letter-spacing 1.2 — label blok di peta.
  static final mapBlock = _nunito(11, FontWeight.w800, letterSpacing: 1.2);

  /// 12/800 — nama rumah di peta.
  static final mapLabel = _nunito(12, FontWeight.w800);
}
