part of 'levels.dart';

// Level 2–4: belajar menyambung berantai, fiber, dan tiang (junction).
// Copy baru (desain hanya punya level 1 & 5).

/// Tiga rumah, LAN saja: rantai kabel lebih hemat daripada kabel sendiri-
/// sendiri dari router, selama satu kabel tidak lewat 20 Mbps.
const _level2 = LevelDef(
  number: 2,
  name: 'Gang Sebelah',
  gridOrigin: Offset(15, 15),
  routerPosition: Offset(75, 285),
  routerLabel: 'Router',
  houses: [
    HouseDef(
      id: 'r1',
      label: 'Rumah 1',
      position: Offset(195, 165),
      customer: 'Bu Wati',
      block: 'Blok A',
      packageMbps: 10,
      peakMbps: 6,
      complaint: 'Bang, video call sama cucu putus-putus!',
    ),
    HouseDef(
      id: 'r2',
      label: 'Rumah 2',
      position: Offset(315, 165),
      customer: 'Pak Darto',
      block: 'Blok A',
      packageMbps: 10,
      peakMbps: 5,
      complaint: 'Bola di HP muter-muter terus, Bang.',
    ),
    HouseDef(
      id: 'r3',
      label: 'Rumah 3',
      position: Offset(255, 375),
      customer: 'Kak Sinta',
      block: 'Blok B',
      packageMbps: 10,
      peakMbps: 7,
      complaint: 'Tugas kuliahku nggak ke-upload, Bang!',
    ),
  ],
  budget: 300000,
  targetSatisfaction: 70,
  passSatisfaction: 50,
  savingsTarget: 100000,
  blockLabels: [
    MapBlockLabel('BLOK A', Offset(255, 112), align: TextAlign.center),
    MapBlockLabel('BLOK B', Offset(376, 440), align: TextAlign.right),
  ],
);

/// Fiber terbuka: Warnet butuh lebih dari 20 Mbps, jadi LAN pasti penuh.
const _level3 = LevelDef(
  number: 3,
  name: 'Warnet Bang Ucok',
  gridOrigin: Offset(15, 15),
  routerPosition: Offset(195, 315),
  routerLabel: 'Router',
  houses: [
    HouseDef(
      id: 'w',
      label: 'Warnet',
      position: Offset(195, 135),
      customer: 'Warnet Bang Ucok',
      block: 'Blok A',
      packageMbps: 30,
      peakMbps: 28,
      labelSide: MarkSide.right,
      patienceSide: MarkSide.right,
      complaint: 'Bang, anak-anak pada kabur, game-nya ngelag!',
    ),
    HouseDef(
      id: 'r1',
      label: 'Rumah 1',
      position: Offset(75, 225),
      customer: 'Bu Ani',
      block: 'Blok A',
      packageMbps: 10,
      peakMbps: 5,
      complaint: 'Resep di YouTube nggak mau jalan, Bang.',
    ),
    HouseDef(
      id: 'r2',
      label: 'Rumah 2',
      position: Offset(315, 225),
      customer: 'Pak Hendra',
      block: 'Blok A',
      packageMbps: 10,
      peakMbps: 6,
      complaint: 'Bang, mau transfer lewat m-banking gagal terus.',
    ),
    HouseDef(
      id: 'r3',
      label: 'Rumah 3',
      position: Offset(315, 405),
      customer: 'Dek Rara',
      block: 'Blok B',
      packageMbps: 10,
      peakMbps: 7,
      complaint: 'Kak, kelas online-ku keluar sendiri!',
    ),
  ],
  budget: 550000,
  targetSatisfaction: 85,
  passSatisfaction: 50,
  savingsTarget: 100000,
  blockLabels: [
    MapBlockLabel('BLOK A', Offset(195, 62), align: TextAlign.center),
    MapBlockLabel('BLOK B', Offset(40, 402)),
  ],
);

/// Tiang (junction) di tengah kompleks: satu kabel ke tiang lalu cabang
/// pendek ke rumah-rumah. Total pemakaiannya lewat 20 Mbps, jadi kabel ke
/// tiang harus fiber, atau rumah bawah disambung langsung dari router.
const _level4 = LevelDef(
  number: 4,
  name: 'Tiang Baru',
  gridOrigin: Offset(15, 15),
  routerPosition: Offset(195, 405),
  houses: [
    HouseDef(
      id: 'r1',
      label: 'Rumah 1',
      position: Offset(75, 105),
      customer: 'Pak Ahmad',
      block: 'Blok A',
      packageMbps: 10,
      peakMbps: 5,
      complaint: 'Bang, ceramah online-nya putus di tengah.',
    ),
    HouseDef(
      id: 'r2',
      label: 'Rumah 2',
      position: Offset(195, 75),
      customer: 'Bu Ratna',
      block: 'Blok A',
      packageMbps: 10,
      peakMbps: 6,
      labelSide: MarkSide.right,
      patienceSide: MarkSide.right,
      complaint: 'Sinetron kesayanganku nge-freeze, Bang!',
    ),
    HouseDef(
      id: 'r3',
      label: 'Rumah 3',
      position: Offset(315, 105),
      customer: 'Mas Bayu',
      block: 'Blok A',
      packageMbps: 10,
      peakMbps: 4,
      complaint: 'Bang, chat WA aja centang satu terus.',
    ),
    HouseDef(
      id: 'r4',
      label: 'Rumah 4',
      position: Offset(75, 285),
      customer: 'Kak Nadia',
      block: 'Blok B',
      packageMbps: 10,
      peakMbps: 7,
      complaint: 'Aku lagi live jualan baju, Bang, kok lemot?',
    ),
    HouseDef(
      id: 'r5',
      label: 'Rumah 5',
      position: Offset(315, 285),
      customer: 'Pak Simbolon',
      block: 'Blok B',
      packageMbps: 10,
      peakMbps: 5,
      complaint: 'Bang, lagu di karaoke online patah-patah!',
    ),
  ],
  junctions: [Junction(id: 'j1', position: Offset(195, 195))],
  budget: 650000,
  targetSatisfaction: 75,
  passSatisfaction: 55,
  blockLabels: [
    MapBlockLabel('BLOK A', Offset(300, 30), align: TextAlign.center),
    MapBlockLabel('BLOK B', Offset(40, 372)),
  ],
);
