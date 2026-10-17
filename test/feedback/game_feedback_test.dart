import 'dart:io';

import 'package:busy_network/app/settings_book.dart';
import 'package:busy_network/feedback/game_feedback.dart';
import 'package:busy_network/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_feedback.dart';

void main() {
  test('cue: suara & getar mengikuti setelan saat itu', () async {
    final settings = SettingsBook.memory();
    final out = RecordingFeedback();
    final feedback = GameFeedback(settings: settings, sound: out, haptics: out);

    feedback.cue(Cue.connect);
    expect(out.sounds, [Cue.connect]);
    expect(out.buzzes, [Cue.connect]);

    await settings.setSound(false);
    feedback.cue(Cue.tap);
    expect(out.sounds, [Cue.connect]);
    expect(out.buzzes, [Cue.connect, Cue.tap]);

    await settings.setVibration(false);
    feedback.cue(Cue.win);
    expect(out.sounds, [Cue.connect]);
    expect(out.buzzes, [Cue.connect, Cue.tap]);
  });

  test('default diam: tanpa suara, tanpa getar', () {
    final feedback = GameFeedback(
      settings: SettingsBook.memory(Settings.initial),
    );
    expect(feedback.sound, isA<SilentSound>());
    expect(feedback.haptics, isA<NoHaptics>());
  });

  test('tiap cue punya berkas suara di assets/audio', () {
    for (final cue in Cue.values) {
      expect(
        File('assets/audio/${cue.sound}.wav').existsSync(),
        isTrue,
        reason: cue.name,
      );
    }
  });
}
