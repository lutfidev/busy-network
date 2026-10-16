import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/progress_book.dart';
import '../../app/routes.dart';
import '../../core/format.dart';
import '../../game/levels/levels.dart';
import '../../game/result/level_result.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'result_success_data.dart';

/// 7 · Hasil Level – Berhasil (1–3 bintang).
class ResultSuccessScreen extends StatelessWidget {
  const ResultSuccessScreen({
    super.key,
    required this.result,
    required this.progress,
  });

  final LevelResult result;

  /// Menentukan level 1 dibuka di tutorial atau Fase Rancang.
  final ProgressBook progress;

  String _play(int number) =>
      AppRoutes.play(number, tutorialDone: progress.progress.tutorialDone);

  /// Level berikutnya bila datanya ada; selain itu Peta Babak (level baru
  /// sudah terbuka di sana).
  void _next(BuildContext context) {
    final next = result.level.number + 1;
    context.go(
      Levels.byNumber(next) != null ? _play(next) : AppRoutes.levelMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = SuccessSummary(result);
    final level = result.level;
    final stars = result.stars;
    final tip = summary.tip;
    return Scaffold(
      backgroundColor: AppColors.groundCelebrate,
      body: Stack(
        children: [
          const Positioned(left: 0, right: 0, top: 0, child: _Confetti()),
          SafeArea(
            child: FillScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.s56),
                  Text(
                    'LEVEL ${level.number} · ${level.name.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.captionStrong.copyWith(
                      color: AppColors.inkMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Semantics(
                    header: true,
                    child: Text(
                      'Hari beres!',
                      textAlign: TextAlign.center,
                      style: AppTypography.h1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Satu gang tidur nyenyak, sinyal aman.',
                    textAlign: TextAlign.center,
                    style: AppTypography.paragraph.copyWith(
                      color: AppColors.inkSecondary,
                      height: null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  _StarTrio(stars: stars),
                  const SizedBox(height: AppSpacing.s18),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Kepuasan',
                            value: IdFormat.percent(result.satisfaction),
                            tone: CardTone.surface,
                            centered: true,
                            valueStyle: AppTypography.titleLarge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: StatTile(
                            label: 'Sisa anggaran',
                            value: IdFormat.rupiah(result.budgetLeft),
                            tone: CardTone.surface,
                            centered: true,
                            valueStyle: AppTypography.subtitle.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: StatTile(
                            label: 'Komplain',
                            value: '${result.complaints}',
                            tone: CardTone.surface,
                            centered: true,
                            valueStyle: AppTypography.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  _RulesCard(rules: summary.rules),
                  if (tip != null) ...[
                    const SizedBox(height: AppSpacing.s20),
                    _TipCard(text: tip),
                  ],
                  const Spacer(),
                  const SizedBox(height: AppSpacing.s16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 10,
                        child: ChunkyButton(
                          label: 'Ulangi',
                          variant: ChunkyVariant.outline,
                          leadingIcon: GameIcons.retry,
                          iconSize: 18,
                          textStyle: AppTypography.titleSmall,
                          onPressed: () => context.go(_play(level.number)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s10),
                      Expanded(
                        flex: 15,
                        child: ChunkyButton(
                          label: 'Level Berikutnya',
                          trailingIcon: GameIcons.chevronRight,
                          iconSize: 18,
                          textStyle: AppTypography.titleSmall,
                          onPressed: () => _next(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s28 - AppElevation.chunky),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiga bintang besar. Bintang yang didapat "pop" bergiliran di atas
/// bintang kosong (js-star); langsung tampil bila animasi dimatikan.
class _StarTrio extends StatefulWidget {
  const _StarTrio({required this.stars});

  final int stars;

  @override
  State<_StarTrio> createState() => _StarTrioState();
}

class _StarTrioState extends State<_StarTrio>
    with SingleTickerProviderStateMixin {
  static final _total = AppMotion.starPopDelays.last + AppMotion.starPop;

  late final _pop = AnimationController(vsync: this, duration: _total);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pop.value = 1;
    } else if (_pop.isDismissed) {
      _pop.forward();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  /// Kemajuan 0..1 animasi bintang ke-[i] (setelah jedanya).
  double _progress(int i) {
    final elapsed = _total * _pop.value - AppMotion.starPopDelays[i];
    return (elapsed.inMicroseconds / AppMotion.starPop.inMicroseconds).clamp(
      0.0,
      1.0,
    );
  }

  Widget _star(int i, double size) {
    final empty = StarIcon(filled: false, size: size, style: StarStyle.large);
    if (widget.stars <= i) return empty;
    return Stack(
      children: [
        empty,
        AnimatedBuilder(
          animation: _pop,
          builder: (context, star) {
            final t = _progress(i);
            return Opacity(
              opacity: AppMotion.starPopOpacity.at(t).clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: AppMotion.starPopAngle.at(t) * math.pi / 180,
                child: Transform.scale(
                  scale: AppMotion.starPopScale.at(t),
                  child: star,
                ),
              ),
            );
          },
          child: StarIcon(filled: true, size: size, style: StarStyle.large),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dapat ${widget.stars} dari 3 bintang',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _star(0, 84),
          const SizedBox(width: AppSpacing.s6),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s18),
            child: _star(1, 108),
          ),
          const SizedBox(width: AppSpacing.s6),
          _star(2, 84),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.rules});

  final List<StarRule> rules;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.panel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s6,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rules.length; i++) ...[
            if (i > 0) const Divider(),
            _RuleRow(rule: rules[i]),
          ],
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});

  final StarRule rule;

  @override
  Widget build(BuildContext context) {
    final pass = rule.passed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StarRating(
                earned: pass ? rule.stars : 0,
                total: rule.stars,
                size: 18,
                spacing: 1,
                filledOverride: pass,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: AppTypography.bodyStrong.copyWith(
                    color: pass ? AppColors.ink : AppColors.inkMuted,
                  ),
                ),
                Text(
                  rule.detail,
                  style: AppTypography.small.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Semantics(
            label: pass ? 'Tercapai' : 'Belum tercapai',
            excludeSemantics: true,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: pass ? AppColors.successBg : AppColors.dangerSoftBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: GameIcon(
                pass ? GameIcons.check : GameIcons.close,
                size: AppSizes.iconSm,
                color: pass ? AppColors.statusOkText : AppColors.statusJamDark,
                strokeWidth: 3.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.tipBg,
        borderRadius: AppRadius.cardAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: GameIcon(
              GameIcons.bulb,
              size: 18,
              color: AppColors.warningStrong,
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.captionBold.copyWith(
                color: AppColors.tipText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Garis & titik warna-warni di atas (koordinat 390×320).
class _Confetti extends StatelessWidget {
  const _Confetti();

  static const _size = Size(390, 320);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: _size.aspectRatio,
        child: CustomPaint(
          painter: SketchPainter(
            (canvas) {
              for (final (d, color) in const [
                ('M40 210 L60 190', AppColors.primary),
                ('M340 220 L356 236', AppColors.cableLan),
                ('M70 120 H90', AppColors.trafficDay),
                ('M310 110 L326 94', AppColors.primary),
              ]) {
                SvgDraw.stroke(canvas, d, color, 6);
              }
              for (final (c, r, color) in const [
                (Offset(352, 160), 6.0, AppColors.statusOk),
                (Offset(30, 160), 5.0, AppColors.trafficDay),
                (Offset(300, 270), 4.0, AppColors.star),
                (Offset(96, 270), 5.0, AppColors.statusOk),
              ]) {
                SvgDraw.circle(canvas, c, r, fill: color);
              }
            },
            designSize: _size,
            id: 'confetti',
          ),
        ),
      ),
    );
  }
}
