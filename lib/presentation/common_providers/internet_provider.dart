import 'package:flutter/material.dart';
import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetProvider with ChangeNotifier {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  late StreamSubscription<InternetStatus> _subscription;

  InternetProvider() {
    _subscription = InternetConnection().onStatusChange.listen((event) {
      final newStatus = event == InternetStatus.connected;
      if (newStatus != _isConnected) {
        _isConnected = newStatus;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
