import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:busy_network/screens/level_map/level_map_layout.dart';
import 'package:busy_network/widgets/level_node.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kiri-atas node & label tiap level di desain (kanvas 390×844).
const _design = <int, (Offset, Offset)>{
  1: (Offset(45, 160), Offset(45, 226)),
  2: (Offset(165, 160), Offset(165, 226)),
  3: (Offset(285, 160), Offset(285, 226)),
  4: (Offset(285, 300), Offset(285, 366)),
  5: (Offset(159, 294), Offset(165, 372)),
  6: (Offset(51, 306), Offset(45, 358)),
  7: (Offset(51, 446), Offset(45, 498)),
  8: (Offset(171, 446), Offset(165, 498)),
  9: (Offset(291, 446), Offset(285, 498)),
  10: (Offset(291, 586), Offset(285, 638)),
  11: (Offset(51, 586), Offset(105, 600)),
};

void main() {
  test('progres awal = koordinat & status desain', () {
    final p = DummyData.designProgress;
    for (final slot in LevelMapLayout.slots) {
      final state = LevelMapLayout.stateOf(p, slot.number);
      final (node, label) = _design[slot.number]!;
      expect(
        LevelMapLayout.nodeTopLeft(slot, state),
        node,
        reason: '${slot.number}',
      );
      expect(
        LevelMapLayout.labelTopLeft(slot, state),
        label,
        reason: '${slot.number}',
      );
    }
    expect(
      [
        for (final s in LevelMapLayout.slots)
          LevelMapLayout.stateOf(p, s.number),
      ],
      [
        ...List.filled(4, LevelNodeState.done),
        LevelNodeState.current,
        ...List.filled(6, LevelNodeState.locked),
      ],
    );
    expect(
      LevelMapLayout.chipTopLeft(LevelMapLayout.slotOf(5)!),
      const Offset(136, 254),
    );
  });

  test('jalur progres awal = path desain', () {
    final paths = LevelMapLayout.paths(5);
    expect(paths.done, const [
      Offset(75, 190),
      Offset(315, 190),
      Offset(315, 330),
      Offset(195, 330),
    ]);
    expect(paths.locked, const [
      Offset(195, 330),
      Offset(75, 330),
      Offset(75, 470),
      Offset(315, 470),
      Offset(315, 610),
      Offset(75, 610),
      Offset(75, 700),
    ]);
  });

  test('level 5 selesai → level 6 sekarang', () {
    final p = DummyData.designProgress.record(5, 2);
    final five = LevelMapLayout.slotOf(5)!;
    final six = LevelMapLayout.slotOf(6)!;
    expect(LevelMapLayout.stateOf(p, 5), LevelNodeState.done);
    expect(
      LevelMapLayout.nodeTopLeft(five, LevelNodeState.done),
      const Offset(165, 300),
    );
    expect(
      LevelMapLayout.labelTopLeft(five, LevelNodeState.done),
      const Offset(165, 366),
    );
    expect(LevelMapLayout.stateOf(p, 6), LevelNodeState.current);
    expect(
      LevelMapLayout.nodeTopLeft(six, LevelNodeState.current),
      const Offset(39, 294),
    );
    expect(
      LevelMapLayout.labelTopLeft(six, LevelNodeState.current),
      const Offset(45, 372),
    );
    expect(LevelMapLayout.chipTopLeft(six), const Offset(16, 254));
    expect(LevelMapLayout.paths(6).done.last, const Offset(75, 330));
    expect(LevelMapLayout.paths(6).locked.first, const Offset(75, 330));
  });

  test('belum ada yang selesai: jalur oranye satu titik', () {
    final paths = LevelMapLayout.paths(Progress(const {}).current);
    expect(paths.done, const [Offset(75, 190)]);
    expect(paths.locked.first, const Offset(75, 190));
  });

  test('semua level 1–11 selesai: jalur lengkap, tanpa level sekarang', () {
    final p = Progress({for (var n = 1; n <= 11; n++) n: 1});
    expect(p.current, 12);
    expect(LevelMapLayout.slotOf(12), isNull);
    final paths = LevelMapLayout.paths(12);
    expect(paths.done.last, const Offset(75, 610));
    expect(paths.locked, const [Offset(75, 610), Offset(75, 700)]);
  });
}
