import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  // Stream to listen for connectivity changes
  final StreamController<bool> _connectivityController = StreamController<bool>();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<void> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _connectivityController.sink.add(
      connectivityResult == ConnectivityResult.mobile ||
      connectivityResult == ConnectivityResult.wifi,
    );
  }

  void startListening() {
    Connectivity().onConnectivityChanged.listen((connectivityResult) {
      _connectivityController.sink.add(
        connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi,
      );
    });
  }

  void dispose() {
    _connectivityController.close();
  }
}
