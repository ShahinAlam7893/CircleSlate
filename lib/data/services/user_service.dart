// lib/data/services/auth_service.dart
import 'dart:convert';
import 'dart:io'; // Import for File
import 'package:http/http.dart'; // Import for Response
import 'package:circleslate/data/services/api_base_helper.dart'; // Your unchanged ApiBaseHelper
import 'package:circleslate/core/errors/exceptions.dart'; // Ensure this path is correct

import '../datasources/shared_pref/local/entity/token_entity.dart';
import '../datasources/shared_pref/local/token_manager.dart'; // Corrected import path

class AuthService {
  final ApiBaseHelper _apiHelper = ApiBaseHelper();
  final TokenManager _tokenManager = TokenManager(); // Initialize TokenManager
  final ApiBaseHelper apiBaseHelper;
  AuthService(this.apiBaseHelper);

  // Helper to decode response body and handle common errors
  dynamic _handleResponse(Response response, String url) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'message': 'Success'};
      try {
        return json.decode(response.body);
      } on FormatException {
        return {'message': response.body}; // Return raw body if not JSON
      }
    } else if (response.statusCode == 400) {
      throw BadRequestException(response.body, url);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw UnauthorizedException(response.body, url);
    } else if (response.statusCode == 404) {
      throw NotFoundException('Resource not found', url);
    } else {
      throw ServerException(
        'Error occurred with status code : ${response.statusCode}\nResponse body: ${response.body}',
        url,
      );
    }
  }

  Future<Response> registerUser({ // Changed return type to Response to match ApiBaseHelper
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    File? profileImage, // Now accepts a File
  }) async {
    try {
      // Prepare fields for multipart request
      final Map<String, String> fields = {
        'full_name': fullName, // Ensure this matches your backend's expected field name
        'email': email,
        'password': password,
        'confirm_password': confirmPassword, // Ensure this matches your backend's expected field name
      };

      Response response;
      // If a profile image is provided, use postMultipart
      if (profileImage != null) {
        response = await _apiHelper.postMultipart(
          '/auth/register/', // Adjust endpoint as needed
          fields,
          file: profileImage,
          fileField: 'profile_photo',
        );
      } else {
        // Otherwise, use a regular post request
        response = await _apiHelper.post(
          '/auth/register/',
          fields,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiHelper.post(
        '/auth/login/', // Adjust endpoint as needed
        {
          'email': email,
          'password': password,
        },
      );
      final responseData = _handleResponse(response, '/auth/login/'); // Check for errors and decode

      // Save tokens using TokenManager
      final accessToken = responseData['tokens']?['access'];
      final refreshToken = responseData['tokens']?['refresh'];
      if (accessToken != null && refreshToken != null) {
        await _tokenManager.saveTokens(TokenEntity(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ));
      }
      return responseData; // Return the decoded response data
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    // Get token from TokenManager
    final tokens = await _tokenManager.getTokens();
    final token = tokens?.accessToken;

    if (token == null || token.isEmpty) {
      throw UnauthorizedException('No auth token found.', '/profile');
    }

    try {
      final response = await _apiHelper.get(
        '/profile/', // Adjust endpoint as needed
        token: token, // Pass token explicitly to ApiBaseHelper
      );
      return _handleResponse(response, '/profile/'); // Check for errors and decode
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiHelper.post(
        '/auth/forgot-password/', // Adjust endpoint as needed
        {'email': email},
      );
      return _handleResponse(response, '/auth/forgot-password/'); // Check for errors and decode
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _apiHelper.post(
        '/auth/verify-otp/', // Adjust endpoint as needed
        {
          'email': email,
          'otp': otp,
        },
      );
      return _handleResponse(response, '/auth/verify-otp/'); // Check for errors and decode
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setNewPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiHelper.post(
        '/auth/set-new-password/', // Adjust endpoint as needed
        {
          'email': email,
          'password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      return _handleResponse(response, '/auth/set-new-password/'); // Check for errors and decode
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenManager.removeTokens(); // Use TokenManager to remove tokens
  }
}
