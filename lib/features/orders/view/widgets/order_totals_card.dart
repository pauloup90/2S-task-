import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/sale_order.dart';

class OrderTotalsCard extends StatelessWidget {
  final SaleOrder order;

  const OrderTotalsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, double value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            formatMoney(value, order.currency),
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 17 : 14),
          ),
        ],
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row('Untaxed amount', order.amountUntaxed),
            row('Taxes', order.amountTax),
            const Divider(height: 16),
            row('Total', order.amountTotal, bold: true),
          ],
        ),
      ),
    );
  }
}
