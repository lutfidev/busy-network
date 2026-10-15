import 'package:flutter/widgets.dart';

/// Kolom setinggi layar yang otomatis bisa di-scroll bila layar terlalu
/// pendek. `Spacer`/`Expanded` di [child] tetap bekerja di layar tinggi.
class FillScrollView extends StatelessWidget {
  const FillScrollView({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight -
                  (padding?.vertical ?? 0).clamp(0, constraints.maxHeight),
            ),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}
