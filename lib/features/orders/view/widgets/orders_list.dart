import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/load_status.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/sale_order.dart';
import '../../cubit/orders_cubit.dart';
import 'order_tile.dart';

class OrdersList extends StatelessWidget {
  final OrdersState state;
  final ValueChanged<SaleOrder> onOpen;

  const OrdersList({super.key, required this.state, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final visible = state.visibleOrders;
    return switch (state.status) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(),
      LoadStatus.failure => ErrorView(
        message: state.error ?? 'Could not load sales orders.',
        onRetry: context.read<OrdersCubit>().load,
      ),
      LoadStatus.success when visible.isEmpty => EmptyView(
        icon: Icons.receipt_long_outlined,
        title: state.query.isEmpty && state.filter == OrderFilter.all ? 'No sales orders yet' : 'No matches',
        message: state.query.isEmpty ? 'No orders to show.' : 'No order matches "${state.query}".',
      ),
      LoadStatus.success => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => OrderTile(order: visible[i], onTap: () => onOpen(visible[i])),
      ),
    };
  }
}
