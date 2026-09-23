import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  Future<bool> get isOnline async => _isOnline(await _connectivity.checkConnectivity());

  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  static bool _isOnline(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);
}
