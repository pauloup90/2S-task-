import 'package:equatable/equatable.dart';

import 'odoo_parsing.dart';

class SaleOrderLine extends Equatable {
  final int id;
  final String product;
  final String description;
  final double quantity;
  final double priceUnit;
  final double priceSubtotal;
  final double priceTotal;

  const SaleOrderLine({
    required this.id,
    required this.product,
    this.description = '',
    this.quantity = 0,
    this.priceUnit = 0,
    this.priceSubtotal = 0,
    this.priceTotal = 0,
  });

  static const odooFields = [
    'id',
    'product_id',
    'name',
    'product_uom_qty',
    'price_unit',
    'price_subtotal',
    'price_total',
  ];

  factory SaleOrderLine.fromOdoo(Map<String, dynamic> map) {
    final description = odooString(map['name']);
    return SaleOrderLine(
      id: map['id'] as int,
      product: many2oneName(map['product_id'], description),
      description: description,
      quantity: odooDouble(map['product_uom_qty']),
      priceUnit: odooDouble(map['price_unit']),
      priceSubtotal: odooDouble(map['price_subtotal']),
      priceTotal: odooDouble(map['price_total']),
    );
  }

  factory SaleOrderLine.fromJson(Map<String, dynamic> json) => SaleOrderLine(
    id: json['id'] as int,
    product: json['product'] as String,
    description: json['description'] as String? ?? '',
    quantity: (json['quantity'] as num).toDouble(),
    priceUnit: (json['priceUnit'] as num).toDouble(),
    priceSubtotal: (json['priceSubtotal'] as num).toDouble(),
    priceTotal: (json['priceTotal'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product,
    'description': description,
    'quantity': quantity,
    'priceUnit': priceUnit,
    'priceSubtotal': priceSubtotal,
    'priceTotal': priceTotal,
  };

  @override
  List<Object?> get props => [id, product, description, quantity, priceUnit, priceSubtotal, priceTotal];
}
