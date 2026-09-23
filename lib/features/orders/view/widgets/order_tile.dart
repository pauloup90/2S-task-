import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/order_status_badge.dart';
import '../../../../data/models/sale_order.dart';

class OrderTile extends StatelessWidget {
  final SaleOrder order;
  final VoidCallback onTap;

  const OrderTile({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(order.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                  OrderStatusBadge(state: order.state),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.partnerName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    Text(
                      formatDate(order.dateOrder),
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                    Text(
                      formatMoney(order.amountTotal, order.currency),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
