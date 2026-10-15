import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'icons/game_icons.dart';

/// Pill "JAM SIBUK" (kuning + petir).
class RushHourBadge extends StatelessWidget {
  const RushHourBadge({super.key, this.label = 'JAM SIBUK'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.chip,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s8, 0, AppSpacing.s10, 0),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIcon(GameIcons.bolt, size: 13),
          const SizedBox(width: AppSpacing.s4),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: AppColors.ink,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { danger, neutral }

/// Chip status kotak (radius 8), mis. "MACET" atau "Paket 20 Mbps".
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.danger,
    this.dense = false,
  });

  final String label;
  final StatusTone tone;

  /// Versi kecil (11 px) di kartu komplain.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      StatusTone.danger => (AppColors.dangerBg, AppColors.dangerText),
      StatusTone.neutral => (AppColors.track, AppColors.ink),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense || tone == StatusTone.neutral
            ? AppSpacing.s8
            : AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.chipAll),
      child: Text(
        label,
        maxLines: 1,
        style: (dense ? AppTypography.micro : AppTypography.label).copyWith(
          color: fg,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Pill info kecil berikon ("Waktu berhenti", "Dijeda").
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    this.icon = GameIcons.pause,
    this.background = AppColors.groundDay,
    this.foreground = AppColors.inkMuted,
    this.height,
    this.textStyle,
  });

  final String label;
  final GameIconData icon;
  final Color background;
  final Color foreground;
  final double? height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: height == null ? AppSpacing.s10 : AppSpacing.s14,
        vertical: height == null ? AppSpacing.s6 : 0,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(icon, size: AppSizes.iconXs, color: foreground),
          SizedBox(width: height == null ? AppSpacing.s6 : AppSpacing.s8),
          Text(
            label,
            maxLines: 1,
            style: (textStyle ?? AppTypography.label.copyWith(letterSpacing: 0))
                .copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

enum CounterTone { day, night }

/// Penghitung bintang "★ 9 / 36".
class StarCounterPill extends StatelessWidget {
  const StarCounterPill({
    super.key,
    required this.value,
    required this.total,
    this.tone = CounterTone.day,
  });

  final int value;
  final int total;
  final CounterTone tone;

  @override
  Widget build(BuildContext context) {
    final night = tone == CounterTone.night;
    return Semantics(
      label: 'Bintang terkumpul $value dari $total',
      excludeSemantics: true,
      child: Container(
        height: AppSizes.counterPill,
        padding: EdgeInsets.fromLTRB(
          night ? AppSpacing.s12 : AppSpacing.s10,
          0,
          night ? AppSpacing.s16 : AppSpacing.s14,
          0,
        ),
        decoration: BoxDecoration(
          color: night ? AppColors.surfaceNightRaised : AppColors.surface,
          borderRadius: AppRadius.pillAll,
          border: Border.all(
            color: night
                ? AppColors.surfaceNightRaisedLine
                : AppColors.surfaceLine,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(
              GameIcons.star,
              size: night ? AppSizes.iconLg : AppSizes.iconMd,
              color: AppColors.star,
              secondaryColor: AppColors.starStroke,
            ),
            SizedBox(width: night ? AppSpacing.s8 : AppSpacing.s6),
            Text(
              '$value',
              style:
                  (night
                          ? AppTypography.title.copyWith(fontSize: 20)
                          : AppTypography.subtitle)
                      .copyWith(
                        color: night ? AppColors.inkOnDark : AppColors.ink,
                      ),
            ),
            if (night) const SizedBox(width: AppSpacing.s8),
            Text(
              night ? '/ $total' : ' / $total',
              style: night
                  ? AppTypography.body.copyWith(color: AppColors.inkOnDarkMuted)
                  : AppTypography.subtitle.copyWith(
                      fontSize: 15,
                      color: AppColors.inkMuted,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
