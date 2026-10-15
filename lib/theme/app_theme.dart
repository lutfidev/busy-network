import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// [ThemeData] aplikasi. Layar siang memakai tema ini apa adanya; layar
/// malam cukup mengganti latar & [DefaultTextStyle] (lihat `NightScope`).
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.ink,
      secondary: AppColors.ink,
      onSecondary: AppColors.surface,
      tertiary: AppColors.trafficDay,
      onTertiary: AppColors.surface,
      error: AppColors.statusJam,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.surfaceLine,
      outlineVariant: AppColors.track,
      surfaceContainerHighest: AppColors.surfaceSubtle,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.surface,
      shadow: AppColors.ink,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypography.display,
      displayMedium: AppTypography.h1,
      displaySmall: AppTypography.clock,
      headlineLarge: AppTypography.h2,
      headlineMedium: AppTypography.headline,
      headlineSmall: AppTypography.titleLarge,
      titleLarge: AppTypography.title,
      titleMedium: AppTypography.subtitle,
      titleSmall: AppTypography.bodyStrong,
      bodyLarge: AppTypography.lead,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.captionStrong,
      labelMedium: AppTypography.label,
      labelSmall: AppTypography.micro,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.groundDay,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(
        color: AppColors.track,
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.track,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primaryOverlay,
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.never,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.ink,
          borderRadius: AppRadius.pillAll,
        ),
        textStyle: AppTypography.captionStrong.copyWith(
          color: AppColors.surface,
        ),
      ),
    );
  }
}
