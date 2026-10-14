import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'icons/game_icons.dart';

/// Tombol ikon bulat (kembali, pengaturan, jeda, percepat).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.size = AppSizes.iconButton,
    this.iconSize = AppSizes.iconLg,
    this.background = AppColors.surface,
    this.borderColor,
    this.iconColor = AppColors.ink,
    this.iconStrokeWidth,
  });

  final GameIconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color background;
  final Color? borderColor;
  final Color iconColor;
  final double? iconStrokeWidth;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 1),
          ),
          alignment: Alignment.center,
          child: GameIcon(
            icon,
            size: iconSize,
            color: iconColor,
            strokeWidth: iconStrokeWidth,
          ),
        ),
      ),
    );
  }
}
