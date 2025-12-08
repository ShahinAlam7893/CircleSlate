// lib/presentation/common_providers/server_status_provider.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/network/endpoints.dart';

class ServerStatusProvider extends ChangeNotifier {
  bool _isServerUp = true;
  bool _isChecking = false;
  String? _lastErrorMessage;

  bool get isServerUp => _isServerUp;
  bool get isChecking => _isChecking;
  String? get lastErrorMessage => _lastErrorMessage;

  Timer? _timer;

  ServerStatusProvider() {
    _checkServer(); // first check immediately
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Only keep checking if we think the server is down
      if (!_isServerUp || _lastErrorMessage != null) {
        _checkServer();
      }
    });
  }

  /// Public method → used by the RETRY button
  Future<void> checkServer() async {
    await _checkServer();
  }

  /// Private method that actually performs the request
  Future<void> _checkServer() async {
    if (_isChecking) return; // prevent parallel checks

    _isChecking = true;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse(Urls.baseUrl))
          .timeout(const Duration(seconds: 6));

      // 2xx and 3xx are fine → server is reachable
      // 401/403 also mean the server is up (just auth problem)
      if (response.statusCode >= 200 && response.statusCode < 500) {
        _updateStatus(true, null);
      } else {
        _updateStatus(false, "Server error ${response.statusCode}");
      }
    } on TimeoutException {
      _updateStatus(false, "Server timeout");
    } on SocketException {
      _updateStatus(false, "No internet connection");
    } on HttpException {
      _updateStatus(false, "Failed to reach server");
    } catch (e) {
      _updateStatus(false, "Connection failed");
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  void _updateStatus(bool status, String? errorMessage) {
    final hasChanged = _isServerUp != status || _lastErrorMessage != errorMessage;

    _isServerUp = status;
    _lastErrorMessage = errorMessage;

    if (hasChanged) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}