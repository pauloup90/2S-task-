import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/connectivity_service.dart';
import 'core/odoo/odoo_client.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/state_views.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/order_repository.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/view/login_page.dart';
import 'features/home/view/home_page.dart';

class App extends StatelessWidget {
  final OdooClient client;
  final AuthRepository authRepository;
  final CustomerRepository customerRepository;
  final OrderRepository orderRepository;
  final ConnectivityService connectivity;

  const App({
    super.key,
    required this.client,
    required this.authRepository,
    required this.customerRepository,
    required this.orderRepository,
    required this.connectivity,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: customerRepository),
        RepositoryProvider.value(value: orderRepository),
        RepositoryProvider.value(value: connectivity),
      ],
      child: BlocProvider(
        create: (_) {
          final cubit = AuthCubit(authRepository)..restoreSession();
          client.onSessionExpired = cubit.sessionExpired;
          return cubit;
        },
        child: MaterialApp(
          title: '2S Sales',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (a, b) => a.status != b.status || a.session != b.session,
            builder: (context, state) => switch (state.status) {
              AuthStatus.unknown => const Scaffold(body: LoadingView()),
              AuthStatus.unauthenticated => const LoginPage(),
              AuthStatus.authenticated => HomePage(key: ValueKey(state.session!.uid), session: state.session!),
            },
          ),
        ),
      ),
    );
  }
}
