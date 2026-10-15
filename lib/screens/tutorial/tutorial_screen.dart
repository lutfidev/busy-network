import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format.dart';
import '../../data/dummy_data.dart';
import '../../data/dummy_scenes.dart';
import '../../game/map_scene.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'tutorial_overlay.dart';
import 'tutorial_steps.dart';

/// 3 · Tutorial Level 1 (3 langkah).
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.initialStep = 1});

  /// 1-based, sesuai label "1 DARI 3".
  final int initialStep;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late int _step = widget.initialStep.clamp(1, TutorialSteps.count);

  final _stackKey = GlobalKey();
  final _routerSpotKey = GlobalKey();
  final _cableSpotKey = GlobalKey();
  final _ctaKey = GlobalKey();

  Rect? _spot;
  double _spotScale = 1;

  bool get _linked => _step == 3;

  void _next() => setState(() => _step = (_step + 1).clamp(1, 3));

  void _measure() {
    if (!mounted) return;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final key = switch (_step) {
      1 => _routerSpotKey,
      2 => _cableSpotKey,
      _ => _ctaKey,
    };
    final target = key.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || target == null || !target.hasSize) return;
    var rect = MatrixUtils.transformRect(
      target.getTransformTo(stack),
      Offset.zero & target.size,
    );
    final scale = _step == 3 ? 1.0 : rect.width / target.size.width;
    if (_step == 3) rect = rect.inflate(TutorialSteps.ctaSpotInflate);
    if (rect != _spot || scale != _spotScale) {
      setState(() {
        _spot = rect;
        _spotScale = scale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    const level = DummyData.level1;
    const lan = DummyData.lan;

    return Scaffold(
      backgroundColor: AppColors.groundDay,
      body: Stack(
        key: _stackKey,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenGutter),
                  child: LevelHeaderCard(
                    overline: 'LEVEL ${level.number}',
                    title: level.name,
                    onBack: () => context.go(AppRoutes.levelMap),
                    stats: [
                      HeaderStat(
                        label: 'Sisa anggaran',
                        value: IdFormat.rupiah(level.budget),
                      ),
                      HeaderStat(
                        label: 'Target kepuasan',
                        value:
                            '≥ ${IdFormat.percent(level.targetSatisfaction)}',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: NetworkMapView(
                    scene: DummyScenes.tutorial(
                      dragging: _step == 2,
                      linked: _linked,
                    ),
                    semanticLabel: 'Peta level 1: router pusat dan dua rumah',
                    overlays: [
                      Positioned.fromRect(
                        rect: TutorialSteps.routerSpot,
                        child: SizedBox(key: _routerSpotKey),
                      ),
                      Positioned.fromRect(
                        rect: TutorialSteps.cableSpot,
                        child: SizedBox(key: _cableSpotKey),
                      ),
                    ],
                  ),
                ),
                BottomPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              'Pilih kabel',
                              style: AppTypography.bodyStrong,
                            ),
                          ),
                          Text(
                            '${_linked ? 1 : 0}/${level.housesTotal} rumah '
                            'tersambung',
                            style: AppTypography.captionBold.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: CableOptionCard(
                                kind: CableKind.lan,
                                name: lan.name,
                                price:
                                    '${IdFormat.rupiah(lan.pricePerSegment)} '
                                    '/ segmen',
                                capacity: 'Kapasitas ${lan.capacityMbps} Mbps',
                                selected: true,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: AppSpacing.cardGap),
                            Expanded(
                              child: CableOptionCard(
                                kind: CableKind.fiber,
                                name: DummyData.fiber.name,
                                price: '',
                                capacity: '',
                                lockedLabel:
                                    'Terbuka di level '
                                    '${DummyData.fiberUnlockLevel}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      KeyedSubtree(
                        key: _ctaKey,
                        child: ChunkyButton(
                          label: 'Mulai Hari',
                          leadingIcon: GameIcons.play,
                          onPressed: () => context.go(AppRoutes.run),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_spot != null) ..._overlay(context, _spot!),
        ],
      ),
    );
  }

  List<Widget> _overlay(BuildContext context, Rect spot) {
    final stackSize =
        (_stackKey.currentContext?.findRenderObject() as RenderBox?)?.size ??
        MediaQuery.sizeOf(context);
    final index = _step - 1;
    final step = TutorialSteps.steps[index];
    final radius = switch (_step) {
      1 => spot.shortestSide / 2,
      2 => TutorialSteps.cableSpotRadius * _spotScale,
      _ => TutorialSteps.ctaSpotRadius,
    };
    final hand = _step == 3
        ? spot.topLeft +
              Offset(spot.width * step.handOffset.dx / 370, step.handOffset.dy)
        : spot.topLeft + step.handOffset * _spotScale;

    // Kartu di bawah sorotan bila muat, kalau tidak di atasnya.
    const estimatedCardHeight = 190.0;
    final below =
        _step != 3 &&
        spot.bottom + AppSpacing.s18 + estimatedCardHeight <= stackSize.height;

    return [
      Positioned.fill(
        child: SpotlightScrim(spot: spot, radius: radius),
      ),
      Positioned(
        left: hand.dx,
        top: hand.dy,
        child: TutorialHand(
          motion: _step == 2 ? HandMotion.drag : HandMotion.bob,
          scale: _step == 3 ? 1 : _spotScale,
        ),
      ),
      Positioned(
        left: AppSpacing.s20,
        right: AppSpacing.s20,
        top: below ? spot.bottom + AppSpacing.s18 : null,
        bottom: below ? null : stackSize.height - spot.top + AppSpacing.s10,
        child: TutorialCard(
          stepIndex: index,
          onNext: _next,
          onSkip: () => context.go(AppRoutes.levelMap),
        ),
      ),
    ];
  }
}
