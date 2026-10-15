import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Bar progres bulat dengan penanda target opsional.
///
/// Digambar dengan [CustomPaint] (bukan LayoutBuilder) supaya aman dipakai
/// di dalam `IntrinsicHeight`/[FillScrollView].
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
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      child: CustomPaint(
        size: Size.fromHeight(height),
        painter: _ProgressPainter(
          value: v,
          color: color,
          trackColor: trackColor,
          marker: marker?.clamp(0.0, 1.0),
          markerColor: markerColor,
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.marker,
    required this.markerColor,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double? marker;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = trackColor,
    );
    if (value > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size(size.width * value, size.height),
          r,
        ),
        Paint()..color = color,
      );
    }
    if (marker != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * marker!, -3, 3, size.height + 6),
          const Radius.circular(2),
        ),
        Paint()..color = markerColor,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.marker != marker ||
      old.markerColor != markerColor;
}
