String odooString(dynamic value, [String fallback = '']) => value is String ? value : fallback;

double odooDouble(dynamic value) => value is num ? value.toDouble() : 0.0;

int? many2oneId(dynamic value) => value is List && value.isNotEmpty && value.first is int ? value.first as int : null;

String many2oneName(dynamic value, [String fallback = '']) =>
    value is List && value.length > 1 ? value[1].toString() : fallback;

DateTime? odooDateTime(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  final iso = value.replaceFirst(' ', 'T');
  final parsed = DateTime.tryParse(iso.endsWith('Z') ? iso : '${iso}Z');
  return parsed?.toLocal();
}
