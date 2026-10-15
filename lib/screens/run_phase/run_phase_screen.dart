import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../data/dummy_data.dart';
import '../../data/dummy_scenes.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'complaint_popup.dart';
import 'run_status_card.dart';

/// 5 · Fase Jalan – Level 5, jam sibuk.
class RunPhaseScreen extends StatelessWidget {
  const RunPhaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.groundNight,
      body: NightScope(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenGutter),
                child: RunStatusCard(
                  onFastForward: () =>
                      context.go(AppRoutes.successWithStars(2)),
                  onPause: () => context.go(AppRoutes.queue),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkMapView(
                        scene: DummyScenes.run(),
                        alignment: Alignment.topCenter,
                        semanticLabel:
                            'Peta jaringan malam hari. Kabel router ke '
                            'Rumah 4 kelebihan beban, Rumah 4 macet, Rumah 3 '
                            'dan 5 mulai lambat.',
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.screenGutter,
                      right: AppSpacing.screenGutter,
                      bottom: AppSpacing.s18,
                      child: ComplaintPopup(
                        name: DummyData.complaintName,
                        house: DummyData.complaintHouse,
                        clockMinutes: DummyData.complaintClockMinutes,
                        message: DummyData.complaintMessage,
                        onManageQueue: () => context.go(AppRoutes.queue),
                        onIgnore: () => context.go(AppRoutes.fail),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
