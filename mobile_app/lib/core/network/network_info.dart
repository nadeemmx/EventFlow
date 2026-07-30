import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  final Connectivity _connectivity;
  StreamController<bool>? _controller;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkInfo({required this._connectivity});

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Stream<bool> get isConnectedStream {
    _controller ??= StreamController<bool>.broadcast();
    _subscription ??= _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      _controller?.add(online);
    });
    return _controller!.stream;
  }

  void dispose() {
    _subscription?.cancel();
    _controller?.close();
    _subscription = null;
    _controller = null;
  }
}
