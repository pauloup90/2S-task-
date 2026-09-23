import '../../core/odoo/odoo_client.dart';
import '../../core/odoo/odoo_service.dart';
import '../local/local_cache.dart';
import '../models/user_session.dart';

class AuthRepository {
  final OdooService _service;
  final LocalCache _cache;

  AuthRepository(this._service, this._cache);

  Future<UserSession> login({
    required String baseUrl,
    required String database,
    required String login,
    required String password,
  }) async {
    final session = await _service.login(baseUrl: baseUrl, database: database, login: login, password: password);
    final previous = _cache.session;
    if (previous != null && (previous.uid != session.uid || previous.baseUrl != session.baseUrl)) {
      await _cache.clearAll();
    }
    await _cache.saveSession(session);
    return session;
  }

  Future<UserSession?> restoreSession() async {
    final session = _cache.session;
    if (session == null) return null;
    _service.client.configure(baseUrl: session.baseUrl, database: session.database);
    if (!await _service.client.hasSessionCookie()) return null;
    try {
      final uid = await _service.currentSessionUid();
      return uid == session.uid ? session : null;
    } on OdooNetworkException {
      return session;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    await _cache.clearAll();
  }
}
