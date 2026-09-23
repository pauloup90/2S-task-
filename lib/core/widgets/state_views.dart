import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _ScrollableFill extends StatelessWidget {
  final Widget child;

  const _ScrollableFill({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(padding: const EdgeInsets.all(32), child: child),
          ),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: AppTheme.brandGold));
}

class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return _ScrollableFill(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: iconColor ?? AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => MessageView(
    icon: Icons.cloud_off_rounded,
    iconColor: AppTheme.danger,
    title: 'Something went wrong',
    message: message,
    actionLabel: 'Try again',
    onAction: onRetry,
  );
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const EmptyView({super.key, required this.icon, required this.title, this.message});

  @override
  Widget build(BuildContext context) => MessageView(icon: icon, title: title, message: message);
}

class CachedDataNotice extends StatelessWidget {
  const CachedDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.statusQuotationBg,
      child: const Row(
        children: [
          Icon(Icons.history_rounded, size: 16, color: AppTheme.statusQuotationText),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing saved data. Pull down to refresh when you are back online.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.statusQuotationText, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
