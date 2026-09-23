import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary)),
    );
  }
}
