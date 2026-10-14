import 'package:flutter/widgets.dart';

import '../game/map_scene.dart';
import '../theme/theme.dart';
import 'dashed_border.dart';
import 'icons/game_icons.dart';

/// Kartu pilihan kabel (LAN / Fiber) di bar bawah fase rancang.
class CableOptionCard extends StatelessWidget {
  const CableOptionCard({
    super.key,
    required this.kind,
    required this.name,
    required this.price,
    required this.capacity,
    this.selected = false,
    this.lockedLabel,
    this.onPressed,
  });

  final CableKind kind;
  final String name;

  /// Mis. "Rp 15.000 / segmen".
  final String price;

  /// Mis. "Kapasitas 20 Mbps · murah".
  final String capacity;
  final bool selected;

  /// Bila diisi, kartu terkunci dan menampilkan teks ini (mis.
  /// "Terbuka di level 3").
  final String? lockedLabel;
  final VoidCallback? onPressed;

  bool get locked => lockedLabel != null;

  @override
  Widget build(BuildContext context) {
    final fiber = kind == CableKind.fiber;
    final Color bg;
    if (locked) {
      bg = AppColors.surfaceSubtle;
    } else if (selected) {
      bg = fiber ? AppColors.primarySoftBg : AppColors.surfaceSubtle;
    } else {
      bg = AppColors.surface;
    }
    final fg = locked ? AppColors.inkMuted : AppColors.ink;
    final swatch = locked
        ? AppColors.groundDayDot
        : (fiber ? AppColors.cableFiber : AppColors.cableLan);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: fiber && !locked ? 9 : 7,
              decoration: BoxDecoration(
                color: swatch,
                borderRadius: AppRadius.pillAll,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(name, style: AppTypography.subtitle.copyWith(color: fg)),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        if (locked)
          Row(
            children: [
              const GameIcon(
                GameIcons.lock,
                size: 14,
                color: AppColors.inkMuted,
                strokeWidth: 2.6,
              ),
              const SizedBox(width: AppSpacing.s6),
              Expanded(
                child: Text(
                  lockedLabel!,
                  style: AppTypography.label.copyWith(
                    letterSpacing: 0,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          )
        else ...[
          Text(price, style: AppTypography.captionStrong.copyWith(color: fg)),
          const SizedBox(height: AppSpacing.s2),
          Text(
            capacity,
            style: AppTypography.small.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ],
    );

    final box = Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.cardAll,
        border: locked
            ? null
            : Border.all(
                color: selected ? AppColors.ink : AppColors.surfaceLine,
                width: selected ? 3 : 2,
              ),
      ),
      alignment: Alignment.topLeft,
      child: content,
    );

    return Semantics(
      button: true,
      enabled: !locked,
      selected: selected,
      label: locked ? '$name, ${lockedLabel!}' : '$name, $price, $capacity',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : onPressed,
        child: locked
            ? CustomPaint(
                foregroundPainter: const DashedBorderPainter(
                  color: AppColors.groundDayDot,
                  radius: AppRadius.card,
                ),
                child: box,
              )
            : box,
      ),
    );
  }
}
