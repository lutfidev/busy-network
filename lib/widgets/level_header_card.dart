import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'app_card.dart';
import 'badges.dart';
import 'circle_icon_button.dart';
import 'icons/game_icons.dart';

/// Data satu tile statistik di header level.
class HeaderStat {
  const HeaderStat({
    required this.label,
    required this.value,
    this.note,
    this.noteColor,
  });

  final String label;
  final String value;
  final String? note;
  final Color? noteColor;
}

/// Bar atas fase rancang/tutorial: tombol kembali, nama level, pill
/// "Waktu berhenti", lalu dua tile statistik.
class LevelHeaderCard extends StatelessWidget {
  const LevelHeaderCard({
    super.key,
    required this.overline,
    required this.title,
    required this.stats,
    required this.onBack,
    this.statusLabel = 'Waktu berhenti',
  });

  final String overline;
  final String title;
  final List<HeaderStat> stats;
  final VoidCallback onBack;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.panel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleIconButton(
                icon: GameIcons.back,
                semanticLabel: 'Kembali ke peta',
                onPressed: onBack,
                size: AppSizes.iconButtonSmall,
                iconSize: AppSizes.iconMd,
                background: AppColors.groundDay,
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overline,
                      style: AppTypography.label.copyWith(
                        color: AppColors.inkMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              InfoPill(label: statusLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: StatTile(
                      label: stats[i].label,
                      value: stats[i].value,
                      note: stats[i].note,
                      noteColor: stats[i].noteColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
