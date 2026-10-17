import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_feedback.dart';

/// Efek suara dari `assets/audio/` lewat `audioplayers`: satu [AudioPool]
/// per [Cue] supaya suara yang sama bisa bertumpuk. Bercampur dengan musik
/// pemain (tidak merebut fokus audio).
///
/// Suara dimuat di latar belakang supaya aplikasi tidak menunggu; cue yang
/// suaranya belum (atau gagal) dimuat diam saja.
class AudioSoundOut implements SoundOut {
  AudioSoundOut() {
    unawaited(_load());
  }

  final _pools = <Cue, AudioPool>{};

  Future<void> _load() async {
    final context = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    for (final cue in Cue.values) {
      try {
        _pools[cue] = await AudioPool.create(
          source: AssetSource('audio/${cue.sound}.wav'),
          maxPlayers: 3,
          audioContext: context,
        );
      } on Object catch (error) {
        debugPrint('Suara ${cue.sound} gagal dimuat: $error');
      }
    }
  }

  @override
  void play(Cue cue) {
    final pool = _pools[cue];
    if (pool == null) return;
    unawaited(
      pool.start().then<void>(
        (_) {},
        onError: (Object error) => debugPrint('Suara gagal diputar: $error'),
      ),
    );
  }
}
