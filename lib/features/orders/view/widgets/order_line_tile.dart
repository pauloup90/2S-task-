import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/sale_order_line.dart';

class OrderLineTile extends StatelessWidget {
  final SaleOrderLine line;
  final String currency;

  const OrderLineTile({super.key, required this.line, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.product, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${formatQuantity(line.quantity)} × ${formatMoney(line.priceUnit, currency)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(formatMoney(line.priceSubtotal, currency), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
