import 'package:flutter/widgets.dart';

import '../feedback/feedback_scope.dart';
import '../feedback/game_feedback.dart';
import '../theme/theme.dart';

/// Sakelar nyala/mati (Pengaturan; tidak ada di desain): pill hijau
/// `statusOk` dengan kenop putih saat nyala, abu saat mati.
///
/// Diketuk → [onChanged] dulu, baru bunyi [Cue.tap]: menyalakan suara
/// langsung terdengar, mematikannya diam.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  /// Ketukan untuk sakelar [value] (dipakai juga baris di sekitarnya).
  static VoidCallback? toggle(
    BuildContext context,
    bool value,
    ValueChanged<bool>? onChanged,
  ) => onChanged == null
      ? null
      : () {
          onChanged(!value);
          FeedbackScope.cue(context, Cue.tap);
        };

  @override
  Widget build(BuildContext context) {
    final onTap = toggle(context, value, onChanged);
    return Semantics(
      container: true,
      button: true,
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ToggleTrack(value: value),
      ),
    );
  }
}

/// Gambar sakelar saja (tanpa sentuhan/semantik), untuk baris yang bisa
/// diketuk seluruhnya.
class ToggleTrack extends StatelessWidget {
  const ToggleTrack({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    const inset = (AppSizes.toggleHeight - AppSizes.toggleKnob) / 2;
    return AnimatedContainer(
      duration: AppMotion.press,
      curve: AppMotion.standard,
      width: AppSizes.toggleWidth,
      height: AppSizes.toggleHeight,
      padding: const EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: value ? AppColors.statusOk : AppColors.toggleOff,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AnimatedAlign(
        duration: AppMotion.press,
        curve: AppMotion.standard,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: AppSizes.toggleKnob,
          height: AppSizes.toggleKnob,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: AppElevation.toggleKnob,
          ),
        ),
      ),
    );
  }
}
