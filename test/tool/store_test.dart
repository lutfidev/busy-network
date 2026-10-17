// Materi listing Play Store ke store/ (lihat docs/RELEASE.md):
//
//   flutter test test/tool/store_test.dart --dart-define=STORE=true
//
// Screenshot ponsel 1080×1920 (layar app 390×844 dalam bingkai + judul),
// feature graphic 1024×500 (PNG 24-bit tanpa alfa, syarat Play Console),
// dan ikon 512×512. Tanpa define di atas, test ini dilewati.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busy_network/app/app.dart';
import 'package:busy_network/app/game_session.dart';
import 'package:busy_network/app/progress_book.dart';
import 'package:busy_network/app/routes.dart';
import 'package:busy_network/data/dummy_data.dart';
import 'package:busy_network/game/levels/levels.dart';
import 'package:busy_network/screens/home/home_painters.dart';
import 'package:busy_network/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/design_pull.dart';
import '../game/levels/level_plans.dart';
import '../test_helpers.dart';
import 'logo_render.dart';
import 'png_rgb.dart';

const bool _enabled = bool.fromEnvironment('STORE');

/// Kanvas screenshot (logis) × [_shotScale] = 1080×1920 (9:16).
const _shotCanvas = Size(540, 960);
const _shotScale = 2.0;

/// Kanvas feature graphic (logis) × [_graphicScale] = 1024×500.
const _graphicCanvas = Size(512, 250);
const _graphicScale = 2.0;

/// Bingkai ponsel di screenshot.
const _phoneTop = 172.0;
const _phoneBottom = 36.0;
const _phoneBezel = 8.0;
const _phoneRadius = 34.0;

final _boundary = GlobalKey();

/// Satu screenshot: judul dua baris (putih lalu oranye) di atas layar app.
class _Shot {
  const _Shot(
    this.file,
    this.head,
    this.accent, {
    required this.location,
    this.session,
    this.before,
  });

  final String file;
  final String head;
  final String accent;
  final String location;

  /// Sesi app; default = progres desain (level 5 sekarang, 9 bintang).
  final GameSession Function()? session;

  /// Aksi sebelum dipotret; gestur yang dikembalikan dilepas sesudahnya.
  final Future<TestGesture?> Function(WidgetTester)? before;
}

/// Hari level bos pukul 21:00 (puncak nobar) dengan rancangan yang aman di
/// jam biasa tapi rantai Rumah 7 → Rumah 6 penuh saat nobar (jebakan di
/// `level_balance_test.dart`), supaya tegangnya terlihat.
GameSession _bossNight() {
  const plan = Plan([
    Pull.fiber('router', 'pos'),
    Pull('router', 'r2'),
    Pull('router', 'r1'),
    Pull('router', 'r3'),
    Pull('router', 'r4'),
    Pull('router', 'r5'),
    Pull('router', 'r7'),
    Pull('router', 'r8'),
    Pull('r7', 'r6'),
  ]);
  final day = design(Levels.byNumber(12)!, plan).planDay();
  while (day.day!.minute < 21 * 60) {
    day.dismissComplaint();
    day.advanceDay(1);
  }
  day.dismissComplaint();
  return GameSession()..begin(day);
}

final _shots = <_Shot>[
  const _Shot(
    '01-jalan',
    'Jaga trafik tetap',
    'lancar di jam sibuk',
    location: AppRoutes.run,
  ),
  _Shot(
    '02-rancang',
    'Tarik kabel',
    'dari router ke rumah',
    location: AppRoutes.design,
    before: (tester) => dragOnMap(tester, designPullPath, release: false),
  ),
  const _Shot(
    '03-antrean',
    'Atur antrean,',
    'siapa didahulukan?',
    location: AppRoutes.queue,
  ),
  _Shot(
    '04-bos',
    'Bertahan saat',
    'malam final bola',
    location: AppRoutes.runOf(12),
    session: _bossNight,
  ),
  _Shot(
    '05-bintang',
    'Hemat anggaran,',
    'raih 3 bintang',
    location: '${AppRoutes.success}?${AppRoutes.starsParam}=3',
  ),
  const _Shot(
    '06-peta',
    '12 level di',
    'Perumahan Batam',
    location: AppRoutes.levelMap,
  ),
];

/// Latar malam Beranda (peta kota) yang menutup seluruh kanvas.
class _Night extends StatelessWidget {
  const _Night({required this.child, this.backdrop = 1});

  final Widget child;

  /// Opasitas peta latar.
  final double backdrop;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: AppColors.groundNight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: backdrop, child: const HomeBackdrop()),
            child,
          ],
        ),
      ),
    );
  }
}

/// Judul dua baris ala Beranda: [head] putih, [accent] oranye.
class _Title extends StatelessWidget {
  const _Title(
    this.head,
    this.accent, {
    required this.style,
    this.align = CrossAxisAlignment.center,
  });

  final String head;
  final String accent;
  final TextStyle style;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(head, style: style.copyWith(color: AppColors.inkOnDark)),
        Text(accent, style: style.copyWith(color: AppColors.primary)),
      ],
    );
  }
}

/// Layar app 390×844 (ukuran desain) diperkecil ke dalam bingkai ponsel.
class _Phone extends StatelessWidget {
  const _Phone({required this.app});

  final Widget app;

  @override
  Widget build(BuildContext context) {
    const screen = AppSizes.designCanvas;
    final media = MediaQuery.of(context).copyWith(
      size: screen,
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
      viewInsets: EdgeInsets.zero,
    );
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(_phoneBezel),
        decoration: BoxDecoration(
          color: AppColors.surfaceNightRaised,
          borderRadius: BorderRadius.circular(_phoneRadius + _phoneBezel),
          border: Border.all(color: AppColors.surfaceNightRaisedLine, width: 2),
        ),
        // Rasio di dalam bezel, supaya layar tidak ber-letterbox.
        child: AspectRatio(
          aspectRatio: screen.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_phoneRadius),
            child: FittedBox(
              child: SizedBox.fromSize(
                size: screen,
                child: MediaQuery(data: media, child: app),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simpan isi [_boundary] (kanvas logis × [scale]) ke store/[name].png.
Future<void> _save(WidgetTester tester, String name, double scale) async {
  await tester.runAsync(() async {
    await GoogleFonts.pendingFonts();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: scale);
    final file = File('store/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(await encodeRgbPng(image));
  });
}

void _canvas(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  disableAnimations(tester);
}

/// Font bundel (Nunito/Fredoka) tidak punya "→" (Antrean: "Kabel Router →
/// Rumah 4"). Di ponsel glyph itu jatuh ke font sistem; test tidak punya
/// font sistem. google_fonts memberi tiap gaya Nunito cadangan bernama
/// keluarga dasar ("Nunito") yang tidak pernah dimuat, jadi font sistem mesin
/// ini dimuat dengan nama itu.
const _systemFonts = [
  ['C:/Windows/Fonts/arial.ttf', 'C:/Windows/Fonts/arialbd.ttf'],
  [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  ],
  [
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
  ],
];

Future<void> _loadSystemFallback() async {
  final files = _systemFonts.firstWhere(
    (set) => set.every((f) => File(f).existsSync()),
    orElse: () => throw StateError(
      'Font sistem dengan glyph "→" tidak ditemukan; tambahkan ke '
      '_systemFonts.',
    ),
  );
  final loader = FontLoader(GoogleFonts.nunito().fontFamilyFallback!.single);
  for (final f in files) {
    loader.addFont(File(f).readAsBytes().then(ByteData.sublistView));
  }
  await loader.load();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUpAll(() async {
    if (_enabled) await _loadSystemFallback();
  });

  for (final shot in _shots) {
    testWidgets('screenshot ${shot.file}', (tester) async {
      _canvas(tester, _shotCanvas);
      final session =
          shot.session?.call() ??
          GameSession(progress: ProgressBook.memory(DummyData.designProgress));
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundary,
          child: _Night(
            child: Column(
              children: [
                SizedBox(
                  height: _phoneTop,
                  child: Center(
                    child: _Title(
                      shot.head,
                      shot.accent,
                      style: AppTypography.h1,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: _phoneBottom),
                    child: Center(
                      child: _Phone(
                        app: JaringanSibukApp(
                          initialLocation: shot.location,
                          session: session,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      // Hari yang berjalan (bos) tidak pernah "settle"; beri beberapa
      // bingkai tanpa memajukan jam.
      if (shot.session == null) {
        await tester.pumpAndSettle();
      } else {
        for (var i = 0; i < 3; i++) {
          await tester.pump();
        }
      }
      final gesture = await shot.before?.call(tester);
      await _save(tester, 'screenshot-${shot.file}', _shotScale);
      await gesture?.up();
    }, skip: !_enabled);
  }

  testWidgets('feature graphic', (tester) async {
    _canvas(tester, _graphicCanvas);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: _Night(
          backdrop: 0.5,
          child: DecoratedBox(
            // Redupkan peta di belakang judul supaya terbaca.
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.9,
                colors: [
                  AppColors.groundNight.withValues(alpha: 0.9),
                  AppColors.groundNight.withValues(alpha: 0),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HomeLogoTile(),
                const SizedBox(width: AppSpacing.s24),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Title(
                      'Jaringan',
                      'Sibuk',
                      style: AppTypography.display,
                      align: CrossAxisAlignment.start,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SizedBox(
                      width: 260,
                      child: Text(
                        'Tarik kabel, jaga sinyal, tenangkan satu kompleks.',
                        style: AppTypography.lead.copyWith(
                          color: AppColors.inkOnDarkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _save(tester, 'feature-graphic', _graphicScale);
  }, skip: !_enabled);

  testWidgets('ikon 512', (tester) async {
    await tester.runAsync(() async {
      // Sama dengan ikon launcher (assets/brand/icon.png), Play membulatkan
      // sudutnya sendiri.
      final image = await renderLogo(
        canvasSize: 512,
        glyphWidth: 300,
        background: AppColors.groundNight,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('store/icon-512.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }, skip: !_enabled);
}
