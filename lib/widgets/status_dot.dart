import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

enum ServiceStatus {
  ok('Lancar', AppColors.statusOk, AppColors.statusOkText),
  slow('Mulai lambat', AppColors.statusSlow, AppColors.starStroke),
  jam('Macet', AppColors.statusJam, AppColors.statusJamDark);

  const ServiceStatus(this.label, this.color, this.ring);

  final String label;
  final Color color;
  final Color ring;
}

/// Titik status 14 px dengan cincin putih + garis luar (daftar antrean).
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status});

  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: [BoxShadow(color: status.ring, spreadRadius: 1)],
      ),
    );
  }
}
