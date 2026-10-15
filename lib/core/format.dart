import 'package:intl/intl.dart';

/// Format angka gaya Indonesia: titik pemisah ribuan, koma desimal.
///
/// ```dart
/// IdFormat.rupiah(850000)  // "Rp 850.000"
/// IdFormat.mbps(8.5)       // "8,5 Mbps"
/// IdFormat.percent(62)     // "62%"
/// IdFormat.clock(20 * 60 + 15) // "20:15"
/// ```
abstract final class IdFormat {
  static const locale = 'id';

  static final NumberFormat _integer = NumberFormat.decimalPattern(locale);
  static final NumberFormat _oneDecimal = NumberFormat('#,##0.#', locale);

  /// Tanda minus tipografis (U+2212) seperti di desain ("−Rp 45.000").
  static const minus = '−';

  /// "Rp 850.000". Nilai negatif → "−Rp 45.000".
  static String rupiah(int amount) {
    final body = 'Rp ${_integer.format(amount.abs())}';
    return amount < 0 ? '$minus$body' : body;
  }

  /// Angka dengan maksimal 1 desimal: 8.5 → "8,5", 20 → "20", 1500 → "1.500".
  static String number(num value) => _oneDecimal.format(value);

  /// "8,5 Mbps".
  static String mbps(num value) => '${number(value)} Mbps';

  /// "25/20" atau "25 / 20" (dengan [spaced]).
  static String ratio(num a, num b, {bool spaced = false}) =>
      spaced ? '${number(a)} / ${number(b)}' : '${number(a)}/${number(b)}';

  /// Persen bulat: 0.62 (fraksi) atau 62 → "62%".
  static String percent(num value, {bool fraction = false}) {
    final v = fraction ? value * 100 : value;
    return '${v.round()}%';
  }

  /// Jam dari menit sejak 00:00 → "20:15".
  static String clock(int minutesOfDay) {
    final h = (minutesOfDay ~/ 60) % 24;
    final m = minutesOfDay % 60;
    return '${_two(h)}:${_two(m)}';
  }

  /// Rentang jam pakai en dash: "19–22".
  static String hourRange(int from, int to) => '$from–$to';

  /// Jam dua digit ("06").
  static String hour(int h) => _two(h);

  static String _two(int v) => v.toString().padLeft(2, '0');
}
