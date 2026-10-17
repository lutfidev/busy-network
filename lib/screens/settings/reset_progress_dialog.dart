import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Tanya dulu sebelum progres dihapus. `true` = pemain memilih "Reset";
/// "Batal", ketuk di luar, atau back = `false`.
Future<bool> showResetProgressDialog(
  BuildContext context, {
  required int stars,
}) async {
  final confirmed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    barrierColor: AppColors.scrim,
    transitionDuration: AppMotion.press,
    pageBuilder: (context, _, _) => ResetProgressDialog(stars: stars),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
  return confirmed ?? false;
}

/// Kartu konfirmasi reset progres (tidak ada di desain; gaya pop-up).
class ResetProgressDialog extends StatelessWidget {
  const ResetProgressDialog({super.key, required this.stars});

  /// Bintang yang akan hilang.
  final int stars;

  @override
  Widget build(BuildContext context) {
    // Dialog umum tidak membawa gaya teks Material.
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: 'Reset progres?',
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.dialogMaxWidth,
                ),
                padding: const EdgeInsets.all(AppSpacing.s20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.panelAll,
                  boxShadow: AppElevation.dialog,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: AppColors.ink),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Reset progres?', style: AppTypography.title),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        '$stars bintang hilang dan permainan mulai lagi dari '
                        'tutorial level 1. Ini nggak bisa dibatalkan.',
                        style: AppTypography.paragraph.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s20),
                      Row(
                        children: [
                          Expanded(
                            child: ChunkyButton(
                              label: 'Batal',
                              variant: ChunkyVariant.outline,
                              size: ChunkySize.small,
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s10),
                          Expanded(
                            child: ChunkyButton(
                              label: 'Reset',
                              variant: ChunkyVariant.danger,
                              size: ChunkySize.small,
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
