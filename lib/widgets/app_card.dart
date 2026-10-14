import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

enum CardTone {
  /// Putih + garis abu (siang).
  surface,

  /// Abu sangat muda tanpa garis (tile di dalam kartu).
  subtle,

  /// Biru malam + garis gelap.
  night,
}

/// Kartu dasar: radius 18 (default), padding 12–16.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.tone = CardTone.surface,
    this.radius = AppRadius.card,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.background,
    this.borderColor,
    this.borderWidth = 1,
    this.shadows,
  });

  final Widget child;
  final CardTone tone;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color? line) = switch (tone) {
      CardTone.surface => (AppColors.surface, AppColors.surfaceLine),
      CardTone.subtle => (AppColors.surfaceSubtle, null),
      CardTone.night => (AppColors.surfaceNight, AppColors.surfaceNightLine),
    };
    final border = borderColor ?? line;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? bg,
        borderRadius: BorderRadius.circular(radius),
        border: border == null
            ? null
            : Border.all(color: border, width: borderWidth),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}

/// Tile angka: label kecil di atas, nilai Fredoka di bawah.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.noteColor,
    this.tone = CardTone.subtle,
    this.centered = false,
    this.valueStyle,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? note;
  final Color? noteColor;
  final CardTone tone;
  final bool centered;
  final TextStyle? valueStyle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final night = tone == CardTone.night;
    final labelColor = night ? AppColors.inkOnDarkMuted : AppColors.inkMuted;
    final valueFg = valueColor ?? (night ? AppColors.inkOnDark : AppColors.ink);
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return AppCard(
      tone: tone,
      radius: centered ? AppRadius.card : AppRadius.buttonSmall,
      padding: centered
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.s10,
              vertical: AppSpacing.s12,
            )
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small.copyWith(color: labelColor),
          ),
          if (centered) const SizedBox(height: AppSpacing.s2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: (valueStyle ?? AppTypography.title).copyWith(
                color: valueFg,
              ),
            ),
          ),
          if (note != null)
            Text(
              note!,
              style: AppTypography.label.copyWith(
                letterSpacing: 0,
                color: noteColor ?? labelColor,
                fontWeight: noteColor == null ? FontWeight.w700 : null,
              ),
            ),
        ],
      ),
    );
  }
}
