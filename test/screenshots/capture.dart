import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aktif hanya dengan `--dart-define=SCREENSHOTS=true`.
const bool screenshotsEnabled = bool.fromEnvironment('SCREENSHOTS');

/// Folder output (default `build/screenshots`).
const String screenshotDir = String.fromEnvironment(
  'SCREENSHOT_DIR',
  defaultValue: 'build/screenshots',
);

final _boundaryKey = GlobalKey();

/// Membungkus [child] agar bisa dipotret.
Widget capturable(Widget child) =>
    RepaintBoundary(key: _boundaryKey, child: child);

/// Menunggu font google_fonts selesai dimuat lalu menyimpan PNG.
Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    await GoogleFonts.pendingFonts();
    // Beri waktu satu frame agar teks di-layout ulang dengan font asli.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$screenshotDir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
