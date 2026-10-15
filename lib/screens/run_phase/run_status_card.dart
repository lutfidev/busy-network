import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../data/dummy_data.dart';
import '../../game/levels/levels.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Bar atas fase jalan: jam, jam sibuk, linimasa hari, kepuasan.
class RunStatusCard extends StatelessWidget {
  const RunStatusCard({
    super.key,
    required this.onFastForward,
    required this.onPause,
  });

  final VoidCallback onFastForward;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    const level = Levels.level5;
    final target = level.targetSatisfaction;
    const now = DummyData.runClockMinutes;
    return AppCard(
      tone: CardTone.night,
      radius: AppRadius.panel,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s14,
        AppSpacing.s12,
        AppSpacing.s14,
        AppSpacing.s14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL ${level.number} · ${level.name.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: AppColors.inkOnDarkMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Row(
                      children: [
                        Text(IdFormat.clock(now), style: AppTypography.clock),
                        const SizedBox(width: AppSpacing.s10),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: RushHourBadge(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              CircleIconButton(
                icon: GameIcons.fastForward,
                semanticLabel: 'Percepat ke akhir hari',
                onPressed: onFastForward,
                size: AppSizes.iconButtonMedium,
                iconSize: AppSizes.iconMd,
                background: AppColors.surfaceNightLine,
                iconColor: AppColors.inkOnDark,
              ),
              const SizedBox(width: AppSpacing.s10),
              CircleIconButton(
                icon: GameIcons.pause,
                semanticLabel: 'Jeda dan atur antrean',
                onPressed: onPause,
                iconSize: AppSizes.iconMd,
                background: AppColors.inkOnDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          const _DayTimeline(),
          const SizedBox(height: AppSpacing.s10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Kepuasan pelanggan',
                  style: AppTypography.captionStrong,
                ),
              ),
              Text.rich(
                TextSpan(
                  text: IdFormat.percent(DummyData.runSatisfaction),
                  style: AppTypography.subtitle.copyWith(color: AppColors.star),
                  children: [
                    TextSpan(
                      text: ' / target ${IdFormat.percent(target)}',
                      style: AppTypography.small.copyWith(
                        color: AppColors.inkOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          ProgressBar(
            value: DummyData.runSatisfaction / 100,
            marker: target / 100,
            color: AppColors.star,
            trackColor: AppColors.surfaceNightLine,
            height: AppSizes.progressThick,
            semanticLabel: 'Kepuasan pelanggan',
          ),
        ],
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  const _DayTimeline();

  static double _frac(double hour) =>
      (hour - DummyData.dayStartHour) /
      (DummyData.dayEndHour - DummyData.dayStartHour);

  @override
  Widget build(BuildContext context) {
    const level = Levels.level5;
    final now = _frac(DummyData.runClockMinutes / 60);
    final rushFrom = _frac(level.rushHourFrom!.toDouble());
    final rushTo = _frac(level.rushHourTo!.toDouble());
    final labelStyle = AppTypography.micro.copyWith(
      color: AppColors.inkOnDarkMuted,
    );
    return Semantics(
      label:
          'Linimasa hari ${IdFormat.hour(DummyData.dayStartHour)}.00 sampai '
          '${DummyData.dayEndHour}.00, jam sibuk ${level.rushHourFrom}.00 '
          'sampai ${level.rushHourTo}.00, sekarang '
          '${IdFormat.clock(DummyData.runClockMinutes).replaceAll(':', '.')}',
      excludeSemantics: true,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: AppSizes.progressMedium,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNightLine,
                          borderRadius: AppRadius.pillAll,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: w * now,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.nightElapsed,
                          borderRadius: AppRadius.pillAll,
                        ),
                      ),
                    ),
                    Positioned(
                      left: w * rushFrom,
                      top: 0,
                      bottom: 0,
                      width: w * (rushTo - rushFrom),
                      child: Opacity(
                        opacity: 0.85,
                        child: Container(color: AppColors.primary),
                      ),
                    ),
                    Positioned(
                      left: w * now - 3,
                      top: -4,
                      width: 6,
                      height: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(IdFormat.hour(DummyData.dayStartHour), style: labelStyle),
              Text(IdFormat.hour(12), style: labelStyle),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Text(
                  IdFormat.hourRange(level.rushHourFrom!, level.rushHourTo!),
                  style: labelStyle,
                ),
              ),
              Text('${DummyData.dayEndHour}', style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }
}
