import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'icons/game_icons.dart';

enum StarStyle {
  /// Bintang kecil di peta: kosong = abu tanpa garis.
  compact,

  /// Bintang besar di layar hasil: kosong tetap bergaris + kilau.
  large,
}

/// Satu bintang terisi atau kosong.
class StarIcon extends StatelessWidget {
  const StarIcon({
    super.key,
    required this.filled,
    this.size = AppSizes.levelStar,
    this.style = StarStyle.compact,
    this.strokeWidth,
  });

  final bool filled;
  final double size;
  final StarStyle style;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final large = style == StarStyle.large;
    final stroke = strokeWidth ?? (large ? 1 : 1.5);
    if (filled) {
      return SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            GameIcon(
              GameIcons.star,
              size: size,
              color: AppColors.star,
              secondaryColor: AppColors.starStroke,
              strokeWidth: stroke,
            ),
            if (large)
              GameIcon(_starShine, size: size, color: AppColors.starHighlight),
          ],
        ),
      );
    }
    if (large) {
      return GameIcon(
        GameIcons.star,
        size: size,
        color: AppColors.starEmptyLarge,
        secondaryColor: AppColors.starEmptyStroke,
        strokeWidth: stroke,
      );
    }
    return GameIcon(_starFillOnly, size: size, color: AppColors.starEmpty);
  }

  static const _starFillOnly = GameIconData([
    IconShape.path(
      'M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z',
      mode: IconPaintMode.fill,
    ),
  ]);

  static const _starShine = GameIconData([
    IconShape.path('M8.6 9.6l2.2-.3'),
  ], strokeWidth: 1.2);
}

/// Deretan bintang, mis. ★★☆.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.earned,
    this.total = 3,
    this.size = AppSizes.levelStar,
    this.spacing = AppSpacing.s2,
    this.filledOverride,
  });

  final int earned;
  final int total;
  final double size;
  final double spacing;

  /// Semua bintang diwarnai sama (dipakai di daftar syarat bintang).
  final bool? filledOverride;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bintang $earned dari $total',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            StarIcon(filled: filledOverride ?? i < earned, size: size),
          ],
        ],
      ),
    );
  }
}
