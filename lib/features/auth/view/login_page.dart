import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [LoginHeader(), SizedBox(height: 32), LoginForm()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
