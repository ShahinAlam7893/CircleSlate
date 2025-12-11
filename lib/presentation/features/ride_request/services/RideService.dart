import 'dart:convert';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:circleslate/presentation/features/ride_request/view/ride_sharing_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RideService {
  static const String baseUrl = Urls.baseUrl;

  static Future<List<RideRequest>> fetchRideRequests(
    String eventId, // ← use this parameter
    String eventDate,
    String eventTime,
    String eventLocation,
  ) async {
    final token = await _getToken();
    print("🔑 Token: $token");

    // Step: Use eventId dynamically in the URL
    final url = Uri.parse('$baseUrl/api/event/events/$eventId/ride-requests/');
    print("🌐 Request URL: $url");

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      print("📬 Response Status Code: ${response.statusCode}");
      print("📬 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((rideRequestJson) {
          return RideRequest.fromJson(
            rideRequestJson,
            eventDate,
            eventTime,
            eventLocation,
          );
        }).toList();
      } else {
        throw Exception('Failed to load ride requests');
      }
    } catch (error) {
      print('❌ Error fetching ride requests: $error');
      return [];
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    print("🔑 Retrieved token from SharedPreferences: $token");
    return token;
  }
}
