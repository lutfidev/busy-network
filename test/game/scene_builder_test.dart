import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/scene_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_pull.dart';
import 'legacy_scenes.dart';
import 'model/cable_checks.dart';
import 'scene_matchers.dart';

void main() {
  void expectSame(GameState state, MapScene legacy) {
    expect(describeScene(SceneBuilder.fromState(state)), describeScene(legacy));
  }

  group('identik dengan scene lama', () {
    test('tutorial langkah 1', () {
      expectSame(
        DummyStates.tutorial(1),
        LegacyScenes.tutorial(dragging: false, linked: false),
      );
    });

    test('tutorial langkah 2', () {
      expectSame(
        DummyStates.tutorial(2),
        LegacyScenes.tutorial(dragging: true, linked: false),
      );
    });

    test('tutorial langkah 3', () {
      expectSame(
        DummyStates.tutorial(3),
        LegacyScenes.tutorial(dragging: false, linked: true),
      );
    });

    // Tarikan sungguhan (router → (195, 300) → (255, 360)) = desain.
    for (final kind in CableKind.values) {
      test('fase rancang (${kind.name})', () {
        expectSame(designPull(kind: kind), LegacyScenes.design(kind));
      });
    }

    test('fase rancang setelah ganti kabel', () {
      final state = designPull()..selectCable(CableKind.fiber);
      expectSame(state, LegacyScenes.design(CableKind.fiber));
    });

    test('fase jalan', () {
      expectSame(DummyStates.run(), LegacyScenes.run());
    });
  });

  test('kabel snapshot jalan sah', () {
    final state = DummyStates.run();
    final positions = {for (final j in state.junctions) j.id: j.position};
    Offset positionOf(String id) => positions[id] ?? state.level.positionOf(id);
    for (final c in state.cables) {
      expectValidCable(state.level, c, positionOf);
    }
  });

  test('rancang tanpa draft: tanpa kabel putus-putus & jari', () {
    final scene = SceneBuilder.fromState(GameState(Levels.level5));
    expect(scene.dragHandle, isNull);
    expect(scene.cables.where((c) => c.state == CableState.drafting), isEmpty);
    expect(scene.nodes.where((n) => n.snapTarget), isEmpty);
  });

  test('tarikan menempel: kabel masuk rumah, cincin tetap, tanpa jari', () {
    final scene = SceneBuilder.fromState(
      designPull()..dragCable(const Offset(312, 386)),
    );
    expect(scene.dragHandle, isNull);
    final draft = scene.cables.singleWhere(
      (c) => c.state == CableState.drafting,
    );
    expect(draft.id, isNull);
    expect(draft.points.last, const Offset(295, 390));
    expect(scene.nodes.singleWhere((n) => n.snapTarget).id, 'r5');
    expect(scene.hasMotion, isTrue, reason: 'js-march & js-snap');
  });

  test('kabel terpasang membawa id-nya; rumah baru tersambung', () {
    final state = designPull()..dragCable(const Offset(312, 386));
    state.endCable();
    final scene = SceneBuilder.fromState(state);
    expect(
      [for (final c in scene.cables) c.id],
      [for (final c in state.cables) c.id],
    );
    expect(
      scene.nodes.singleWhere((n) => n.id == 'r5').state,
      HouseState.connected,
    );
    expect(scene.hasMotion, isFalse);
  });

  test('awal hari: rumah tanpa data frame tampil polos, tanpa trafik', () {
    final state = designPull()..startDay();
    final scene = SceneBuilder.fromState(state);
    expect(scene.theme, MapTheme.night);
    expect(scene.dragHandle, isNull);
    expect(scene.badges, isEmpty);
    expect(scene.hasMotion, isFalse);
    final byId = {for (final n in scene.nodes) n.id: n};
    expect(byId['r1']!.state, HouseState.ok);
    expect(byId['r1']!.patience, 1);
    expect(byId['r5']!.state, HouseState.idle);
    expect(byId['r5']!.patience, isNull);
  });

  test('fase hasil digambar siang tanpa draft', () {
    final state = designPull()
      ..startDay()
      ..finishDay();
    final scene = SceneBuilder.fromState(state);
    expect(scene.theme, MapTheme.day);
    expect(scene.dragHandle, isNull);
  });
}
