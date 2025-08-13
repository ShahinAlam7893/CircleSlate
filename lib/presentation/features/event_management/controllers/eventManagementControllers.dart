import 'dart:convert';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:circleslate/presentation/features/event_management/models/eventsModels.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EventService {
  static const String baseUrl = Urls.baseUrl;

  static Future<void> sendResponse(String eventId, String responseType) async {
    final token = await _getToken(); // Get the token
    final url = Uri.parse('$baseUrl/event/events/$eventId/respond/');

    // Debugging output: print the token and the URL
    print('Sending response for event ID: $eventId');
    print('URL: $url');
    print('Response Type: $responseType');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Debugging output: print the headers
    print('Headers: $headers');

    final body = jsonEncode({'response': responseType});

    // Debugging output: print the body being sent
    print('Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      // Debugging output: print the response status and body
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Successfully sent the response
        print('Response sent successfully');
      } else {
        // Handle failure
        print('Failed to send response: ${response.body}');
      }
    } catch (error) {
      print('Error sending response: $error');
    }
  }

  /// Fetches upcoming events from the API
  static Future<List<Event>> fetchEvents() async {
    print("🔍 Starting fetchEvents...");

    final token = await _getToken();
    print("🔑 Retrieved token: $token");

    if (token == null) {
      print("❌ No token found.");
      return [];
    }
    final urls = Urls.fatch_upcoming_events;

    print("🌐 Making GET request to ${urls}");
    final response = await http.get(
      Uri.parse(Urls.fatch_upcoming_events),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("📬 Response status: ${response.statusCode}");
    print("📬 Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print("✅ Successfully decoded JSON data with ${data.length} events");
      return data.map((e) => Event.fromJson(e)).toList();
    } else {
      print("❌ Failed to load events. Status: ${response.statusCode}");
      throw Exception(
        'Failed to load events. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  /// Retrieves token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    print("🔑 _getToken returned: $token");
    return token;
  }

  static Future<Event> fetchEventDetails(String eventId) async {
    print("🔍 Fetching event details for event ID: $eventId");

    final token = await _getToken();
    if (token == null) {
      print("❌ No token found.");
      throw Exception("No token found");
    }

    final eventUrl = "$baseUrl/event/events/$eventId/";
    print("🌐 Making GET request to $eventUrl");

    final response = await http.get(
      Uri.parse(eventUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("📬 Response status: ${response.statusCode}");
    print("📬 Response body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print("✅ Successfully decoded event details: $data");
      return Event.fromJson(data);
    } else {
      print("❌ Failed to load event details. Status: ${response.statusCode}");
      throw Exception(
        'Failed to load event details. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }
}
