import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LoginErrorBox extends StatelessWidget {
  final String message;

  const LoginErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppTheme.dangerText, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
