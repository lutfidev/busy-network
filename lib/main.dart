import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'app/game_session.dart';
import 'app/progress_book.dart';
import 'data/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font dibundel di assets/google_fonts → tidak perlu unduh saat runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final progress = await _openProgress();
  runApp(JaringanSibukApp(session: GameSession(progress: progress)));
}

/// Progres tersimpan di perangkat; bila penyimpanannya tidak bisa dibuka,
/// permainan tetap jalan dengan progres di memori.
Future<ProgressBook> _openProgress() async {
  try {
    return ProgressBook(await PrefsProgressStore.open());
  } on Object catch (error) {
    debugPrint('Progres tidak bisa dibuka: $error');
    return ProgressBook.memory();
  }
}
