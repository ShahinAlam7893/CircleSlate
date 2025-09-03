// lib/data/services/auth_service.dart
import 'dart:convert';
import 'package:circleslate/data/services/api_base_helper.dart';
import 'package:circleslate/core/errors/exceptions.dart';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:circleslate/core/utils/shared_prefs_helper.dart';

class AuthService {
  final ApiBaseHelper _apiHelper = ApiBaseHelper();

  // -------------------- REGISTER --------------------
  Future<void> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? profilePictureUrl,
  }) async {
    try {
      final response = await _apiHelper.post(Urls.register, {
        'full_name': fullName,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  // -------------------- LOGIN --------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiHelper.post(Urls.login, {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  // -------------------- GET USER PROFILE --------------------
  Future<Map<String, dynamic>> getProfile() async {
    final token = await SharedPrefsHelper.getToken();
    if (token == null) {
      throw UnauthorizedException('No auth token found.', Urls.userProfile);
    }

    try {
      final response = await _apiHelper.get(Urls.userProfile, token: token);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  // -------------------- FORGOT PASSWORD --------------------
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiHelper.post(Urls.forgotPassword, {
        'email': email,
      });

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  // -------------------- VERIFY OTP --------------------
  Future<void> verifyOtp(String email, String otp) async {
    try {
      final response = await _apiHelper.post(Urls.verifyOtp, {
        'email': email,
        'otp': otp,
      });

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  // -------------------- RESET PASSWORD (Forgot Password) --------------------
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiHelper.post(Urls.resetPassword, {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  // -------------------- UPDATE PASSWORD (Logged-in user) --------------------
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await SharedPrefsHelper.getToken();
    if (token == null) {
      throw UnauthorizedException('No auth token found.', Urls.resetPassword);
    }

    try {
      final response = await _apiHelper.put(
        Urls.resetPassword,
        {
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
        token: token,
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }
}
