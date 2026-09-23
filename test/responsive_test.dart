import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:two_s_task/core/theme/app_theme.dart';
import 'package:two_s_task/core/utils/load_status.dart';
import 'package:two_s_task/data/models/customer.dart';
import 'package:two_s_task/data/models/pending_phone_edit.dart';
import 'package:two_s_task/data/models/sale_order.dart';
import 'package:two_s_task/data/models/sale_order_line.dart';
import 'package:two_s_task/data/models/user_session.dart';
import 'package:two_s_task/features/auth/cubit/auth_cubit.dart';
import 'package:two_s_task/features/auth/view/login_page.dart';
import 'package:two_s_task/features/customers/cubit/customer_detail_cubit.dart';
import 'package:two_s_task/features/customers/cubit/customers_cubit.dart';
import 'package:two_s_task/features/customers/view/customer_detail_page.dart';
import 'package:two_s_task/features/customers/view/customers_page.dart';
import 'package:two_s_task/features/home/view/account_page.dart';
import 'package:two_s_task/features/orders/cubit/order_detail_cubit.dart';
import 'package:two_s_task/features/orders/cubit/orders_cubit.dart';
import 'package:two_s_task/features/orders/view/order_detail_page.dart';
import 'package:two_s_task/features/orders/view/orders_page.dart';
import 'package:two_s_task/features/sync/cubit/sync_cubit.dart';
import 'package:two_s_task/features/sync/view/offline_banner.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockSyncCubit extends MockCubit<SyncState> implements SyncCubit {}

class _MockCustomersCubit extends MockCubit<CustomersState> implements CustomersCubit {}

class _MockCustomerDetailCubit extends MockCubit<CustomerDetailState> implements CustomerDetailCubit {}

class _MockOrdersCubit extends MockCubit<OrdersState> implements OrdersCubit {}

class _MockOrderDetailCubit extends MockCubit<OrderDetailState> implements OrderDetailCubit {}

const _longName = 'Mohamed Abdelrahman Abdelaziz El-Sayed El-Masry Trading & Distribution Co.';
const _session = UserSession(
  uid: 6,
  name: 'Demo Sales User With A Very Long Display Name',
  login: 'demo.sales.reviewer.account@example.com',
  baseUrl: 'https://a-very-long-subdomain-for-testing.odoo.com',
  database: 'production_database_with_long_name',
  isInternalUser: false,
);
const _customer = Customer(
  id: 1,
  name: _longName,
  phone: '+20 100 123 4567 ext. 8899',
  email: 'mohamed.abdelrahman.abdelaziz.elsayed@some-long-company-domain.com',
  street: '15 El-Horreya Street, Building 7, Apartment 12, Heliopolis',
  city: 'New Administrative Capital',
  country: 'Egypt',
  ref: 'SEED-01',
  hasPendingSync: true,
);
final _order = SaleOrder(
  id: 1,
  name: 'S00010/2026/CAIRO-BRANCH',
  partnerName: _longName,
  dateOrder: DateTime(2026, 9, 23, 18, 30),
  amountUntaxed: 1234567.89,
  amountTax: 172839.50,
  amountTotal: 1407407.39,
  currency: 'EGP',
);
const _line = SaleOrderLine(
  id: 1,
  product: '[SEED-P01] 2S Egyptian Cotton Men Lounge Set - Navy Blue - Extra Extra Large',
  quantity: 1250.5,
  priceUnit: 99999.99,
  priceSubtotal: 124999987.49,
  priceTotal: 142499985.74,
);
final _syncState = SyncState(
  isOnline: false,
  pending: [
    PendingPhoneEdit(customerId: 1, customerName: _longName, phone: '+20 1', createdAt: DateTime(2026)),
    PendingPhoneEdit(customerId: 2, customerName: 'B', phone: '+20 2', createdAt: DateTime(2026)),
  ],
);

void main() {
  late _MockAuthCubit auth;
  late _MockSyncCubit sync;
  late _MockCustomersCubit customers;
  late _MockCustomerDetailCubit customerDetail;
  late _MockOrdersCubit orders;
  late _MockOrderDetailCubit orderDetail;

  setUp(() {
    auth = _MockAuthCubit();
    sync = _MockSyncCubit();
    customers = _MockCustomersCubit();
    customerDetail = _MockCustomerDetailCubit();
    orders = _MockOrdersCubit();
    orderDetail = _MockOrderDetailCubit();

    when(() => auth.state).thenReturn(
      const AuthState.unauthenticated(
        error: 'Wrong email or password. Please check the server URL, the database name and your credentials.',
      ),
    );
    when(() => sync.state).thenReturn(_syncState);
    when(() => customers.state).thenReturn(
      CustomersState(
        status: LoadStatus.success,
        customers: List.generate(12, (i) => _customer.copyWith(hasPendingSync: i.isEven)),
        fromCache: true,
        isRefreshing: true,
      ),
    );
    when(() => customerDetail.state).thenReturn(const CustomerDetailState(customer: _customer, isRefreshing: true));
    when(() => orders.state).thenReturn(
      OrdersState(
        status: LoadStatus.success,
        orders: List.generate(10, (i) => _order.copyWith(state: SaleOrderState.values[i % 5])),
        fromCache: true,
      ),
    );
    when(() => orderDetail.state).thenReturn(
      OrderDetailState(order: _order, lines: const [_line, _line, _line], status: LoadStatus.success, fromCache: true),
    );
  });

  Widget wrap(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: auth),
      BlocProvider<SyncCubit>.value(value: sync),
      BlocProvider<CustomersCubit>.value(value: customers),
      BlocProvider<CustomerDetailCubit>.value(value: customerDetail),
      BlocProvider<OrdersCubit>.value(value: orders),
      BlocProvider<OrderDetailCubit>.value(value: orderDetail),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );

  final screens = <String, Widget>{
    'login': const LoginPage(),
    'customers': const CustomersPage(),
    'customer detail': const CustomerDetailPage(),
    'orders': const OrdersPage(),
    'order detail': const OrderDetailPage(),
    'account': const AccountPage(session: _session),
  };

  for (final scale in [1.0, 1.5, 2.0]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} fits a 320x568 phone at text scale $scale', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(wrap(entry.value));
        await tester.pump(const Duration(milliseconds: 500));
      });
    }
  }

  testWidgets('customer phone editor fits at text scale 2.0', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(wrap(const CustomerDetailPage()));
    await tester.ensureVisible(find.byKey(const Key('phone_edit')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('phone_edit')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('phone_field')), findsOneWidget);
  });
}
