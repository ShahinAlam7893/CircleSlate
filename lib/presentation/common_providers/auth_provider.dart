import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circleslate/data/services/user_service.dart';
import 'package:circleslate/data/services/api_base_helper.dart';
import 'package:http/http.dart' as http;
import 'package:circleslate/core/utils/profile_data_manager.dart';

import '../../core/network/endpoints.dart';



class AuthProvider extends ChangeNotifier {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();
  final AuthService _userService;

  bool _isLoading = false;
  String? _errorMessage;
  String? _userEmail;
  String? _userOtp;
  String? _accessToken;
  String? aToken;
  String? _refreshToken;
  Map<String, dynamic>? _userProfile;
  List<dynamic> _conversations = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<dynamic> get conversations => _conversations;
  bool get isLoggedIn => _accessToken != null;

  // Getter for current user ID
  String? get currentUserId => _userProfile?['id']?.toString();

  AuthProvider() : _userService = AuthService(ApiBaseHelper()) {
    Future.microtask(() => loadTokensFromStorage());
  }

  /// Initialize user data on app startup
  Future<void> initializeUserData() async {
    try {
      // Load tokens and cached profile
      await loadTokensFromStorage();

      // If user is logged in, fetch fresh profile data
      if (_accessToken != null && _userProfile == null) {
        await fetchUserProfile();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] Error initializing user data: $e');
    }
  }

  // -------------------- REGISTER --------------------
  Future<bool> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    dynamic profileImage,
  }) async {
    _setLoading(true);

    if (password != confirmPassword) {
      return _setError('Passwords do not match.');
    }

    try {
      final response = await _userService.registerUser(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        profileImage: profileImage,
      );

      _setLoading(false);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final userFriendlyMessage = _getUserFriendlyErrorMessage(
          response.statusCode, 
          response.body
        );
        return _setError(userFriendlyMessage);
      }
    } catch (e) {
      return _setError('An unexpected error occurred. Please try again.');
    }
  }

  // -------------------- LOGIN --------------------
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final response = await _apiBaseHelper.post(
        Urls.login,
        {"email": email, "password": password},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['tokens'] != null) {
        _accessToken = data['tokens']['access'];
        _refreshToken = data['tokens']['refresh'];
        await fetchUserProfile();
        await _saveTokensToStorage();
        aToken = await loadTokensFromStorage();

        _setLoading(false);
        notifyListeners();
        return true;
      }

      // Use helper method to get user-friendly error message
      final userFriendlyMessage = _getUserFriendlyErrorMessage(
        response.statusCode, 
        data['message']
      );
      return _setError(userFriendlyMessage);
    } catch (e) {
      return _setError('An unexpected error occurred. Please try again.');
    }
  }

  Future<bool> addChild(String name, int age) async {
    final url = Uri.parse(Urls.children);

    final prefs = await SharedPreferences.getInstance();
    final savedAccessToken = prefs.getString('accessToken');
    String? token = savedAccessToken;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'age': age}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchChildren() async {
    final url = Uri.parse(Urls.children);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccessToken = prefs.getString('accessToken');
      String? token = savedAccessToken;
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((child) {
          return {
            'name': child['name']?.toString() ?? '',
            'age': child['age']?.toString() ?? '',
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("❌ Exception fetching children: $e");
      return [];
    }
  }

  // -------------------- FORGOT PASSWORD --------------------
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _userEmail = email;

    try {
      final response = await _apiBaseHelper.post(
        Urls.forgotPassword,
        {'email': email},
      );

      _setLoading(false);
      return response.statusCode == 200;
    } catch (e) {
      return _setError('Failed to send OTP. Please try again.');
    }
  }

  // -------------------- VERIFY OTP --------------------
  Future<bool> verifyOtp(String otp) async {
    if (_userEmail == null) {
      return _setError('No email provided for verification.');
    }

    _setLoading(true);

    try {
      final response = await _apiBaseHelper.post(
        Urls.verifyOtp,
        {'email': _userEmail, 'otp': otp},
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        _userOtp = otp;
        return true;
      }
      return _setError(response.body);
    } catch (e) {
      return _setError('OTP verification failed. Please try again.');
    }
  }


  // -------------------- UPDATE PASSWORD (Logged-in user) --------------------
  Future<bool> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return _setError('Passwords do not match.');
    }

    if (_accessToken == null) {
      return _setError('No access token found. Please login again.');
    }

    _setLoading(true);

    try {
      final token = _accessToken;
      final url = Uri.parse('${Urls.resetPassword}');

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        return true;
      }

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final errorMessage = data['message'] ?? data['detail'] ?? 'Password update failed.';
      return _setError(errorMessage);

    } catch (e) {
      _setLoading(false);
      return _setError('An unexpected error occurred while updating password.');
    }
  }

  // -------------------- RESET PASSWORD (Forgot password, not logged-in) --------------------

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return _setError('Passwords do not match.');
    }

    if (_userEmail == null || _userOtp == null) {
      return _setError('Email/OTP not found. Please verify first.');
    }

    _setLoading(true);

    try {
      final url = Uri.parse(Urls.resetPasswordAlt);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _userEmail,
          'otp': _userOtp,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        return true;
      }

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final errorMessage = data['message'] ?? data['detail'] ?? 'Password reset failed.';
      return _setError(errorMessage);

    } catch (e) {
      _setLoading(false);
      return _setError('An unexpected error occurred during password reset.');
    }
  }

  // -------------------- FETCH USER PROFILE (For Home Screen) --------------------
  Future<bool> fetchUserProfile() async {
    if (_accessToken == null) {
      return _setError("No access token found. Please login again.");
    }

    _setLoading(true);

    try {
      final response = await _apiBaseHelper.get(
        Urls.userProfile,
        token: _accessToken,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        _userProfile = {
          "id": data["id"],
          "email": data["email"],
          "full_name": data["full_name"],
          "profile_photo": data["profile_photo"],
          "date_joined": data["date_joined"],
          "bio": data["profile"]?["bio"] ?? "",
          "phone_number": data["profile"]?["phone_number"] ?? "",
          "date_of_birth": data["profile"]?["date_of_birth"] ?? "",
          "children": data["profile"]?["children"] ?? []
        };

        // Save user ID to SharedPreferences for persistence
        await _saveUserProfileToStorage();

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        return _setError("Failed to load profile data.");
      }
    } catch (e) {
      return _setError("Error loading profile: $e");
    }
  }

Future<bool> deleteAccount() async {
  _setLoading(true);

  try {
    if (_accessToken == null || _accessToken!.isEmpty) {
      return _setError("No valid access token found. Please login again.");
    }

    // ── VERY IMPORTANT ───────────────────────────────────────
    // Print or log the token and URL (temporarily!)
    debugPrint('Deleting account with token: $_accessToken');
    debugPrint('URL: ${Urls.deleteAccount}');

    final uri = Uri.parse(Urls.deleteAccount);

    // Option A: Most common – DELETE without body
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Option B: Some backends want POST for dangerous actions
    // final response = await http.post(
    //   uri,
    //   headers: {
    //     'Authorization': 'Bearer $_accessToken',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({}), // or {"confirm": true} etc.
    // );

    debugPrint('Delete response: ${response.statusCode} → ${response.body}');

    _setLoading(false);

    if (response.statusCode == 200 || response.statusCode == 204) {
      await logout();
      return true;
    }

    // ── Try to show the real error from server ───────────────────
    String errorMsg = 'Failed to delete account';

    try {
      final data = jsonDecode(response.body);
      errorMsg = data['message'] ?? data['detail'] ?? data['error'] ?? errorMsg;
    } catch (_) {
      errorMsg = 'Server error ${response.statusCode}';
    }

    return _setError(errorMsg);

  } catch (e, stack) {
    debugPrint('Delete account exception: $e');
    debugPrint('Stack: $stack');
    _setLoading(false);
    return _setError('Network error: $e');
  }
}
  // -------------------- FETCH CONVERSATIONS --------------------
  Future<bool> fetchConversations() async {
    _errorMessage = null; // Clear previous errors
    _conversations = []; // Clear previous conversations
    // Defer loading notification to avoid calling during build
    Future.microtask(() => _setLoading(true));

    if (_accessToken == null) {
      return _setError("No access token found. Please login to view conversations.");
    }

    try {
      final response = await _apiBaseHelper.get(
        Urls.conversations,
        token: _accessToken,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _conversations = data; // Assuming the API returns a list of conversations
        Future.microtask(() => _setLoading(false));
        Future.microtask(() => notifyListeners());
        return true;
      } else {
        return _setError("Failed to load conversations: ${response.body}");
      }
    } catch (e) {
      return _setError("An unexpected error occurred while fetching conversations: $e");
    }
  }

  // -------------------- UPDATE USER PROFILE --------------------
  Future<bool> updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      final token = _accessToken;

      if (token == null) {
        return false;
      }

      final uri = Uri.parse(Urls.updateProfile);
      final request = http.MultipartRequest('PATCH', uri);

      // Authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Text fields
      if (updatedData['full_name'] != null) {
        request.fields['full_name'] = updatedData['full_name'];
      }

      // Profile phone number (nested field)
      if (updatedData['phone_number'] != null) {
        request.fields['profile.phone_number'] = updatedData['phone_number'];
      }

      // Children (if needed)
      if (updatedData['children'] != null) {
        request.fields['profile.children'] = jsonEncode(updatedData['children']);
      }

      // Profile photo
      if (updatedData['profile_image'] != null &&
          File(updatedData['profile_image']).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_photo', // API expects this name
            updatedData['profile_image'],
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Refresh profile data and notify listeners
        await refreshUserData();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Refresh user data from API and update local storage
  Future<void> refreshUserData() async {
    try {
      await fetchUserProfile();
      // Also refresh children data if needed
      await fetchChildren();
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] Error refreshing user data: $e');
    }
  }

  /// Get cached user profile from local storage
  Map<String, dynamic>? getCachedUserProfile() {
    return _userProfile;
  }

  /// Check if user profile is loaded
  bool get isProfileLoaded => _userProfile != null;

  // -------------------- TOKEN STORAGE --------------------
  Future<void> _saveTokensToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', _accessToken ?? '');
    await prefs.setString('refreshToken', _refreshToken ?? '');
  }

  Future<void> _saveUserProfileToStorage() async {
    if (_userProfile != null) {
      await ProfileDataManager.saveProfileData(_userProfile!);
      debugPrint('[AuthProvider] User profile saved to storage: ${_userProfile!['id']}');
    }
  }

  Future<void> _loadUserProfileFromStorage() async {
    final profileData = await ProfileDataManager.loadProfileData();
    if (profileData != null) {
      _userProfile = profileData;
      debugPrint('[AuthProvider] User profile loaded from storage: ${_userProfile!['id']}');
    }
  }

  Future<String?> loadTokensFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAccessToken = prefs.getString('accessToken');
    final savedRefreshToken = prefs.getString('refreshToken');

    _accessToken = savedAccessToken;
    _refreshToken = savedRefreshToken;

    // Load user profile from storage
    await _loadUserProfileFromStorage();

    // return the token so caller can print/use it
    return savedAccessToken;
  }

  // -------------------- HELPERS --------------------
  void _setLoading(bool value) {
    _isLoading = value;
    // Defer notifyListeners to avoid calling during build phase
    Future.microtask(() => notifyListeners());
  }

  bool _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    Future.microtask(() => notifyListeners());
    return false;
  }

  /// Helper method to convert technical errors into user-friendly messages
  String _getUserFriendlyErrorMessage(int statusCode, String? serverMessage) {
    switch (statusCode) {
      case 400:
        return 'Please check your information and try again.';
      case 401:
        return 'Invalid email or password. Please try again.';
      case 403:
        return 'Access denied. Please contact support.';
      case 404:
        return 'Service not found. Please try again later.';
      case 409:
        return 'An account with this email already exists.';
      case 422:
        return 'Please check your information and try again.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server is temporarily unavailable. Please try again later.';
      default:
        // Try to extract meaningful message from server response
        if (serverMessage != null && serverMessage.isNotEmpty) {
          // Check if it's a user-friendly message (no technical details)
          if (!serverMessage.contains('status') && 
              !serverMessage.contains('error') && 
              !serverMessage.contains('exception') &&
              !serverMessage.contains('{') &&
              !serverMessage.contains('[') &&
              serverMessage.length < 100) {
            return serverMessage;
          }
        }
        return 'Something went wrong. Please try again.';
    }
  }

  void setTokens(String? accessToken, String? refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    Future.microtask(() => notifyListeners());
  }

  // Logout method to clear all user data
  Future<void> logout() async {
    debugPrint('[AuthProvider] Logging out user...');

    // Clear in-memory data
    _accessToken = null;
    _refreshToken = null;
    _userProfile = null;
    _userEmail = null;
    _userOtp = null;
    _errorMessage = null;
    _conversations.clear();

    // Clear stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await ProfileDataManager.clearProfileData();

    debugPrint('[AuthProvider] User logged out successfully');
    notifyListeners();
  }
}
