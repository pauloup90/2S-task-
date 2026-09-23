import 'package:flutter/material.dart';

import '../../data/models/sale_order.dart';
import '../theme/app_theme.dart';

class OrderStatusBadge extends StatelessWidget {
  final SaleOrderState state;

  const OrderStatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      SaleOrderState.draft || SaleOrderState.sent => (AppTheme.statusQuotationBg, AppTheme.statusQuotationText),
      SaleOrderState.sale || SaleOrderState.done => (AppTheme.statusConfirmedBg, AppTheme.statusConfirmedText),
      SaleOrderState.cancel => (AppTheme.statusCancelledBg, AppTheme.statusCancelledText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        state.label,
        style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
