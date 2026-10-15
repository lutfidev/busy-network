import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/render/map_renderer.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

Cell c(int i, int j) => (i: i, j: j);

void main() {
  group('LevelDef: grid', () {
    test('ukuran & tepi node = token tema', () {
      expect(LevelDef.mapSize, AppSizes.mapArea);
      expect(LevelDef.routerReach, AppSizes.routerSize / 2);
      expect(LevelDef.houseReach, AppSizes.houseRadius);
      expect(GameState.dockRadius, MapRenderer.snapRingRadius);
    });

    test('cellOf / pointOf memakai titik asal level', () {
      const l = Levels.level5;
      expect(l.cellOf(const Offset(195, 240)), c(6, 8));
      expect(l.pointOf(c(6, 8)), const Offset(195, 240));
      expect(l.cellOf(const Offset(208, 226)), c(6, 8));
      expect(l.cellOf(const Offset(211, 256)), c(7, 9));
    });

    test('snap ke titik grid terdekat di dalam peta', () {
      const l5 = Levels.level5;
      expect(
        l5.pointOf(l5.snap(const Offset(250, 352))),
        const Offset(255, 360),
      );
      // Baris y = 0 menempel tepi atas: tidak dipakai.
      expect(l5.pointOf(l5.snap(const Offset(100, 4))), const Offset(105, 30));
      expect(
        l5.pointOf(l5.snap(const Offset(500, 600))),
        const Offset(375, 450),
      );
      expect(
        l5.pointOf(l5.snap(const Offset(-40, 200))),
        const Offset(15, 210),
      );

      const l1 = Levels.level1;
      expect(l1.pointOf(l1.snap(const Offset(20, 470))), const Offset(15, 465));
    });
  });

  group('CableWalk', () {
    test('mengikuti jari selangkah demi selangkah', () {
      final w = CableWalk(c(0, 0))
        ..moveTo(c(0, 1))
        ..moveTo(c(1, 2))
        ..moveTo(c(2, 2));
      expect(w.cells, [c(0, 0), c(0, 1), c(1, 2), c(2, 2)]);
    });

    test('lompatan jauh: miring dulu, lalu lurus', () {
      final w = CableWalk(c(0, 0))..moveTo(c(2, 4));
      expect(w.cells, [c(0, 0), c(1, 1), c(2, 2), c(2, 3), c(2, 4)]);
    });

    test('kembali ke titik yang dilewati → jalur dipotong', () {
      final w = CableWalk(c(0, 0))
        ..moveTo(c(0, 3))
        ..moveTo(c(0, 1));
      expect(w.cells, [c(0, 0), c(0, 1)]);
      w.moveTo(c(0, 0));
      expect(w.cells, [c(0, 0)]);
    });

    test('jalur yang memotong dirinya membuang putarannya', () {
      final w = CableWalk(c(0, 0))
        ..moveTo(c(0, 2))
        ..moveTo(c(1, 2))
        ..moveTo(c(1, 1))
        ..moveTo(c(-1, 1));
      expect(w.cells, [c(0, 0), c(0, 1), c(-1, 1)]);
    });

    test('pusat node lain menghalangi', () {
      final w = CableWalk(c(0, 0), blocked: {c(0, 2)})..moveTo(c(0, 4));
      expect(w.cells, [c(0, 0), c(0, 1)]);
    });

    test('menempel ke rumah tujuan lalu lepas lagi', () {
      final w = CableWalk(c(0, 0), blocked: {c(2, 2)})
        ..moveTo(c(2, 2), dock: true);
      expect(w.end, c(2, 2));
      // Pusat rumah hanya boleh di ujung: lanjut ke titik lain = lepas dulu.
      w.moveTo(c(3, 2));
      expect(w.cells, [c(0, 0), c(1, 1), c(2, 1), c(3, 2)]);
    });
  });

  group('cablePolyline', () {
    test('titik segaris dibuang', () {
      expect(
        cablePolyline(const [
          Offset(0, 0),
          Offset(0, 30),
          Offset(0, 60),
          Offset(30, 90),
          Offset(60, 120),
          Offset(90, 120),
        ]),
        const [Offset(0, 0), Offset(0, 60), Offset(60, 120), Offset(90, 120)],
      );
    });

    test('ujung dipotong di tepi node', () {
      expect(
        cablePolyline(
          const [Offset(195, 240), Offset(255, 240), Offset(315, 240)],
          startTrim: 24,
          endTrim: 20,
        ),
        const [Offset(219, 240), Offset(295, 240)],
      );
      final diagonal = cablePolyline(const [
        Offset(0, 0),
        Offset(30, 30),
      ], startTrim: 24);
      expect(diagonal.first.dx, closeTo(24 / 1.4142135623730951, 1e-9));
      expect(diagonal.first.dy, closeTo(24 / 1.4142135623730951, 1e-9));
      expect(diagonal.last, const Offset(30, 30));
    });

    test('satu ruas pendek tidak terbalik', () {
      final p = cablePolyline(
        const [Offset(0, 0), Offset(0, 30)],
        startTrim: 24,
        endTrim: 20,
      );
      expect(p.first.dy, closeTo(30 * 24 / 44, 1e-9));
      expect(p.last.dy, closeTo(p.first.dy, 1e-9));
    });

    test('satu titik saja', () {
      expect(cablePolyline(const [Offset(5, 5)]), const [Offset(5, 5)]);
    });
  });
}
