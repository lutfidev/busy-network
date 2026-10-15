import 'package:busy_network/widgets/icons/svg_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parser path menangani perintah absolut & relatif', () {
    final p = parseSvgPath('M10 10 H20 V30 L10 30 Z');
    final b = p.getBounds();
    expect(b.left, 10);
    expect(b.top, 10);
    expect(b.right, 20);
    expect(b.bottom, 30);
  });

  test('parser path menangani angka menempel & arc', () {
    // Ikon play & gembok dari desain.
    final play = parseSvgPath(
      'M7 4.5v15a1 1 0 0 0 1.5.86l12-7.5a1 1 0 0 0 0-1.72l-12-7.5A1 1 0 0 0 7 4.5z',
    );
    expect(play.getBounds().left, closeTo(7, 0.01));
    expect(play.getBounds().right, greaterThan(20));
    final lock = parseSvgPath('M8 11V7.5a4 4 0 0 1 8 0V11');
    expect(lock.getBounds().top, closeTo(3.5, 0.01));
  });

  test('perintah tak dikenal melempar FormatException', () {
    expect(() => parseSvgPath('M0 0 X1 1'), throwsFormatException);
  });
}
