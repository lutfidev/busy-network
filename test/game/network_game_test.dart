import 'dart:ui' as ui;

import 'package:busy_network/data/dummy_states.dart';
import 'package:busy_network/game/components/components.dart';
import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/model.dart';
import 'package:busy_network/game/network_game.dart';
import 'package:busy_network/game/render/map_motion.dart';
import 'package:busy_network/game/render/map_renderer.dart';
import 'package:busy_network/game/scene_builder.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart' hide RouterComponent;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../test_helpers.dart';

final _boundary = GlobalKey();

/// Pasang [game] di `GameWidget` seukuran area peta (atau [size]) sampai
/// komponennya terpasang. Tanpa `pumpAndSettle`: peta bergerak tidak
/// pernah tenang.
Future<NetworkGame> pumpGame(
  WidgetTester tester,
  GameState state, {
  bool animate = false,
  Size size = AppSizes.mapArea,
}) async {
  setScreenSize(tester, size);
  final game = NetworkGame(state: state, animate: animate);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: GameWidget(game: game),
    ),
  );
  await tester.pump();
  await tester.pump();
  expect(game.isAttached, isTrue, reason: 'game terpasang di GameWidget');
  return game;
}

Iterable<T> piecesOf<T>(NetworkGame game) => game.world.children.whereType<T>();

Future<Uint8List> _bytes(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

/// Gambar referensi: seluruh scene lewat [MapRenderer.drawScene].
Future<Uint8List> referencePixels(MapScene scene) {
  final recorder = ui.PictureRecorder();
  MapRenderer.drawScene(ui.Canvas(recorder), scene);
  final size = AppSizes.mapArea;
  return recorder
      .endRecording()
      .toImage(size.width.toInt(), size.height.toInt())
      .then(_bytes);
}

Future<Uint8List> gamePixels() async {
  final boundary =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return _bytes(await boundary.toImage());
}

/// Muat font peta dulu supaya game dan referensi sama-sama memakai
/// Fredoka/Nunito.
Future<void> loadMapFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    await referencePixels(SceneBuilder.fromState(DummyStates.run()));
    await GoogleFonts.pendingFonts();
  });
}

void main() {
  setUpFonts();

  group('komponen', () {
    testWidgets('satu komponen per bagian scene fase jalan', (tester) async {
      final state = DummyStates.run();
      final scene = SceneBuilder.fromState(state);
      final game = await pumpGame(tester, state);

      expect(piecesOf<GroundComponent>(game), hasLength(1));
      expect(piecesOf<CableComponent>(game), hasLength(scene.cables.length));
      expect(
        piecesOf<TrafficComponent>(game),
        hasLength(
          scene.cables.where((c) => c.traffic != TrafficState.none).length,
        ),
      );
      int count(NodeKind kind) =>
          scene.nodes.where((n) => n.kind == kind).length;
      expect(piecesOf<RouterComponent>(game), hasLength(1));
      expect(piecesOf<HouseComponent>(game), hasLength(count(NodeKind.house)));
      expect(
        piecesOf<JunctionComponent>(game),
        hasLength(count(NodeKind.junction)),
      );
      expect(piecesOf<BadgeComponent>(game), hasLength(scene.badges.length));
      expect(piecesOf<DragHandleComponent>(game), isEmpty);
    });

    testWidgets('kabel yang ditarik punya jari', (tester) async {
      final game = await pumpGame(tester, DummyStates.design(CableKind.lan));
      final handle = piecesOf<DragHandleComponent>(game).single;
      expect(handle.center, game.scene.dragHandle);
    });

    testWidgets('bidang sentuh node berpusat di posisinya (koordinat peta)', (
      tester,
    ) async {
      final state = DummyStates.run();
      final game = await pumpGame(tester, state);
      final router = piecesOf<RouterComponent>(game).single;
      final r = state.level.routerPosition.toVector2();
      expect(router.containsLocalPoint(r), isTrue);
      expect(
        router.containsLocalPoint(r + Vector2(AppSizes.routerSize / 2 - 1, 0)),
        isTrue,
      );
      expect(
        router.containsLocalPoint(r + Vector2(AppSizes.routerSize / 2 + 1, 0)),
        isFalse,
      );
      for (final house in piecesOf<HouseComponent>(game)) {
        final c = state.level.house(house.node.id).position.toVector2();
        expect(house.containsLocalPoint(c), isTrue, reason: house.node.id);
        expect(
          house.containsLocalPoint(c + Vector2(0, AppSizes.houseRadius + 1)),
          isFalse,
          reason: house.node.id,
        );
      }
      expect(game.componentsAtPoint(r.clone()).whereType<RouterComponent>(), [
        router,
      ]);
    });

    testWidgets('urutan gambar sama dengan MapRenderer.drawScene', (
      tester,
    ) async {
      final game = await pumpGame(tester, DummyStates.run());
      final ordered = game.world.children.toList();
      int layer(Component c) => switch (c) {
        GroundComponent() => 0,
        CableComponent() => 1,
        TrafficComponent() => 2,
        MapNodeComponent() => 3,
        BadgeComponent() => 4,
        _ => 5,
      };
      final layers = ordered.map(layer).toList();
      expect(layers, [...layers]..sort());
      expect(
        [for (final c in ordered.whereType<MapNodeComponent>()) c.node.id],
        [for (final n in game.scene.nodes) n.id],
      );
    });
  });

  group('kamera', () {
    testWidgets('resolusi tetap 390×472 dengan sudut kiri atas = (0, 0)', (
      tester,
    ) async {
      final game = await pumpGame(
        tester,
        DummyStates.run(),
        size: const Size(360, 360 * 472 / 390),
      );
      final viewport = game.camera.viewport as FixedResolutionViewport;
      expect(viewport.resolution, Vector2(390, 472));
      // Vector2 Flame memakai float32.
      expect(viewport.scale.x, closeTo(360 / 390, 1e-6));
      expect(game.camera.viewfinder.anchor, Anchor.topLeft);
      expect(game.camera.viewfinder.position, Vector2.zero());
    });
  });

  group('gambar identik dengan MapRenderer.drawScene', () {
    final states = <String, GameState Function()>{
      'tutorial 1': () => DummyStates.tutorial(1),
      'tutorial 2': () => DummyStates.tutorial(2),
      'tutorial 3': () => DummyStates.tutorial(3),
      'fase rancang LAN': () => DummyStates.design(CableKind.lan),
      'fase rancang fiber': () => DummyStates.design(CableKind.fiber),
      'fase jalan': DummyStates.run,
    };
    for (final MapEntry(key: name, value: create) in states.entries) {
      testWidgets(name, (tester) async {
        await loadMapFonts(tester);
        final state = create();
        await pumpGame(tester, state);
        await tester.runAsync(() async {
          expect(
            await gamePixels(),
            await referencePixels(SceneBuilder.fromState(state)),
          );
        });
      });
    }
  });

  group('mesin', () {
    testWidgets('animasi mati → berhenti di pose diam', (tester) async {
      final game = await pumpGame(tester, DummyStates.run());
      expect(game.paused, isTrue);
      expect(game.motion, same(MapMotion.still));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('trafik bergerak mengikuti detik berjalan', (tester) async {
      final game = await pumpGame(tester, DummyStates.run(), animate: true);
      expect(game.paused, isFalse);
      await tester.pump(const Duration(milliseconds: 350));
      expect(game.seconds, closeTo(0.35, 1e-6));
      final expected = MapMotion.at(game.seconds);
      expect(game.motion.flowPhase, expected.flowPhase);
      expect(game.motion.jamPhase, expected.jamPhase);
      expect(game.motion.alarmOpacity, closeTo(0.25, 1e-3));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('peta tanpa gerak berhenti setelah satu bingkai', (
      tester,
    ) async {
      final game = await pumpGame(
        tester,
        DummyStates.tutorial(3),
        animate: true,
      );
      expect(game.paused, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('animasi dimatikan saat jalan → kembali ke pose diam', (
      tester,
    ) async {
      final game = await pumpGame(tester, DummyStates.run(), animate: true);
      await tester.pump(const Duration(milliseconds: 350));
      game.animate = false;
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.paused, isTrue);
      expect(game.seconds, 0);
      expect(game.motion, same(MapMotion.still));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('font berubah → digambar ulang lalu diam lagi', (tester) async {
      final game = await pumpGame(tester, DummyStates.tutorial(1));
      expect(game.paused, isTrue);
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.system.name,
        SystemChannels.system.codec.encodeMessage(<String, Object?>{
          'type': 'fontsChange',
        }),
        (_) {},
      );
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump();
      expect(game.paused, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('mengikuti GameState', () {
    testWidgets('ganti jenis kabel → kabel tarikan ikut berubah', (
      tester,
    ) async {
      await loadMapFonts(tester);
      final state = DummyStates.design(CableKind.lan);
      final game = await pumpGame(tester, state);
      final housesBefore = piecesOf<HouseComponent>(game).toList();

      state.selectCable(CableKind.fiber);
      await tester.pump();

      final draft = piecesOf<CableComponent>(game)
          .singleWhere((c) => c.cable.state == CableState.drafting);
      expect(draft.cable.kind, CableKind.fiber);
      // Komponen dipakai ulang (identitas stabil untuk tarik kabel).
      expect(piecesOf<HouseComponent>(game).toList(), housesBefore);
      expect(game.paused, isTrue);
      await tester.runAsync(() async {
        expect(
          await gamePixels(),
          await referencePixels(SceneBuilder.fromState(state)),
        );
      });
    });

    testWidgets('ganti GameState → peta menggambar state baru', (tester) async {
      final step2 = DummyStates.tutorial(2);
      final game = await pumpGame(tester, step2);
      expect(piecesOf<DragHandleComponent>(game), isEmpty);
      expect(
        piecesOf<CableComponent>(game).single.cable.state,
        CableState.drafting,
      );

      final step3 = DummyStates.tutorial(3);
      game.state = step3;
      step2.dispose();
      await tester.pump();

      expect(game.state, same(step3));
      expect(
        piecesOf<CableComponent>(game).single.cable.state,
        CableState.normal,
      );
      final house1 = piecesOf<HouseComponent>(game)
          .singleWhere((h) => h.node.id == 'r1');
      expect(house1.node.state, HouseState.connected);
    });

    testWidgets('mulai hari → trafik muncul dan mesin jalan', (tester) async {
      final state = DummyStates.tutorial(3);
      final game = await pumpGame(tester, state, animate: true);
      expect(piecesOf<TrafficComponent>(game), isEmpty);
      expect(game.paused, isTrue);

      state.startDay();
      state.updateFrame(
        const SimFrame(
          houses: {
            'r1': HouseLive(state: HouseState.ok, patience: 1, usageMbps: 5),
          },
        ),
      );
      await tester.pump();

      expect(game.scene.theme, MapTheme.night);
      expect(piecesOf<TrafficComponent>(game), hasLength(1));
      expect(game.paused, isFalse);
    });
  });
}
