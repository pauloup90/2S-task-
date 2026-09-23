import '../../core/odoo/odoo_client.dart';
import '../../core/odoo/odoo_service.dart';
import '../local/local_cache.dart';
import '../models/customer.dart';
import '../models/pending_phone_edit.dart';

class CustomersResult {
  final List<Customer> customers;

  final bool fromCache;

  const CustomersResult(this.customers, {this.fromCache = false});
}

enum PhoneUpdateOutcome { synced, queued }

class SyncReport {
  final int synced;
  final int remaining;
  final List<String> failures;

  const SyncReport({this.synced = 0, this.remaining = 0, this.failures = const []});
}

class CustomerRepository {
  final OdooService _service;
  final LocalCache _cache;

  CustomerRepository(this._service, this._cache);

  List<PendingPhoneEdit> get pendingEdits => _cache.pendingPhoneEdits;

  Stream<void> get pendingChanges => _cache.queueChanges;

  Future<CustomersResult> getCustomers({String query = ''}) async {
    try {
      final remote = await _service.fetchCustomers(query: query);
      if (query.trim().isEmpty) {
        await _cache.replaceCustomers(remote);
      } else {
        await _cache.putCustomers(remote);
      }
      return CustomersResult(_withPendingEdits(remote));
    } on OdooNetworkException {
      final cached = _cache.customers.where((c) => c.matches(query)).toList();
      return CustomersResult(_withPendingEdits(cached), fromCache: true);
    }
  }

  Future<Customer?> getCustomer(int id) async {
    try {
      final remote = await _service.fetchCustomer(id);
      if (remote != null) await _cache.putCustomers([remote]);
      return remote == null ? null : _withPendingEdits([remote]).first;
    } on OdooNetworkException {
      final cached = _cache.customer(id);
      return cached == null ? null : _withPendingEdits([cached]).first;
    }
  }

  Future<PhoneUpdateOutcome> updatePhone(Customer customer, String phone, {bool offline = false}) async {
    try {
      if (offline) throw const OdooNetworkException();
      await _service.updateCustomerPhone(customer.id, phone);
      await _cache.removePhoneEdit(customer.id);
      await _cache.putCustomers([customer.copyWith(phone: phone, hasPendingSync: false)]);
      return PhoneUpdateOutcome.synced;
    } on OdooNetworkException {
      await _cache.enqueuePhoneEdit(
        PendingPhoneEdit(customerId: customer.id, customerName: customer.name, phone: phone, createdAt: DateTime.now()),
      );
      return PhoneUpdateOutcome.queued;
    }
  }

  Future<SyncReport> syncPendingEdits() async {
    var synced = 0;
    final failures = <String>[];
    for (final edit in _cache.pendingPhoneEdits) {
      try {
        await _service.updateCustomerPhone(edit.customerId, edit.phone);
        final cached = _cache.customer(edit.customerId);
        if (cached != null) {
          await _cache.putCustomers([cached.copyWith(phone: edit.phone, hasPendingSync: false)]);
        }
        await _cache.removePhoneEdit(edit.customerId);
        synced++;
      } on OdooNetworkException {
        break;
      } on OdooSessionExpiredException {
        rethrow;
      } on OdooException catch (e) {
        failures.add('${edit.customerName}: ${e.message}');
        await _cache.removePhoneEdit(edit.customerId);
      }
    }
    return SyncReport(synced: synced, remaining: _cache.pendingPhoneEdits.length, failures: failures);
  }

  List<Customer> _withPendingEdits(List<Customer> customers) {
    final pending = {for (final e in _cache.pendingPhoneEdits) e.customerId: e.phone};
    if (pending.isEmpty) return customers;
    return [
      for (final c in customers) pending.containsKey(c.id) ? c.copyWith(phone: pending[c.id], hasPendingSync: true) : c,
    ];
  }
}
