import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_session.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../customers/cubit/customers_cubit.dart';
import '../../customers/view/customers_page.dart';
import '../../orders/cubit/orders_cubit.dart';
import '../../orders/view/orders_page.dart';
import '../../sync/cubit/sync_cubit.dart';
import '../../sync/view/offline_banner.dart';
import '../cubit/home_tab_cubit.dart';
import 'account_page.dart';
import 'widgets/home_tab.dart';

class HomePage extends StatelessWidget {
  final UserSession session;

  const HomePage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final tabs = <HomeTab>[
      const HomeTab('Customers', Icons.people_outline_rounded, Icons.people_rounded, CustomersPage()),
      if (session.isInternalUser)
        const HomeTab('Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded, OrdersPage()),
      HomeTab('Account', Icons.person_outline_rounded, Icons.person_rounded, AccountPage(session: session)),
    ];

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeTabCubit()),
        BlocProvider(
          create: (context) =>
              SyncCubit(context.read<CustomerRepository>(), context.read<ConnectivityService>())..start(),
        ),
        BlocProvider(create: (context) => CustomersCubit(context.read<CustomerRepository>())..load()),
        if (session.isInternalUser)
          BlocProvider(create: (context) => OrdersCubit(context.read<OrderRepository>())..load()),
      ],
      child: BlocBuilder<HomeTabCubit, int>(
        builder: (context, selected) {
          final index = selected.clamp(0, tabs.length - 1);
          return Scaffold(
            backgroundColor: AppTheme.surfaceWarm,
            body: Column(
              children: [
                const OfflineBanner(),
                Expanded(
                  child: IndexedStack(index: index, children: [for (final tab in tabs) tab.page]),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: context.read<HomeTabCubit>().select,
              destinations: [
                for (final tab in tabs)
                  NavigationDestination(icon: Icon(tab.icon), selectedIcon: Icon(tab.selectedIcon), label: tab.label),
              ],
            ),
          );
        },
      ),
    );
  }
}
