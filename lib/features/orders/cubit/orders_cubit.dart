import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/odoo/odoo_exceptions.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/sale_order.dart';
import '../../../data/repositories/order_repository.dart';

enum OrderFilter {
  all('All'),
  quotations('Quotations'),
  confirmed('Confirmed');

  final String label;
  const OrderFilter(this.label);

  bool accepts(SaleOrder order) => switch (this) {
    OrderFilter.all => true,
    OrderFilter.quotations => order.state.isQuotation,
    OrderFilter.confirmed => order.state == SaleOrderState.sale || order.state == SaleOrderState.done,
  };
}

class OrdersState extends Equatable {
  final LoadStatus status;
  final List<SaleOrder> orders;
  final String query;
  final OrderFilter filter;
  final bool fromCache;
  final bool isRefreshing;
  final String? error;

  const OrdersState({
    this.status = LoadStatus.initial,
    this.orders = const [],
    this.query = '',
    this.filter = OrderFilter.all,
    this.fromCache = false,
    this.isRefreshing = false,
    this.error,
  });

  List<SaleOrder> get visibleOrders => orders.where(filter.accepts).toList();

  OrdersState copyWith({
    LoadStatus? status,
    List<SaleOrder>? orders,
    String? query,
    OrderFilter? filter,
    bool? fromCache,
    bool? isRefreshing,
    String? error,
  }) => OrdersState(
    status: status ?? this.status,
    orders: orders ?? this.orders,
    query: query ?? this.query,
    filter: filter ?? this.filter,
    fromCache: fromCache ?? this.fromCache,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    error: error,
  );

  @override
  List<Object?> get props => [status, orders, query, filter, fromCache, isRefreshing, error];
}

class OrdersCubit extends Cubit<OrdersState> {
  final OrderRepository _repository;
  final Duration searchDebounce;
  Timer? _debounce;
  int _requestId = 0;

  OrdersCubit(this._repository, {this.searchDebounce = const Duration(milliseconds: 400)}) : super(const OrdersState());

  Future<void> load() async {
    final requestId = ++_requestId;
    final hasData = state.orders.isNotEmpty;
    emit(state.copyWith(status: hasData ? state.status : LoadStatus.loading, isRefreshing: hasData));
    try {
      final result = await _repository.getOrders(query: state.query);
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          status: LoadStatus.success,
          orders: result.orders,
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

  void setFilter(OrderFilter filter) => emit(state.copyWith(filter: filter));

  void orderChanged(SaleOrder order) {
    emit(state.copyWith(orders: [for (final o in state.orders) o.id == order.id ? order : o]));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
