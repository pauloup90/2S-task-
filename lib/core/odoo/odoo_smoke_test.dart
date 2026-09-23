import 'odoo_client.dart';

class SmokeCheck {
  final String name;
  final bool passed;
  final String detail;

  const SmokeCheck(this.name, this.passed, this.detail);

  @override
  String toString() => '${passed ? 'PASS' : 'FAIL'}  $name  ($detail)';
}

class OdooSmokeTest {
  final OdooClient client;

  OdooSmokeTest(this.client);

  Future<List<SmokeCheck>> run({required String login, required String password}) async {
    final checks = <SmokeCheck>[];

    Future<bool> step(String name, Future<String> Function() body) async {
      try {
        checks.add(SmokeCheck(name, true, await body()));
        return true;
      } on OdooException catch (e) {
        checks.add(SmokeCheck(name, false, '${e.runtimeType}: ${e.message}'));
        return false;
      }
    }

    late OdooAuthResult auth;
    final loggedIn = await step('authenticate', () async {
      auth = await client.authenticate(login, password);
      final hasCookie = await client.hasSessionCookie();
      if (!hasCookie) throw const OdooServerException('no session_id cookie returned');
      return 'uid=${auth.uid}, session_id cookie stored';
    });
    if (!loggedIn) return checks;

    await step('session info', () async => 'uid=${await client.sessionUid()}');
    await step('res.users share', () async {
      final rows = await client.callKw(
        'res.users',
        'read',
        args: [
          [auth.uid],
          ['share'],
        ],
      );
      return 'share=${(rows as List).first['share']}';
    });
    await step('customers search_read', () async {
      final rows = await client.searchRead(
        'res.partner',
        domain: [
          ['customer_rank', '>', 0],
        ],
        fields: ['name'],
        limit: 5,
      );
      return '${rows.length} rows';
    });
    await step('sale.order search_read', () async {
      final rows = await client.searchRead('sale.order', fields: ['name', 'state'], limit: 5);
      return '${rows.length} rows';
    });
    return checks;
  }
}
