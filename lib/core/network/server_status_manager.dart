// lib/core/network/server_status_manager.dart

import 'package:flutter/material.dart';

class ServerStatusManager extends ChangeNotifier {
  static final ServerStatusManager _instance = ServerStatusManager._internal();
  factory ServerStatusManager() => _instance;
  ServerStatusManager._internal();

  bool _isServerDown = false;
  bool get isServerDown => _isServerDown;

  /// Call this when you get 5xx, timeout, DNS error, etc.
  void markServerAsDown() {
    if (!_isServerDown) {
      _isServerDown = true;
      notifyListeners();
    }
  }

  /// Call this when you successfully reach the server again
  void markServerAsUp() {
    if (_isServerDown) {
      _isServerDown = false;
      notifyListeners();
    }
  }
}