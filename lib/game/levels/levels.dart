import 'dart:ui';

import '../map_scene.dart';
import '../model/cable.dart';
import '../model/level_def.dart';

/// Level Babak 1 · Perumahan Batam. Angka & koordinat dari
/// `design/Jaringan Sibuk.html`.
abstract final class Levels {
  static const level1 = LevelDef(
    number: 1,
    name: 'Rumah Pertama',
    gridOrigin: Offset(15, 15),
    routerPosition: Offset(105, 315),
    routerLabel: 'Router',
    houses: [
      // TODO(langkah 5/8): pelanggan, paket & pemakaian belum ada di desain.
      HouseDef(
        id: 'r1',
        label: 'Rumah 1',
        position: Offset(255, 165),
        customer: 'Pak Joko',
        packageMbps: 10,
        peakMbps: 6,
      ),
      HouseDef(
        id: 'r2',
        label: 'Rumah 2',
        position: Offset(315, 345),
        customer: 'Bu Lina',
        packageMbps: 10,
        peakMbps: 4,
      ),
    ],
    budget: 200000,
    targetSatisfaction: 60,
    blockLabels: [
      MapBlockLabel('BLOK A', Offset(255, 112), align: TextAlign.center),
    ],
  );

  static const _j1 = Offset(195, 150);

  static const level5 = LevelDef(
    number: 5,
    name: 'Gang Melati',
    gridOrigin: Offset(15, 0),
    routerPosition: Offset(195, 240),
    houses: [
      HouseDef(
        id: 'r1',
        label: 'Rumah 1',
        position: Offset(75, 90),
        customer: 'Pak Anton',
        packageMbps: 10,
        peakMbps: 4,
      ),
      HouseDef(
        id: 'w',
        label: 'Warung',
        position: Offset(195, 60),
        customer: 'Warung Bu Ijah',
        place: 'Blok A',
        packageMbps: 20,
        peakMbps: 12,
        labelSide: MarkSide.right,
        patienceSide: MarkSide.right,
      ),
      HouseDef(
        id: 'r3',
        label: 'Rumah 3',
        position: Offset(315, 90),
        customer: 'Kak Dewi',
        packageMbps: 10,
        peakMbps: 8.5,
      ),
      HouseDef(
        id: 'r4',
        label: 'Rumah 4',
        position: Offset(315, 240),
        customer: 'Bu Sri',
        packageMbps: 20,
        peakMbps: 16,
        patienceSide: MarkSide.above,
      ),
      HouseDef(
        id: 'r5',
        label: 'Rumah 5',
        position: Offset(315, 390),
        customer: 'Pak Rudi',
        packageMbps: 10,
        peakMbps: 9,
      ),
      HouseDef(
        id: 'r6',
        label: 'Rumah 6',
        position: Offset(195, 420),
        customer: 'Bang Togar',
        packageMbps: 20,
        peakMbps: 11,
        patienceSide: MarkSide.right,
      ),
      HouseDef(
        id: 'r7',
        label: 'Rumah 7',
        position: Offset(75, 330),
        customer: 'Mbak Wulan',
        packageMbps: 10,
        peakMbps: 6,
      ),
    ],
    junctions: [Junction(id: 'j1', position: _j1)],
    cables: [
      Cable(
        id: 'c-r1',
        from: 'j1',
        to: 'r1',
        points: [_j1, Offset(135, 90), Offset(95, 90)],
      ),
      Cable(
        id: 'c-r3',
        from: 'j1',
        to: 'r3',
        points: [_j1, Offset(255, 90), Offset(295, 90)],
      ),
      Cable(
        id: 'c-r4',
        from: LevelDef.routerId,
        to: 'r4',
        points: [Offset(219, 240), Offset(295, 240)],
        badgeAt: Offset(262, 276),
      ),
      Cable(
        id: 'c-w',
        from: LevelDef.routerId,
        to: 'w',
        kind: CableKind.fiber,
        via: ['j1'],
        points: [Offset(195, 216), Offset(195, 80)],
      ),
    ],
    budget: 850000,
    targetSatisfaction: 80,
    rushHourFrom: 19,
    rushHourTo: 22,
    blockLabels: [
      MapBlockLabel('BLOK A', Offset(300, 30), align: TextAlign.center),
      MapBlockLabel('BLOK B', Offset(376, 320), align: TextAlign.right),
      MapBlockLabel('BLOK C', Offset(40, 402)),
    ],
    nightBlockLabels: [
      MapBlockLabel('BLOK A', Offset(300, 24), align: TextAlign.center),
      MapBlockLabel('BLOK B', Offset(376, 452), align: TextAlign.right),
      MapBlockLabel('BLOK C', Offset(40, 402)),
    ],
  );

  static const all = [level1, level5];
}
