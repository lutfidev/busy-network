import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Jam untuk animasi berulang (`animation: … infinite` di desain).
///
/// [builder] menerima detik sejak jam mulai sebagai [ValueListenable].
/// Berikan ke `CustomPainter(repaint: …)` atau `ValueListenableBuilder`
/// supaya hanya bagian yang bergerak yang digambar ulang; nilainya lalu
/// diubah jadi pose lewat `Keyframes`. Padanan `update(dt)` game loop Flame.
///
/// Jam diam di 0 (= bingkai statis desain) bila [enabled] false atau
/// `MediaQuery.disableAnimations` aktif: setelan aksesibilitas "hapus
/// animasi", dan dipakai test supaya `pumpAndSettle` tidak macet.
class LoopClock extends StatefulWidget {
  const LoopClock({super.key, required this.builder, this.enabled = true});

  final Widget Function(BuildContext context, ValueListenable<double> seconds)
  builder;

  /// `false` bila tidak ada yang bergerak (hemat baterai).
  final bool enabled;

  @override
  State<LoopClock> createState() => _LoopClockState();
}

class _LoopClockState extends State<LoopClock>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _seconds = ValueNotifier<double>(0);

  void _tick(Duration elapsed) {
    _seconds.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  void _sync() {
    final run =
        widget.enabled &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (run == _ticker.isActive) return;
    if (run) {
      _ticker.start();
    } else {
      _ticker.stop();
      _seconds.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LoopClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _seconds);
}
