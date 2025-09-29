import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/network/endpoints.dart';

class ServerStatusProvider extends ChangeNotifier {
  bool _isServerUp = true;
  bool get isServerUp => _isServerUp;

  Timer? _timer;

  ServerStatusProvider() {
    _startMonitoring();
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkServer();
    });
  }

  Future<void> _checkServer() async {
    try {
      final response = await http
          .get(Uri.parse(Urls.baseUrl))
          .timeout(const Duration(seconds: 5));

      // Handle status codes
      if (response.statusCode == 200) {
        _updateStatus(true); // Server healthy
      } else if ([401, 403, 404, 500, 503].contains(response.statusCode)) {
        _updateStatus(false); // Server down
      } else {
        _updateStatus(false); // Treat all other codes as down
      }
    } catch (_) {
      // Timeout, connection error, DNS fail, etc.
      _updateStatus(false);
    }
  }

  void _updateStatus(bool status) {
    if (_isServerUp != status) {
      _isServerUp = status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
