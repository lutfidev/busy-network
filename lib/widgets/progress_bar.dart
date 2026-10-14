import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Bar progres bulat dengan penanda target opsional.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.trackColor = AppColors.track,
    this.height = AppSizes.progress,
    this.marker,
    this.markerColor = AppColors.inkOnDark,
    this.semanticLabel,
  });

  /// 0..1
  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  /// Posisi penanda target 0..1 (mis. target kepuasan 80%).
  final double? marker;
  final Color markerColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final bar = LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: AppRadius.pillAll,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: w * v,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadius.pillAll,
                  ),
                ),
              ),
              if (marker != null)
                Positioned(
                  left: w * marker!.clamp(0.0, 1.0),
                  top: -3,
                  width: 3,
                  height: height + 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: markerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      child: bar,
    );
  }
}
