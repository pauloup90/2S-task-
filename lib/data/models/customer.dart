import 'package:equatable/equatable.dart';

import 'odoo_parsing.dart';

class Customer extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String street;
  final String city;
  final String country;
  final String ref;

  final bool hasPendingSync;

  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.street = '',
    this.city = '',
    this.country = '',
    this.ref = '',
    this.hasPendingSync = false,
  });

  static const odooFields = ['id', 'name', 'phone', 'email', 'street', 'city', 'country_id', 'ref'];

  factory Customer.fromOdoo(Map<String, dynamic> map) => Customer(
    id: map['id'] as int,
    name: odooString(map['name'], 'Unnamed'),
    phone: odooString(map['phone']),
    email: odooString(map['email']),
    street: odooString(map['street']),
    city: odooString(map['city']),
    country: many2oneName(map['country_id']),
    ref: odooString(map['ref']),
  );

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as int,
    name: json['name'] as String,
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    street: json['street'] as String? ?? '',
    city: json['city'] as String? ?? '',
    country: json['country'] as String? ?? '',
    ref: json['ref'] as String? ?? '',
    hasPendingSync: json['hasPendingSync'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'street': street,
    'city': city,
    'country': country,
    'ref': ref,
    'hasPendingSync': hasPendingSync,
  };

  String get address => [street, city, country].where((part) => part.isNotEmpty).join(', ');

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        email.toLowerCase().contains(q) ||
        phone.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        ref.toLowerCase().contains(q);
  }

  Customer copyWith({String? phone, bool? hasPendingSync}) => Customer(
    id: id,
    name: name,
    phone: phone ?? this.phone,
    email: email,
    street: street,
    city: city,
    country: country,
    ref: ref,
    hasPendingSync: hasPendingSync ?? this.hasPendingSync,
  );

  @override
  List<Object?> get props => [id, name, phone, email, street, city, country, ref, hasPendingSync];
}
