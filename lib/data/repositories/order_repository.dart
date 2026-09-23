import '../../core/odoo/odoo_client.dart';
import '../../core/odoo/odoo_service.dart';
import '../local/local_cache.dart';
import '../models/sale_order.dart';
import '../models/sale_order_line.dart';

class OrdersResult {
  final List<SaleOrder> orders;
  final bool fromCache;

  const OrdersResult(this.orders, {this.fromCache = false});
}

class OrderDetail {
  final SaleOrder order;
  final List<SaleOrderLine> lines;
  final bool fromCache;

  const OrderDetail(this.order, this.lines, {this.fromCache = false});
}

class OrderRepository {
  final OdooService _service;
  final LocalCache _cache;

  OrderRepository(this._service, this._cache);

  Future<OrdersResult> getOrders({String query = ''}) async {
    try {
      final remote = await _service.fetchSaleOrders(query: query);
      if (query.trim().isEmpty) {
        await _cache.replaceOrders(remote);
      } else {
        await _cache.putOrders(remote);
      }
      return OrdersResult(remote);
    } on OdooNetworkException {
      final q = query.trim().toLowerCase();
      final cached = _cache.orders
          .where((o) => q.isEmpty || o.name.toLowerCase().contains(q) || o.partnerName.toLowerCase().contains(q))
          .toList();
      return OrdersResult(cached, fromCache: true);
    }
  }

  Future<OrderDetail?> getOrderDetail(int orderId) async {
    try {
      final order = await _service.fetchSaleOrder(orderId);
      if (order == null) return null;
      final lines = await _service.fetchOrderLines(orderId);
      await _cache.putOrders([order]);
      await _cache.saveOrderLines(orderId, lines);
      return OrderDetail(order, lines);
    } on OdooNetworkException {
      final order = _cache.order(orderId);
      final lines = _cache.orderLines(orderId);
      if (order == null || lines == null) rethrow;
      return OrderDetail(order, lines, fromCache: true);
    }
  }

  Future<SaleOrder> confirm(SaleOrder order) async {
    final updated = await _service.confirmSaleOrder(order.id) ?? order.copyWith(state: SaleOrderState.sale);
    await _cache.putOrders([updated]);
    return updated;
  }
}
