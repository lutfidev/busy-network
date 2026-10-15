import 'dart:ui';

import '../../widgets/level_node.dart';

/// Satu node di Peta Babak. Koordinat = pojok kiri-atas di kanvas desain
/// (390×844), seperti `left/top` di HTML.
class LevelMapEntry {
  const LevelMapEntry({
    required this.number,
    required this.state,
    required this.topLeft,
    this.stars = 0,
    this.labelTopLeft,
    this.labelBeside = false,
  });

  final int number;
  final LevelNodeState state;
  final Offset topLeft;
  final int stars;

  /// Posisi bintang (selesai/sekarang) atau angka (terkunci).
  final Offset? labelTopLeft;

  /// Angka level terkunci ditulis di samping (level 11), bukan di bawah.
  final bool labelBeside;
}

/// Tata letak Peta Babak 1 – Perumahan Batam.
abstract final class LevelMapLayout {
  /// Potongan kanvas desain yang berisi peta (di bawah header, di atas
  /// kartu bos). Semua koordinat di bawah dikurangi [origin].
  static const Offset origin = Offset(0, 100);
  static const Size size = Size(390, 590);

  static const currentChipTopLeft = Offset(136, 254);
  static const currentChipWidth = 118.0;

  static const entries = <LevelMapEntry>[
    LevelMapEntry(
      number: 1,
      state: LevelNodeState.done,
      topLeft: Offset(45, 160),
      stars: 3,
      labelTopLeft: Offset(45, 226),
    ),
    LevelMapEntry(
      number: 2,
      state: LevelNodeState.done,
      topLeft: Offset(165, 160),
      stars: 2,
      labelTopLeft: Offset(165, 226),
    ),
    LevelMapEntry(
      number: 3,
      state: LevelNodeState.done,
      topLeft: Offset(285, 160),
      stars: 3,
      labelTopLeft: Offset(285, 226),
    ),
    LevelMapEntry(
      number: 4,
      state: LevelNodeState.done,
      topLeft: Offset(285, 300),
      stars: 1,
      labelTopLeft: Offset(285, 366),
    ),
    LevelMapEntry(
      number: 5,
      state: LevelNodeState.current,
      topLeft: Offset(159, 294),
      labelTopLeft: Offset(165, 372),
    ),
    LevelMapEntry(
      number: 6,
      state: LevelNodeState.locked,
      topLeft: Offset(51, 306),
      labelTopLeft: Offset(45, 358),
    ),
    LevelMapEntry(
      number: 7,
      state: LevelNodeState.locked,
      topLeft: Offset(51, 446),
      labelTopLeft: Offset(45, 498),
    ),
    LevelMapEntry(
      number: 8,
      state: LevelNodeState.locked,
      topLeft: Offset(171, 446),
      labelTopLeft: Offset(165, 498),
    ),
    LevelMapEntry(
      number: 9,
      state: LevelNodeState.locked,
      topLeft: Offset(291, 446),
      labelTopLeft: Offset(285, 498),
    ),
    LevelMapEntry(
      number: 10,
      state: LevelNodeState.locked,
      topLeft: Offset(291, 586),
      labelTopLeft: Offset(285, 638),
    ),
    LevelMapEntry(
      number: 11,
      state: LevelNodeState.locked,
      topLeft: Offset(51, 586),
      labelTopLeft: Offset(105, 600),
      labelBeside: true,
    ),
  ];
}
