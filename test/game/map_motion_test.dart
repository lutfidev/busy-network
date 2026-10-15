import 'package:busy_network/data/dummy_scenes.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/render/map_motion.dart';
import 'package:busy_network/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapMotion.at', () {
    test('detik 0 = bingkai statis desain', () {
      final m = MapMotion.at(0);
      expect(m.flowPhase, MapMotion.still.flowPhase);
      expect(m.jamPhase, MapMotion.still.jamPhase);
      expect(m.alarmOpacity, MapMotion.still.alarmOpacity);
    });

    test('trafik lancar maju 36 px per 1,4 s (js-flow)', () {
      expect(MapMotion.at(0.7).flowPhase, closeTo(18, 1e-9));
      expect(MapMotion.at(1.05).flowPhase, closeTo(27, 1e-9));
      // Satu siklus penuh kembali ke awal (mulus karena 36 = 2 × jarak 18).
      expect(MapMotion.at(1.4).flowPhase, closeTo(0, 1e-9));
    });

    test('trafik macet maju 18 px per 3,2 s (js-jam)', () {
      expect(MapMotion.at(1.6).jamPhase, closeTo(9, 1e-9));
      expect(MapMotion.at(0.8).jamPhase, closeTo(4.5, 1e-9));
    });
  });

  test('alarm berkedip 1 → 0,25 → 1 tiap 0,7 s (js-alarm)', () {
    expect(MapMotion.at(0).alarmOpacity, 1);
    expect(MapMotion.at(0.35).alarmOpacity, closeTo(0.25, 1e-9));
    expect(MapMotion.at(0.175).alarmOpacity, closeTo(0.625, 1e-9));
    expect(MapMotion.at(0.7).alarmOpacity, closeTo(1, 1e-9));
  });

  test('hasMotion: alarm tanpa trafik tetap bergerak', () {
    const p = [Offset.zero, Offset(30, 0)];
    const house = MapNode(id: 'r', kind: NodeKind.house, position: Offset.zero);
    expect(
      const MapScene(theme: MapTheme.night, nodes: [house]).hasMotion,
      isFalse,
    );
    expect(
      const MapScene(
        theme: MapTheme.night,
        nodes: [house],
        cables: [MapCable(points: p, state: CableState.overloaded)],
      ).hasMotion,
      isTrue,
    );
    expect(
      const MapScene(
        theme: MapTheme.night,
        nodes: [
          MapNode(
            id: 'r',
            kind: NodeKind.house,
            position: Offset.zero,
            alarm: true,
          ),
        ],
      ).hasMotion,
      isTrue,
    );
    expect(
      const MapScene(
        theme: MapTheme.night,
        nodes: [
          MapNode(
            id: 'router',
            kind: NodeKind.router,
            position: Offset.zero,
            routerAlarm: true,
          ),
        ],
      ).hasMotion,
      isTrue,
    );
  });

  group('NetworkMapView', () {
    Future<void> pumpMap(
      WidgetTester tester,
      MapScene scene, {
      bool disableAnimations = false,
    }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: NetworkMapView(scene: scene),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('peta dengan trafik terus menggambar ulang', (tester) async {
      await pumpMap(tester, DummyScenes.run());
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('animasi mati → peta diam', (tester) async {
      await pumpMap(tester, DummyScenes.run(), disableAnimations: true);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('peta tanpa trafik tidak memakai jam', (tester) async {
      await pumpMap(
        tester,
        DummyScenes.tutorial(dragging: false, linked: true),
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
