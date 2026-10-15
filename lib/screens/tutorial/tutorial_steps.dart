import 'dart:ui';

/// Isi kartu tutorial per langkah (copy persis dari desain).
class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    this.nextLabel,
    required this.handOffset,
  });

  final String title;
  final String body;

  /// `null` = tidak ada tombol lanjut (langkah terakhir).
  final String? nextLabel;

  /// Posisi tangan relatif ke pojok kiri-atas sorotan (px desain).
  final Offset handOffset;
}

abstract final class TutorialSteps {
  static const count = 3;

  static const steps = <TutorialStep>[
    TutorialStep(
      title: 'Ini router pusat',
      body:
          'Semua internet di kompleks ini datang dari sini. Jaga dia '
          'baik-baik.',
      nextLabel: 'Lanjut',
      handOffset: Offset(33, 53),
    ),
    TutorialStep(
      title: 'Tarik kabel ke rumah',
      body:
          'Geser jari dari router ke Rumah 1. Kabel cuma bisa belok lurus '
          'atau miring 45°.',
      nextLabel: 'Udah, lanjut',
      handOffset: Offset(36, 198),
    ),
    TutorialStep(
      title: 'Mantap, Rumah 1 nyala!',
      body: 'Sekarang tekan Mulai Hari dan lihat trafiknya jalan.',
      handOffset: Offset(252, 36),
    ),
  ];

  /// Area sorotan langkah 1–2 dalam koordinat peta (390×472).
  static const routerSpot = Rect.fromLTWH(59, 269, 92, 92);
  static const cableSpot = Rect.fromLTWH(56, 112, 252, 252);
  static const cableSpotRadius = 36.0;

  /// Sorotan langkah 3 = tombol "Mulai Hari" diperbesar sekian px.
  static const ctaSpotInflate = 6.0;
  static const ctaSpotRadius = 26.0;
}
