import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format.dart';
import '../../data/dummy_data.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'queue_house_card.dart';
import 'queue_logic.dart';

/// 6 · Panel Atur Antrean (game dijeda).
class QueuePanelScreen extends StatefulWidget {
  const QueuePanelScreen({super.key});

  @override
  State<QueuePanelScreen> createState() => _QueuePanelScreenState();
}

class _QueuePanelScreenState extends State<QueuePanelScreen> {
  QueueModel _model = QueueModel.initial();
  bool _applied = false;

  void _update(QueueModel model) => setState(() {
    _model = model;
    _applied = false;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.groundNight,
      body: NightScope(
        child: Stack(
          children: [
            const Positioned.fill(child: _PausedBackdrop()),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenGutter,
                      22,
                      AppSpacing.screenGutter,
                      22,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InfoPill(
                          label: 'Dijeda',
                          height: AppSizes.statusPill,
                          background: AppColors.surfaceNightLine,
                          foreground: AppColors.inkOnDark,
                          textStyle: AppTypography.captionStrong,
                        ),
                        Text(
                          IdFormat.clock(DummyData.runClockMinutes),
                          style: AppTypography.title,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _sheet(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheet(BuildContext context) {
    final m = _model;
    final (Color capColor, Color capBg, String hint) = m.overloaded
        ? (
            AppColors.statusJam,
            AppColors.dangerPanelBg,
            'Kelebihan ${IdFormat.mbps(m.load - m.capacityMbps)}. Turunkan '
                'batas Bu Sri atau Pak Rudi.',
          )
        : m.tight
        ? (
            AppColors.statusSlow,
            AppColors.warningPanelBg,
            'Pas-pasan. Aman, tapi jangan nambah pelanggan di jalur ini.',
          )
        : (
            AppColors.statusOk,
            AppColors.successPanelBg,
            'Lega! Kabel ini aman sampai jam sibuk lewat.',
          );

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: 'Atur antrean',
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.s10,
          AppSpacing.screenGutter,
          AppSpacing.s20 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sheetTop,
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.ink),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetHandle()),
              const SizedBox(height: AppSpacing.s12),
              Text('Atur Antrean', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Batasi jatah tiap rumah biar kabel nggak jebol.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              AppCard(
                background: capBg,
                borderColor: capColor,
                borderWidth: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s14,
                  vertical: AppSpacing.s12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.cableLan,
                            borderRadius: AppRadius.pillAll,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(
                            DummyData.queueCableLabel,
                            style: AppTypography.captionStrong,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          '${IdFormat.number(m.load)} / '
                          '${IdFormat.mbps(m.capacityMbps)}',
                          style: AppTypography.subtitle.copyWith(
                            color: m.overloaded
                                ? AppColors.dangerText
                                : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    ProgressBar(
                      value: m.load / m.capacityMbps,
                      color: capColor,
                      height: AppSizes.progressMedium,
                      semanticLabel: 'Beban kabel',
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      hint,
                      style: AppTypography.small.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: m.houses.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.cardGap),
                  itemBuilder: (context, i) {
                    final h = m.houses[i];
                    return QueueHouseCard(
                      house: h,
                      status: m.statusOf(h),
                      limit: m.limits[h.id]!,
                      use: m.effectiveUse(h),
                      prioritized: m.priority.contains(h.id),
                      onLimitChanged: (v) => _update(m.withLimit(h.id, v)),
                      onTogglePriority: () => _update(m.togglePriority(h.id)),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 10,
                    child: ChunkyButton(
                      label: _applied ? 'Tersimpan' : 'Terapkan',
                      variant: ChunkyVariant.outline,
                      height: AppSizes.buttonPanel,
                      textStyle: AppTypography.titleSmall,
                      leadingIcon: _applied ? GameIcons.check : null,
                      leadingIconColor: AppColors.statusOkText,
                      iconSize: 18,
                      onPressed: () => setState(() => _applied = true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    flex: 13,
                    child: ChunkyButton(
                      label: 'Lanjutkan',
                      height: AppSizes.buttonPanel,
                      textStyle: AppTypography.title.copyWith(fontSize: 20),
                      leadingIcon: GameIcons.play,
                      iconSize: 18,
                      onPressed: () => context.go(AppRoutes.run),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sisa peta yang dijeda, samar di belakang panel.
class _PausedBackdrop extends StatelessWidget {
  const _PausedBackdrop();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Opacity(
        opacity: 0.35,
        child: Align(
          alignment: Alignment.topCenter,
          child: AspectRatio(
            aspectRatio: AppSizes.designCanvas.aspectRatio,
            child: CustomPaint(
              painter: SketchPainter(
                (canvas) {
                  SvgDraw.stroke(canvas, 'M195 120 V40', AppColors.primary, 7);
                  SvgDraw.stroke(
                    canvas,
                    'M195 120 H330',
                    AppColors.statusJam,
                    7,
                  );
                  SvgDraw.stroke(
                    canvas,
                    'M195 120 L120 60 H40',
                    AppColors.cableLanNight,
                    7,
                  );
                  SvgDraw.circle(
                    canvas,
                    const Offset(40, 60),
                    14,
                    fill: AppColors.statusOk,
                  );
                  SvgDraw.circle(
                    canvas,
                    const Offset(330, 120),
                    14,
                    fill: AppColors.statusJam,
                  );
                  SvgDraw.rrect(
                    canvas,
                    const Rect.fromLTWH(179, 104, 32, 32),
                    10,
                    fill: AppColors.inkOnDark,
                  );
                },
                designSize: AppSizes.designCanvas,
                id: 'paused',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
