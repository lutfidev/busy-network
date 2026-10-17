import 'package:busy_network/music/music_out.dart';
import 'package:busy_network/music/track.dart';

/// Satu permintaan ke [MusicOut.play].
typedef MusicCall = ({Track? track, Duration fade, Duration delay});

/// Mencatat lagu yang diminta, alih-alih memutarnya.
class RecordingMusic implements MusicOut {
  final calls = <MusicCall>[];

  /// Lagu yang terdengar terakhir diminta; `null` = diam.
  Track? get current => calls.isEmpty ? null : calls.last.track;

  @override
  void play(
    Track? track, {
    Duration fade = Duration.zero,
    Duration delay = Duration.zero,
  }) => calls.add((track: track, fade: fade, delay: delay));
}
