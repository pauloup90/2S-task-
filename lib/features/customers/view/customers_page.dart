import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/load_status.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../sync/cubit/sync_cubit.dart';
import '../cubit/customer_detail_cubit.dart';
import '../cubit/customers_cubit.dart';
import 'customer_detail_page.dart';
import 'widgets/customers_list.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  void _openDetail(BuildContext context, Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CustomersCubit>()),
            BlocProvider.value(value: context.read<SyncCubit>()),
            BlocProvider(create: (_) => CustomerDetailCubit(context.read<CustomerRepository>(), customer)..refresh()),
          ],
          child: const CustomerDetailPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<SyncCubit, SyncState>(
          listenWhen: (a, b) => a.pending != b.pending,
          listener: (context, sync) => cubit.pendingChanged({for (final e in sync.pending) e.customerId}),
        ),
        BlocListener<SyncCubit, SyncState>(
          listenWhen: (a, b) => !a.isOnline && b.isOnline,
          listener: (context, _) {
            if (cubit.state.fromCache) cubit.refresh();
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Customers')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchField(hint: 'Search name, email, phone or reference', onChanged: cubit.search),
            ),
            Expanded(
              child: BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, state) => Column(
                  children: [
                    if (state.isRefreshing) const LinearProgressIndicator(minHeight: 2),
                    if (state.fromCache && state.status == LoadStatus.success) const CachedDataNotice(),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppTheme.brandGold,
                        onRefresh: cubit.refresh,
                        child: CustomersList(state: state, onOpen: (customer) => _openDetail(context, customer)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
