import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'odoo_exceptions.dart';

export 'odoo_exceptions.dart';

class OdooAuthResult {
  final int uid;
  final String name;
  final String login;
  final Map<String, dynamic> raw;

  const OdooAuthResult({required this.uid, required this.name, required this.login, required this.raw});
}

class OdooClient {
  final Dio _dio;
  final CookieJar cookieJar;
  String _baseUrl;
  String _database;
  int _requestId = 0;

  void Function()? onSessionExpired;

  OdooClient({
    required String baseUrl,
    required String database,
    CookieJar? cookieJar,
    Dio? dio,
    Duration timeout = const Duration(seconds: 20),
  }) : _baseUrl = _normalize(baseUrl),
       _database = database,
       cookieJar = cookieJar ?? CookieJar(),
       _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = timeout
      ..receiveTimeout = timeout
      ..sendTimeout = timeout
      ..contentType = Headers.jsonContentType
      ..responseType = ResponseType.json;
    _dio.interceptors.add(CookieManager(this.cookieJar));
  }

  String get baseUrl => _baseUrl;
  String get database => _database;

  void configure({required String baseUrl, required String database}) {
    _baseUrl = _normalize(baseUrl);
    _database = database;
  }

  static String _normalize(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');

  Future<OdooAuthResult> authenticate(String login, String password) async {
    final result = await _rpc('/web/session/authenticate', {'db': _database, 'login': login, 'password': password});
    if (result is! Map || result['uid'] is! int) {
      throw const OdooAuthException('Wrong email or password.');
    }
    final map = Map<String, dynamic>.from(result);
    return OdooAuthResult(uid: map['uid'] as int, name: (map['name'] ?? login).toString(), login: login, raw: map);
  }

  Future<int?> sessionUid() async {
    try {
      final info = await _rpc('/web/session/get_session_info', {});
      if (info is Map && info['uid'] is int) return info['uid'] as int;
      return null;
    } on OdooSessionExpiredException {
      return null;
    }
  }

  Future<bool> hasSessionCookie() async {
    final cookies = await cookieJar.loadForRequest(Uri.parse(_baseUrl));
    return cookies.any((c) => c.name == 'session_id');
  }

  Future<void> logout() async {
    try {
      await _rpc('/web/session/destroy', {});
    } catch (_) {}
    await cookieJar.deleteAll();
  }

  Future<dynamic> callKw(
    String model,
    String method, {
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) {
    return _rpc('/web/dataset/call_kw', {'model': model, 'method': method, 'args': args, 'kwargs': kwargs});
  }

  Future<List<Map<String, dynamic>>> searchRead(
    String model, {
    List<dynamic> domain = const [],
    List<String> fields = const [],
    int? limit,
    int? offset,
    String? order,
  }) async {
    final result = await callKw(
      model,
      'search_read',
      kwargs: {'domain': domain, 'fields': fields, 'limit': ?limit, 'offset': ?offset, 'order': ?order},
    );
    return (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<int> searchCount(String model, List<dynamic> domain) async {
    final result = await callKw(model, 'search_count', args: [domain]);
    return result as int;
  }

  Future<int> create(String model, Map<String, dynamic> values) async {
    final result = await callKw(model, 'create', args: [values]);
    return result is List ? result.first as int : result as int;
  }

  Future<bool> write(String model, List<int> ids, Map<String, dynamic> values) async {
    final result = await callKw(model, 'write', args: [ids, values]);
    return result == true;
  }

  Future<dynamic> _rpc(String path, Map<String, dynamic> params) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post(
        '$_baseUrl$path',
        data: {'jsonrpc': '2.0', 'method': 'call', 'params': params, 'id': ++_requestId},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }

    final body = response.data;
    if (body is! Map) {
      throw const OdooServerException('Unexpected response from the Odoo server.');
    }
    if (body['error'] != null) {
      final error = _mapRpcError(body['error']);
      if (error is OdooSessionExpiredException) onSessionExpired?.call();
      throw error;
    }
    return body['result'];
  }

  OdooException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const OdooNetworkException();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) {
          return const OdooServerException('Odoo endpoint not found. Check the server URL.');
        }
        return OdooServerException('Odoo server returned HTTP $code.');
      default:
        return const OdooNetworkException();
    }
  }

  OdooException _mapRpcError(dynamic error) {
    final map = error is Map ? error : const {};
    final data = map['data'] is Map ? map['data'] as Map : const {};
    final name = (data['name'] ?? '').toString();
    final message = (data['message'] ?? map['message'] ?? 'Odoo error').toString();

    if (name.contains('SessionExpired') || map['code'] == 100) {
      return const OdooSessionExpiredException();
    }
    if (name.contains('AccessDenied')) {
      return const OdooAuthException('Wrong email or password.');
    }
    if (name.contains('AccessError')) {
      return OdooAccessException(message.split('\n').first.trim());
    }
    if (name.contains('ValidationError') || name.contains('UserError')) {
      return OdooValidationException(message);
    }
    return OdooServerException(message);
  }
}
