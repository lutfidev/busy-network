import 'package:shared_preferences/shared_preferences.dart';

import '../game/progress/progress.dart';

/// Tempat progres disimpan di antara sesi.
abstract interface class ProgressStore {
  /// Progres tersimpan; `null` bila belum ada atau tidak terbaca.
  Progress? load();

  Future<void> save(Progress progress);
}

/// Progres di memori saja (test, dan cadangan bila perangkat menolak).
class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([this._saved]);

  Progress? _saved;

  @override
  Progress? load() => _saved;

  @override
  Future<void> save(Progress progress) async => _saved = progress;
}

/// Progres di `shared_preferences`: satu kunci [key] berisi JSON
/// `Progress.encode`.
class PrefsProgressStore implements ProgressStore {
  PrefsProgressStore._(this._prefs);

  static const key = 'progres';

  static Future<PrefsProgressStore> open() async => PrefsProgressStore._(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {key}),
    ),
  );

  final SharedPreferencesWithCache _prefs;

  @override
  Progress? load() {
    final value = _prefs.get(key);
    return value is String ? Progress.decode(value) : null;
  }

  @override
  Future<void> save(Progress progress) =>
      _prefs.setString(key, progress.encode());
}
