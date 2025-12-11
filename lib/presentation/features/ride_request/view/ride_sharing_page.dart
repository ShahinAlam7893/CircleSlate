import 'dart:convert';

import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:circleslate/presentation/features/ride_request/services/RideService.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RideRequest {
  final String requesterName;
  final String requestedBy;
  final String requesterImageUrl;

  final String eventDate;
  final String eventTime;
  final String eventLocation;
  final String status;

  final String id; // e.g., "Pending Response", "Accepted"

  const RideRequest({
    required this.requesterName,
    required this.requestedBy,
    required this.requesterImageUrl,

    required this.eventDate,
    required this.eventTime,
    required this.eventLocation,
    required this.status,
    required this.id,
  });

  // Factory constructor to create RideRequest from JSON (API response)
  factory RideRequest.fromJson(
    Map<String, dynamic> json,
    String eventDate,
    String eventTime,
    String eventLocation,
  ) {
    return RideRequest(
      id: json["id"],
      requesterName: json['requester']['full_name'] ?? 'Unknown',
      requestedBy: json['requester']['email'] ?? 'Unknown',
      requesterImageUrl:
          json['requester']['profile_photo_url'] ?? '', // Can be null
      eventDate: eventDate,
      eventTime: eventTime,
      eventLocation: eventLocation,
      status: json['status_display'] ?? 'Pending',
    );
  }
}

class RideSharingPage extends StatefulWidget {
  final String eventId;
  final String eventdate;
  final String eventstartTime;
  final String eventendTime;
  final String eventlocation;

  const RideSharingPage({
    super.key,
    required this.eventId,
    required this.eventdate,
    required this.eventstartTime,
    required this.eventlocation,
    required this.eventendTime,
  });

  @override
  State<RideSharingPage> createState() => _RideSharingPageState();
}

class _RideSharingPageState extends State<RideSharingPage> {
  late String eventId;
  late String eventDate;
  late String eventTime;
  late String eventLocation;

  late Future<List<RideRequest>> rideRequests;

  @override
  void initState() {
    super.initState();

    // You should assign the variables with values passed from the previous screen or from the URL parameters.
    eventId = widget.eventId; // Ensure the eventId is passed to this widget.
    eventDate = widget.eventdate; // Make sure the correct data is passed
    eventTime = widget.eventstartTime;
    eventLocation = widget.eventlocation;

    // Fetch ride requests after the initial state is set.
    rideRequests = RideService.fetchRideRequests(
      eventId,
      eventDate,
      eventTime,
      eventLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Ride Sharing',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              context.push('/chat');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<RideRequest>>(
        future: rideRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rideRequests = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: rideRequests
                  .map((request) => _buildRideRequestCard(request))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    print("🔑 Retrieved token from SharedPreferences: $token");
    return token;
  }

  Future<void> acceptRide(String rideId) async {
    final url =
        '${Urls.baseUrl}/api/event/ride-requests/$rideId/accept/';
    print('API URL: $url');

    // Await the token
    final token = await _getToken();
    print('Token: $token');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // body is not required
      },
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Ride accepted successfully!');
    } else {
      // Decode the error response
      final errorData = jsonDecode(response.body);

      // If "detail" key exists, show it, otherwise fallback to whole body
      final errorMessage = errorData['detail'] ?? response.body;

      SnackbarUtils.showError(context, 'Failed to accept ride:\n$errorMessage');
      print('Failed to accept ride.');
    }
  }

  Widget _buildRideRequestCard(RideRequest request) {
    Color statusBackgroundColor;
    Color statusTextColor;
    Widget? actionButton;

    if (request.status == 'Pending') {
      statusBackgroundColor = Color(0xFFFFF8E1);
      statusTextColor = Color(0xCC1B1D2A);
      actionButton = ElevatedButton.icon(
        onPressed: () async {
          await acceptRide(request.id); // Hit API
          setState(() {
            // Update the status locally after accepting
            request = RideRequest(
              requesterName: request.requesterName,
              requestedBy: request.requestedBy,
              requesterImageUrl: request.requesterImageUrl,
              eventDate: request.eventDate,
              eventTime: request.eventTime,
              eventLocation: request.eventLocation,
              status: 'Accepted', // Update status
              id: request.id,
            );
          });
        },
        icon: Icon(Icons.check, size: 18, color: Color(0xFF5A8DEE)),
        label: Text(
          'Accept',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1B1D2A),
            fontFamily: 'Poppins',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFD8ECFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        ),
      );
    } else if (request.status == 'Accepted') {
      statusBackgroundColor = Color(0x6636D399);
      statusTextColor = Color(0xCC1B1D2A);

      actionButton = ElevatedButton.icon(
        onPressed: () {
          context.push('/one-to-one-conversation');
          // Handle chat action for accepted ride
        },
        icon: Icon(
          Icons.chat_bubble_outline,
          size: 18,
          color: Color(0xFF5A8DEE),
        ),
        label: Text(
          'Chat',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1B1D2A),
            fontFamily: 'Poppins',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFD8ECFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        ),
      );
    } else {
      statusBackgroundColor = Colors.grey[200]!;
      statusTextColor = Colors.grey[700]!;
      actionButton = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(
                    request.requesterImageUrl.isNotEmpty
                        ? request.requesterImageUrl
                        : 'assets/images/default_profile_picture.png', // your default image
                  ),
                  onBackgroundImageError: (_, __) {
                    // Fallback in case asset path is wrong
                    // Not needed if you always have a valid default image
                  },
                ),

                const SizedBox(width: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xE51B1D2A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(color: Colors.blue, thickness: 1), // Divider
            const SizedBox(height: 16.0),
            _buildInfoRow(
              Icons.calendar_month,
              widget.eventdate,
              iconColor: Color(0xFF5A8DEE),
            ),
            const SizedBox(height: 8.0),
            _buildInfoRow(
              Icons.access_time,
              widget.eventstartTime,
              iconColor: Color(0xFFFFE082),
            ),
            const SizedBox(height: 8.0),
            _buildInfoRow(
              Icons.location_on,
              widget.eventlocation,

              iconColor: Color(0xFFF87171),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackgroundColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: statusTextColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (actionButton != null) actionButton,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8.0),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.0,
            color: Color(0xB21B1D2A),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
