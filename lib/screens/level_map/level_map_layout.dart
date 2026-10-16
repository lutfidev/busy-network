import 'dart:ui';

import '../../game/progress/progress.dart';
import '../../theme/theme.dart';
import '../../widgets/level_node.dart';

/// Tempat satu level di Peta Babak: pusat node di kanvas desain (390×844).
class LevelSlot {
  const LevelSlot(this.number, this.center, {this.labelBeside = false});

  final int number;
  final Offset center;

  /// Angka level terkunci ditulis di samping (level 11), bukan di bawah.
  final bool labelBeside;
}

/// Tata letak Peta Babak 1 – Perumahan Batam. Posisi node & label
/// diturunkan dari status level; dengan progres awal hasilnya persis
/// koordinat desain.
abstract final class LevelMapLayout {
  /// Potongan kanvas desain yang berisi peta (di bawah header, di atas
  /// kartu bos). Semua koordinat di bawah dikurangi [origin].
  static const Offset origin = Offset(0, 100);
  static const Size size = Size(390, 590);

  static const currentChipWidth = 118.0;

  static const slots = <LevelSlot>[
    LevelSlot(1, Offset(75, 190)),
    LevelSlot(2, Offset(195, 190)),
    LevelSlot(3, Offset(315, 190)),
    LevelSlot(4, Offset(315, 330)),
    LevelSlot(5, Offset(195, 330)),
    LevelSlot(6, Offset(75, 330)),
    LevelSlot(7, Offset(75, 470)),
    LevelSlot(8, Offset(195, 470)),
    LevelSlot(9, Offset(315, 470)),
    LevelSlot(10, Offset(315, 610)),
    LevelSlot(11, Offset(75, 610), labelBeside: true),
  ];

  /// Ujung jalur setelah level 11 (menuju kartu bos).
  static const pathEnd = Offset(75, 700);

  static LevelSlot? slotOf(int number) {
    for (final slot in slots) {
      if (slot.number == number) return slot;
    }
    return null;
  }

  static LevelNodeState stateOf(Progress progress, int number) {
    if (progress.isDone(number)) return LevelNodeState.done;
    if (progress.isOpen(number)) return LevelNodeState.current;
    return LevelNodeState.locked;
  }

  static Offset nodeTopLeft(LevelSlot slot, LevelNodeState state) {
    final radius =
        switch (state) {
          LevelNodeState.done => AppSizes.levelNode,
          LevelNodeState.current => AppSizes.levelNodeCurrent,
          LevelNodeState.locked => AppSizes.levelNodeLocked,
        } /
        2;
    return slot.center - Offset(radius, radius);
  }

  /// Bintang (selesai/sekarang) atau angka (terkunci), lebar
  /// `AppSizes.levelNode` dan rata tengah di bawah node.
  static Offset labelTopLeft(LevelSlot slot, LevelNodeState state) =>
      slot.center +
      switch (state) {
        LevelNodeState.done => const Offset(-30, 36),
        LevelNodeState.current => const Offset(-30, 42),
        LevelNodeState.locked when slot.labelBeside => const Offset(30, -10),
        LevelNodeState.locked => const Offset(-30, 28),
      };

  /// Chip nama di atas level sekarang.
  static Offset chipTopLeft(LevelSlot slot) =>
      slot.center + const Offset(-currentChipWidth / 2, -76);

  /// Jalur oranye level 1 → level [current] dan jalur putus-putus level
  /// [current] → level 11 → [pathEnd]; titik segaris dibuang.
  static ({List<Offset> done, List<Offset> locked}) paths(int current) {
    final reached = current.clamp(1, slots.length);
    final centers = [for (final s in slots) s.center];
    return (
      done: _straight(centers.sublist(0, reached)),
      locked: _straight([...centers.sublist(reached - 1), pathEnd]),
    );
  }

  static List<Offset> _straight(List<Offset> points) {
    final result = <Offset>[];
    for (final p in points) {
      if (result.length >= 2) {
        final a = result[result.length - 2];
        final b = result.last;
        final cross =
            (b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx);
        if (cross.abs() < 1e-9) result.removeLast();
      }
      result.add(p);
    }
    return result;
  }
}
