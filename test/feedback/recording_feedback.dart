import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/settings_book.dart';
import 'package:busy_network/feedback/game_feedback.dart';

/// Mencatat suara & getar yang diminta, alih-alih memutarnya.
class RecordingFeedback implements SoundOut, HapticOut {
  final sounds = <Cue>[];
  final buzzes = <Cue>[];

  @override
  void play(Cue cue) => sounds.add(cue);

  @override
  void buzz(Cue cue) => buzzes.add(cue);
}

/// Sesi yang suaranya direkam ke [out].
GameSession recordingSession(
  RecordingFeedback out, {
  ProgressBook? progress,
  SettingsBook? settings,
}) => GameSession(
  progress: progress,
  feedback: GameFeedback(
    settings: settings ?? SettingsBook.memory(),
    sound: out,
    haptics: out,
  ),
);
