import 'package:busy_network/app/app.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/screens/level_map/level_map_screen.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

/// Animasi dengan setelan normal (tanpa [disableAnimations]). Jangan pakai
/// `pumpAndSettle` di sini untuk layar beranimasi berulang.
Future<void> pumpAnimated(WidgetTester tester, String location) async {
  setScreenSize(tester, const Size(390, 844));
  await tester.pumpWidget(JaringanSibukApp(initialLocation: location));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpFonts();

  group('cincin level aktif', () {
    Finder ring() => find.descendant(
      of: find.byType(LevelMapScreen),
      matching: find.byType(Opacity),
    );

    testWidgets('berdenyut: membesar sambil memudar', (tester) async {
      await pumpAnimated(tester, AppRoutes.levelMap);
      double opacity() => tester.widget<Opacity>(ring()).opacity;
      double scale() => tester
          .widget<Transform>(
            find.ancestor(of: ring(), matching: find.byType(Transform)).first,
          )
          .transform
          .getMaxScaleOnAxis();

      final (o1, s1) = (opacity(), scale());
      await tester.pump(const Duration(milliseconds: 600));
      expect(opacity(), lessThan(o1));
      expect(scale(), greaterThan(s1));
      expect(scale(), lessThanOrEqualTo(1.55));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('animasi mati → pose statis', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.levelMap);
      expect(
        tester.widget<Opacity>(ring()).opacity,
        closeTo(AppMotion.ringOpacity.at(0.25), 1e-9),
      );
    });
  });
}
