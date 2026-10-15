import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/scene_builder.dart';
import 'package:flutter_test/flutter_test.dart';

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

    for (final kind in CableKind.values) {
      test('fase rancang (${kind.name})', () {
        expectSame(DummyStates.design(kind), LegacyScenes.design(kind));
      });
    }

    test('fase rancang setelah ganti kabel', () {
      final state = DummyStates.design(CableKind.lan)
        ..selectCable(CableKind.fiber);
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

  test('awal hari: rumah tanpa data frame tampil polos, tanpa trafik', () {
    final state = DummyStates.design(CableKind.lan)..startDay();
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
    final state = DummyStates.design(CableKind.lan)
      ..startDay()
      ..finishDay();
    final scene = SceneBuilder.fromState(state);
    expect(scene.theme, MapTheme.day);
    expect(scene.dragHandle, isNull);
  });
}
