import 'package:flutter/foundation.dart';

import '../data/dummy_data.dart';
import '../data/progress_store.dart';
import '../game/progress/progress.dart';

/// Progres pemain selama aplikasi berjalan: dibaca Beranda & Peta Babak,
/// ditulis saat level selesai ([record]). Belum ada yang tersimpan →
/// progres awal desain ([DummyData.progress]).
class ProgressBook extends ChangeNotifier {
  ProgressBook(this._store) : _progress = _store.load() ?? DummyData.progress;

  /// Progres di memori saja (default aplikasi di test).
  ProgressBook.memory() : this(MemoryProgressStore());

  final ProgressStore _store;
  Progress _progress;

  Progress get progress => _progress;

  /// Catat [stars] bintang level [level] (yang terbaik dipakai), beri tahu
  /// pendengar, lalu simpan. Gagal simpan tidak menghentikan permainan:
  /// progres di memori tetap berlaku.
  Future<void> record(int level, int stars) async {
    final next = _progress.record(level, stars);
    if (identical(next, _progress)) return;
    _progress = next;
    notifyListeners();
    try {
      await _store.save(next);
    } on Object catch (error) {
      debugPrint('Progres gagal disimpan: $error');
    }
  }
}
