import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/load_status.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/customer.dart';
import '../../cubit/customers_cubit.dart';
import 'customer_tile.dart';

class CustomersList extends StatelessWidget {
  final CustomersState state;
  final ValueChanged<Customer> onOpen;

  const CustomersList({super.key, required this.state, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(),
      LoadStatus.failure => ErrorView(
        message: state.error ?? 'Could not load customers.',
        onRetry: context.read<CustomersCubit>().load,
      ),
      LoadStatus.success when state.customers.isEmpty => EmptyView(
        icon: Icons.people_outline_rounded,
        title: state.query.isEmpty ? 'No customers yet' : 'No matches',
        message: state.query.isEmpty
            ? 'Customers from Odoo (customer rank > 0) will appear here.'
            : 'No customer matches "${state.query}".',
      ),
      LoadStatus.success => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.customers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) =>
            CustomerTile(customer: state.customers[i], onTap: () => onOpen(state.customers[i])),
      ),
    };
  }
}
