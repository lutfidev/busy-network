import 'dart:ui';

import 'package:busy_network/game/map_scene.dart';

/// Salinan `DummyScenes` sebelum langkah 2: acuan "tampil identik" untuk
/// `SceneBuilder.fromState`. Jangan diubah kecuali visual memang berubah.
abstract final class LegacyScenes {
  // ── Tutorial level 1 ──────────────────────────────────────────────────
  static const tutorialRouter = Offset(105, 315);
  static const tutorialHouse1 = Offset(255, 165);

  static MapScene tutorial({required bool dragging, required bool linked}) {
    return MapScene(
      theme: MapTheme.day,
      blockLabels: const [
        MapBlockLabel('BLOK A', Offset(255, 112), align: TextAlign.center),
      ],
      cables: [
        if (dragging)
          const MapCable(
            points: [tutorialRouter, tutorialHouse1],
            state: CableState.drafting,
          ),
        if (linked) const MapCable(points: [tutorialRouter, tutorialHouse1]),
      ],
      nodes: [
        MapNode(
          id: 'r1',
          kind: NodeKind.house,
          position: tutorialHouse1,
          label: 'Rumah 1',
          state: linked ? HouseState.connected : HouseState.idle,
        ),
        const MapNode(
          id: 'r2',
          kind: NodeKind.house,
          position: Offset(315, 345),
          label: 'Rumah 2',
        ),
        const MapNode(
          id: 'router',
          kind: NodeKind.router,
          position: tutorialRouter,
          label: 'Router',
        ),
      ],
    );
  }

  // ── Gang Melati (level 5) ─────────────────────────────────────────────
  static const _router = Offset(195, 240);
  static const _junctionTop = Offset(195, 150);

  static const _cableRumah1 = [_junctionTop, Offset(135, 90), Offset(95, 90)];
  static const _cableRumah3 = [_junctionTop, Offset(255, 90), Offset(295, 90)];
  static const _cableRumah4 = [Offset(219, 240), Offset(295, 240)];
  static const _cableWarung = [Offset(195, 216), Offset(195, 80)];

  /// Ujung kabel yang sedang ditarik di fase rancang.
  static const draftEnd = Offset(255, 360);

  static MapScene design(CableKind drafting) {
    return MapScene(
      theme: MapTheme.day,
      blockLabels: const [
        MapBlockLabel('BLOK A', Offset(300, 30), align: TextAlign.center),
        MapBlockLabel('BLOK B', Offset(376, 320), align: TextAlign.right),
        MapBlockLabel('BLOK C', Offset(40, 402)),
      ],
      cables: [
        const MapCable(points: _cableRumah1),
        const MapCable(points: _cableRumah3),
        const MapCable(points: _cableRumah4),
        const MapCable(points: _cableWarung, kind: CableKind.fiber),
        MapCable(
          points: const [Offset(195, 264), Offset(195, 300), draftEnd],
          kind: drafting,
          state: CableState.drafting,
        ),
      ],
      nodes: const [
        MapNode(id: 'j1', kind: NodeKind.junction, position: _junctionTop),
        MapNode(
          id: 'r1',
          kind: NodeKind.house,
          position: Offset(75, 90),
          label: 'Rumah 1',
          state: HouseState.connected,
        ),
        MapNode(
          id: 'w',
          kind: NodeKind.house,
          position: Offset(195, 60),
          label: 'Warung',
          labelOffset: Offset(44, 5),
          labelAlign: TextAlign.left,
          state: HouseState.connected,
        ),
        MapNode(
          id: 'r3',
          kind: NodeKind.house,
          position: Offset(315, 90),
          label: 'Rumah 3',
          state: HouseState.connected,
        ),
        MapNode(
          id: 'r4',
          kind: NodeKind.house,
          position: Offset(315, 240),
          label: 'Rumah 4',
          state: HouseState.connected,
        ),
        MapNode(
          id: 'r5',
          kind: NodeKind.house,
          position: Offset(315, 390),
          label: 'Rumah 5',
          snapTarget: true,
        ),
        MapNode(
          id: 'r6',
          kind: NodeKind.house,
          position: Offset(195, 420),
          label: 'Rumah 6',
        ),
        MapNode(
          id: 'r7',
          kind: NodeKind.house,
          position: Offset(75, 330),
          label: 'Rumah 7',
        ),
        MapNode(id: 'router', kind: NodeKind.router, position: _router),
      ],
      dragHandle: draftEnd,
    );
  }

  static MapScene run() {
    return MapScene(
      theme: MapTheme.night,
      blockLabels: const [
        MapBlockLabel('BLOK A', Offset(300, 24), align: TextAlign.center),
        MapBlockLabel('BLOK B', Offset(376, 452), align: TextAlign.right),
        MapBlockLabel('BLOK C', Offset(40, 402)),
      ],
      cables: const [
        MapCable(points: _cableRumah1, traffic: TrafficState.flow),
        MapCable(points: _cableRumah3, traffic: TrafficState.flow),
        MapCable(
          points: [Offset(195, 264), Offset(195, 400)],
          traffic: TrafficState.flow,
        ),
        MapCable(
          points: [Offset(195, 330), Offset(95, 330)],
          traffic: TrafficState.flow,
        ),
        MapCable(
          points: [Offset(315, 260), Offset(315, 370)],
          traffic: TrafficState.jam,
        ),
        MapCable(
          points: _cableWarung,
          kind: CableKind.fiber,
          traffic: TrafficState.flow,
        ),
        MapCable(
          points: _cableRumah4,
          thick: true,
          state: CableState.overloaded,
          traffic: TrafficState.jam,
        ),
      ],
      badges: const [MapBadge('Penuh! 25/20', Offset(262, 276))],
      nodes: [
        const MapNode(
          id: 'j1',
          kind: NodeKind.junction,
          position: _junctionTop,
        ),
        const MapNode(
          id: 'j2',
          kind: NodeKind.junction,
          position: Offset(195, 330),
        ),
        const MapNode(
          id: 'r1',
          kind: NodeKind.house,
          position: Offset(75, 90),
          label: 'Rumah 1',
          state: HouseState.ok,
          patience: 36 / 40,
        ),
        const MapNode(
          id: 'w',
          kind: NodeKind.house,
          position: Offset(195, 60),
          label: 'Warung',
          labelAlign: TextAlign.left,
          state: HouseState.ok,
          patience: 34 / 40,
          patiencePlacement: PatiencePlacement.right,
        ),
        const MapNode(
          id: 'r3',
          kind: NodeKind.house,
          position: Offset(315, 90),
          label: 'Rumah 3',
          state: HouseState.slow,
          patience: 22 / 40,
        ),
        // Desain: bar 7/40 tapi label "sabar 15%". Model menyimpan satu
        // nilai sabar (0,15), jadi bar menyusut 1 px (spec, keputusan 4).
        const MapNode(
          id: 'r4',
          kind: NodeKind.house,
          position: Offset(315, 240),
          label: 'Rumah 4 · sabar 15%',
          labelEmphasis: true,
          state: HouseState.jam,
          patience: 0.15,
          patiencePlacement: PatiencePlacement.above,
          alarm: true,
        ),
        const MapNode(
          id: 'r5',
          kind: NodeKind.house,
          position: Offset(315, 390),
          label: 'Rumah 5',
          state: HouseState.slow,
          patience: 16 / 40,
        ),
        const MapNode(
          id: 'r6',
          kind: NodeKind.house,
          position: Offset(195, 420),
          label: 'Rumah 6',
          labelAlign: TextAlign.left,
          state: HouseState.ok,
          patience: 32 / 40,
          patiencePlacement: PatiencePlacement.right,
        ),
        const MapNode(
          id: 'r7',
          kind: NodeKind.house,
          position: Offset(75, 330),
          label: 'Rumah 7',
          state: HouseState.ok,
          patience: 30 / 40,
        ),
        const MapNode(
          id: 'router',
          kind: NodeKind.router,
          position: _router,
          routerAlarm: true,
        ),
      ],
    );
  }
}
