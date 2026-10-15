import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import 'game_session.dart';
import 'router.dart';
import 'routes.dart';

class JaringanSibukApp extends StatefulWidget {
  const JaringanSibukApp({
    super.key,
    this.initialLocation = AppRoutes.home,
    this.session,
  });

  final String initialLocation;

  /// Sesi permainan; default sesi baru (test bisa mengisi hari sendiri).
  final GameSession? session;

  @override
  State<JaringanSibukApp> createState() => _JaringanSibukAppState();
}

class _JaringanSibukAppState extends State<JaringanSibukApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
    session: widget.session,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jaringan Sibuk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
