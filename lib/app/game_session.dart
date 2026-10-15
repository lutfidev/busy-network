import '../data/dummy_states.dart';
import '../game/model/model.dart';

/// Hari yang sedang dimainkan, dioper antarrute: Fase Rancang menaruhnya
/// saat "Mulai Hari" ([begin]), Fase Jalan & Panel Atur Antrean memakai
/// hari yang sama ([currentDay]), layar hasil membaca akhirnya ([last],
/// langkah 6). Dibuat sekali oleh aplikasi dan diteruskan router ke layar.
///
/// Hari milik sesi (dibuat `GameState.planDay`) tidak di-`dispose`: layar
/// lain bisa masih mendengarkannya saat rutenya keluar; cukup dilepas.
class GameSession {
  GameState? _day;

  /// Hari terakhir yang dimainkan layar Fase Jalan, termasuk yang sudah
  /// selesai.
  GameState? get last => _day;

  /// Mulai hari baru dari rancangan (state fase jalan).
  void begin(GameState day) {
    if (day.phase != GamePhase.run) {
      throw ArgumentError.value(day.phase, 'day.phase', 'harus fase jalan');
    }
    _day = day;
  }

  /// Hari untuk layar Fase Jalan & Panel Antrean: hari yang sedang
  /// berjalan, atau — bila tidak ada (deep link, tutorial sampai langkah 7,
  /// hari sebelumnya sudah selesai) — bingkai Fase Jalan di desain, yang
  /// lalu menjadi hari sekarang (dan [last]).
  GameState currentDay() {
    final day = _day;
    if (day != null && day.phase == GamePhase.run) return day;
    return _day = DummyStates.run();
  }

  /// Pemain meninggalkan [day] sebelum selesai (kembali ke Fase Rancang).
  void abandon(GameState day) {
    if (identical(day, _day)) _day = null;
  }
}
