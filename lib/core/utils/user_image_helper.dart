import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../network/endpoints.dart';

class UserImageHelper {
  static const String _baseUrl = '${Urls.baseUrl}';

  static String? getCurrentUserImageUrl(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.userProfile;

      if (userProfile != null && userProfile['profile_photo'] != null) {
        String imageUrl = userProfile['profile_photo'].toString();

        if (imageUrl.startsWith('http')) {
          return imageUrl;
        }

        if (imageUrl.startsWith('/')) {
          return '$_baseUrl$imageUrl';
        }

        return '$_baseUrl/media/$imageUrl';
      }
    } catch (e) {
      debugPrint('[UserImageHelper] Error getting current user image: $e');
    }

    return null;
  }

  static Future<String?> getUserImageUrl(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        debugPrint('[UserImageHelper] No access token found');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/user/$userId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final profilePhoto = userData['profile_photo'];

        if (profilePhoto != null && profilePhoto.toString().isNotEmpty) {
          String imageUrl = profilePhoto.toString();

          if (imageUrl.startsWith('https')) {
            return imageUrl;
          }

          if (imageUrl.startsWith('/')) {
            return '$_baseUrl$imageUrl';
          }
          return '$_baseUrl/media/$imageUrl';
        }
      } else {
        debugPrint(
          '[UserImageHelper] Failed to fetch user image: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[UserImageHelper] Error fetching user image for $userId: $e');
    }

    return null;
  }

  static Widget buildUserAvatar({
    required String? imageUrl,
    double radius = 16,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    debugPrint(
      '[UserImageHelper] Loading image for buildUserAvatar: $imageUrl',
    );
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? Colors.grey[200],
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) {
            debugPrint(
              '[UserImageHelper] Error loading image: $error for URL: $url',
            );
            return CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor ?? Colors.grey[300],
              child: Icon(
                Icons.person,
                color: iconColor ?? Colors.grey[600],
                size: radius * 0.8,
              ),
            );
          },
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? Colors.grey[200],
            backgroundImage: imageProvider,
          ),
        );
      } else {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[200],
          backgroundImage: AssetImage(imageUrl),
          onBackgroundImageError: (error, stackTrace) {
            debugPrint(
              '[UserImageHelper] Error loading asset image: $error for URL: $imageUrl',
            );
          },
          child: null,
        );
      }
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: Icon(
          Icons.person,
          color: iconColor ?? Colors.grey[600],
          size: radius * 0.8,
        ),
      );
    }
  }

  static Widget buildUserAvatarWithErrorHandling({
    required String? imageUrl,
    double radius = 16,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    debugPrint(
      '[UserImageHelper] Loading image for buildUserAvatarWithErrorHandling: $imageUrl',
    );
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? Colors.grey[200],
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) {
            debugPrint(
              '[UserImageHelper] Error loading image: $error for URL: $url',
            );
            return CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor ?? Colors.grey[300],
              child: Icon(
                Icons.person,
                color: iconColor ?? Colors.grey[600],
                size: radius * 0.8,
              ),
            );
          },
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? Colors.grey[200],
            backgroundImage: imageProvider,
          ),
        );
      } else {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[200],
          backgroundImage: AssetImage(imageUrl),
          onBackgroundImageError: (error, stackTrace) {
            debugPrint(
              '[UserImageHelper] Error loading asset image: $error for URL: $imageUrl',
            );
          },
          child: null,
        );
      }
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: Icon(
          Icons.person,
          color: iconColor ?? Colors.grey[600],
          size: radius * 0.8,
        ),
      );
    }
  }

  static Widget buildCurrentUserAvatar({
    required BuildContext context,
    double radius = 16,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    final imageUrl = getCurrentUserImageUrl(context);
    return buildUserAvatarWithErrorHandling(
      imageUrl: imageUrl,
      radius: radius,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
    );
  }

  /// Build a CircleAvatar widget for a specific user by ID
  static Future<Widget> buildUserAvatarById({
    required String userId,
    double radius = 16,
    Color? backgroundColor,
    Color? iconColor,
  }) async {
    final imageUrl = await getUserImageUrl(userId);
    return buildUserAvatarWithErrorHandling(
      imageUrl: imageUrl,
      radius: radius,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
    );
  }
}
