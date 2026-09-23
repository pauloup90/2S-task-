import '../../data/models/customer.dart';
import '../../data/models/sale_order.dart';
import '../../data/models/sale_order_line.dart';
import '../../data/models/user_session.dart';
import 'odoo_client.dart';

class OdooService {
  final OdooClient client;

  OdooService(this.client);

  Future<UserSession> login({
    required String baseUrl,
    required String database,
    required String login,
    required String password,
  }) async {
    client.configure(baseUrl: baseUrl, database: database);
    final auth = await client.authenticate(login, password);
    final isInternal = await isInternalUser(auth.uid, fallback: auth.raw['is_internal_user']);
    return UserSession(
      uid: auth.uid,
      name: auth.name,
      login: login,
      baseUrl: client.baseUrl,
      database: database,
      isInternalUser: isInternal,
    );
  }

  Future<bool> isInternalUser(int uid, {dynamic fallback}) async {
    try {
      final rows = await client.callKw(
        'res.users',
        'read',
        args: [
          [uid],
          ['share'],
        ],
      );
      final share = rows is List && rows.isNotEmpty ? (rows.first as Map)['share'] : null;
      return share is bool ? !share : fallback == true;
    } on OdooAccessException {
      return fallback == true;
    }
  }

  Future<int?> currentSessionUid() => client.sessionUid();

  Future<void> logout() => client.logout();

  Future<List<Customer>> fetchCustomers({String query = '', int limit = 200}) async {
    final domain = <dynamic>[
      ['customer_rank', '>', 0],
    ];
    final q = query.trim();
    if (q.isNotEmpty) {
      domain.addAll([
        '|',
        '|',
        '|',
        ['name', 'ilike', q],
        ['email', 'ilike', q],
        ['phone', 'ilike', q],
        ['ref', 'ilike', q],
      ]);
    }
    final rows = await client.searchRead(
      'res.partner',
      domain: domain,
      fields: Customer.odooFields,
      limit: limit,
      order: 'name asc',
    );
    return rows.map(Customer.fromOdoo).toList();
  }

  Future<Customer?> fetchCustomer(int id) async {
    final rows = await client.searchRead(
      'res.partner',
      domain: [
        ['id', '=', id],
      ],
      fields: Customer.odooFields,
      limit: 1,
    );
    return rows.isEmpty ? null : Customer.fromOdoo(rows.first);
  }

  Future<void> updateCustomerPhone(int customerId, String phone) async {
    await client.write('res.partner', [customerId], {'phone': phone});
  }

  Future<List<SaleOrder>> fetchSaleOrders({String query = '', int limit = 200}) async {
    final q = query.trim();
    final rows = await client.searchRead(
      'sale.order',
      domain: q.isEmpty
          ? const []
          : [
              '|',
              ['name', 'ilike', q],
              ['partner_id', 'ilike', q],
            ],
      fields: SaleOrder.odooFields,
      limit: limit,
      order: 'date_order desc, id desc',
    );
    return rows.map(SaleOrder.fromOdoo).toList();
  }

  Future<SaleOrder?> fetchSaleOrder(int id) async {
    final rows = await client.searchRead(
      'sale.order',
      domain: [
        ['id', '=', id],
      ],
      fields: SaleOrder.odooFields,
      limit: 1,
    );
    return rows.isEmpty ? null : SaleOrder.fromOdoo(rows.first);
  }

  Future<List<SaleOrderLine>> fetchOrderLines(int orderId) async {
    final rows = await client.searchRead(
      'sale.order.line',
      domain: [
        ['order_id', '=', orderId],
        ['display_type', '=', false],
      ],
      fields: SaleOrderLine.odooFields,
      order: 'sequence asc, id asc',
    );
    return rows.map(SaleOrderLine.fromOdoo).toList();
  }

  Future<SaleOrder?> confirmSaleOrder(int orderId) async {
    await client.callKw(
      'sale.order',
      'action_confirm',
      args: [
        [orderId],
      ],
    );
    return fetchSaleOrder(orderId);
  }
}
