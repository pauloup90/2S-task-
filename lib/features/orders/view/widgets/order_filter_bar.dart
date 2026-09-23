import 'package:flutter/material.dart';

import '../../cubit/orders_cubit.dart';

class OrderFilterBar extends StatelessWidget {
  final OrderFilter selected;
  final ValueChanged<OrderFilter> onSelected;

  const OrderFilterBar({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            for (final filter in OrderFilter.values) ...[
              ChoiceChip(
                label: Text(filter.label),
                selected: selected == filter,
                onSelected: (_) => onSelected(filter),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}
