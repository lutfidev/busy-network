import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'queue_logic.dart';

/// Kartu satu pelanggan di panel antrean.
class QueueHouseCard extends StatelessWidget {
  const QueueHouseCard({
    super.key,
    required this.house,
    required this.status,
    required this.limit,
    required this.use,
    required this.prioritized,
    required this.onLimitChanged,
    required this.onTogglePriority,
  });

  final QueueHouse house;
  final ServiceStatus status;
  final int limit;
  final double use;
  final bool prioritized;
  final ValueChanged<int> onLimitChanged;
  final VoidCallback onTogglePriority;

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.small.copyWith(color: AppColors.inkMuted);
    return AppCard(
      tone: CardTone.subtle,
      borderColor: AppColors.track,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusDot(status: status),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(house.name, style: AppTypography.bodyStrong),
                    Text('${house.where} · ${status.label}', style: muted),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              StatusChip(
                label: 'Paket ${house.packageMbps} Mbps',
                tone: StatusTone.neutral,
              ),
              const SizedBox(width: AppSpacing.s10),
              _PriorityButton(
                active: prioritized,
                name: house.name,
                onPressed: onTogglePriority,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  'Batas',
                  style: AppTypography.label.copyWith(
                    color: AppColors.inkMuted,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: SizedBox(
                  height: AppSizes.chip,
                  child: Slider(
                    value: limit.toDouble(),
                    min: 1,
                    max: house.packageMbps.toDouble(),
                    divisions: house.packageMbps - 1,
                    label: IdFormat.mbps(limit),
                    semanticFormatterCallback: (v) => IdFormat.mbps(v),
                    onChanged: (v) => onLimitChanged(v.round()),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              SizedBox(
                width: 64,
                child: Text(
                  IdFormat.mbps(limit),
                  textAlign: TextAlign.right,
                  style: AppTypography.buttonSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Text('Pakai sekarang', style: muted),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: ProgressBar(
                  value: use / house.packageMbps,
                  color: AppColors.trafficDay,
                  height: AppSizes.progressThin,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                IdFormat.mbps(use),
                style: AppTypography.label.copyWith(
                  letterSpacing: 0,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.active,
    required this.name,
    required this.onPressed,
  });

  final bool active;
  final String name;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      toggled: active,
      label: 'Prioritaskan $name',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: AppSizes.iconButtonMedium,
          height: AppSizes.iconButtonMedium,
          decoration: BoxDecoration(
            color: active ? AppColors.primarySoftBg : AppColors.surface,
            borderRadius: AppRadius.buttonSmallAll,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.surfaceLine,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: active
              ? const GameIcon(
                  GameIcons.star,
                  color: AppColors.star,
                  secondaryColor: AppColors.starStroke,
                  strokeWidth: 1.8,
                )
              : const GameIcon(
                  GameIcons.starOutline,
                  color: AppColors.blockLabel,
                ),
        ),
      ),
    );
  }
}
