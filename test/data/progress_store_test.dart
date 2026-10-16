import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void usePrefs(Map<String, Object> data) {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(data);
  }

  test('kosong → null; simpan lalu buka ulang → progres yang sama', () async {
    usePrefs({});
    final store = await PrefsProgressStore.open();
    expect(store.load(), isNull);
    final p = Progress(const {1: 3, 5: 2}, tutorialDone: true);
    await store.save(p);
    final reopened = await PrefsProgressStore.open();
    expect(reopened.load(), p);
  });

  test('isi rusak atau bertipe lain → null', () async {
    for (final value in <Object>['{rusak', 42, true]) {
      usePrefs({PrefsProgressStore.key: value});
      final store = await PrefsProgressStore.open();
      expect(store.load(), isNull, reason: '$value');
    }
  });

  test('memori: menyimpan untuk load berikutnya', () async {
    final store = MemoryProgressStore();
    expect(store.load(), isNull);
    await store.save(Progress(const {1: 1}));
    expect(store.load(), Progress(const {1: 1}));
  });
}
