import 'package:intl/intl.dart';

String formatMoney(double amount, String currency) {
  final value = NumberFormat('#,##0.00').format(amount);
  return currency.isEmpty ? value : '$value $currency';
}

String formatDateTime(DateTime? date) => date == null ? '-' : DateFormat('d MMM yyyy, HH:mm').format(date);

String formatDate(DateTime? date) => date == null ? '-' : DateFormat('d MMM yyyy').format(date);

String formatQuantity(double qty) => qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
