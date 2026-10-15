import 'dart:ui';

import '../core/format.dart';
import 'map_scene.dart';
import 'model/model.dart';
import 'sim/sim.dart';

/// Menurunkan [MapScene] (yang digambar `MapRenderer`) dari [GameState].
abstract final class SceneBuilder {
  /// Label rumah di sisi kanan saat belum ada bar sabar (Warung, fase
  /// rancang).
  static const rightLabelOffset = Offset(44, 5);

  static MapScene fromState(GameState s) {
    final level = s.level;
    final run = s.phase == GamePhase.run;
    final frame = run ? s.frame : null;
    final draft = s.phase == GamePhase.design ? s.draft : null;
    final usage = frame?.demand ?? const <String, double>{};
    final net = s.network;
    final overloaded = {
      if (frame != null)
        for (final c in s.cables)
          if (net.isOverloaded(c, usage)) c.id,
    };
    // Kabel kelebihan beban digambar paling atas.
    final cables = [
      for (final c in s.cables)
        if (!overloaded.contains(c.id)) c,
      for (final c in s.cables)
        if (overloaded.contains(c.id)) c,
    ];

    return MapScene(
      theme: run ? MapTheme.night : MapTheme.day,
      blockLabels: run ? level.nightBlockLabels : level.blockLabels,
      cables: [
        for (final c in cables)
          _cable(
            c,
            net,
            usage,
            live: frame != null,
            full: overloaded.contains(c.id),
          ),
        if (draft != null)
          MapCable(
            points: draft.points,
            kind: draft.kind,
            state: CableState.drafting,
          ),
      ],
      badges: [
        for (final c in cables)
          if (overloaded.contains(c.id))
            MapBadge(
              'Penuh! '
              '${IdFormat.ratio(net.cableLoad(c, usage), c.spec.capacityMbps)}',
              c.badgeCenter,
            ),
      ],
      nodes: [
        for (final j in s.junctions)
          MapNode(
            id: j.id,
            kind: NodeKind.junction,
            position: j.position,
            snapTarget: draft?.target == j.id,
          ),
        for (final h in level.houses)
          if (frame?.houses[h.id] case final live?)
            _liveHouse(h, live)
          else
            _plainHouse(
              h,
              frame == null && s.connectedHouses.contains(h.id)
                  ? HouseState.connected
                  : HouseState.idle,
              snapTarget: draft?.target == h.id,
            ),
        MapNode(
          id: LevelDef.routerId,
          kind: NodeKind.router,
          position: level.routerPosition,
          label: level.routerLabel,
          routerAlarm: overloaded.isNotEmpty,
        ),
      ],
      dragHandle: draft?.handle,
    );
  }

  static MapCable _cable(
    Cable c,
    Network net,
    Map<String, double> usage, {
    required bool live,
    required bool full,
  }) {
    final traffic = !live
        ? TrafficState.none
        : net.isJammed(c, usage)
        ? TrafficState.jam
        : net.cableLoad(c, usage) > 0
        ? TrafficState.flow
        : TrafficState.none;
    return MapCable(
      id: c.id,
      points: c.points,
      kind: c.kind,
      state: full ? CableState.overloaded : CableState.normal,
      traffic: traffic,
      thick: full && c.kind == CableKind.lan,
    );
  }

  /// Rumah tanpa data simulasi (fase rancang, atau belum tersambung).
  static MapNode _plainHouse(
    HouseDef h,
    HouseState state, {
    bool snapTarget = false,
  }) {
    final right = h.labelSide == MarkSide.right;
    return MapNode(
      id: h.id,
      kind: NodeKind.house,
      position: h.position,
      label: h.label,
      labelOffset: right ? rightLabelOffset : null,
      labelAlign: right ? TextAlign.left : TextAlign.center,
      state: state,
      snapTarget: snapTarget,
    );
  }

  static MapNode _liveHouse(HouseDef h, HouseLive live) {
    final jam = live.state == HouseState.jam;
    return MapNode(
      id: h.id,
      kind: NodeKind.house,
      position: h.position,
      label: jam
          ? '${h.label} · sabar '
                '${IdFormat.percent(live.patience, fraction: true)}'
          : h.label,
      labelAlign: h.patienceSide == MarkSide.right
          ? TextAlign.left
          : TextAlign.center,
      labelEmphasis: jam,
      state: live.state,
      patience: live.patience,
      patiencePlacement: switch (h.patienceSide) {
        MarkSide.below => PatiencePlacement.below,
        MarkSide.right => PatiencePlacement.right,
        MarkSide.above => PatiencePlacement.above,
      },
      alarm: jam,
    );
  }
}
