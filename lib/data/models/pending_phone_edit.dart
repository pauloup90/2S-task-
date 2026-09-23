import 'package:equatable/equatable.dart';

class PendingPhoneEdit extends Equatable {
  final int customerId;
  final String customerName;
  final String phone;
  final DateTime createdAt;

  const PendingPhoneEdit({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.createdAt,
  });

  factory PendingPhoneEdit.fromJson(Map<String, dynamic> json) => PendingPhoneEdit(
    customerId: json['customerId'] as int,
    customerName: json['customerName'] as String? ?? '',
    phone: json['phone'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'customerName': customerName,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [customerId, customerName, phone, createdAt];
}
