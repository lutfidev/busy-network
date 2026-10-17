import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'icons/game_icons.dart';
import 'star_rating.dart';
import '../feedback/feedback_scope.dart';

enum LevelNodeState { done, current, locked }

/// Bulatan level di Peta Babak (selesai · sekarang · terkunci).
///
/// Ukuran mengikuti desain: 60 / 72 / 48 px. Bintang & label tidak
/// termasuk; susun di luar sesuai tata letak peta.
class LevelNode extends StatelessWidget {
  const LevelNode({
    super.key,
    required this.number,
    required this.state,
    this.onPressed,
    this.semanticLabel,
  });

  final int number;
  final LevelNodeState state;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  double get diameter => switch (state) {
    LevelNodeState.done => AppSizes.levelNode,
    LevelNodeState.current => AppSizes.levelNodeCurrent,
    LevelNodeState.locked => AppSizes.levelNodeLocked,
  };

  @override
  Widget build(BuildContext context) {
    final Widget circle = switch (state) {
      LevelNodeState.done => _circle(
        bg: AppColors.surface,
        border: AppColors.primary,
        shadow: AppColors.groundDayDot,
        depth: AppElevation.levelNode,
        child: Text(
          '$number',
          style: AppTypography.levelNumber.copyWith(color: AppColors.ink),
        ),
      ),
      LevelNodeState.current => _circle(
        bg: AppColors.primary,
        border: AppColors.surface,
        shadow: AppColors.primaryShadow,
        depth: AppElevation.chunky,
        child: Text(
          '$number',
          style: AppTypography.levelNumberCurrent.copyWith(
            color: AppColors.ink,
          ),
        ),
      ),
      LevelNodeState.locked => _circle(
        bg: AppColors.surfaceLine,
        child: const GameIcon(
          GameIcons.lock,
          size: AppSizes.iconMd,
          color: AppColors.inkMuted,
        ),
      ),
    };
    final locked = state == LevelNodeState.locked;
    return Semantics(
      button: !locked,
      enabled: !locked && onPressed != null,
      label:
          semanticLabel ??
          (locked ? 'Level $number terkunci' : 'Level $number'),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: FeedbackScope.tap(context, locked ? null : onPressed),
        child: circle,
      ),
    );
  }

  Widget _circle({
    required Color bg,
    required Widget child,
    Color? border,
    Color? shadow,
    double depth = 0,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border == null
            ? null
            : Border.all(
                color: border,
                width: AppSizes.levelNodeBorder,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
        boxShadow: shadow == null ? null : AppElevation.solid(shadow, depth),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Node level + bintangnya di bawah (untuk galeri / daftar).
class LevelNodeWithStars extends StatelessWidget {
  const LevelNodeWithStars({
    super.key,
    required this.number,
    required this.state,
    this.stars = 0,
    this.onPressed,
  });

  final int number;
  final LevelNodeState state;
  final int stars;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LevelNode(number: number, state: state, onPressed: onPressed),
        const SizedBox(height: AppSpacing.s6),
        if (state == LevelNodeState.locked)
          Text(
            '$number',
            style: AppTypography.captionStrong.copyWith(
              color: AppColors.inkMuted,
            ),
          )
        else
          StarRating(earned: stars),
      ],
    );
  }
}
