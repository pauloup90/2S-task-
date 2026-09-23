import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/odoo/odoo_exceptions.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customer_repository.dart';

class CustomersState extends Equatable {
  final LoadStatus status;
  final List<Customer> customers;
  final String query;
  final bool fromCache;
  final bool isRefreshing;
  final String? error;

  const CustomersState({
    this.status = LoadStatus.initial,
    this.customers = const [],
    this.query = '',
    this.fromCache = false,
    this.isRefreshing = false,
    this.error,
  });

  CustomersState copyWith({
    LoadStatus? status,
    List<Customer>? customers,
    String? query,
    bool? fromCache,
    bool? isRefreshing,
    String? error,
  }) => CustomersState(
    status: status ?? this.status,
    customers: customers ?? this.customers,
    query: query ?? this.query,
    fromCache: fromCache ?? this.fromCache,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    error: error,
  );

  @override
  List<Object?> get props => [status, customers, query, fromCache, isRefreshing, error];
}

class CustomersCubit extends Cubit<CustomersState> {
  final CustomerRepository _repository;
  final Duration searchDebounce;
  Timer? _debounce;
  int _requestId = 0;

  CustomersCubit(this._repository, {this.searchDebounce = const Duration(milliseconds: 400)})
    : super(const CustomersState());

  Future<void> load() async {
    final requestId = ++_requestId;
    final hasData = state.customers.isNotEmpty;
    emit(state.copyWith(status: hasData ? state.status : LoadStatus.loading, isRefreshing: hasData));
    try {
      final result = await _repository.getCustomers(query: state.query);
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          status: LoadStatus.success,
          customers: result.customers,
          fromCache: result.fromCache,
          isRefreshing: false,
        ),
      );
    } on OdooException catch (e) {
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          status: hasData ? LoadStatus.success : LoadStatus.failure,
          isRefreshing: false,
          error: e.message,
        ),
      );
    }
  }

  Future<void> refresh() => load();

  void search(String query) {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, load);
  }

  void customerChanged(Customer customer) {
    emit(state.copyWith(customers: [for (final c in state.customers) c.id == customer.id ? customer : c]));
  }

  void pendingChanged(Set<int> pendingIds) {
    emit(
      state.copyWith(
        customers: [for (final c in state.customers) c.copyWith(hasPendingSync: pendingIds.contains(c.id))],
      ),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
