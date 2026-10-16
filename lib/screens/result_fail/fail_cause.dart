import '../../core/format.dart';
import '../../game/result/level_result.dart';

/// Isi kartu "BIANG KEROKNYA": kalimat tebal + saran.
typedef FailCause = ({String title, String hint});

FailCause failCause(Culprit culprit) => switch (culprit) {
  FullCable(
    :final area,
    :final minute,
    :final heavyUsers,
    :final suggestFiber,
  ) =>
    (
      title: 'Kabel ke $area kelebihan beban jam ${IdFormat.clock(minute)}.',
      hint: suggestFiber
          ? 'Ganti kabel utamanya ke fiber, atau batasi jatah '
                '${_and(heavyUsers)} sebelum jam sibuk.'
          : 'Batasi jatah ${_and(heavyUsers)} sebelum jam sibuk.',
    ),
  Unconnected(:final customers) => (
    title: '${customers.length} rumah belum tersambung.',
    hint: 'Tarik kabel ke ${_and(customers.take(2))} sebelum mulai hari.',
  ),
  TightLimit(:final customers) => (
    title: 'Jatah ${_and(customers)} dibatasi terlalu ketat.',
    hint: 'Naikkan batas antreannya, kabelnya masih kuat.',
  ),
};

/// "A" / "A dan B" (paling banyak dua nama).
String _and(Iterable<String> names) => names.join(' dan ');
