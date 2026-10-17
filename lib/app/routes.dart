/// Path semua layar. Rute bersarang supaya tombol back Android mengikuti
/// alur: Beranda → Peta → (Tutorial | Rancang → Jalan → Antrean) → Hasil,
/// dan Beranda → Pengaturan → Galeri.
abstract final class AppRoutes {
  static const home = '/';
  static const levelMap = '/peta';
  static const tutorial = '/peta/tutorial';
  static const design = '/peta/rancang';
  static const run = '/peta/rancang/jalan';
  static const queue = '/peta/rancang/jalan/antrean';
  static const success = '/peta/hasil/berhasil';
  static const fail = '/peta/hasil/gagal';
  static const settings = '/pengaturan';
  static const gallery = '/pengaturan/galeri';

  /// Query `?bintang=1..3` di layar hasil berhasil.
  static const starsParam = 'bintang';

  /// Query `?langkah=1..3` di tutorial.
  static const stepParam = 'langkah';

  /// Query `?level=n` di Fase Rancang.
  static const levelParam = 'level';

  /// Mulai level [number] dari awal: level 1 = tutorial selama
  /// [tutorialDone] belum, selain itu Fase Rancang level itu.
  static String play(int number, {required bool tutorialDone}) =>
      number == 1 && !tutorialDone ? tutorial : '$design?$levelParam=$number';

  /// Fase Jalan / Panel Antrean hari level [level]; halaman Fase Rancang di
  /// bawahnya ikut dibangun dengan level itu.
  static String runOf(int level) => '$run?$levelParam=$level';
  static String queueOf(int level) => '$queue?$levelParam=$level';

  static String successWithStars(int stars) => '$success?$starsParam=$stars';
}
