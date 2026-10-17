import 'package:flutter/widgets.dart';

import '../app/settings_book.dart';
import 'game_feedback.dart';

/// Menyediakan [GameFeedback] untuk tombol & layar di bawahnya.
class FeedbackScope extends InheritedWidget {
  const FeedbackScope({
    super.key,
    required this.feedback,
    required super.child,
  });

  final GameFeedback feedback;

  static final _silent = GameFeedback(settings: SettingsBook.memory());

  /// Feedback terdekat; tanpa scope (galeri, test komponen) = diam.
  static GameFeedback of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FeedbackScope>()?.feedback ??
      _silent;

  /// Bunyikan [cue] lewat feedback terdekat.
  static void cue(BuildContext context, Cue cue) => of(context).cue(cue);

  /// [onPressed] yang berbunyi [Cue.tap] dulu; `null` tetap `null`
  /// (tombol mati diam).
  static VoidCallback? tap(BuildContext context, VoidCallback? onPressed) =>
      onPressed == null
      ? null
      : () {
          cue(context, Cue.tap);
          onPressed();
        };

  @override
  bool updateShouldNotify(FeedbackScope oldWidget) =>
      feedback != oldWidget.feedback;
}
