import 'dart:ui';

import 'package:busy_network/game/map_scene.dart';

/// Uraian lengkap scene (urutan = urutan gambar) supaya selisihnya terbaca.
List<String> describeScene(MapScene s) => [
  'theme=${s.theme} handle=${_o(s.dragHandle)}',
  for (final l in s.blockLabels) 'block ${l.text} ${_o(l.position)} ${l.align}',
  for (final c in s.cables)
    'cable ${c.points.map(_o).join(' ')} ${c.kind} ${c.state} '
        '${c.traffic} thick=${c.thick}',
  for (final b in s.badges) 'badge ${b.text} ${_o(b.center)} w=${b.width}',
  for (final n in s.nodes)
    'node ${n.id} ${n.kind} ${_o(n.position)} label=${n.label} '
        'offset=${_o(n.labelOffset)} ${n.labelAlign} emph=${n.labelEmphasis} '
        '${n.state} patience=${n.patience} ${n.patiencePlacement} '
        'alarm=${n.alarm} snap=${n.snapTarget} routerAlarm=${n.routerAlarm}',
];

String _o(Offset? o) => o == null ? 'null' : '(${o.dx}, ${o.dy})';
