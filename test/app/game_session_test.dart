import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/sim/sim.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/sim/sim_fixtures.dart';
import '../screens/run_fixtures.dart';

void main() {
  test('hari asli lulus → bintang dicatat ke progres', () {
    final session = GameSession(
      progress: ProgressBook.memory(DummyData.designProgress),
    );
    final day = winningDay(minute: SimClock.dayStart);
    session.begin(day);
    playDay(day);
    final result = session.finish();
    expect(result.stars, 3);
    expect(session.result, same(result));
    expect(session.progress.progress.starsOf(5), 3);
    expect(session.progress.progress.current, 6);
  });

  test('finish dua kali: hasil sama, dicatat sekali', () {
    final book = ProgressBook.memory();
    var notified = 0;
    book.addListener(() => notified++);
    final session = GameSession(progress: book);
    final day = winningDay(minute: 23 * 60);
    session.begin(day);
    playDay(day);
    expect(session.finish(), same(session.finish()));
    expect(notified, 1);
  });

  test('hari gagal tidak mengubah progres', () {
    final session = GameSession();
    final day = designDay(Levels.level5.cables);
    session.begin(day);
    playDay(day);
    expect(session.finish().passed, isFalse);
    expect(session.progress.progress.starsOf(5), 0);
  });

  test('hari potret (deep link) tidak dicatat walau lulus', () {
    final session = GameSession();
    final day = session.currentDay();
    playDay(day);
    final result = session.finish();
    expect(result.passed, isTrue);
    expect(session.progress.progress.starsOf(5), 0);
  });

  test('hari belum selesai → StateError; hari baru menghapus hasil lama', () {
    final session = GameSession();
    expect(session.finish, throwsStateError);
    final day = winningDay(minute: 23 * 60);
    session.begin(day);
    expect(session.finish, throwsStateError);
    playDay(day);
    session.finish();
    session.begin(winningDay(minute: 23 * 60));
    expect(session.result, isNull);
  });

  test('potret hasil desain: bintang keluar dari aturan', () {
    expect(
      [
        for (final n in [1, 2, 3]) DummyData.success(n).stars,
      ],
      [1, 2, 3],
    );
    expect(DummyData.fail.passed, isFalse);
  });
}
