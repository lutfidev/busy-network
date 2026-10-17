import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/data/progress_store.dart';
import 'package:busy_network/game/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenStore implements ProgressStore {
  @override
  Progress? load() => null;

  @override
  Future<void> save(Progress progress) async => throw StateError('disk penuh');
}

void main() {
  test('store kosong → mulai dari level 1', () {
    expect(ProgressBook.memory().progress, Progress.empty);
    expect(ProgressBook(MemoryProgressStore()).progress.current, 1);
  });

  test('progres awal bisa diisi (potret desain)', () {
    final book = ProgressBook.memory(DummyData.designProgress);
    expect(book.progress.current, 5);
    expect(book.progress.totalStars, 9);
    final saved = ProgressBook(
      MemoryProgressStore(Progress(const {1: 1})),
      initial: DummyData.designProgress,
    );
    expect(saved.progress, Progress(const {1: 1}), reason: 'tersimpan menang');
  });

  test(
    'record: memberi tahu & menyimpan; bintang lebih rendah diabaikan',
    () async {
      final store = MemoryProgressStore();
      final book = ProgressBook(store);
      var notified = 0;
      book.addListener(() => notified++);
      await book.record(5, 2);
      expect(book.progress.starsOf(5), 2);
      expect(store.load()!.starsOf(5), 2);
      expect(notified, 1);
      await book.record(5, 1);
      expect(book.progress.starsOf(5), 2);
      expect(notified, 1);
    },
  );

  test('memuat progres yang tersimpan', () {
    final book = ProgressBook(MemoryProgressStore(Progress(const {1: 1})));
    expect(book.progress, Progress(const {1: 1}));
  });

  test('gagal simpan: progres di memori tetap berlaku', () async {
    final book = ProgressBook(_BrokenStore());
    await book.record(5, 3);
    expect(book.progress.starsOf(5), 3);
  });

  test('completeTutorial: memberi tahu & menyimpan sekali', () async {
    final store = MemoryProgressStore();
    final book = ProgressBook(store);
    var notified = 0;
    book.addListener(() => notified++);
    await book.completeTutorial();
    expect(book.progress.tutorialDone, isTrue);
    expect(book.progress.totalStars, 0);
    expect(store.load()!.tutorialDone, isTrue);
    expect(notified, 1);
    await book.completeTutorial();
    expect(notified, 1);
  });

  test('completeTutorial gagal simpan: tetap selesai di memori', () async {
    final book = ProgressBook(_BrokenStore());
    await book.completeTutorial();
    expect(book.progress.tutorialDone, isTrue);
  });
}
