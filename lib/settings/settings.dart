import 'dart:convert';

/// Setelan pemain (layar Pengaturan). Murni, tanpa Flutter.
class Settings {
  const Settings({this.sound = true, this.vibration = true});

  /// Awal permainan: suara & getar nyala.
  static const initial = Settings();

  /// Versi format [encode]; versi lain diabaikan saat [decode].
  static const version = 1;

  /// Efek suara.
  final bool sound;

  /// Getar (haptic).
  final bool vibration;

  Settings copyWith({bool? sound, bool? vibration}) => Settings(
    sound: sound ?? this.sound,
    vibration: vibration ?? this.vibration,
  );

  String encode() =>
      jsonEncode({'versi': version, 'suara': sound, 'getar': vibration});

  /// Kebalikan [encode]; `null` bila kosong, rusak, atau versi lain.
  static Settings? decode(String? source) {
    if (source == null) return null;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return null;
    }
    if (json is! Map || json['versi'] != version) return null;
    final sound = json['suara'];
    final vibration = json['getar'];
    if (sound is! bool || vibration is! bool) return null;
    return Settings(sound: sound, vibration: vibration);
  }

  @override
  bool operator ==(Object other) =>
      other is Settings && other.sound == sound && other.vibration == vibration;

  @override
  int get hashCode => Object.hash(sound, vibration);

  @override
  String toString() => 'Settings(sound: $sound, vibration: $vibration)';
}
