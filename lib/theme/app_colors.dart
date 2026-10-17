import 'package:flutter/painting.dart';

/// Palet warna "Jaringan Sibuk".
///
/// Sumber: `design/Jaringan Sibuk.html` → "Design token & komponen" (token
/// inti) + warna pendukung yang dipakai di 8 layar prototipe. Widget tidak
/// boleh menulis `Color(0x...)` sendiri; selalu ambil dari sini.
abstract final class AppColors {
  // ── Token inti (kartu "Warna") ─────────────────────────────────────────
  /// Kabel LAN (siang).
  static const cableLan = Color(0xFF7F93A8);

  /// Kabel LAN di peta malam.
  static const cableLanNight = Color(0xFF6F86A0);

  /// Kabel fiber, sekaligus warna utama (tombol CTA).
  static const cableFiber = Color(0xFFF2A81D);
  static const primary = cableFiber;

  /// Bayangan padat tombol utama / kabel fiber.
  static const primaryShadow = Color(0xFFB5760A);

  /// Titik trafik (malam) dan versi siangnya.
  static const traffic = Color(0xFF45E9F2);
  static const trafficDay = Color(0xFF1FB5C0);

  /// Titik trafik di peta babak (siang, sedikit lebih terang).
  static const trafficMap = Color(0xFF1FC8D4);

  static const star = Color(0xFFF5C518);
  static const starStroke = Color(0xFFC99A00);
  static const starHighlight = Color(0xFFFFF3B0);

  /// Bintang kosong kecil (peta level) dan besar (hasil).
  static const starEmpty = Color(0xFFCBD4DE);
  static const starEmptyLarge = Color(0xFFD3DBE3);
  static const starEmptyStroke = Color(0xFFC3CDD8);

  static const statusOk = Color(0xFF2DBE6C);
  static const statusOkText = Color(0xFF1B8A4C);
  static const statusSlow = Color(0xFFF5C518);
  static const statusSlowText = Color(0xFF8A6A00);
  static const statusJam = Color(0xFFF0453A);
  static const statusJamDark = Color(0xFFC42B21);

  static const ink = Color(0xFF1B2333);
  static const inkMuted = Color(0xFF5A6578);

  /// Teks sekunder (paragraf) di permukaan terang.
  static const inkSecondary = Color(0xFF3A4558);

  static const groundDay = Color(0xFFEEF2F5);
  static const groundDayDot = Color(0xFFC9D3DD);
  static const groundNight = Color(0xFF0F1726);
  static const groundNightDot = Color(0xFF1F2B44);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceLine = Color(0xFFD3DBE3);
  static const surfaceNight = Color(0xFF172238);
  static const surfaceNightLine = Color(0xFF24314D);

  // ── Permukaan & garis pendukung ────────────────────────────────────────
  /// Latar tile statistik / kartu kabel (siang).
  static const surfaceSubtle = Color(0xFFF6F8FA);

  /// Track progress & pembatas tipis (siang).
  static const track = Color(0xFFE3E9EF);

  /// Gelembung chat komplain.
  static const bubble = Color(0xFFF1F4F7);

  /// Latar layar Peta Babak & Hasil Berhasil.
  static const groundMap = Color(0xFFE9EEF2);
  static const groundCelebrate = Color(0xFFEAF1F6);

  /// Blok bangunan di Peta Babak.
  static const mapBlock = Color(0xFFDCE3EA);

  /// Jalur level terkunci di Peta Babak.
  static const mapPathLocked = Color(0xFFB4C1CE);

  /// Label blok (BLOK A) siang/malam.
  static const blockLabel = Color(0xFF8A97A8);
  static const blockLabelNight = Color(0xFF5C6E8C);

  /// Rumah yang belum tersambung.
  static const houseIdle = Color(0xFF9AA8B8);

  // ── Malam (Beranda, Fase Jalan, Hasil Gagal) ───────────────────────────
  static const inkOnDark = Color(0xFFF4F7FB);
  static const inkOnDarkMuted = Color(0xFFA9B6CC);
  static const inkOnDarkSoft = Color(0xFFDCE3EE);
  static const surfaceNightRaised = Color(0xFF1C2740);
  static const surfaceNightRaisedLine = Color(0xFF2A3858);
  static const surfaceNightDeep = Color(0xFF121A2B);
  static const surfaceNightTile = Color(0xFF1E2940);
  static const nightRoad = Color(0xFF152036);
  static const nightCableIdle = Color(0xFF4D6382);
  static const nightElapsed = Color(0xFF3A4C6B);
  static const nightDead = Color(0xFF3A4760);
  static const nightCaption = Color(0xFF8494AE);

  /// Teks merah terang di latar gelap ("Rumah 4 · sabar 15%", 41%).
  static const dangerOnDark = Color(0xFFFF8A80);

  // ── Router ─────────────────────────────────────────────────────────────
  static const routerScreen = Color(0xFF3A4760);
  static const routerScreenLight = Color(0xFFC9D3DD);

  // ── Nada semantik (latar chip / banner) ────────────────────────────────
  static const dangerBg = Color(0xFFFFE1DE);
  static const dangerText = Color(0xFFA3231A);
  static const dangerSoftBg = Color(0xFFFFE9E6);
  static const dangerPanelBg = Color(0xFFFFF0EE);
  static const warningBg = Color(0xFFFFF1E0);
  static const warningText = Color(0xFF7A3E06);
  static const warningStrong = Color(0xFFA84E08);
  static const warningPanelBg = Color(0xFFFFF9E0);
  static const tipBg = Color(0xFFFFF6E5);
  static const tipText = Color(0xFF5C3405);
  static const successBg = Color(0xFFE3F6EB);
  static const successPanelBg = Color(0xFFECF8F1);

  /// Pilihan aktif bernuansa fiber (kartu Fiber, tombol prioritas).
  static const primarySoftBg = Color(0xFFFFF6E5);

  /// Overlay sentuhan pada kontrol berwarna utama (16%).
  static const primaryOverlay = Color(0x29F2A81D);

  /// Lintasan sakelar mati (Pengaturan; tidak ada di desain).
  static const toggleOff = Color(0xFFC3CDD8);

  // ── Scrim & bayangan ───────────────────────────────────────────────────
  static const scrim = Color(0xA30F1726); // rgba(15,23,38,.64)
  static const shadowInk08 = Color(0x141B2333); // rgba(27,35,51,.08)
  static const shadowInk25 = Color(0x401B2333); // rgba(27,35,51,.25)
  static const shadowBlack25 = Color(0x40000000);
  static const shadowBlack40 = Color(0x66000000);
  static const transparent = Color(0x00000000);
}
