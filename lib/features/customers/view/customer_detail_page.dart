import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../sync/cubit/sync_cubit.dart';
import '../cubit/customer_detail_cubit.dart';
import '../cubit/customers_cubit.dart';
import 'widgets/customer_header_card.dart';
import 'widgets/customer_phone_card.dart';
import 'widgets/info_row.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomerDetailCubit, CustomerDetailState>(
          listenWhen: (a, b) => b.saveResult != PhoneSaveResult.none,
          listener: (context, state) {
            final (text, color) = switch (state.saveResult) {
              PhoneSaveResult.synced => ('Phone number updated in Odoo.', AppTheme.statusConfirmedText),
              PhoneSaveResult.queued => (
                'You are offline. The change is saved and will sync automatically.',
                AppTheme.statusSyncPendingText,
              ),
              _ => (state.error ?? 'Could not update the phone number.', AppTheme.dangerText),
            };
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
            if (state.saveResult != PhoneSaveResult.failed) {
              context.read<CustomersCubit>().customerChanged(state.customer);
            }
          },
        ),
        BlocListener<SyncCubit, SyncState>(
          listenWhen: (a, b) => a.pending != b.pending,
          listener: (context, sync) =>
              context.read<CustomerDetailCubit>().pendingChanged({for (final e in sync.pending) e.customerId}),
        ),
      ],
      child: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
        builder: (context, state) {
          final customer = state.customer;
          return Scaffold(
            backgroundColor: AppTheme.surfaceWarm,
            appBar: AppBar(title: const Text('Customer')),
            body: RefreshIndicator(
              color: AppTheme.brandGold,
              onRefresh: context.read<CustomerDetailCubit>().refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 2, child: state.isRefreshing ? const LinearProgressIndicator(minHeight: 2) : null),
                    CustomerHeaderCard(customer: customer),
                    const SizedBox(height: 12),
                    CustomerPhoneCard(
                      key: ValueKey('phone-${customer.id}'),
                      customer: customer,
                      isSaving: state.isSaving,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          InfoRow(icon: Icons.email_outlined, label: 'Email', value: customer.email),
                          const Divider(height: 1),
                          InfoRow(icon: Icons.place_outlined, label: 'Address', value: customer.address),
                          const Divider(height: 1),
                          InfoRow(icon: Icons.tag_rounded, label: 'Reference', value: customer.ref),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
