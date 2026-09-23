import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/odoo/odoo_exceptions.dart';
import '../../../data/models/user_session.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(const AuthState());

  Future<void> restoreSession() async {
    try {
      final session = await _repository.restoreSession();
      emit(session == null ? const AuthState.unauthenticated() : AuthState.authenticated(session));
    } catch (_) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login({
    required String baseUrl,
    required String database,
    required String login,
    required String password,
  }) async {
    emit(state.submitting());
    try {
      final session = await _repository.login(
        baseUrl: baseUrl,
        database: database,
        login: login.trim(),
        password: password,
      );
      emit(AuthState.authenticated(session));
    } on OdooException catch (e) {
      emit(AuthState.unauthenticated(error: e.message));
    } catch (_) {
      emit(const AuthState.unauthenticated(error: 'Unexpected error while logging in.'));
    }
  }

  void sessionExpired() {
    if (state.status != AuthStatus.authenticated) return;
    emit(const AuthState.unauthenticated(error: 'Your session has expired. Please log in again.'));
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState.unauthenticated());
  }
}
