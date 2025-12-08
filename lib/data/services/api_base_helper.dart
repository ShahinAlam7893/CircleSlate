// lib/core/network/api_base_helper.dart

import 'dart:io';
import 'dart:convert';
import 'package:circleslate/core/errors/snackbar_service.dart';
import 'package:circleslate/core/network/server_status_manager.dart'; // ← NEW: Import this
import 'package:http/http.dart' as http;
import 'package:circleslate/core/errors/exceptions.dart';
import 'package:flutter/material.dart';

class ApiBaseHelper {
  final BuildContext? context;

  ApiBaseHelper({this.context});

  // ────────────────────── MARK SERVER DOWN GLOBALLY ──────────────────────
  void _triggerServerDown() {
    ServerStatusManager().markServerAsDown(); // ← Full-screen overlay appears
  }

  void _triggerServerUp() {
    ServerStatusManager().markServerAsUp(); // ← Optional: hide when back online
  }

  // ────────────────────── RESPONSE HANDLER ──────────────────────
  void _handleResponse(http.Response response, String url) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        _triggerServerUp(); // Server responded successfully → safe to hide overlay
        return;
      case 400:
        throw BadRequestException(
          response.body.isNotEmpty ? json.decode(response.body)['message'] ?? 'Bad request' : 'Bad request',
          url,
        );
      case 401:
        throw UnauthorizedException('Session expired', url);
      case 403:
        throw UnauthorizedException('Access forbidden', url);
      case 404:
        throw NotFoundException('Resource not found', url);
      case 500:
      case 502:
      case 503:
      case 504:
        _triggerServerDown(); // ← Critical server error
        throw ServerException('Server error (${response.statusCode})', url);
      default:
        _triggerServerDown();
        throw FetchDataException(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
          url,
        );
    }
  }

  // ────────────────────── POST ──────────────────────
  Future<http.Response> post(String url, dynamic body) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            body: json.encode(body),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      _handleResponse(response, url);
      return response;
    } on SocketException {
      _showError('No internet connection');
      throw FetchDataException('No Internet connection', url);
    } on TimeoutException {
      _triggerServerDown(); // ← Server not responding
      _showError('Server is taking too long to respond');
      throw TimeoutException('Request timeout', url);
    } on HttpException {
      _triggerServerDown();
      _showError('Could not connect to server');
      throw FetchDataException('Server not reachable', url);
    } catch (e) {
      if (e is! AppException) {
        _triggerServerDown();
        _showError('Something went wrong');
      }
      rethrow;
    }
  }

  // ────────────────────── GET ──────────────────────
  Future<http.Response> get(String url, {String? token}) async {
    try {
      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      _handleResponse(response, url);
      return response;
    } on SocketException {
      _showError('No internet connection');
      throw FetchDataException('No Internet connection', url);
    } on TimeoutException {
      _triggerServerDown();
      _showError('Server timeout');
      throw TimeoutException('Request timeout', url);
    } on HttpException {
      _triggerServerDown();
      _showError('Server not reachable');
      throw FetchDataException('Could not find the server', url);
    } catch (e) {
      if (e is! AppException) {
        _triggerServerDown();
        _showError('Connection failed');
      }
      rethrow;
    }
  }

  // ────────────────────── PUT ──────────────────────
  Future<http.Response> put(String url, dynamic body, {String? token}) async {
    try {
      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .put(Uri.parse(url), body: json.encode(body), headers: headers)
          .timeout(const Duration(seconds: 30));

      _handleResponse(response, url);
      return response;
    } on SocketException {
      _showError('No internet');
      throw FetchDataException('No Internet connection', url);
    } on TimeoutException {
      _triggerServerDown();
      _showError('Server timeout');
      throw TimeoutException('Request timeout', url);
    } catch (e) {
      if (e is! AppException) {
        _triggerServerDown();
        _showError('Update failed');
      }
      rethrow;
    }
  }

  // ────────────────────── MULTIPART POST ──────────────────────
  Future<http.Response> postMultipart(
    String url,
    Map<String, String> fields, {
    File? file,
    required String fileField,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields.addAll(fields);

      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      _handleResponse(response, url);
      return response;
    } on SocketException {
      _showError('No internet connection');
      throw FetchDataException('No Internet connection', url);
    } on TimeoutException {
      _triggerServerDown();
      _showError('Upload timeout');
      throw TimeoutException('Upload timeout', url);
    } catch (e) {
      _triggerServerDown();
      _showError('Upload failed');
      throw FetchDataException('Upload failed: $e', url);
    }
  }

  // ────────────────────── MULTIPART PUT ──────────────────────
  Future<http.Response> putMultipart(
    String url,
    Map<String, String> fields, {
    String? token,
    File? file,
    String fileField = 'file',
  }) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse(url));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields.addAll(fields);

      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      _handleResponse(response, url);
      return response;
    } catch (e) {
      _triggerServerDown();
      _showError('Update failed');
      throw FetchDataException('Failed to update: $e', url);
    }
  }

  // ────────────────────── SHOW SNACKBAR (only if context available) ──────────────────────
  void _showError(String message) {
    if (context != null && context!.mounted) {
      SnackbarService.showError(context!, message);
    }
  }
}