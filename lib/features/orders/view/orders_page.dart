import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/load_status.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/sale_order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../sync/cubit/sync_cubit.dart';
import '../cubit/order_detail_cubit.dart';
import '../cubit/orders_cubit.dart';
import 'order_detail_page.dart';
import 'widgets/order_filter_bar.dart';
import 'widgets/orders_list.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  void _openDetail(BuildContext context, SaleOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<OrdersCubit>()),
            BlocProvider(create: (_) => OrderDetailCubit(context.read<OrderRepository>(), order)..load()),
          ],
          child: const OrderDetailPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrdersCubit>();
    return BlocListener<SyncCubit, SyncState>(
      listenWhen: (a, b) => !a.isOnline && b.isOnline,
      listener: (context, _) {
        if (cubit.state.fromCache) cubit.refresh();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Sales Orders')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SearchField(hint: 'Search order number or customer', onChanged: cubit.search),
            ),
            BlocSelector<OrdersCubit, OrdersState, OrderFilter>(
              selector: (state) => state.filter,
              builder: (context, filter) => OrderFilterBar(selected: filter, onSelected: cubit.setFilter),
            ),
            Expanded(
              child: BlocBuilder<OrdersCubit, OrdersState>(
                builder: (context, state) => Column(
                  children: [
                    if (state.isRefreshing) const LinearProgressIndicator(minHeight: 2),
                    if (state.fromCache && state.status == LoadStatus.success) const CachedDataNotice(),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppTheme.brandGold,
                        onRefresh: cubit.refresh,
                        child: OrdersList(state: state, onOpen: (order) => _openDetail(context, order)),
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
