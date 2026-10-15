import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/render/map_motion.dart';
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

  test('kabel ditarik maju 36 px per 1 s (js-march)', () {
    expect(MapMotion.still.marchPhase, 0);
    expect(MapMotion.at(0).marchPhase, 0);
    expect(MapMotion.at(0.25).marchPhase, closeTo(9, 1e-9));
    expect(MapMotion.at(1).marchPhase, closeTo(0, 1e-9));
  });

  test('cincin snap berdenyut 0,9 → 0,25 → 0,9 tiap 1,1 s (js-snap)', () {
    expect(MapMotion.still.snapOpacity, 1);
    expect(MapMotion.at(0).snapOpacity, closeTo(0.9, 1e-9));
    expect(MapMotion.at(0.55).snapOpacity, closeTo(0.25, 1e-9));
    expect(MapMotion.at(1.1).snapOpacity, closeTo(0.9, 1e-9));
  });

  test('hasMotion: kabel ditarik & cincin snap bergerak', () {
    const p = [Offset.zero, Offset(30, 0)];
    expect(
      const MapScene(
        theme: MapTheme.day,
        nodes: [],
        cables: [MapCable(points: p, state: CableState.drafting)],
      ).hasMotion,
      isTrue,
    );
    expect(
      const MapScene(
        theme: MapTheme.day,
        nodes: [
          MapNode(
            id: 'r',
            kind: NodeKind.house,
            position: Offset.zero,
            snapTarget: true,
          ),
        ],
      ).hasMotion,
      isTrue,
    );
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
}
