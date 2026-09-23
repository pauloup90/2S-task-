import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/customer.dart';
import '../models/pending_phone_edit.dart';
import '../models/sale_order.dart';
import '../models/sale_order_line.dart';
import '../models/user_session.dart';

class LocalCache {
  static const _sessionBox = 'session';
  static const _customersBox = 'customers';
  static const _ordersBox = 'orders';
  static const _orderLinesBox = 'order_lines';
  static const _queueBox = 'phone_queue';

  final Box<String> _session;
  final Box<String> _customers;
  final Box<String> _orders;
  final Box<String> _orderLines;
  final Box<String> _queue;

  LocalCache._(this._session, this._customers, this._orders, this._orderLines, this._queue);

  static Future<LocalCache> open() async {
    await Hive.initFlutter();
    return LocalCache._(
      await Hive.openBox<String>(_sessionBox),
      await Hive.openBox<String>(_customersBox),
      await Hive.openBox<String>(_ordersBox),
      await Hive.openBox<String>(_orderLinesBox),
      await Hive.openBox<String>(_queueBox),
    );
  }

  UserSession? get session {
    final raw = _session.get('current');
    return raw == null ? null : UserSession.fromJson(_decode(raw));
  }

  Future<void> saveSession(UserSession session) => _session.put('current', jsonEncode(session.toJson()));

  List<Customer> get customers {
    final list = _customers.values.map((raw) => Customer.fromJson(_decode(raw))).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Customer? customer(int id) {
    final raw = _customers.get(id.toString());
    return raw == null ? null : Customer.fromJson(_decode(raw));
  }

  Future<void> replaceCustomers(List<Customer> customers) async {
    await _customers.clear();
    await putCustomers(customers);
  }

  Future<void> putCustomers(List<Customer> customers) =>
      _customers.putAll({for (final c in customers) c.id.toString(): jsonEncode(c.toJson())});

  List<SaleOrder> get orders {
    final list = _orders.values.map((raw) => SaleOrder.fromJson(_decode(raw))).toList();
    list.sort((a, b) => (b.dateOrder ?? DateTime(0)).compareTo(a.dateOrder ?? DateTime(0)));
    return list;
  }

  SaleOrder? order(int id) {
    final raw = _orders.get(id.toString());
    return raw == null ? null : SaleOrder.fromJson(_decode(raw));
  }

  Future<void> replaceOrders(List<SaleOrder> orders) async {
    await _orders.clear();
    await putOrders(orders);
  }

  Future<void> putOrders(List<SaleOrder> orders) =>
      _orders.putAll({for (final o in orders) o.id.toString(): jsonEncode(o.toJson())});

  List<SaleOrderLine>? orderLines(int orderId) {
    final raw = _orderLines.get(orderId.toString());
    if (raw == null) return null;
    return (jsonDecode(raw) as List).map((e) => SaleOrderLine.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> saveOrderLines(int orderId, List<SaleOrderLine> lines) =>
      _orderLines.put(orderId.toString(), jsonEncode(lines.map((l) => l.toJson()).toList()));

  List<PendingPhoneEdit> get pendingPhoneEdits {
    final list = _queue.values.map((raw) => PendingPhoneEdit.fromJson(_decode(raw))).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> enqueuePhoneEdit(PendingPhoneEdit edit) =>
      _queue.put(edit.customerId.toString(), jsonEncode(edit.toJson()));

  Future<void> removePhoneEdit(int customerId) => _queue.delete(customerId.toString());

  Stream<void> get queueChanges => _queue.watch().map((_) {});

  Future<void> clearAll() async {
    await Future.wait([_session.clear(), _customers.clear(), _orders.clear(), _orderLines.clear(), _queue.clear()]);
  }

  static Map<String, dynamic> _decode(String raw) => Map<String, dynamic>.from(jsonDecode(raw) as Map);
}
