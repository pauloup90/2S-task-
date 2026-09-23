import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/customer.dart';

class CustomerHeaderCard extends StatelessWidget {
  final Customer customer;

  const CustomerHeaderCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.brandGoldLight,
              child: Text(
                customer.initials,
                style: const TextStyle(color: AppTheme.brandGold, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  if (customer.city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(customer.city, style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
