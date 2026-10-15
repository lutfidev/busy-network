import 'package:busy_network/game/map_scene.dart';
import 'package:busy_network/game/model/cable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const designDraft = [Offset(195, 264), Offset(195, 300), Offset(255, 360)];

  group('segmentCount', () {
    test('kabel yang ditarik di desain = 3 segmen', () {
      expect(segmentCount(designDraft), 3);
    });

    test('diagonal tutorial 150 px = 5 segmen', () {
      expect(segmentCount(const [Offset(105, 315), Offset(255, 165)]), 5);
    });

    test('lurus 120 px = 4 segmen', () {
      expect(segmentCount(const [Offset(195, 240), Offset(315, 240)]), 4);
    });

    test('minimal 1 segmen', () {
      expect(segmentCount(const [Offset(0, 0), Offset(5, 0)]), 1);
      expect(segmentCount(const [Offset(0, 0)]), 1);
    });
  });

  group('isGridAngle', () {
    test('0°, 45°, 90° boleh', () {
      expect(isGridAngle(Offset.zero, const Offset(60, 0)), isTrue);
      expect(isGridAngle(Offset.zero, const Offset(0, -60)), isTrue);
      expect(isGridAngle(Offset.zero, const Offset(60, -60)), isTrue);
    });

    test('sudut lain ditolak', () {
      expect(isGridAngle(Offset.zero, const Offset(60, 30)), isFalse);
    });
  });

  group('CableSpec', () {
    test('of sesuai jenis', () {
      expect(CableSpec.of(CableKind.lan), same(CableSpec.lan));
      expect(CableSpec.of(CableKind.fiber), same(CableSpec.fiber));
    });

    test('angka sesuai desain', () {
      expect(CableSpec.lan.pricePerSegment, 15000);
      expect(CableSpec.lan.capacityMbps, 20);
      expect(CableSpec.lan.unlockLevel, 1);
      expect(CableSpec.fiber.pricePerSegment, 60000);
      expect(CableSpec.fiber.capacityMbps, 100);
      expect(CableSpec.fiber.unlockLevel, 3);
    });
  });

  group('Cable', () {
    test('biaya = segmen × harga', () {
      const lan = Cable(id: 'a', from: 'router', to: 'r5', points: designDraft);
      const fiber = Cable(
        id: 'b',
        from: 'router',
        to: 'r5',
        kind: CableKind.fiber,
        points: designDraft,
      );
      expect(lan.segments, 3);
      expect(lan.cost, 45000);
      expect(fiber.cost, 180000);
    });

    test('stops memuat junction yang dilewati', () {
      const c = Cable(
        id: 'c-w',
        from: 'router',
        to: 'w',
        via: ['j1'],
        points: [Offset(195, 216), Offset(195, 80)],
      );
      expect(c.stops, ['router', 'j1', 'w']);
    });

    test('badge default 36 px di bawah titik tengah', () {
      const c = Cable(
        id: 'x',
        from: 'a',
        to: 'b',
        points: [Offset(195, 264), Offset(195, 400)],
      );
      expect(c.badgeCenter, const Offset(195, 368));
    });

    test('badgeAt menimpa default', () {
      const c = Cable(
        id: 'x',
        from: 'a',
        to: 'b',
        points: [Offset(219, 240), Offset(295, 240)],
        badgeAt: Offset(262, 276),
      );
      expect(c.badgeCenter, const Offset(262, 276));
    });
  });

  group('CableDraft', () {
    test('withKind mengganti jenis & biaya, sisanya tetap', () {
      const draft = CableDraft(
        from: 'router',
        kind: CableKind.lan,
        points: designDraft,
        target: 'r5',
        handle: Offset(255, 360),
      );
      expect(draft.segments, 3);
      expect(draft.cost, 45000);
      final fiber = draft.withKind(CableKind.fiber);
      expect(fiber.kind, CableKind.fiber);
      expect(fiber.cost, 180000);
      expect(fiber.target, 'r5');
      expect(fiber.handle, const Offset(255, 360));
      expect(fiber.points, designDraft);
    });
  });
}
