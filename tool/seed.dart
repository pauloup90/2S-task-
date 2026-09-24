// ignore_for_file: avoid_print
import 'dart:io';

import 'package:two_s_task/core/odoo/odoo_client.dart';
import 'package:two_s_task/core/odoo/odoo_seed.dart';

import 'env.dart';

Future<void> main() async {
  final env = loadEnv();
  final url = requireEnv(env, 'ODOO_URL');
  final db = requireEnv(env, 'ODOO_DB');
  final client = OdooClient(baseUrl: url, database: db);

  try {
    final auth = await client.authenticate(requireEnv(env, 'ODOO_LOGIN'), requireEnv(env, 'ODOO_PASSWORD'));
    print('Logged in to $url ($db) as uid ${auth.uid}');

    final existing = await client.searchCount('res.partner', [
      ['ref', '=like', '${OdooSeed.refPrefix}%'],
    ]);
    if (existing > 0) {
      print('Found $existing SEED- partners: skipping customers, products and orders.');
    } else {
      final customerIds = await _seedCustomers(client);
      final productIds = await _seedProducts(client);
      await _seedOrders(client, OdooSeed.orders, customerIds, productIds);
    }

    final portal = await _ensureUser(
      client,
      url: url,
      db: db,
      name: OdooSeed.portalUserName,
      login: OdooSeed.portalUserLogin,
      password: requireEnv(env, 'SEED_PORTAL_PASSWORD'),
      groupXmlIds: ['base.group_portal'],
      expectInternal: false,
      legacyLogins: [OdooSeed.legacyPortalUserLogin],
    );
    final demo = await _ensureUser(
      client,
      url: url,
      db: db,
      name: OdooSeed.demoUserName,
      login: OdooSeed.demoUserLogin,
      password: requireEnv(env, 'SEED_DEMO_PASSWORD'),
      groupXmlIds: ['base.group_user', 'sales_team.group_sale_salesman_all_leads', 'base.group_partner_manager'],
      expectInternal: true,
    );

    await _seedReviewerData(client, portalPartnerId: portal.partnerId, demoUid: demo.uid);
    print('Done.');
  } on OdooException catch (e) {
    stderr.writeln('Seeding failed: ${e.runtimeType}: ${e.message}');
    exit(1);
  }
}

Future<Map<String, int>> _seedCustomers(OdooClient client) async {
  final egypt = await client.searchRead(
    'res.country',
    domain: [
      ['code', '=', 'EG'],
    ],
    fields: ['id'],
    limit: 1,
  );
  final countryId = egypt.isEmpty ? null : egypt.first['id'];

  final ids = <String, int>{};
  for (final c in OdooSeed.customers) {
    ids[c.ref] = await client.create('res.partner', {
      'name': c.name,
      'ref': c.ref,
      'email': c.email,
      'phone': c.phone,
      'street': c.street,
      'city': c.city,
      'country_id': ?countryId,
      'customer_rank': 1,
      'is_company': false,
    });
  }
  print('Created ${ids.length} customers');
  return ids;
}

Future<Map<String, int>> _seedProducts(OdooClient client) async {
  final ids = <String, int>{};
  for (final p in OdooSeed.products) {
    final found = await client.searchRead(
      'product.product',
      domain: [
        ['default_code', '=', p.code],
      ],
      fields: ['id'],
      limit: 1,
    );
    ids[p.code] = found.isNotEmpty
        ? found.first['id'] as int
        : await client.create('product.product', {
            'name': p.name,
            'default_code': p.code,
            'list_price': p.price,
            'type': 'consu',
            'sale_ok': true,
          });
  }
  print('Ready: ${ids.length} products');
  return ids;
}

Future<void> _seedReviewerData(OdooClient client, {required int portalPartnerId, required int demoUid}) async {
  final egypt = await client.searchRead(
    'res.country',
    domain: [
      ['code', '=', 'EG'],
    ],
    fields: ['id'],
    limit: 1,
  );
  const pc = OdooSeed.portalCustomer;
  await client.write(
    'res.partner',
    [portalPartnerId],
    {
      'ref': pc.ref,
      'phone': pc.phone,
      'street': pc.street,
      'city': pc.city,
      'country_id': ?(egypt.isEmpty ? null : egypt.first['id']),
      'customer_rank': 1,
    },
  );
  print('Portal contact is now customer ${pc.ref}');

  final customers = <String, int>{pc.ref: portalPartnerId};
  for (final row in await client.searchRead(
    'res.partner',
    domain: [
      ['ref', '=like', '${OdooSeed.refPrefix}%'],
    ],
    fields: ['ref'],
  )) {
    customers[row['ref'] as String] = row['id'] as int;
  }
  final products = <String, int>{
    for (final row in await client.searchRead(
      'product.product',
      domain: [
        ['default_code', '=like', '${OdooSeed.refPrefix}%'],
      ],
      fields: ['default_code'],
    ))
      row['default_code'] as String: row['id'] as int,
  };

  for (final (label, orders, salesperson) in [
    ('demo quotations', OdooSeed.demoOrders, demoUid),
    ('portal orders', OdooSeed.portalOrders, null),
  ]) {
    final prefix = orders.first.ref.substring(0, orders.first.ref.lastIndexOf('-') + 1);
    final count = await client.searchCount('sale.order', [
      ['client_order_ref', '=like', '$prefix%'],
    ]);
    if (count > 0) {
      print('Found $count $label: skipping');
    } else {
      await _seedOrders(client, orders, customers, products, salespersonId: salesperson);
    }
  }
}

Future<void> _seedOrders(
  OdooClient client,
  List<SeedOrder> orders,
  Map<String, int> customers,
  Map<String, int> products, {
  int? salespersonId,
}) async {
  var confirmed = 0;
  for (final o in orders) {
    final id = await client.create('sale.order', {
      'partner_id': customers[o.customerRef],
      'client_order_ref': o.ref,
      'user_id': ?salespersonId,
      'order_line': [
        for (final line in o.lines)
          [
            0,
            0,
            {'product_id': products[line.productCode], 'product_uom_qty': line.quantity},
          ],
      ],
    });
    if (o.confirm) {
      await client.callKw(
        'sale.order',
        'action_confirm',
        args: [
          [id],
        ],
      );
      confirmed++;
    }
  }
  print(
    'Created ${orders.length} sale orders ($confirmed confirmed, '
    '${orders.length - confirmed} quotations)',
  );
}

Future<({int uid, int partnerId})> _ensureUser(
  OdooClient client, {
  required String url,
  required String db,
  required String name,
  required String login,
  required String password,
  required List<String> groupXmlIds,
  required bool expectInternal,
  List<String> legacyLogins = const [],
}) async {
  final context = {'active_test': false, 'no_reset_password': true};
  final found =
      (await client.callKw(
                'res.users',
                'search_read',
                kwargs: {
                  'domain': [
                    [
                      'login',
                      'in',
                      [login, ...legacyLogins],
                    ],
                  ],
                  'fields': ['id', 'login'],
                  'limit': 1,
                  'context': context,
                },
              )
              as List)
          .cast<Map>();

  final groupIds = <int>[];
  for (final xmlId in groupXmlIds) {
    final parts = xmlId.split('.');
    final rows = await client.searchRead(
      'ir.model.data',
      domain: [
        ['module', '=', parts[0]],
        ['name', '=', parts[1]],
        ['model', '=', 'res.groups'],
      ],
      fields: ['res_id'],
      limit: 1,
    );
    if (rows.isEmpty) throw OdooServerException('Group $xmlId not found');
    groupIds.add(rows.first['res_id'] as int);
  }
  final fields =
      await client.callKw(
            'res.users',
            'fields_get',
            kwargs: {
              'allfields': ['group_ids', 'groups_id'],
              'attributes': ['type'],
            },
          )
          as Map;
  final groupField = fields.containsKey('group_ids') ? 'group_ids' : 'groups_id';

  if (found.isEmpty) {
    await client.callKw(
      'res.users',
      'create',
      args: [
        {
          'name': name,
          'login': login,
          'password': password,
          groupField: [
            [6, 0, groupIds],
          ],
        },
      ],
      kwargs: {'context': context},
    );
    print('Created user "$login"');
  } else {
    final id = found.first['id'] as int;
    await client.callKw(
      'res.users',
      'write',
      args: [
        [id],
        {
          'login': login,
          'password': password,
          'active': true,
          groupField: [
            for (final groupId in groupIds) [4, groupId],
          ],
        },
      ],
      kwargs: {'context': context},
    );
    final oldLogin = found.first['login'];
    print(oldLogin == login ? 'User "$login" exists, password reset' : 'Renamed user "$oldLogin" to "$login"');
  }

  final session = OdooClient(baseUrl: url, database: db);
  final auth = await session.authenticate(login, password);
  final rows = await session.callKw(
    'res.users',
    'read',
    args: [
      [auth.uid],
      ['share', 'partner_id'],
    ],
  );
  final share = (rows as List).first['share'] as bool;
  if (share == expectInternal) {
    throw OdooServerException('"$login" has share=$share, expected ${!expectInternal}');
  }
  print('Login OK: "$login" uid ${auth.uid}, share=$share (${share ? 'portal' : 'internal'})');
  return (uid: auth.uid, partnerId: ((rows.first as Map)['partner_id'] as List).first as int);
}
