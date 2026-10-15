import 'package:busy_network/app/app.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/screens/home/home_painters.dart';
import 'package:busy_network/screens/level_map/level_map_screen.dart';
import 'package:busy_network/screens/result_success/result_success_screen.dart';
import 'package:busy_network/screens/tutorial/tutorial_overlay.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:busy_network/widgets/widgets.dart';
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

  group('bintang hasil berhasil', () {
    Finder filled() => find.descendant(
      of: find.byType(ResultSuccessScreen),
      matching: find.byType(Opacity),
    );
    List<double> opacities(WidgetTester tester) => [
      for (final e in filled().evaluate()) (e.widget as Opacity).opacity,
    ];

    testWidgets('muncul bergiliran lalu diam', (tester) async {
      await pumpAnimated(tester, AppRoutes.successWithStars(3));
      // 0,1 s: belum ada yang muncul (jeda pertama 0,2 s).
      expect(opacities(tester), [0, 0, 0]);
      await tester.pump(const Duration(milliseconds: 600));
      // 0,7 s: bintang 1 hampir selesai, bintang 2 baru mulai, 3 belum.
      final mid = opacities(tester);
      expect(mid[0], 1);
      expect(mid[1], inExclusiveRange(0, 1));
      expect(mid[2], 0);
      await tester.pumpAndSettle();
      expect(opacities(tester), [1, 1, 1]);
    });

    testWidgets('hanya bintang yang didapat yang muncul', (tester) async {
      await pumpAnimated(tester, AppRoutes.successWithStars(1));
      await tester.pumpAndSettle();
      expect(opacities(tester), [1]);
    });

    testWidgets('animasi mati → langsung tampil', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: AppRoutes.successWithStars(2));
      expect(opacities(tester), [1, 1]);
    });
  });

  group('tangan tutorial', () {
    String step(int n) => '${AppRoutes.tutorial}?${AppRoutes.stepParam}=$n';
    Finder inHand(Type type) => find.descendant(
      of: find.byType(TutorialHand),
      matching: find.byType(type),
    );
    Offset shift(WidgetTester tester) {
      final m = tester.widget<Transform>(inHand(Transform).first).transform;
      return Offset(m.getTranslation().x, m.getTranslation().y);
    }

    testWidgets('langkah 2: menyeret ke Rumah 1 lalu memudar', (tester) async {
      await pumpAnimated(tester, step(2));
      await tester.pump(const Duration(milliseconds: 16));
      final start = shift(tester);
      await tester.pump(const Duration(milliseconds: 1000));
      final moved = shift(tester);
      expect(moved.dx, greaterThan(start.dx + 50));
      expect(moved.dy, lessThan(start.dy - 50));

      var minOpacity = 1.0;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final o = tester.widget<Opacity>(inHand(Opacity)).opacity;
        if (o < minOpacity) minOpacity = o;
      }
      expect(minOpacity, lessThan(0.5));
    });

    testWidgets('langkah 1 & 3: mengangguk', (tester) async {
      for (final n in [1, 3]) {
        await pumpAnimated(tester, step(n));
        await tester.pump(const Duration(milliseconds: 16));
        final start = shift(tester);
        await tester.pump(const Duration(milliseconds: 500));
        final down = shift(tester);
        expect(down.dy, greaterThan(start.dy + 3), reason: 'langkah $n');
        expect(down.dx, greaterThan(start.dx), reason: 'langkah $n');
        await tester.pump(const Duration(milliseconds: 600));
        expect(shift(tester).dy, lessThan(down.dy), reason: 'langkah $n');
      }
    });

    testWidgets('animasi mati → tangan diam di titik awal', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester, location: step(2));
      expect(shift(tester), Offset.zero);
      expect(tester.widget<Opacity>(inHand(Opacity)).opacity, 1);
    });
  });

  group('latar Beranda', () {
    Finder painter() => find.descendant(
      of: find.byType(HomeBackdrop),
      matching: find.byType(CustomPaint),
    );

    testWidgets('terus bergerak', (tester) async {
      await pumpAnimated(tester, AppRoutes.home);
      final sketch =
          tester.widget<CustomPaint>(painter()).painter! as SketchPainter;
      var repaints = 0;
      sketch.addListener(() => repaints++);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(repaints, 2);
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('animasi mati → diam', (tester) async {
      setScreenSize(tester, const Size(390, 844));
      await pumpApp(tester);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
