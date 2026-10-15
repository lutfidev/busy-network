import 'package:busy_network/theme/theme.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const second = Duration(seconds: 1);

  test('loop: pecahan siklus berulang', () {
    expect(Keyframes.loop(0, second), 0);
    expect(Keyframes.loop(0.25, second), closeTo(0.25, 1e-9));
    expect(Keyframes.loop(1.25, second), closeTo(0.25, 1e-9));
    expect(
      Keyframes.loop(0.7, const Duration(milliseconds: 1400)),
      closeTo(0.5, 1e-9),
    );
  });

  test('alternate: maju lalu mundur (animation-direction: alternate)', () {
    expect(Keyframes.alternate(0, second), 0);
    expect(Keyframes.alternate(0.25, second), closeTo(0.25, 1e-9));
    expect(Keyframes.alternate(1.25, second), closeTo(0.75, 1e-9));
    expect(Keyframes.alternate(2.25, second), closeTo(0.25, 1e-9));
  });

  test('at: nilai di titik keyframe dan easing per segmen', () {
    const blink = Keyframes([(0, 1), (0.5, 0.25), (1, 1)]);
    expect(blink.at(0), 1);
    expect(blink.at(0.5), 0.25);
    expect(blink.at(1), 1);
    // Tengah segmen pertama: ease-in-out simetris → tepat di tengah nilai.
    expect(blink.at(0.25), closeTo(0.625, 1e-9));
    // Easing dihitung per segmen, bukan sepanjang animasi.
    expect(
      blink.at(0.1),
      closeTo(1 - 0.75 * Curves.easeInOut.transform(0.2), 1e-9),
    );
  });

  test('at: segmen datar dan di luar rentang', () {
    const drag = Keyframes([(0, 0), (0.12, 0), (0.72, 1), (1, 1)]);
    expect(drag.at(0.06), 0);
    expect(drag.at(0.8), 1);
    expect(drag.at(-1), 0);
    expect(drag.at(2), 1);
  });
}
