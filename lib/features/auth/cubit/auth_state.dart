part of 'auth_cubit.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserSession? session;
  final bool isSubmitting;
  final String? error;

  const AuthState({this.status = AuthStatus.unknown, this.session, this.isSubmitting = false, this.error});

  const AuthState.unauthenticated({String? error}) : this(status: AuthStatus.unauthenticated, error: error);

  const AuthState.authenticated(UserSession session) : this(status: AuthStatus.authenticated, session: session);

  AuthState submitting() => AuthState(status: status, session: session, isSubmitting: true);

  @override
  List<Object?> get props => [status, session, isSubmitting, error];
}
