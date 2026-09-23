import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../cubit/sync_cubit.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncCubit, SyncState>(
      listenWhen: (a, b) => b.lastReport != null && a.lastReport != b.lastReport,
      listener: (context, state) {
        final report = state.lastReport!;
        context.read<SyncCubit>().reportConsumed();
        if (report.synced == 0 && report.failures.isEmpty) return;
        final parts = [
          if (report.synced > 0) '${report.synced} phone change${report.synced == 1 ? '' : 's'} synced to Odoo',
          if (report.failures.isNotEmpty) 'Rejected by Odoo: ${report.failures.join('; ')}',
        ];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parts.join('\n')),
            backgroundColor: report.failures.isEmpty ? AppTheme.statusConfirmedText : AppTheme.dangerText,
          ),
        );
      },
      builder: (context, state) {
        if (state.isOnline && state.pendingCount == 0) return const SizedBox.shrink();

        final offline = !state.isOnline;
        final text = offline
            ? (state.pendingCount > 0
                  ? 'Offline · ${state.pendingCount} change${state.pendingCount == 1 ? '' : 's'} waiting to sync'
                  : 'Offline · showing saved data')
            : '${state.pendingCount} change${state.pendingCount == 1 ? '' : 's'} waiting to sync';

        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Material(
            color: offline ? AppTheme.statusQuotationBg : AppTheme.statusSyncPendingBg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      offline ? Icons.wifi_off_rounded : Icons.sync_rounded,
                      size: 18,
                      color: AppTheme.statusQuotationText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.statusQuotationText,
                        ),
                      ),
                    ),
                    if (state.isSyncing)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (state.pendingCount > 0)
                      TextButton(onPressed: context.read<SyncCubit>().syncNow, child: const Text('Sync now')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
