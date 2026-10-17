import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_feedback.dart';

/// Efek suara dari `assets/audio/` lewat `audioplayers` mode
/// [PlayerMode.lowLatency] (SoundPool di Android: mulai cepat, cocok untuk
/// bunyi pendek). Tiap [Cue] punya [_voices] pemain yang dipakai bergiliran
/// supaya bunyi yang sama bisa bertumpuk. Bercampur dengan musik pemain
/// (tidak merebut fokus audio).
///
/// SoundPool tidak mengabari kapan bunyi selesai, jadi tiap putar =
/// `stop()` lalu `resume()` (stream baru), bukan `AudioPool`.
///
/// Suara dimuat di latar belakang supaya aplikasi tidak menunggu; cue yang
/// suaranya belum (atau gagal) dimuat diam saja.
class AudioSoundOut implements SoundOut {
  AudioSoundOut() {
    unawaited(_load());
  }

  static const _voices = 2;

  final _players = <Cue, List<AudioPlayer>>{};
  final _next = <Cue, int>{};

  Future<void> _load() async {
    final context = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    await Future.wait([for (final cue in Cue.values) _loadCue(cue, context)]);
  }

  Future<void> _loadCue(Cue cue, AudioContext context) async {
    try {
      final players = <AudioPlayer>[];
      for (var i = 0; i < _voices; i++) {
        final player = AudioPlayer();
        await player.setAudioContext(context);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('audio/${cue.sound}.wav'));
        players.add(player);
      }
      _players[cue] = players;
    } on Object catch (error) {
      debugPrint('Suara ${cue.sound} gagal dimuat: $error');
    }
  }

  @override
  void play(Cue cue) {
    final players = _players[cue];
    if (players == null) return;
    final turn = _next[cue] ?? 0;
    _next[cue] = turn + 1;
    final player = players[turn % players.length];
    unawaited(
      player
          .stop()
          .then((_) => player.resume())
          .catchError(
            (Object error) => debugPrint('Suara gagal diputar: $error'),
          ),
    );
  }
}
