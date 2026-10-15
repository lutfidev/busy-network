import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/network_game.dart';
import 'package:busy_network/game/network_game_view.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flame/game.dart' hide RouterComponent;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

const _spot = Key('spot');

/// Area 360×600: lebih tinggi dari rasio peta, jadi peta 360 × 435,7.
const _area = Size(360, 600);
const _scale = 360 / 390;
final _mapHeight = AppSizes.mapArea.height * _scale;

Future<void> pumpView(
  WidgetTester tester,
  GameState state, {
  bool disableAnimations = false,
  AlignmentGeometry alignment = Alignment.center,
}) async {
  setScreenSize(tester, _area);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: _area, disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: NetworkGameView(
          state: state,
          alignment: alignment,
          semanticLabel: 'Peta uji',
          overlays: const [
            Positioned(
              left: 195,
              top: 236,
              child: SizedBox(key: _spot, width: 30, height: 30),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
}

NetworkGame gameOf(WidgetTester tester) => tester
    .widget<GameWidget<NetworkGame>>(find.byType(GameWidget<NetworkGame>))
    .game!;

void main() {
  setUpFonts();

  group('gerak', () {
    testWidgets('peta dengan trafik terus menggambar ulang', (tester) async {
      await pumpView(tester, DummyStates.run());
      expect(gameOf(tester).paused, isFalse);
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('animasi mati → peta diam', (tester) async {
      await pumpView(tester, DummyStates.run(), disableAnimations: true);
      expect(gameOf(tester).animate, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('peta tanpa trafik diam', (tester) async {
      await pumpView(tester, DummyStates.tutorial(3));
      expect(gameOf(tester).paused, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('rute tertutup (TickerMode mati) → peta diam', (tester) async {
      setScreenSize(tester, _area);
      final state = DummyStates.run();
      Widget view({required bool ticking}) => MediaQuery(
        data: const MediaQueryData(size: _area),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TickerMode(
            enabled: ticking,
            child: NetworkGameView(state: state),
          ),
        ),
      );
      await tester.pumpWidget(view(ticking: true));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(gameOf(tester).paused, isFalse);

      await tester.pumpWidget(view(ticking: false));
      await tester.pump(const Duration(milliseconds: 16));
      expect(gameOf(tester).paused, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(view(ticking: true));
      expect(gameOf(tester).paused, isFalse);
    });

    testWidgets('setelan animasi diubah → game ikut', (tester) async {
      final state = DummyStates.run();
      await pumpView(tester, state);
      final game = gameOf(tester);
      await pumpView(tester, state, disableAnimations: true);
      expect(gameOf(tester), same(game), reason: 'game tidak dibuat ulang');
      expect(game.animate, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('tata letak', () {
    testWidgets('di tengah: peta & overlay diskalakan seragam', (tester) async {
      await pumpView(tester, DummyStates.tutorial(1), disableAnimations: true);
      final top = (_area.height - _mapHeight) / 2;
      final map = tester.getRect(find.byType(GameWidget<NetworkGame>));
      expect(map.left, 0);
      expect(map.top, closeTo(top, 1e-6));
      expect(map.width, closeTo(360, 1e-6));
      expect(map.height, closeTo(_mapHeight, 1e-6));

      final spot = tester.getRect(find.byKey(_spot));
      expect(spot.left, closeTo(195 * _scale, 1e-6));
      expect(spot.top, closeTo(top + 236 * _scale, 1e-6));
      expect(spot.width, closeTo(30 * _scale, 1e-6));
    });

    testWidgets('rata atas (Fase Jalan)', (tester) async {
      await pumpView(
        tester,
        DummyStates.run(),
        disableAnimations: true,
        alignment: Alignment.topCenter,
      );
      expect(tester.getRect(find.byType(GameWidget<NetworkGame>)).top, 0);
      expect(
        tester.getRect(find.byKey(_spot)).top,
        closeTo(236 * _scale, 1e-6),
      );
    });

    testWidgets('peta tidak bisa difokus (bukan perhentian D-pad)', (
      tester,
    ) async {
      await pumpView(tester, DummyStates.tutorial(1), disableAnimations: true);
      final insideGame = tester.element(
        find
            .descendant(
              of: find.byType(GameWidget<NetworkGame>),
              matching: find.byType(MouseRegion),
            )
            .first,
      );
      expect(Focus.of(insideGame).canRequestFocus, isFalse);
    });

    testWidgets('label semantik peta', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpView(tester, DummyStates.tutorial(1), disableAnimations: true);
      expect(find.bySemanticsLabel('Peta uji'), findsOneWidget);
      semantics.dispose();
    });
  });

  testWidgets('state baru → game yang sama menggambar state itu', (
    tester,
  ) async {
    final step2 = DummyStates.tutorial(2);
    await pumpView(tester, step2, disableAnimations: true);
    final game = gameOf(tester);

    final step3 = DummyStates.tutorial(3);
    step2.dispose();
    await pumpView(tester, step3, disableAnimations: true);

    expect(gameOf(tester), same(game));
    expect(game.state, same(step3));
  });
}
