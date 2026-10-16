import 'dart:convert';

/// Progres pemain: bintang terbaik tiap nomor level. Level terbuka & level
/// sekarang diturunkan dari sini, tidak disimpan.
class Progress {
  Progress(Map<int, int> stars)
    : _stars = Map.unmodifiable({
        for (final MapEntry(key: level, value: count) in stars.entries)
          if (_checked(level, count) > 0) level: count,
      });

  static const version = 1;

  final Map<int, int> _stars;

  int starsOf(int level) => _stars[level] ?? 0;

  /// Level sudah selesai (berbintang).
  bool isDone(int level) => starsOf(level) > 0;

  /// Level 1 selalu terbuka; level lain bila level sebelumnya selesai.
  bool isOpen(int level) => level == 1 || isDone(level - 1);

  /// Level terbuka pertama yang belum selesai.
  int get current {
    var level = 1;
    while (isDone(level)) {
      level++;
    }
    return level;
  }

  int get totalStars => _stars.values.fold(0, (sum, s) => sum + s);

  /// Level 1..[levelCount] yang sudah selesai.
  int levelsDone(int levelCount) => [
    for (var n = 1; n <= levelCount; n++)
      if (isDone(n)) n,
  ].length;

  /// Catat [stars] bintang di [level]; bintang terbaik yang dipakai.
  /// Mengembalikan `this` bila tidak ada yang berubah.
  Progress record(int level, int stars) {
    _checked(level, stars);
    if (stars <= starsOf(level)) return this;
    return Progress({..._stars, level: stars});
  }

  String encode() => jsonEncode({
    'versi': version,
    'bintang': {
      for (final level in _stars.keys.toList()..sort()) '$level': _stars[level],
    },
  });

  /// Kebalikan [encode]; `null` bila kosong, rusak, atau versi lain.
  static Progress? decode(String? source) {
    if (source == null) return null;
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return null;
    }
    if (json is! Map || json['versi'] != version) return null;
    final stars = json['bintang'];
    if (stars is! Map) return null;
    final parsed = <int, int>{};
    for (final MapEntry(:key, :value) in stars.entries) {
      final level = key is String ? int.tryParse(key) : null;
      if (level == null ||
          level < 1 ||
          value is! int ||
          value < 0 ||
          value > 3) {
        return null;
      }
      parsed[level] = value;
    }
    return Progress(parsed);
  }

  static int _checked(int level, int stars) {
    if (level < 1) throw ArgumentError.value(level, 'level', 'mulai dari 1');
    if (stars < 0 || stars > 3) {
      throw ArgumentError.value(stars, 'stars', '0..3');
    }
    return stars;
  }

  @override
  bool operator ==(Object other) =>
      other is Progress &&
      other._stars.length == _stars.length &&
      _stars.entries.every((e) => other._stars[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    _stars.entries.map((e) => Object.hash(e.key, e.value)),
  );
}
