import 'package:flutter/services.dart';

import '../app/settings_book.dart';

/// Kejadian yang terdengar & terasa.
enum Cue {
  /// Tombol diketuk.
  tap('tap'),

  /// Kabel terpasang.
  connect('connect'),

  /// Kabel sampai di rumah tapi anggaran kurang.
  refuse('refuse'),

  /// Kabel dibongkar.
  remove('remove'),

  /// Komplain muncul (hari terjeda).
  complaint('complaint'),

  /// Hari selesai, lulus.
  win('win'),

  /// Hari selesai, gagal.
  fail('fail');

  const Cue(this.sound);

  /// Nama berkas `assets/audio/<sound>.wav`.
  final String sound;
}

/// Pemutar efek suara.
abstract interface class SoundOut {
  void play(Cue cue);
}

/// Penggetar.
abstract interface class HapticOut {
  void buzz(Cue cue);
}

/// Tanpa suara (test, dan bila audio perangkat gagal dibuka).
class SilentSound implements SoundOut {
  const SilentSound();

  @override
  void play(Cue cue) {}
}

/// Tanpa getar (test).
class NoHaptics implements HapticOut {
  const NoHaptics();

  @override
  void buzz(Cue cue) {}
}

/// Getar bawaan sistem (`HapticFeedback`): makin penting kejadiannya, makin
/// berat.
class SystemHaptics implements HapticOut {
  const SystemHaptics();

  @override
  void buzz(Cue cue) {
    switch (cue) {
      case Cue.tap:
        HapticFeedback.selectionClick();
      case Cue.connect || Cue.remove:
        HapticFeedback.lightImpact();
      case Cue.complaint || Cue.win:
        HapticFeedback.mediumImpact();
      case Cue.refuse || Cue.fail:
        HapticFeedback.heavyImpact();
    }
  }
}

/// Suara & getar permainan, mengikuti [settings] saat itu. Default diam
/// (test); `main()` memasang `AudioSoundOut` & [SystemHaptics].
class GameFeedback {
  GameFeedback({
    required this.settings,
    this.sound = const SilentSound(),
    this.haptics = const NoHaptics(),
  });

  final SettingsBook settings;
  final SoundOut sound;
  final HapticOut haptics;

  void cue(Cue cue) {
    final s = settings.settings;
    if (s.sound) sound.play(cue);
    if (s.vibration) haptics.buzz(cue);
  }
}
