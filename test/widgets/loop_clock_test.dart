import 'package:busy_network/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ValueListenable<double> clock;

  Widget subject({bool enabled = true, bool disableAnimations = false}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: LoopClock(
        enabled: enabled,
        builder: (context, seconds) {
          clock = seconds;
          return const SizedBox();
        },
      ),
    );
  }

  testWidgets('jam berjalan mengikuti frame', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pump(const Duration(milliseconds: 100));
    final start = clock.value;
    await tester.pump(const Duration(milliseconds: 700));
    expect(clock.value - start, closeTo(0.7, 1e-6));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('diam di 0 bila MediaQuery.disableAnimations', (tester) async {
    await tester.pumpWidget(subject(disableAnimations: true));
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('berhenti & kembali ke 0 saat animasi dimatikan', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(clock.value, greaterThan(0));

    await tester.pumpWidget(subject(disableAnimations: true));
    expect(clock.value, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('enabled: false → diam', (tester) async {
    await tester.pumpWidget(subject(enabled: false));
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
