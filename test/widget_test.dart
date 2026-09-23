import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:two_s_task/core/odoo/odoo_exceptions.dart';
import 'package:two_s_task/data/repositories/auth_repository.dart';
import 'package:two_s_task/features/auth/cubit/auth_cubit.dart';
import 'package:two_s_task/features/auth/view/login_page.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUp(() => repo = _MockAuthRepository());

  Widget app(AuthCubit cubit) => BlocProvider.value(
    value: cubit,
    child: const MaterialApp(home: LoginPage()),
  );

  testWidgets('login screen validates empty fields', (tester) async {
    await tester.pumpWidget(app(AuthCubit(repo)));

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyZeroInteractions(repo);
  });

  testWidgets('login screen submits typed credentials and shows Odoo errors', (tester) async {
    when(
      () => repo.login(
        baseUrl: any(named: 'baseUrl'),
        database: any(named: 'database'),
        login: any(named: 'login'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const OdooAuthException('Wrong email or password.'));

    await tester.pumpWidget(app(AuthCubit(repo)));
    await tester.enterText(find.byKey(const Key('login_email')), 'user@example.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'wrong');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Wrong email or password.'), findsOneWidget);
    verify(
      () => repo.login(
        baseUrl: 'https://2stask.odoo.com',
        database: '2stask',
        login: 'user@example.com',
        password: 'wrong',
      ),
    ).called(1);
  });
}
