import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import 'router.dart';
import 'routes.dart';

class JaringanSibukApp extends StatefulWidget {
  const JaringanSibukApp({super.key, this.initialLocation = AppRoutes.home});

  final String initialLocation;

  @override
  State<JaringanSibukApp> createState() => _JaringanSibukAppState();
}

class _JaringanSibukAppState extends State<JaringanSibukApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
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
