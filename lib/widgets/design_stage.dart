import 'package:flutter/widgets.dart';

/// Panggung berkoordinat desain: anak-anak diletakkan dengan koordinat
/// kanvas desain (mis. 390×472), lalu seluruh panggung diskalakan seragam
/// agar muat di ruang yang tersedia (lebar 360 → skala 0,92).
///
/// Ini padanan `FixedResolutionViewport` di Flame, jadi posisi dari file
/// desain bisa dipakai apa adanya.
class DesignStage extends StatelessWidget {
  const DesignStage({
    super.key,
    required this.size,
    required this.children,
    this.alignment = Alignment.center,
    this.clip = true,
  });

  final Size size;
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final stage = FittedBox(
      fit: BoxFit.contain,
      alignment: alignment,
      child: SizedBox.fromSize(
        size: size,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
    return clip ? ClipRect(child: stage) : stage;
  }
}
