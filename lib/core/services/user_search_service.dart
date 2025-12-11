// lib/core/services/user_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_search_result_model.dart';
import '../network/endpoints.dart';

class UserSearchService {
  Future<List<UserSearchResult>> searchUsers(String query) async {
    print('[UserSearchService] searchUsers called with query: "$query"');

    if (query.trim().isEmpty) {
      print('[UserSearchService] Query is empty. Returning empty list.');
      return [];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      print('[UserSearchService] Retrieved token: $token');

      if (token == null) {
        throw Exception('No access token found');
      }

      final url = Uri.parse(
          '${Urls.searchUsers}?q=${Uri.encodeComponent(query)}');
      print('[UserSearchService] Sending GET request to: $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[UserSearchService] Response status: ${response.statusCode}');
      print('[UserSearchService] Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[UserSearchService] Decoded JSON: $data');

        final results = data['results'] as List;
        print('[UserSearchService] Found ${results.length} user(s) in results.');

        return results
            .map((userJson) {
          print('[UserSearchService] Parsing user: $userJson');
          return UserSearchResult.fromJson(userJson);
        })
            .toList();
      } else {
        throw Exception(
            'Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      print('[UserSearchService] Error searching users: $e');
      rethrow;
    }
  }

  void dispose() {
    print('[UserSearchService] dispose() called.');
  }
}
