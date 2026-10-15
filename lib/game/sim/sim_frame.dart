import 'dart:math' as math;

import '../map_scene.dart';
import 'sim_clock.dart';

/// Keadaan satu rumah tersambung saat hari berjalan.
class HouseLive {
  const HouseLive({
    required this.state,
    required this.patience,
    required this.usageMbps,
    this.limitMbps,
    this._servedMbps,
  });

  final HouseState state;

  /// Sisa kesabaran 0..1.
  final double patience;

  /// Pemakaian yang diinginkan rumah saat ini (kurva harian × puncak).
  final double usageMbps;

  /// Batas antrean; `null` = tanpa batas.
  final int? limitMbps;
  final double? _servedMbps;

  /// Yang masuk jaringan: pemakaian dipotong batas antrean ("Pakai
  /// sekarang" di panel antrean, beban kabel di badge "Penuh!").
  double get demandMbps => limitMbps == null
      ? usageMbps
      : math.min(usageMbps, limitMbps!.toDouble());

  /// Yang benar-benar sampai setelah kapasitas kabel dibagi.
  double get servedMbps => _servedMbps ?? demandMbps;

  /// Bagian pemakaian yang terlayani (0..1); 1 bila tidak memakai apa pun.
  double get service => usageMbps > 0 ? servedMbps / usageMbps : 1;
}

/// Potret simulasi pada satu menit.
class SimFrame {
  const SimFrame({
    this.minute = SimClock.dayStart,
    required this.houses,
    this.satisfaction = 100,
  });

  /// Jam (menit sejak 00:00).
  final int minute;

  /// Hanya rumah tersambung.
  final Map<String, HouseLive> houses;

  /// Kepuasan pelanggan 0..100 (persen, dibulatkan ke bawah).
  final int satisfaction;

  /// Permintaan tiap rumah yang masuk jaringan ([HouseLive.demandMbps]).
  Map<String, double> get demand => {
    for (final e in houses.entries) e.key: e.value.demandMbps,
  };
}

/// Komplain pelanggan: rumah [houseId] macet pada [minute].
class Complaint {
  const Complaint({required this.houseId, required this.minute});

  final String houseId;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is Complaint && other.houseId == houseId && other.minute == minute;

  @override
  int get hashCode => Object.hash(houseId, minute);
}
