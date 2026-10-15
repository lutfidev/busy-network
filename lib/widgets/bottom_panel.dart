import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Panel putih menempel di bawah layar (radius atas 28 + bayangan lembut).
class BottomPanel extends StatelessWidget {
  const BottomPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.s16,
      AppSpacing.s16,
      AppSpacing.s16,
      AppSpacing.s24,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: padding.add(EdgeInsets.only(bottom: bottomInset)),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sheetTop,
        boxShadow: AppElevation.sheet,
      ),
      child: child,
    );
  }
}

/// Garis pegangan kecil di atas bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.sheetHandleWidth,
      height: AppSizes.sheetHandleHeight,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLine,
        borderRadius: AppRadius.pillAll,
      ),
    );
  }
}
