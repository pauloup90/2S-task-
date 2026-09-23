import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/customer.dart';

class CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerTile({super.key, required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = [customer.phone, customer.city].where((s) => s.isNotEmpty).join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppTheme.brandGoldLight,
          child: Text(
            customer.initials,
            style: const TextStyle(color: AppTheme.brandGold, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle.isEmpty ? customer.email : subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: customer.hasPendingSync
            ? const Tooltip(
                message: 'Phone change waiting to sync',
                child: Icon(Icons.cloud_upload_outlined, color: AppTheme.statusSyncPendingText),
              )
            : const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
