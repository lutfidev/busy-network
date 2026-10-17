import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings.dart';

/// Tempat setelan disimpan di antara sesi.
abstract interface class SettingsStore {
  /// Setelan tersimpan; `null` bila belum ada atau tidak terbaca.
  Settings? load();

  Future<void> save(Settings settings);
}

/// Setelan di memori saja (test, dan cadangan bila perangkat menolak).
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this._saved]);

  Settings? _saved;

  @override
  Settings? load() => _saved;

  @override
  Future<void> save(Settings settings) async => _saved = settings;
}

/// Setelan di `shared_preferences`: satu kunci [key] berisi JSON
/// `Settings.encode`.
class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore._(this._prefs);

  static const key = 'pengaturan';

  static Future<PrefsSettingsStore> open() async => PrefsSettingsStore._(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {key}),
    ),
  );

  final SharedPreferencesWithCache _prefs;

  @override
  Settings? load() {
    final value = _prefs.get(key);
    return value is String ? Settings.decode(value) : null;
  }

  @override
  Future<void> save(Settings settings) =>
      _prefs.setString(key, settings.encode());
}
