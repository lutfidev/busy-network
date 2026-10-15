/// Path semua layar. Rute bersarang supaya tombol back Android mengikuti
/// alur: Beranda → Peta → (Tutorial | Rancang → Jalan → Antrean) → Hasil.
abstract final class AppRoutes {
  static const home = '/';
  static const levelMap = '/peta';
  static const tutorial = '/peta/tutorial';
  static const design = '/peta/rancang';
  static const run = '/peta/rancang/jalan';
  static const queue = '/peta/rancang/jalan/antrean';
  static const success = '/peta/hasil/berhasil';
  static const fail = '/peta/hasil/gagal';
  static const gallery = '/galeri';

  /// Query `?bintang=1..3` di layar hasil berhasil.
  static const starsParam = 'bintang';

  /// Query `?langkah=1..3` di tutorial.
  static const stepParam = 'langkah';

  static String successWithStars(int stars) => '$success?$starsParam=$stars';
}
