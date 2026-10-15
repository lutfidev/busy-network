import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Pop-up komplain pelanggan di fase jalan.
class ComplaintPopup extends StatelessWidget {
  const ComplaintPopup({
    super.key,
    required this.name,
    required this.house,
    required this.clockMinutes,
    required this.message,
    required this.onManageQueue,
    required this.onIgnore,
  });

  final String name;
  final String house;
  final int clockMinutes;
  final String message;
  final VoidCallback onManageQueue;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s14,
              AppSpacing.s14,
              AppSpacing.s14,
              AppSpacing.s12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.panelAll,
              boxShadow: AppElevation.popupNight,
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.ink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppSizes.avatar,
                        height: AppSizes.avatar,
                        decoration: const BoxDecoration(
                          color: AppColors.dangerBg,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.split(' ').last.characters.first,
                          style: AppTypography.subtitle.copyWith(
                            color: AppColors.statusJamDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$name – $house',
                              style: AppTypography.bodySmallStrong,
                            ),
                            Text(
                              'Komplain baru · ${IdFormat.clock(clockMinutes)}',
                              style: AppTypography.small.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      const StatusChip(label: 'MACET', dense: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s10,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.bubble,
                      borderRadius: AppRadius.speechBubble,
                    ),
                    child: Text(
                      message,
                      style: AppTypography.body.copyWith(height: 1.4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          label: 'Atur antrean',
                          variant: ChunkyVariant.dark,
                          size: ChunkySize.small,
                          leadingIcon: GameIcons.queue,
                          onPressed: onManageQueue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      SizedBox(
                        width: 104,
                        child: ChunkyButton(
                          label: 'Abaikan',
                          variant: ChunkyVariant.soft,
                          size: ChunkySize.small,
                          onPressed: onIgnore,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Ekor balon menunjuk ke rumah yang komplain.
          Positioned(
            right: 52,
            top: -9,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
