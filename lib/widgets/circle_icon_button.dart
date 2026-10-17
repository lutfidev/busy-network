import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'icons/game_icons.dart';
import '../feedback/feedback_scope.dart';

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
    this.toggled,
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

  /// Tombol sakelar (mis. percepat): status nyala untuk pembaca layar.
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      toggled: toggled,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: FeedbackScope.tap(context, onPressed),
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
