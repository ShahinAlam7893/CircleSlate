import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Utility class to manage profile data consistently across the app
class ProfileDataManager {
  static const String _profileKey = 'userProfile';
  static const String _lastUpdateKey = 'lastProfileUpdate';

  /// Save profile data to local storage
  static Future<void> saveProfileData(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profileData));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      debugPrint('[ProfileDataManager] Profile data saved successfully');
    } catch (e) {
      debugPrint('[ProfileDataManager] Error saving profile data: $e');
    }
  }

  /// Load profile data from local storage
  static Future<Map<String, dynamic>?> loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson) as Map<String, dynamic>;
        debugPrint('[ProfileDataManager] Profile data loaded from storage');
        return profileData;
      }
    } catch (e) {
      debugPrint('[ProfileDataManager] Error loading profile data: $e');
    }
    return null;
  }

  /// Check if profile data is stale (older than specified duration)
  static Future<bool> isProfileDataStale({Duration maxAge = const Duration(minutes: 5)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      if (lastUpdateStr == null) return true;
      
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      
      return now.difference(lastUpdate) > maxAge;
    } catch (e) {
      debugPrint('[ProfileDataManager] Error checking profile data staleness: $e');
      return true;
    }
  }

  /// Clear profile data from local storage
  static Future<void> clearProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.remove(_lastUpdateKey);
      debugPrint('[ProfileDataManager] Profile data cleared');
    } catch (e) {
      debugPrint('[ProfileDataManager] Error clearing profile data: $e');
    }
  }

  /// Get child name from profile data
  static String? getChildName(Map<String, dynamic> profileData) {
    try {
      final children = profileData['children'] as List?;
      if (children != null && children.isNotEmpty) {
        final firstChild = children.first;
        if (firstChild is Map<String, dynamic>) {
          return firstChild['name']?.toString();
        }
      }
    } catch (e) {
      debugPrint('[ProfileDataManager] Error getting child name: $e');
    }
    return null;
  }

  /// Get user full name from profile data
  static String? getUserFullName(Map<String, dynamic> profileData) {
    try {
      return profileData['full_name']?.toString();
    } catch (e) {
      debugPrint('[ProfileDataManager] Error getting user full name: $e');
    }
    return null;
  }

  /// Get profile image URL from profile data
  static String? getProfileImageUrl(Map<String, dynamic> profileData) {
    try {
      String imageUrl = profileData['profile_photo']?.toString() ?? '';
      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        imageUrl = 'http://72.60.26.57$imageUrl';
      }
      return imageUrl;
    } catch (e) {
      debugPrint('[ProfileDataManager] Error getting profile image URL: $e');
    }
    return null;
  }
}
