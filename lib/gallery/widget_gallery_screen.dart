import 'package:flutter/material.dart';

import '../core/format.dart';
import '../game/map_scene.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Galeri komponen untuk cek visual terhadap lembar "Design token &
/// komponen" (`design/reference/09-design-token.png`).
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  CableKind _cable = CableKind.lan;
  int _taps = 0;

  void _tap() => setState(() => _taps++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSubtle,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenGutter),
          children: [
            Row(
              children: [
                if (widget.onBack != null) ...[
                  CircleIconButton(
                    icon: GameIcons.back,
                    semanticLabel: 'Kembali',
                    onPressed: widget.onBack,
                    borderColor: AppColors.surfaceLine,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JARINGAN SIBUK · TOKEN v0.1',
                        style: AppTypography.captionStrong.copyWith(
                          color: AppColors.inkMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text('Galeri komponen', style: AppTypography.titleLarge),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            _Section(title: 'Warna', child: _ColorGrid()),
            _Section(title: 'Tipografi', child: _TypeScale()),
            _Section(
              title: 'Jarak & radius',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.s14,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      for (final s in const [4.0, 8.0, 12.0, 16.0, 24.0, 32.0])
                        _Labeled(
                          label: IdFormat.number(s),
                          child: Container(
                            width: s,
                            height: s,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Wrap(
                    spacing: AppSpacing.s12,
                    children: [
                      for (final r in const [
                        AppRadius.chip,
                        AppRadius.buttonSmall,
                        AppRadius.card,
                        AppRadius.panel,
                        AppRadius.pill,
                      ])
                        _Labeled(
                          label: r == AppRadius.pill
                              ? 'pill'
                              : IdFormat.number(r),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.track,
                              borderRadius: BorderRadius.circular(r),
                              border: Border.all(
                                color: AppColors.ink,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Tombol · ditekan $_taps×',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ChunkyButton(
                    label: 'Main',
                    size: ChunkySize.hero,
                    leadingIcon: GameIcons.play,
                    onPressed: _tap,
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  ChunkyButton(
                    label: 'Mulai Hari',
                    size: ChunkySize.medium,
                    onPressed: _tap,
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  ChunkyButton(
                    label: 'Ulangi',
                    variant: ChunkyVariant.outline,
                    size: ChunkySize.medium,
                    height: AppSizes.buttonOutline,
                    textStyle: AppTypography.subtitle,
                    onPressed: _tap,
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          label: 'Atur antrean',
                          variant: ChunkyVariant.dark,
                          size: ChunkySize.small,
                          leadingIcon: GameIcons.queue,
                          onPressed: _tap,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      SizedBox(
                        width: 104,
                        child: ChunkyButton(
                          label: 'Abaikan',
                          variant: ChunkyVariant.soft,
                          size: ChunkySize.small,
                          onPressed: _tap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Wrap(
                    spacing: AppSpacing.s10,
                    runSpacing: AppSpacing.s10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CircleIconButton(
                        icon: GameIcons.pause,
                        semanticLabel: 'Jeda',
                        background: AppColors.ink,
                        iconColor: AppColors.surface,
                        iconSize: 18,
                        onPressed: _tap,
                      ),
                      CircleIconButton(
                        icon: GameIcons.back,
                        semanticLabel: 'Kembali',
                        borderColor: AppColors.surfaceLine,
                        onPressed: _tap,
                      ),
                      const RushHourBadge(),
                      const StatusChip(label: 'MACET'),
                      const StatusChip(
                        label: 'Paket 20 Mbps',
                        tone: StatusTone.neutral,
                      ),
                      const InfoPill(label: 'Waktu berhenti'),
                      TextLinkButton(label: 'Lewati', onPressed: _tap),
                    ],
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Bintang & penghitung',
              child: Wrap(
                spacing: AppSpacing.s16,
                runSpacing: AppSpacing.s12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: const [
                  StarRating(earned: 3),
                  StarRating(earned: 2),
                  StarRating(earned: 0),
                  StarIcon(filled: true, size: 64, style: StarStyle.large),
                  StarIcon(filled: false, size: 64, style: StarStyle.large),
                  StarCounterPill(value: 9, total: 36),
                  NightScope(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s8),
                      child: StarCounterPill(
                        value: 9,
                        total: 36,
                        tone: CounterTone.night,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Level di peta',
              child: Wrap(
                spacing: AppSpacing.s16,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  LevelNodeWithStars(
                    number: 3,
                    state: LevelNodeState.done,
                    stars: 3,
                    onPressed: _tap,
                  ),
                  LevelNodeWithStars(
                    number: 5,
                    state: LevelNodeState.current,
                    onPressed: _tap,
                  ),
                  const LevelNodeWithStars(
                    number: 6,
                    state: LevelNodeState.locked,
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Kartu & statistik',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LevelHeaderCard(
                    overline: 'LEVEL 5',
                    title: 'Gang Melati',
                    onBack: _tap,
                    stats: [
                      HeaderStat(
                        label: 'Sisa anggaran',
                        value: IdFormat.rupiah(850000),
                        note: '${IdFormat.rupiah(-45000)} sedang ditarik',
                        noteColor: AppColors.warningStrong,
                      ),
                      HeaderStat(
                        label: 'Target kepuasan',
                        value: '≥ ${IdFormat.percent(80)}',
                        note: 'Jam sibuk ${IdFormat.hourRange(19, 22)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Kepuasan',
                          value: IdFormat.percent(86),
                          tone: CardTone.surface,
                          centered: true,
                          valueStyle: AppTypography.titleLarge,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: StatTile(
                          label: 'Pakai',
                          value: IdFormat.mbps(8.5),
                          tone: CardTone.surface,
                          centered: true,
                          valueStyle: AppTypography.subtitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  const ProgressBar(value: 0.33),
                  const SizedBox(height: AppSpacing.s10),
                  const ProgressBar(
                    value: 0.62,
                    color: AppColors.star,
                    height: AppSizes.progressThick,
                    marker: 0.8,
                    markerColor: AppColors.ink,
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Pilih kabel',
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CableOptionCard(
                        kind: CableKind.lan,
                        name: 'LAN',
                        price: '${IdFormat.rupiah(15000)} / segmen',
                        capacity: 'Kapasitas 20 Mbps · murah',
                        selected: _cable == CableKind.lan,
                        onPressed: () => setState(() => _cable = CableKind.lan),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: CableOptionCard(
                        kind: CableKind.fiber,
                        name: 'Fiber',
                        price: '${IdFormat.rupiah(60000)} / segmen',
                        capacity: 'Kapasitas 100 Mbps · ngebut',
                        selected: _cable == CableKind.fiber,
                        onPressed: () =>
                            setState(() => _cable = CableKind.fiber),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _Section(
              title: 'Kabel terkunci',
              child: CableOptionCard(
                kind: CableKind.fiber,
                name: 'Fiber',
                price: '',
                capacity: '',
                lockedLabel: 'Terbuka di level 3',
              ),
            ),
            const _Section(
              title: 'Rumah & router',
              child: Wrap(
                children: [
                  HouseGlyph(state: HouseState.idle, label: 'Belum'),
                  HouseGlyph(
                    state: HouseState.ok,
                    patience: 0.9,
                    label: 'Lancar',
                  ),
                  HouseGlyph(
                    state: HouseState.slow,
                    patience: 0.5,
                    label: 'Lambat',
                  ),
                  HouseGlyph(
                    state: HouseState.jam,
                    patience: 0.17,
                    alarm: true,
                    label: 'Macet',
                  ),
                  RouterGlyph(label: 'Router'),
                ],
              ),
            ),
            const _Section(title: 'Kabel & trafik', child: CableSample()),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: AppCard(
        radius: AppRadius.panel,
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.title),
            const SizedBox(height: AppSpacing.s12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: AppSpacing.s6),
        Text(label, style: AppTypography.label.copyWith(letterSpacing: 0)),
      ],
    );
  }
}

class _ColorGrid extends StatelessWidget {
  static const _swatches = <(String, Color, String)>[
    ('cableLan', AppColors.cableLan, '#7F93A8 · malam #6F86A0'),
    ('cableFiber / primary', AppColors.primary, '#F2A81D · bayangan #B5760A'),
    ('traffic', AppColors.traffic, '#45E9F2 · siang #1FB5C0'),
    ('star', AppColors.star, '#F5C518 · garis #C99A00'),
    ('statusOk · lancar', AppColors.statusOk, '#2DBE6C · teks #1B8A4C'),
    ('statusSlow · lambat', AppColors.statusSlow, '#F5C518 · teks #8A6A00'),
    ('statusJam · macet', AppColors.statusJam, '#F0453A · tua #C42B21'),
    ('ink', AppColors.ink, '#1B2333 · muted #5A6578'),
    ('groundDay', AppColors.groundDay, '#EEF2F5 · titik #C9D3DD'),
    ('groundNight', AppColors.groundNight, '#0F1726 · titik #1F2B44'),
    ('surfaceNight', AppColors.surfaceNight, '#172238 · garis #24314D'),
    ('surface', AppColors.surface, '#FFFFFF · garis #D3DBE3'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 480 ? 4 : 2;
        final w = (c.maxWidth - AppSpacing.s12 * (cols - 1)) / cols;
        return Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s14,
          children: [
            for (final (name, color, note) in _swatches)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: AppRadius.buttonSmallAll,
                        border: Border.all(color: AppColors.surfaceLine),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(name, style: AppTypography.captionStrong),
                    Text(
                      note,
                      style: AppTypography.small.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TypeScale extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = <(String, TextStyle, String)>[
      ('display · 66/600', AppTypography.display, 'Sibuk'),
      ('h1 · 42/600', AppTypography.h1, 'Hari beres!'),
      (
        'clock · 36/600',
        AppTypography.clock,
        '${IdFormat.clock(20 * 60 + 15)} · ${IdFormat.rupiah(850000)}',
      ),
      ('title · 22/600', AppTypography.title, 'Mulai Hari'),
      (
        'body · 15/700',
        AppTypography.body,
        'Bang, kok lemot?? Anak saya lagi ujian online!',
      ),
      ('label · 12/800', AppTypography.label, 'LEVEL 5 · GANG MELATI'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fredoka (judul, angka besar, tombol) · Nunito (teks, label) · '
          'semua angka tabular',
          style: AppTypography.captionBold.copyWith(color: AppColors.inkMuted),
        ),
        for (final (label, style, sample) in rows)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: AppColors.inkMuted,
                    letterSpacing: 0,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(sample, style: style),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
