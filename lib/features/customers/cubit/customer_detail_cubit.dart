import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/odoo/odoo_exceptions.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customer_repository.dart';

enum PhoneSaveResult { none, synced, queued, failed }

class CustomerDetailState extends Equatable {
  final Customer customer;
  final bool isRefreshing;
  final bool isSaving;
  final String? error;

  final PhoneSaveResult saveResult;

  const CustomerDetailState({
    required this.customer,
    this.isRefreshing = false,
    this.isSaving = false,
    this.error,
    this.saveResult = PhoneSaveResult.none,
  });

  CustomerDetailState copyWith({
    Customer? customer,
    bool? isRefreshing,
    bool? isSaving,
    String? error,
    PhoneSaveResult saveResult = PhoneSaveResult.none,
  }) => CustomerDetailState(
    customer: customer ?? this.customer,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isSaving: isSaving ?? this.isSaving,
    error: error,
    saveResult: saveResult,
  );

  @override
  List<Object?> get props => [customer, isRefreshing, isSaving, error, saveResult];
}

class CustomerDetailCubit extends Cubit<CustomerDetailState> {
  final CustomerRepository _repository;

  CustomerDetailCubit(this._repository, Customer customer) : super(CustomerDetailState(customer: customer));

  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final latest = await _repository.getCustomer(state.customer.id);
      if (isClosed) return;
      emit(state.copyWith(customer: latest, isRefreshing: false));
    } on OdooException catch (e) {
      if (!isClosed) emit(state.copyWith(isRefreshing: false, error: e.message));
    }
  }

  Future<bool> savePhone(String phone, {required bool offline}) async {
    final value = phone.trim();
    emit(state.copyWith(isSaving: true));
    try {
      final outcome = await _repository.updatePhone(state.customer, value, offline: offline);
      final queued = outcome == PhoneUpdateOutcome.queued;
      emit(
        state.copyWith(
          customer: state.customer.copyWith(phone: value, hasPendingSync: queued),
          isSaving: false,
          saveResult: queued ? PhoneSaveResult.queued : PhoneSaveResult.synced,
        ),
      );
      return true;
    } on OdooException catch (e) {
      emit(state.copyWith(isSaving: false, error: e.message, saveResult: PhoneSaveResult.failed));
      return false;
    }
  }

  void pendingChanged(Set<int> pendingIds) {
    final pending = pendingIds.contains(state.customer.id);
    if (pending != state.customer.hasPendingSync) {
      emit(state.copyWith(customer: state.customer.copyWith(hasPendingSync: pending)));
    }
  }

  static String? validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[0-9\s().-]+$').hasMatch(v)) return 'Use digits, spaces and + ( ) - only';
    if (v.replaceAll(RegExp(r'\D'), '').length < 6) return 'Phone number is too short';
    return null;
  }
}
