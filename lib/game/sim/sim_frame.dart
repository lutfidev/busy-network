import '../map_scene.dart';

/// Keadaan satu rumah tersambung saat hari berjalan.
class HouseLive {
  const HouseLive({
    required this.state,
    required this.patience,
    required this.usageMbps,
    required this.demandMbps,
    required this.servedMbps,
  });

  /// Bagian [usage] yang terlayani oleh [served] (0..1); 1 bila tidak
  /// memakai apa pun.
  static double serviceOf(double usage, double served) =>
      usage > 0 ? served / usage : 1;

  final HouseState state;

  /// Sisa kesabaran 0..1.
  final double patience;

  /// Pemakaian yang diinginkan rumah saat ini (kurva harian × puncak).
  final double usageMbps;

  /// Yang masuk jaringan: pemakaian dipotong batas antrean ("Pakai
  /// sekarang" di panel antrean, beban kabel di badge "Penuh!").
  final double demandMbps;

  /// Yang benar-benar sampai setelah kapasitas kabel dibagi.
  final double servedMbps;

  /// Bagian pemakaian yang terlayani (0..1).
  double get service => serviceOf(usageMbps, servedMbps);
}

/// Potret simulasi pada satu menit.
class SimFrame {
  const SimFrame({
    required this.minute,
    required this.houses,
    required this.satisfaction,
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
