import 'package:equatable/equatable.dart';

import 'odoo_parsing.dart';

enum SaleOrderState {
  draft('Quotation'),
  sent('Quotation Sent'),
  sale('Sales Order'),
  done('Locked'),
  cancel('Cancelled');

  final String label;
  const SaleOrderState(this.label);

  static SaleOrderState parse(dynamic value) =>
      SaleOrderState.values.firstWhere((s) => s.name == value, orElse: () => SaleOrderState.draft);

  bool get isQuotation => this == draft || this == sent;
  bool get canConfirm => isQuotation;
}

class SaleOrder extends Equatable {
  final int id;
  final String name;
  final int? partnerId;
  final String partnerName;
  final DateTime? dateOrder;
  final SaleOrderState state;
  final double amountUntaxed;
  final double amountTax;
  final double amountTotal;
  final String currency;

  const SaleOrder({
    required this.id,
    required this.name,
    this.partnerId,
    this.partnerName = '',
    this.dateOrder,
    this.state = SaleOrderState.draft,
    this.amountUntaxed = 0,
    this.amountTax = 0,
    this.amountTotal = 0,
    this.currency = '',
  });

  static const odooFields = [
    'id',
    'name',
    'partner_id',
    'date_order',
    'state',
    'amount_untaxed',
    'amount_tax',
    'amount_total',
    'currency_id',
  ];

  factory SaleOrder.fromOdoo(Map<String, dynamic> map) => SaleOrder(
    id: map['id'] as int,
    name: odooString(map['name'], 'Order #${map['id']}'),
    partnerId: many2oneId(map['partner_id']),
    partnerName: many2oneName(map['partner_id']),
    dateOrder: odooDateTime(map['date_order']),
    state: SaleOrderState.parse(map['state']),
    amountUntaxed: odooDouble(map['amount_untaxed']),
    amountTax: odooDouble(map['amount_tax']),
    amountTotal: odooDouble(map['amount_total']),
    currency: many2oneName(map['currency_id']),
  );

  factory SaleOrder.fromJson(Map<String, dynamic> json) => SaleOrder(
    id: json['id'] as int,
    name: json['name'] as String,
    partnerId: json['partnerId'] as int?,
    partnerName: json['partnerName'] as String? ?? '',
    dateOrder: json['dateOrder'] == null ? null : DateTime.parse(json['dateOrder'] as String),
    state: SaleOrderState.parse(json['state']),
    amountUntaxed: (json['amountUntaxed'] as num).toDouble(),
    amountTax: (json['amountTax'] as num).toDouble(),
    amountTotal: (json['amountTotal'] as num).toDouble(),
    currency: json['currency'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'partnerId': partnerId,
    'partnerName': partnerName,
    'dateOrder': dateOrder?.toIso8601String(),
    'state': state.name,
    'amountUntaxed': amountUntaxed,
    'amountTax': amountTax,
    'amountTotal': amountTotal,
    'currency': currency,
  };

  SaleOrder copyWith({SaleOrderState? state}) => SaleOrder(
    id: id,
    name: name,
    partnerId: partnerId,
    partnerName: partnerName,
    dateOrder: dateOrder,
    state: state ?? this.state,
    amountUntaxed: amountUntaxed,
    amountTax: amountTax,
    amountTotal: amountTotal,
    currency: currency,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    partnerId,
    partnerName,
    dateOrder,
    state,
    amountUntaxed,
    amountTax,
    amountTotal,
    currency,
  ];
}
