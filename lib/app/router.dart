import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../data/dummy_data.dart';
import '../gallery/widget_gallery_screen.dart';
import '../game/levels/levels.dart';
import '../screens/design_phase/design_phase_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/level_map/level_map_screen.dart';
import '../screens/queue_panel/queue_panel_screen.dart';
import '../screens/result_fail/result_fail_screen.dart';
import '../screens/result_success/result_success_screen.dart';
import '../screens/run_phase/run_phase_screen.dart';
import '../screens/tutorial/tutorial_screen.dart';
import '../theme/theme.dart';
import 'game_session.dart';
import 'routes.dart';

int? _intParam(GoRouterState state, String name) =>
    int.tryParse(state.uri.queryParameters[name] ?? '');

/// [session] membawa hari dari Fase Rancang ke Fase Jalan & Panel Antrean.
GoRouter createRouter({
  String initialLocation = AppRoutes.home,
  GameSession? session,
}) {
  final play = session ?? GameSession();
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomeScreen(progress: play.progress),
        routes: [
          GoRoute(
            path: 'peta',
            builder: (context, state) =>
                LevelMapScreen(progress: play.progress),
            routes: [
              GoRoute(
                path: 'tutorial',
                builder: (context, state) => TutorialScreen(
                  session: play,
                  initialStep: (_intParam(state, AppRoutes.stepParam) ?? 1)
                      .clamp(1, 3),
                ),
              ),
              GoRoute(
                path: 'rancang',
                builder: (context, state) => DesignPhaseScreen(
                  session: play,
                  level:
                      Levels.byNumber(
                        _intParam(state, AppRoutes.levelParam) ?? 0,
                      ) ??
                      Levels.level5,
                ),
                routes: [
                  GoRoute(
                    path: 'jalan',
                    builder: (context, state) => RunPhaseScreen(session: play),
                    routes: [
                      GoRoute(
                        path: 'antrean',
                        pageBuilder: (context, state) => CustomTransitionPage(
                          key: state.pageKey,
                          transitionDuration: AppMotion.sheetIn,
                          child: QueuePanelScreen(session: play),
                          transitionsBuilder: _slideUp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'hasil/berhasil',
                builder: (context, state) => ResultSuccessScreen(
                  progress: play.progress,
                  result: switch (play.result) {
                    final result? when result.passed => result,
                    _ => DummyData.success(
                      (_intParam(state, AppRoutes.starsParam) ?? 2).clamp(1, 3),
                    ),
                  },
                ),
              ),
              GoRoute(
                path: 'hasil/gagal',
                builder: (context, state) => ResultFailScreen(
                  progress: play.progress,
                  result: switch (play.result) {
                    final result? when !result.passed => result,
                    _ => DummyData.fail,
                  },
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'galeri',
            builder: (context, state) =>
                WidgetGalleryScreen(onBack: () => context.go(AppRoutes.home)),
          ),
        ],
      ),
    ],
  );
}

Widget _slideUp(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
  return FadeTransition(
    opacity: Tween<double>(begin: 0.4, end: 1).animate(curved),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
