import 'package:flutter_test/flutter_test.dart';
import 'package:two_s_task/data/models/customer.dart';
import 'package:two_s_task/data/models/odoo_parsing.dart';
import 'package:two_s_task/data/models/sale_order.dart';
import 'package:two_s_task/data/models/sale_order_line.dart';

void main() {
  group('Customer.fromOdoo', () {
    test('maps Odoo false values to empty strings', () {
      final c = Customer.fromOdoo({
        'id': 7,
        'name': 'Ahmed El-Sayed',
        'phone': false,
        'email': false,
        'street': false,
        'city': 'Cairo',
        'country_id': [65, 'Egypt'],
        'ref': 'SEED-01',
      });
      expect(c.phone, '');
      expect(c.email, '');
      expect(c.country, 'Egypt');
      expect(c.address, 'Cairo, Egypt');
      expect(c.initials, 'AE');
    });

    test('survives a JSON round trip for the Hive cache', () {
      const c = Customer(id: 1, name: 'Salma Zaki', phone: '+20 1', hasPendingSync: true);
      expect(Customer.fromJson(c.toJson()), c);
    });

    test('matches search on name, phone and ref', () {
      const c = Customer(id: 1, name: 'Salma Zaki', phone: '+20 109', ref: 'SEED-06');
      expect(c.matches('salma'), isTrue);
      expect(c.matches('109'), isTrue);
      expect(c.matches('seed-06'), isTrue);
      expect(c.matches('omar'), isFalse);
    });
  });

  group('SaleOrder.fromOdoo', () {
    test('parses many2one, state and UTC date', () {
      final o = SaleOrder.fromOdoo({
        'id': 3,
        'name': 'S00003',
        'partner_id': [9, 'Kareem Hassan'],
        'date_order': '2026-09-23 10:00:00',
        'state': 'sale',
        'amount_untaxed': 1800,
        'amount_tax': 0,
        'amount_total': 1800.0,
        'currency_id': [1, 'EGP'],
      });
      expect(o.partnerId, 9);
      expect(o.partnerName, 'Kareem Hassan');
      expect(o.state, SaleOrderState.sale);
      expect(o.state.canConfirm, isFalse);
      expect(o.dateOrder, DateTime.utc(2026, 9, 23, 10).toLocal());
      expect(o.currency, 'EGP');
      expect(SaleOrder.fromJson(o.toJson()), o);
    });

    test('draft and sent can be confirmed', () {
      expect(SaleOrderState.parse('draft').canConfirm, isTrue);
      expect(SaleOrderState.parse('sent').canConfirm, isTrue);
      expect(SaleOrderState.parse('cancel').canConfirm, isFalse);
    });
  });

  test('SaleOrderLine falls back to the description when product is false', () {
    final line = SaleOrderLine.fromOdoo({
      'id': 1,
      'product_id': false,
      'name': 'Custom item',
      'product_uom_qty': 2,
      'price_unit': 10,
      'price_subtotal': 20,
      'price_total': 20,
    });
    expect(line.product, 'Custom item');
    expect(line.quantity, 2);
  });

  test('odooDateTime returns null for false', () {
    expect(odooDateTime(false), isNull);
  });
}
