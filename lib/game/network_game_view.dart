import 'package:flame/game.dart' hide RouterComponent;
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import '../widgets/design_stage.dart';
import 'model/model.dart';
import 'network_game.dart';

/// Peta jaringan di layar level: [NetworkGame] dalam `GameWidget`, dengan
/// overlay Flutter (tooltip biaya, penanda sorotan tutorial) di atasnya.
///
/// Peta mengisi kotak rasio 390×472 terbesar yang muat, diletakkan menurut
/// [alignment]. [overlays] diletakkan dengan koordinat peta (Positioned di
/// atas 390×472) dan ikut diskalakan bersama peta.
///
/// Game dibuat sekali; [state] baru diteruskan ke game yang sama. Peta diam
/// bila setelan "hapus animasi" (`MediaQuery.disableAnimations`) aktif atau
/// rutenya tertutup rute lain (`TickerMode` mati; loop Flame tidak ikut
/// `TickerMode` sendiri). Peta tidak bisa difokus: hanya sentuhan.
class NetworkGameView extends StatefulWidget {
  const NetworkGameView({
    super.key,
    required this.state,
    this.overlays = const [],
    this.semanticLabel,
    this.alignment = Alignment.center,
  });

  final GameState state;
  final List<Widget> overlays;
  final String? semanticLabel;
  final AlignmentGeometry alignment;

  @override
  State<NetworkGameView> createState() => _NetworkGameViewState();
}

class _NetworkGameViewState extends State<NetworkGameView> {
  late final NetworkGame _game = NetworkGame(state: widget.state);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game.animate =
        TickerMode.valuesOf(context).enabled &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  @override
  void didUpdateWidget(NetworkGameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.state = widget.state;
  }

  @override
  Widget build(BuildContext context) {
    const size = AppSizes.mapArea;
    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      child: ClipRect(
        child: Align(
          alignment: widget.alignment,
          child: AspectRatio(
            aspectRatio: size.aspectRatio,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ExcludeFocus(
                    child: GameWidget(game: _game, autofocus: false),
                  ),
                ),
                Positioned.fill(
                  child: DesignStage(
                    size: size,
                    clip: false,
                    children: widget.overlays,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
