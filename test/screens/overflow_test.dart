import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/gallery/widget_gallery_screen.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/screens/queue_panel/queue_panel_screen.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game/design_pull.dart';
import '../game/levels/level_plans.dart';
import '../test_helpers.dart';

/// Setiap layar harus bebas overflow di lebar 360 px (dan ukuran umum
/// lain). Overflow RenderFlex dilaporkan sebagai exception → test gagal.
final _routes = <String>[
  AppRoutes.home,
  AppRoutes.levelMap,
  '${AppRoutes.tutorial}?${AppRoutes.stepParam}=1',
  '${AppRoutes.tutorial}?${AppRoutes.stepParam}=2',
  '${AppRoutes.tutorial}?${AppRoutes.stepParam}=3',
  AppRoutes.design,
  for (final level in Levels.all)
    if (level.number != 5) AppRoutes.play(level.number, tutorialDone: true),
  AppRoutes.run,
  AppRoutes.queue,
  '${AppRoutes.success}?${AppRoutes.starsParam}=1',
  '${AppRoutes.success}?${AppRoutes.starsParam}=3',
  AppRoutes.fail,
  AppRoutes.settings,
  AppRoutes.gallery,
];

const _sizes = <Size>[
  Size(360, 640),
  Size(360, 740),
  Size(360, 800),
  Size(390, 844),
  Size(412, 915),
];

void main() {
  setUpFonts();

  for (final size in _sizes) {
    for (final route in _routes) {
      testWidgets('tanpa overflow: $route @ ${size.width}×${size.height}', (
        tester,
      ) async {
        setScreenSize(tester, size);
        await pumpApp(tester, location: route);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final route in _routes) {
    testWidgets('tanpa overflow (teks 130%): $route @ 360×800', (tester) async {
      setScreenSize(tester, const Size(360, 800));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, location: route);
      expect(tester.takeException(), isNull);
    });
  }

  // Fase Rancang mulai kosong: tooltip biaya baru muncul saat menarik.
  for (final (size, textScale) in [
    for (final size in _sizes) (size, 1.0),
    (const Size(360, 800), 1.3),
  ]) {
    testWidgets('tanpa overflow: rancang sambil menarik @ '
        '${size.width}×${size.height}, teks ${textScale * 100}%', (
      tester,
    ) async {
      setScreenSize(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, location: AppRoutes.design);
      // Tata letak sebelum font termuat sudah dicek test rute di atas.
      await loadAppFonts(tester);
      tester.takeException();
      await tester.tap(find.text('Fiber'));
      await tester.pumpAndSettle();
      final gesture = await dragOnMap(tester, [
        ...designPullPath,
        const Offset(312, 386),
      ], release: false);
      expect(find.textContaining('segmen · Rp'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  }

  // Hari level 1 dari tutorial: Fase Jalan & Hasil level 1 (bukan potret).
  for (final (size, textScale) in [
    (const Size(360, 640), 1.0),
    (const Size(360, 800), 1.3),
  ]) {
    testWidgets('tanpa overflow: hari tutorial level 1 @ '
        '${size.width}×${size.height}, teks ${textScale * 100}%', (
      tester,
    ) async {
      setScreenSize(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      // Font dimuat dulu di Beranda: tata letak sebelum font termuat sudah
      // dicek test rute di atas.
      await pumpApp(tester);
      await loadAppFonts(tester);
      await tester.pumpWidget(const SizedBox());
      await pumpApp(
        tester,
        location: '${AppRoutes.tutorial}?${AppRoutes.stepParam}=2',
      );
      expect(tester.takeException(), isNull);
      await dragOnMap(tester, const [
        Offset(105, 315),
        Offset(165, 255),
        Offset(255, 165),
      ]);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Mulai Hari'));
      await playFor(tester, 2);
      expect(find.text('LEVEL 1 · RUMAH PERTAMA'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Hari beres!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  // Hari sungguhan tiap level (rancangan acuan): Fase Jalan saat jam sibuk,
  // Panel Antrean dengan semua rumahnya, lalu Hasil.
  for (final level in Levels.all) {
    for (final (size, textScale) in [
      (const Size(360, 640), 1.0),
      (const Size(360, 800), 1.3),
    ]) {
      testWidgets('tanpa overflow: hari level ${level.number} @ '
          '${size.width}×${size.height}, teks ${textScale * 100}%', (
        tester,
      ) async {
        setScreenSize(tester, size);
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(tester);
        await loadAppFonts(tester);
        await tester.pumpWidget(const SizedBox());
        final day = design(level, referencePlans[level.number]!).planDay();
        await pumpApp(
          tester,
          location: AppRoutes.runOf(level.number),
          session: GameSession()..begin(day),
          settle: false,
        );
        await playFor(tester, 70);
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel('Jeda dan atur antrean'));
        await tester.pumpAndSettle();
        expect(find.byType(QueuePanelScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
        expect(find.text('Hari beres!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  // Dialog reset progres (progres desain, jadi tombolnya aktif).
  for (final (size, textScale) in [
    for (final size in _sizes) (size, 1.0),
    (const Size(360, 640), 1.3),
  ]) {
    testWidgets('tanpa overflow: dialog reset progres @ '
        '${size.width}×${size.height}, teks ${textScale * 100}%', (
      tester,
    ) async {
      setScreenSize(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        location: AppRoutes.settings,
        session: GameSession(
          progress: ProgressBook.memory(DummyData.designProgress),
        ),
      );
      await tester.ensureVisible(find.text('Reset progres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset progres'));
      await tester.pumpAndSettle();
      expect(find.text('Reset progres?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('galeri bisa di-scroll sampai bawah di 360 px', (tester) async {
    setScreenSize(tester, const Size(360, 740));
    disableAnimations(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const WidgetGalleryScreen()),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Kabel & trafik'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
