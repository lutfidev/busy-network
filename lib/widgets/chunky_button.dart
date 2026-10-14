import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'icons/game_icons.dart';

enum ChunkyVariant {
  /// Kuning + bayangan padat (CTA utama).
  primary,

  /// Putih + garis tinta 2 px ("Ulangi", "Terapkan").
  outline,

  /// Tinta gelap + teks putih ("Atur antrean", "Lanjut").
  dark,

  /// Abu lembut + teks Nunito ("Abaikan").
  soft,
}

enum ChunkySize {
  /// 72 px · radius 24 · 30 px — tombol "Main".
  hero(
    AppSizes.buttonHero,
    AppRadius.buttonLarge,
    AppSizes.iconXl,
    AppSpacing.s12,
    AppElevation.chunkyLarge,
  ),

  /// 60 px · radius 20 · 22 px — "Mulai Hari".
  large(
    AppSizes.buttonLarge,
    AppRadius.button,
    AppSizes.iconMd,
    AppSpacing.s10,
    AppElevation.chunky,
  ),

  /// 56 px · radius 20 · 20 px — tombol standar di lembar token.
  medium(
    AppSizes.button,
    AppRadius.button,
    18,
    AppSpacing.s8,
    AppElevation.chunky,
  ),

  /// 44 px · radius 14 · 16 px — tombol di kartu/pop-up.
  small(
    AppSizes.buttonSmall,
    AppRadius.buttonSmall,
    AppSizes.iconSm,
    AppSpacing.s8,
    0,
  );

  const ChunkySize(
    this.height,
    this.radius,
    this.iconSize,
    this.gap,
    this.depth,
  );

  final double height;
  final double radius;
  final double iconSize;
  final double gap;
  final double depth;

  TextStyle get textStyle => switch (this) {
    ChunkySize.hero => AppTypography.h2,
    ChunkySize.large => AppTypography.title,
    ChunkySize.medium => AppTypography.title.copyWith(fontSize: 20),
    ChunkySize.small => AppTypography.buttonSmall,
  };
}

/// Tombol "tebal" khas Jaringan Sibuk: bayangan padat 5–6 px yang turun
/// [AppElevation.pressDepth] px saat ditekan.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ChunkyVariant.primary,
    this.size = ChunkySize.large,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
    this.textStyle,
    this.iconSize,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final ChunkyVariant variant;
  final ChunkySize size;
  final GameIconData? leadingIcon;
  final GameIconData? trailingIcon;

  /// Override tinggi bila layar memakai varian di luar skala (58, 62).
  final double? height;
  final TextStyle? textStyle;
  final double? iconSize;
  final String? semanticLabel;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final v = widget.variant;
    final s = widget.size;

    final (Color bg, Color fg, Color? shadow, Border? border) = switch (v) {
      ChunkyVariant.primary => (
        AppColors.primary,
        AppColors.ink,
        AppColors.primaryShadow,
        null,
      ),
      ChunkyVariant.outline => (
        AppColors.surface,
        AppColors.ink,
        null,
        Border.all(color: AppColors.ink, width: 2),
      ),
      ChunkyVariant.dark => (AppColors.ink, AppColors.surface, null, null),
      ChunkyVariant.soft => (AppColors.bubble, AppColors.ink, null, null),
    };
    final depth = shadow == null ? 0.0 : s.depth;
    final pressedShift = depth == 0
        ? 0.0
        : (_pressed ? AppElevation.pressDepth : 0.0);
    final baseStyle =
        widget.textStyle ??
        (v == ChunkyVariant.soft ? AppTypography.bodySmallStrong : s.textStyle);
    final iconSize = widget.iconSize ?? s.iconSize;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leadingIcon != null) ...[
          GameIcon(widget.leadingIcon!, size: iconSize, color: fg),
          SizedBox(width: s.gap),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: baseStyle.copyWith(color: fg),
          ),
        ),
        if (widget.trailingIcon != null) ...[
          SizedBox(width: s.gap),
          GameIcon(widget.trailingIcon!, size: iconSize, color: fg),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: Padding(
          // Ruang untuk bayangan padat supaya layout tidak bergeser.
          padding: EdgeInsets.only(bottom: depth),
          child: AnimatedContainer(
            duration: AppMotion.press,
            curve: AppMotion.standard,
            height: widget.height ?? s.height,
            transform: Matrix4.translationValues(0, pressedShift, 0),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            decoration: BoxDecoration(
              color: enabled ? bg : bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(s.radius),
              border: border,
              boxShadow: shadow == null
                  ? null
                  : AppElevation.solid(shadow, depth - pressedShift),
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Tombol teks polos ("Balik ke peta", "Lewati").
class TextLinkButton extends StatelessWidget {
  const TextLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.inkMuted,
    this.style,
    this.underline = false,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final TextStyle? style;
  final bool underline;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          height: height,
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: (style ?? AppTypography.captionStrong).copyWith(
                color: color,
                decoration: underline ? TextDecoration.underline : null,
                decorationColor: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
