import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Center(
              child: Text(
                '2S',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.brandGold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sales Portal',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text('Sign in with your Odoo account', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
      ],
    );
  }
}
