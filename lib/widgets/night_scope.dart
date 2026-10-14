import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Membungkus layar bertema malam: latar [AppColors.groundNight] dan
/// warna teks default [AppColors.inkOnDark].
class NightScope extends StatelessWidget {
  const NightScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.groundNight,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.inkOnDark),
        child: child,
      ),
    );
  }
}
