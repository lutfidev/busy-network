/// Data dummy untuk prototipe statis. Semua angka & teks diambil dari
/// `design/Jaringan Sibuk.html`. Sesi berikutnya diganti state game asli.
library;

import '../game/map_scene.dart';

class ChapterInfo {
  const ChapterInfo({
    required this.number,
    required this.name,
    required this.starsEarned,
    required this.starsTotal,
    required this.levelsDone,
    required this.levelsTotal,
  });

  final int number;
  final String name;
  final int starsEarned;
  final int starsTotal;
  final int levelsDone;
  final int levelsTotal;

  /// Progres babak untuk bar di Beranda. Desain memakai lebar 33%.
  double get progress => levelsDone / levelsTotal;
}

class CableSpec {
  const CableSpec({
    required this.kind,
    required this.name,
    required this.pricePerSegment,
    required this.capacityMbps,
    required this.tagline,
  });

  final CableKind kind;
  final String name;
  final int pricePerSegment;
  final int capacityMbps;

  /// "murah" / "ngebut".
  final String tagline;
}

class LevelInfo {
  const LevelInfo({
    required this.number,
    required this.name,
    required this.budget,
    required this.targetSatisfaction,
    required this.housesTotal,
    required this.housesConnected,
    this.rushHourFrom,
    this.rushHourTo,
  });

  final int number;
  final String name;
  final int budget;
  final int targetSatisfaction;
  final int housesTotal;
  final int housesConnected;
  final int? rushHourFrom;
  final int? rushHourTo;
}

class QueueHouse {
  const QueueHouse({
    required this.id,
    required this.name,
    required this.where,
    required this.packageMbps,
    required this.usageMbps,
    required this.initialLimit,
    this.onOverloadedCable = false,
    this.initiallyPrioritized = false,
  });

  final String id;
  final String name;
  final String where;
  final int packageMbps;
  final double usageMbps;
  final int initialLimit;

  /// Rumah yang lewat kabel Router → Rumah 4 (kabel yang penuh).
  final bool onOverloadedCable;
  final bool initiallyPrioritized;
}

abstract final class DummyData {
  static const chapter = ChapterInfo(
    number: 1,
    name: 'Perumahan Batam',
    starsEarned: 9,
    starsTotal: 36,
    levelsDone: 4,
    levelsTotal: 12,
  );

  static const lan = CableSpec(
    kind: CableKind.lan,
    name: 'LAN',
    pricePerSegment: 15000,
    capacityMbps: 20,
    tagline: 'murah',
  );

  static const fiber = CableSpec(
    kind: CableKind.fiber,
    name: 'Fiber',
    pricePerSegment: 60000,
    capacityMbps: 100,
    tagline: 'ngebut',
  );

  /// Level tempat kabel fiber terbuka.
  static const fiberUnlockLevel = 3;

  static const level1 = LevelInfo(
    number: 1,
    name: 'Rumah Pertama',
    budget: 200000,
    targetSatisfaction: 60,
    housesTotal: 2,
    housesConnected: 0,
  );

  static const level5 = LevelInfo(
    number: 5,
    name: 'Gang Melati',
    budget: 850000,
    targetSatisfaction: 80,
    housesTotal: 7,
    housesConnected: 4,
    rushHourFrom: 19,
    rushHourTo: 22,
  );

  /// Kabel yang sedang ditarik di fase rancang.
  static const draftingSegments = 3;

  // ── Fase jalan ────────────────────────────────────────────────────────
  static const dayStartHour = 6;
  static const dayEndHour = 24;
  static const runClockMinutes = 20 * 60 + 15;
  static const runSatisfaction = 62;
  static const overloadedLoad = 25;
  static const overloadedCapacity = 20;
  static const overloadedHousePatience = 15;

  /// Rumah yang komplain (nama & label diambil dari definisi level).
  static const complaintHouseId = 'r4';
  static const complaintName = 'Bu Sri';
  static const complaintHouse = 'Rumah 4';
  static const complaintClockMinutes = 20 * 60 + 14;
  static const complaintMessage =
      'Bang, kok lemot?? Anak saya lagi ujian online!';

  // ── Panel atur antrean ────────────────────────────────────────────────
  static const queueCableLabel = 'Kabel Router → Rumah 4';
  static const queueHouses = <QueueHouse>[
    QueueHouse(
      id: 'r4',
      name: 'Bu Sri',
      where: 'Rumah 4',
      packageMbps: 20,
      usageMbps: 16,
      initialLimit: 20,
      onOverloadedCable: true,
    ),
    QueueHouse(
      id: 'r5',
      name: 'Pak Rudi',
      where: 'Rumah 5',
      packageMbps: 10,
      usageMbps: 9,
      initialLimit: 10,
      onOverloadedCable: true,
    ),
    QueueHouse(
      id: 'r3',
      name: 'Kak Dewi',
      where: 'Rumah 3',
      packageMbps: 10,
      usageMbps: 8.5,
      initialLimit: 10,
    ),
    QueueHouse(
      id: 'w',
      name: 'Warung Bu Ijah',
      where: 'Blok A',
      packageMbps: 20,
      usageMbps: 12,
      initialLimit: 20,
      initiallyPrioritized: true,
    ),
    QueueHouse(
      id: 'r1',
      name: 'Pak Anton',
      where: 'Rumah 1',
      packageMbps: 10,
      usageMbps: 4,
      initialLimit: 10,
    ),
    QueueHouse(
      id: 'r6',
      name: 'Bang Togar',
      where: 'Rumah 6',
      packageMbps: 20,
      usageMbps: 11,
      initialLimit: 20,
    ),
    QueueHouse(
      id: 'r7',
      name: 'Mbak Wulan',
      where: 'Rumah 7',
      packageMbps: 10,
      usageMbps: 6,
      initialLimit: 10,
    ),
  ];

  // ── Hasil ─────────────────────────────────────────────────────────────
  static const savingsTarget = 200000;

  static const failSatisfaction = 41;
  static const failComplaints = 11;
  static const failHousesLost = 2;
}
