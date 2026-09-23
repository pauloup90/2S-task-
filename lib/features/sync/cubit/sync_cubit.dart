import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/connectivity_service.dart';
import '../../../core/odoo/odoo_exceptions.dart';
import '../../../data/models/pending_phone_edit.dart';
import '../../../data/repositories/customer_repository.dart';

class SyncState extends Equatable {
  final bool isOnline;
  final bool isSyncing;
  final List<PendingPhoneEdit> pending;

  final SyncReport? lastReport;

  const SyncState({this.isOnline = true, this.isSyncing = false, this.pending = const [], this.lastReport});

  int get pendingCount => pending.length;

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    List<PendingPhoneEdit>? pending,
    SyncReport? lastReport,
    bool clearReport = false,
  }) => SyncState(
    isOnline: isOnline ?? this.isOnline,
    isSyncing: isSyncing ?? this.isSyncing,
    pending: pending ?? this.pending,
    lastReport: clearReport ? null : (lastReport ?? this.lastReport),
  );

  @override
  List<Object?> get props => [isOnline, isSyncing, pending, lastReport];
}

class SyncCubit extends Cubit<SyncState> {
  final CustomerRepository _customers;
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<void>? _queueSub;

  SyncCubit(this._customers, this._connectivity) : super(const SyncState());

  Future<void> start() async {
    emit(state.copyWith(pending: _customers.pendingEdits, isOnline: await _connectivity.isOnline));
    _queueSub = _customers.pendingChanges.listen((_) {
      if (!isClosed) emit(state.copyWith(pending: _customers.pendingEdits));
    });
    _connectivitySub = _connectivity.onlineChanges.listen((online) {
      final cameBack = online && !state.isOnline;
      emit(state.copyWith(isOnline: online));
      if (cameBack) syncNow();
    });
    if (state.isOnline) await syncNow();
  }

  Future<void> syncNow() async {
    if (state.isSyncing || state.pending.isEmpty) return;
    emit(state.copyWith(isSyncing: true, clearReport: true));
    try {
      final report = await _customers.syncPendingEdits();
      emit(
        state.copyWith(
          isSyncing: false,
          pending: _customers.pendingEdits,
          lastReport: report,
          isOnline: report.remaining == 0 ? true : state.isOnline,
        ),
      );
    } on OdooException {
      emit(state.copyWith(isSyncing: false));
    }
  }

  void reportConsumed() => emit(state.copyWith(clearReport: true));

  @override
  Future<void> close() async {
    await _connectivitySub?.cancel();
    await _queueSub?.cancel();
    return super.close();
  }
}
