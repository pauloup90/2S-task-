import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/odoo/odoo_exceptions.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/sale_order.dart';
import '../../../data/models/sale_order_line.dart';
import '../../../data/repositories/order_repository.dart';

enum ConfirmResult { none, confirmed, failed }

class OrderDetailState extends Equatable {
  final SaleOrder order;
  final List<SaleOrderLine> lines;
  final LoadStatus status;
  final bool fromCache;
  final bool isConfirming;
  final String? error;
  final ConfirmResult confirmResult;

  const OrderDetailState({
    required this.order,
    this.lines = const [],
    this.status = LoadStatus.initial,
    this.fromCache = false,
    this.isConfirming = false,
    this.error,
    this.confirmResult = ConfirmResult.none,
  });

  OrderDetailState copyWith({
    SaleOrder? order,
    List<SaleOrderLine>? lines,
    LoadStatus? status,
    bool? fromCache,
    bool? isConfirming,
    String? error,
    ConfirmResult confirmResult = ConfirmResult.none,
  }) => OrderDetailState(
    order: order ?? this.order,
    lines: lines ?? this.lines,
    status: status ?? this.status,
    fromCache: fromCache ?? this.fromCache,
    isConfirming: isConfirming ?? this.isConfirming,
    error: error,
    confirmResult: confirmResult,
  );

  @override
  List<Object?> get props => [order, lines, status, fromCache, isConfirming, error, confirmResult];
}

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _repository;

  OrderDetailCubit(this._repository, SaleOrder order) : super(OrderDetailState(order: order));

  Future<void> load() async {
    final firstLoad = state.status != LoadStatus.success;
    if (firstLoad) emit(state.copyWith(status: LoadStatus.loading));
    try {
      final detail = await _repository.getOrderDetail(state.order.id);
      if (isClosed) return;
      if (detail == null) {
        emit(state.copyWith(status: LoadStatus.failure, error: 'This order no longer exists in Odoo.'));
        return;
      }
      emit(
        state.copyWith(
          order: detail.order,
          lines: detail.lines,
          status: LoadStatus.success,
          fromCache: detail.fromCache,
        ),
      );
    } on OdooException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: firstLoad ? LoadStatus.failure : LoadStatus.success, error: e.message));
    }
  }

  Future<void> confirm() async {
    if (!state.order.state.canConfirm || state.isConfirming) return;
    emit(state.copyWith(isConfirming: true));
    try {
      final updated = await _repository.confirm(state.order);
      emit(state.copyWith(order: updated, isConfirming: false, confirmResult: ConfirmResult.confirmed));
    } on OdooException catch (e) {
      final message = e is OdooNetworkException ? 'Confirming needs a connection. Please try again online.' : e.message;
      emit(state.copyWith(isConfirming: false, error: message, confirmResult: ConfirmResult.failed));
    }
  }
}
