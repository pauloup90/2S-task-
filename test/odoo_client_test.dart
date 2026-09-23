import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:two_s_task/core/odoo/odoo_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Object? Function(RequestOptions options, Map<String, dynamic> body) handler;
  final requests = <(String, Map<String, dynamic>)>[];

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body =
        jsonDecode(options.data is String ? options.data as String : jsonEncode(options.data)) as Map<String, dynamic>;
    requests.add((options.path, body));
    final result = handler(options, body);
    if (result is DioException) throw result;
    return ResponseBody.fromString(
      jsonEncode(result),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        'set-cookie': ['session_id=abc123; Path=/; HttpOnly'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

OdooClient _client(_FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return OdooClient(baseUrl: 'https://example.odoo.com/', database: 'db', dio: dio);
}

Map<String, dynamic> _error(String name, {String message = 'boom', int code = 200}) => {
  'jsonrpc': '2.0',
  'id': 1,
  'error': {
    'code': code,
    'message': 'Odoo Server Error',
    'data': {'name': name, 'message': message},
  },
};

void main() {
  test('authenticate posts db/login/password and stores the session cookie', () async {
    final adapter = _FakeAdapter(
      (_, _) => {
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'uid': 2, 'name': 'hamdy'},
      },
    );
    final client = _client(adapter);

    final auth = await client.authenticate('user@example.com', 'secret');

    expect(auth.uid, 2);
    expect(adapter.requests.single.$1, 'https://example.odoo.com/web/session/authenticate');
    expect(adapter.requests.single.$2['params'], {'db': 'db', 'login': 'user@example.com', 'password': 'secret'});
    expect(await client.hasSessionCookie(), isTrue);
  });

  test('searchRead goes through /web/dataset/call_kw with kwargs', () async {
    final adapter = _FakeAdapter(
      (_, _) => {
        'jsonrpc': '2.0',
        'id': 1,
        'result': [
          {'id': 1, 'name': 'A'},
        ],
      },
    );
    final rows = await _client(adapter).searchRead(
      'res.partner',
      domain: [
        ['customer_rank', '>', 0],
      ],
      fields: ['name'],
      limit: 5,
    );

    expect(rows.single['name'], 'A');
    final (path, body) = adapter.requests.single;
    expect(path, endsWith('/web/dataset/call_kw'));
    expect(body['params']['model'], 'res.partner');
    expect(body['params']['method'], 'search_read');
    expect(body['params']['kwargs']['limit'], 5);
  });

  test('AccessDenied maps to OdooAuthException', () async {
    final client = _client(_FakeAdapter((_, _) => _error('odoo.exceptions.AccessDenied')));
    expect(client.authenticate('a', 'b'), throwsA(isA<OdooAuthException>()));
  });

  test('session expiry throws and notifies the app', () async {
    var notified = false;
    final client = _client(_FakeAdapter((_, _) => _error('odoo.http.SessionExpiredException', code: 100)))
      ..onSessionExpired = () => notified = true;

    await expectLater(client.searchRead('res.partner'), throwsA(isA<OdooSessionExpiredException>()));
    expect(notified, isTrue);
  });

  test('AccessError and ValidationError keep the Odoo message', () async {
    final access = _client(
      _FakeAdapter(
        (_, _) => _error(
          'odoo.exceptions.AccessError',
          message: 'No access\n\nThis operation is allowed for the following groups:\n\t- Sales / User',
        ),
      ),
    );
    await expectLater(
      access.write('res.partner', [1], {'phone': '1'}),
      throwsA(isA<OdooAccessException>().having((e) => e.message, 'message', 'No access')),
    );
    final validation = _client(_FakeAdapter((_, _) => _error('odoo.exceptions.ValidationError')));
    expect(validation.write('res.partner', [1], {}), throwsA(isA<OdooValidationException>()));
  });

  test('connection failures map to OdooNetworkException', () async {
    final client = _client(
      _FakeAdapter((options, _) => DioException.connectionError(requestOptions: options, reason: 'offline')),
    );
    expect(client.searchRead('res.partner'), throwsA(isA<OdooNetworkException>()));
  });
}
