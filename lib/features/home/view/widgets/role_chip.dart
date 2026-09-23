import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RoleChip extends StatelessWidget {
  final bool isInternal;

  const RoleChip({super.key, required this.isInternal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isInternal ? AppTheme.statusConfirmedBg : AppTheme.statusCancelledBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isInternal ? 'Internal user' : 'Portal user',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isInternal ? AppTheme.statusConfirmedText : AppTheme.statusCancelledText,
        ),
      ),
    );
  }
}
