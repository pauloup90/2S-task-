import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:two_s_task/core/odoo/odoo_exceptions.dart';
import 'package:two_s_task/core/utils/load_status.dart';
import 'package:two_s_task/data/models/customer.dart';
import 'package:two_s_task/data/models/sale_order.dart';
import 'package:two_s_task/data/models/user_session.dart';
import 'package:two_s_task/data/repositories/auth_repository.dart';
import 'package:two_s_task/data/repositories/customer_repository.dart';
import 'package:two_s_task/data/repositories/order_repository.dart';
import 'package:two_s_task/features/auth/cubit/auth_cubit.dart';
import 'package:two_s_task/features/customers/cubit/customer_detail_cubit.dart';
import 'package:two_s_task/features/customers/cubit/customers_cubit.dart';
import 'package:two_s_task/features/orders/cubit/order_detail_cubit.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockOrderRepository extends Mock implements OrderRepository {}

const _session = UserSession(
  uid: 2,
  name: 'hamdy',
  login: 'user@example.com',
  baseUrl: 'https://example.odoo.com',
  database: 'db',
  isInternalUser: true,
);
const _ahmed = Customer(id: 1, name: 'Ahmed', phone: '+20 100 000 0000');
const _salma = Customer(id: 2, name: 'Salma', phone: '+20 109 000 0000');
const _quotation = SaleOrder(id: 10, name: 'S00010', partnerName: 'Ahmed', amountTotal: 550);

void main() {
  setUpAll(() {
    registerFallbackValue(_ahmed);
    registerFallbackValue(_quotation);
  });

  group('AuthCubit', () {
    late _MockAuthRepository repo;
    setUp(() => repo = _MockAuthRepository());

    Future<UserSession> login() => repo.login(
      baseUrl: any(named: 'baseUrl'),
      database: any(named: 'database'),
      login: any(named: 'login'),
      password: any(named: 'password'),
    );

    blocTest<AuthCubit, AuthState>(
      'emits authenticated on valid credentials',
      setUp: () => when(login).thenAnswer((_) async => _session),
      build: () => AuthCubit(repo),
      act: (c) => c.login(baseUrl: 'u', database: 'd', login: ' user@example.com ', password: 'p'),
      expect: () => [const AuthState(isSubmitting: true), const AuthState.authenticated(_session)],
      verify: (_) => verify(() => repo.login(baseUrl: 'u', database: 'd', login: 'user@example.com', password: 'p')),
    );

    blocTest<AuthCubit, AuthState>(
      'emits the Odoo error on wrong password',
      setUp: () => when(login).thenThrow(const OdooAuthException('Wrong email or password.')),
      build: () => AuthCubit(repo),
      act: (c) => c.login(baseUrl: 'u', database: 'd', login: 'x', password: 'y'),
      expect: () => [
        const AuthState(isSubmitting: true),
        const AuthState.unauthenticated(error: 'Wrong email or password.'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'restores a saved session on startup',
      setUp: () => when(() => repo.restoreSession()).thenAnswer((_) async => _session),
      build: () => AuthCubit(repo),
      act: (c) => c.restoreSession(),
      expect: () => [const AuthState.authenticated(_session)],
    );

    blocTest<AuthCubit, AuthState>(
      'logout returns to the login screen',
      setUp: () => when(() => repo.logout()).thenAnswer((_) async {}),
      build: () => AuthCubit(repo),
      seed: () => const AuthState.authenticated(_session),
      act: (c) => c.logout(),
      expect: () => [const AuthState.unauthenticated()],
    );
  });

  group('CustomersCubit', () {
    late _MockCustomerRepository repo;
    setUp(() => repo = _MockCustomerRepository());

    blocTest<CustomersCubit, CustomersState>(
      'loads customers',
      setUp: () => when(
        () => repo.getCustomers(query: any(named: 'query')),
      ).thenAnswer((_) async => const CustomersResult([_ahmed, _salma])),
      build: () => CustomersCubit(repo),
      act: (c) => c.load(),
      expect: () => [
        const CustomersState(status: LoadStatus.loading),
        const CustomersState(status: LoadStatus.success, customers: [_ahmed, _salma]),
      ],
    );

    blocTest<CustomersCubit, CustomersState>(
      'shows an error state when the first load fails',
      setUp: () =>
          when(() => repo.getCustomers(query: any(named: 'query'))).thenThrow(const OdooAccessException('No access')),
      build: () => CustomersCubit(repo),
      act: (c) => c.load(),
      expect: () => [
        const CustomersState(status: LoadStatus.loading),
        const CustomersState(status: LoadStatus.failure, error: 'No access'),
      ],
    );

    blocTest<CustomersCubit, CustomersState>(
      'debounces search and queries the repository once',
      setUp: () => when(
        () => repo.getCustomers(query: any(named: 'query')),
      ).thenAnswer((_) async => const CustomersResult([_salma])),
      build: () => CustomersCubit(repo, searchDebounce: const Duration(milliseconds: 10)),
      act: (c) async {
        c.search('Sa');
        c.search('Sal');
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (c) {
        verify(() => repo.getCustomers(query: 'Sal')).called(1);
        verifyNever(() => repo.getCustomers(query: 'Sa'));
        expect(c.state.customers, [_salma]);
      },
    );
  });

  group('CustomerDetailCubit', () {
    late _MockCustomerRepository repo;
    setUp(() => repo = _MockCustomerRepository());

    Future<PhoneUpdateOutcome> update() => repo.updatePhone(any(), any(), offline: any(named: 'offline'));

    blocTest<CustomerDetailCubit, CustomerDetailState>(
      'saves the phone in Odoo when online',
      setUp: () => when(update).thenAnswer((_) async => PhoneUpdateOutcome.synced),
      build: () => CustomerDetailCubit(repo, _ahmed),
      act: (c) => c.savePhone(' +20 111 222 3333 ', offline: false),
      expect: () => [
        const CustomerDetailState(customer: _ahmed, isSaving: true),
        CustomerDetailState(
          customer: _ahmed.copyWith(phone: '+20 111 222 3333'),
          saveResult: PhoneSaveResult.synced,
        ),
      ],
    );

    blocTest<CustomerDetailCubit, CustomerDetailState>(
      'marks the edit as pending when queued offline',
      setUp: () => when(update).thenAnswer((_) async => PhoneUpdateOutcome.queued),
      build: () => CustomerDetailCubit(repo, _ahmed),
      act: (c) => c.savePhone('+20 111 222 3333', offline: true),
      skip: 1,
      expect: () => [
        CustomerDetailState(
          customer: _ahmed.copyWith(phone: '+20 111 222 3333', hasPendingSync: true),
          saveResult: PhoneSaveResult.queued,
        ),
      ],
    );

    blocTest<CustomerDetailCubit, CustomerDetailState>(
      'reports a failure Odoo rejects (e.g. portal user without write access)',
      setUp: () => when(update).thenThrow(const OdooAccessException('Not allowed')),
      build: () => CustomerDetailCubit(repo, _ahmed),
      act: (c) => c.savePhone('+20 111 222 3333', offline: false),
      skip: 1,
      expect: () => [
        const CustomerDetailState(customer: _ahmed, error: 'Not allowed', saveResult: PhoneSaveResult.failed),
      ],
    );

    test('validatePhone', () {
      expect(CustomerDetailCubit.validatePhone(''), isNotNull);
      expect(CustomerDetailCubit.validatePhone('abc'), isNotNull);
      expect(CustomerDetailCubit.validatePhone('123'), isNotNull);
      expect(CustomerDetailCubit.validatePhone('+20 (100) 123-4567'), isNull);
    });
  });

  group('OrderDetailCubit', () {
    late _MockOrderRepository repo;
    setUp(() => repo = _MockOrderRepository());

    blocTest<OrderDetailCubit, OrderDetailState>(
      'confirms a quotation',
      setUp: () =>
          when(() => repo.confirm(any())).thenAnswer((_) async => _quotation.copyWith(state: SaleOrderState.sale)),
      build: () => OrderDetailCubit(repo, _quotation),
      seed: () => const OrderDetailState(order: _quotation, status: LoadStatus.success),
      act: (c) => c.confirm(),
      expect: () => [
        const OrderDetailState(order: _quotation, status: LoadStatus.success, isConfirming: true),
        OrderDetailState(
          order: _quotation.copyWith(state: SaleOrderState.sale),
          status: LoadStatus.success,
          confirmResult: ConfirmResult.confirmed,
        ),
      ],
    );

    blocTest<OrderDetailCubit, OrderDetailState>(
      'does nothing for an already confirmed order',
      build: () => OrderDetailCubit(repo, _quotation.copyWith(state: SaleOrderState.sale)),
      act: (c) => c.confirm(),
      expect: () => const <OrderDetailState>[],
      verify: (_) => verifyNever(() => repo.confirm(any())),
    );
  });
}
