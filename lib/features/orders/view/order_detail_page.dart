import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/load_status.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/sale_order.dart';
import '../cubit/order_detail_cubit.dart';
import '../cubit/orders_cubit.dart';
import 'widgets/order_line_tile.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/order_totals_card.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  Future<void> _confirm(BuildContext context, SaleOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm ${order.name}?'),
        content: Text(
          'The quotation for ${order.partnerName} '
          '(${formatMoney(order.amountTotal, order.currency)}) becomes a sales order in Odoo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<OrderDetailCubit>().confirm();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDetailCubit, OrderDetailState>(
      listenWhen: (a, b) => b.confirmResult != ConfirmResult.none,
      listener: (context, state) {
        final confirmed = state.confirmResult == ConfirmResult.confirmed;
        if (confirmed) context.read<OrdersCubit>().orderChanged(state.order);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(confirmed ? '${state.order.name} confirmed.' : state.error ?? 'Could not confirm the order.'),
            backgroundColor: confirmed ? AppTheme.statusConfirmedText : AppTheme.dangerText,
          ),
        );
      },
      builder: (context, state) {
        final order = state.order;
        final cubit = context.read<OrderDetailCubit>();
        return Scaffold(
          backgroundColor: AppTheme.surfaceWarm,
          appBar: AppBar(title: Text(order.name)),
          bottomNavigationBar: order.state.canConfirm && state.status == LoadStatus.success
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        key: const Key('confirm_order'),
                        onPressed: state.isConfirming ? null : () => _confirm(context, order),
                        icon: state.isConfirming
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(state.isConfirming ? 'Confirming...' : 'Confirm order'),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.brandGold),
                      ),
                    ),
                  ),
                )
              : null,
          body: RefreshIndicator(
            color: AppTheme.brandGold,
            onRefresh: cubit.load,
            child: switch (state.status) {
              LoadStatus.initial || LoadStatus.loading => const LoadingView(),
              LoadStatus.failure => ErrorView(
                message: state.error ?? 'Could not load this order.',
                onRetry: cubit.load,
              ),
              LoadStatus.success => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.fromCache) ...[
                    const ClipRRect(borderRadius: BorderRadius.all(Radius.circular(10)), child: CachedDataNotice()),
                    const SizedBox(height: 12),
                  ],
                  OrderSummaryCard(order: order),
                  const SizedBox(height: 16),
                  Text(
                    'Order lines (${state.lines.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (state.lines.isEmpty)
                    const Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'This order has no product lines.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < state.lines.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            OrderLineTile(line: state.lines[i], currency: order.currency),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  OrderTotalsCard(order: order),
                ],
              ),
            },
          ),
        );
      },
    );
  }
}
