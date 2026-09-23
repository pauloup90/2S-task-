import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_session.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../sync/cubit/sync_cubit.dart';
import 'widgets/role_chip.dart';

class AccountPage extends StatelessWidget {
  final UserSession session;

  const AccountPage({super.key, required this.session});

  Future<void> _confirmLogout(BuildContext context) async {
    final pending = context.read<SyncCubit>().state.pendingCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: Text(
          pending == 0
              ? 'Saved customers and orders will be removed from this device.'
              : 'You have $pending phone change${pending == 1 ? '' : 's'} not yet synced to Odoo. '
                    'Logging out will discard ${pending == 1 ? 'it' : 'them'}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.brandGold,
                    child: Text(
                      session.name.isEmpty ? '?' : session.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(session.login, style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        RoleChip(isInternal: session.isInternalUser),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!session.isInternalUser) ...[
            const SizedBox(height: 12),
            const Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                title: Text('Sales Orders are hidden'),
                subtitle: Text('Only internal users (base.group_user) can see and confirm sales orders.'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('Server'),
                  subtitle: Text(session.baseUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Database'),
                  subtitle: Text(session.database),
                ),
                const Divider(height: 1),
                BlocBuilder<SyncCubit, SyncState>(
                  builder: (context, sync) => ListTile(
                    leading: Icon(sync.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
                    title: Text(sync.isOnline ? 'Online' : 'Offline'),
                    subtitle: Text(
                      sync.pendingCount == 0
                          ? 'All changes synced'
                          : '${sync.pendingCount} phone change${sync.pendingCount == 1 ? '' : 's'} waiting to sync',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              key: const Key('logout_button'),
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.dangerBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
