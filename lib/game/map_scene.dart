import 'dart:ui';

/// Model data statis peta jaringan (posisi dalam koordinat desain).
///
/// Area peta di desain berukuran 390×472 dengan grid 30 px. Semua
/// koordinat di sini mengacu ke ruang itu; widget/komponen Flame yang
/// menggambar peta yang bertugas menskalakan ke layar.
///
/// Sesi ini peta masih statis. Logika game (tarik kabel, simulasi trafik)
/// nanti mengisi/menurunkan [MapScene] dari state game.

enum MapTheme { day, night }

enum NodeKind { router, house, junction }

/// Status rumah. [connected] = sudah tersambung di fase rancang (belum ada
/// trafik). [ok]/[slow]/[jam] = status saat simulasi berjalan.
enum HouseState { idle, connected, ok, slow, jam }

enum CableKind { lan, fiber }

enum CableState {
  /// Kabel terpasang biasa.
  normal,

  /// Kabel yang sedang ditarik jari (garis putus-putus).
  drafting,

  /// Kabel kelebihan beban (merah, berkedip).
  overloaded,
}

enum TrafficState { none, flow, jam }

/// Posisi bar kesabaran relatif ke pusat rumah.
enum PatiencePlacement { below, right, above }

class MapNode {
  const MapNode({
    required this.id,
    required this.kind,
    required this.position,
    this.label,
    this.labelOffset,
    this.labelAlign = TextAlign.center,
    this.labelEmphasis = false,
    this.state = HouseState.idle,
    this.patience,
    this.patiencePlacement = PatiencePlacement.below,
    this.alarm = false,
    this.snapTarget = false,
    this.routerAlarm = false,
  });

  final String id;
  final NodeKind kind;
  final Offset position;

  /// Teks label ("Rumah 1"). `null` = tanpa label.
  final String? label;

  /// Posisi baseline label relatif ke [position]. Default: di bawah node.
  final Offset? labelOffset;
  final TextAlign labelAlign;

  /// Label diberi warna peringatan (mis. "Rumah 4 · sabar 15%").
  final bool labelEmphasis;

  final HouseState state;

  /// Sisa kesabaran pelanggan 0..1, digambar sebagai bar kecil.
  final double? patience;
  final PatiencePlacement patiencePlacement;

  /// Cincin merah di rumah macet.
  final bool alarm;

  /// Cincin putus-putus "lepas jari di sini" saat menarik kabel.
  final bool snapTarget;

  /// LED ketiga router menyala merah (ada kabel penuh).
  final bool routerAlarm;
}

class MapCable {
  const MapCable({
    required this.points,
    this.kind = CableKind.lan,
    this.state = CableState.normal,
    this.traffic = TrafficState.none,
    this.thick = false,
  });

  /// Polyline kabel; segmen hanya 0°/45°/90°.
  final List<Offset> points;
  final CableKind kind;
  final CableState state;
  final TrafficState traffic;

  /// LAN yang digambar setebal fiber (jalur utama yang kelebihan beban).
  final bool thick;
}

class MapBlockLabel {
  const MapBlockLabel(this.text, this.position, {this.align = TextAlign.left});

  final String text;

  /// Titik baseline; makna x mengikuti [align] (seperti `text-anchor`).
  final Offset position;
  final TextAlign align;
}

/// Lencana teks di atas peta (mis. "Penuh! 25/20").
class MapBadge {
  const MapBadge(this.text, this.center, {this.width = 92});

  final String text;
  final Offset center;
  final double width;
}

class MapScene {
  const MapScene({
    required this.theme,
    required this.nodes,
    this.cables = const [],
    this.blockLabels = const [],
    this.badges = const [],
    this.dragHandle,
    this.size = const Size(390, 472),
  });

  final MapTheme theme;
  final List<MapNode> nodes;
  final List<MapCable> cables;
  final List<MapBlockLabel> blockLabels;
  final List<MapBadge> badges;

  /// Ujung kabel yang sedang ditarik (lingkaran jari).
  final Offset? dragHandle;
  final Size size;

  /// Ada yang bergerak (trafik)? Kalau tidak, peta cukup digambar sekali.
  bool get hasMotion => cables.any((c) => c.traffic != TrafficState.none);
}
