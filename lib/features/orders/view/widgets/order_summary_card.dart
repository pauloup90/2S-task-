import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/order_status_badge.dart';
import '../../../../data/models/sale_order.dart';

class OrderSummaryCard extends StatelessWidget {
  final SaleOrder order;

  const OrderSummaryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.partnerName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                ),
                OrderStatusBadge(state: order.state),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Order date: ${formatDateTime(order.dateOrder)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
