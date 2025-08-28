import 'dart:convert';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:circleslate/presentation/features/event_management/models/eventsModels.dart';
import 'package:circleslate/presentation/features/ride_request/view/ride_sharing_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date parsing
import 'package:url_launcher/url_launcher.dart'; // For Google Calendar URL launching

import '../../../common_providers/user_events_provider.dart';
import '../controllers/eventManagementControllers.dart';

// --- AppColors (Unchanged) ---
class AppColors {
  static const Color primaryBlue = Color(0xFF4285F4);
  static const Color inputBorderColor = Colors.grey;
  static const Color textColorSecondary = Color(0xFF333333);
  static const Color inputHintColor = Colors.grey;
  static const Color lightBlueBackground = Color(0x1AD8ECFF);
  static const Color textDark = Color(0xE51B1D2A);
  static const Color textMedium = Color(0x991B1D2A);
  static const Color textLight = Color(0xB21B1D2A);
  static const Color accentBlue = Color(0xFF5A8DEE);
  static const Color inputOutline = Color(0x1A101010);
  static const Color emailIconBackground = Color(0x1AD8ECFF);
  static const Color otpInputFill = Color(0xFFF9FAFB);
  static const Color successIconBackground = Color(0x1AD8ECFF);
  static const Color successIconColor = Color(0xFF4CAF50);
  static const Color headerBackground = Color(0xFF4285F4);
  static const Color availableGreen = Color(0xFF4CAF50);
  static const Color unavailableRed = Color(0xFFF44336);
  static const Color dateBackground = Color(0xFFE0E0E0);
  static const Color dateText = Color(0xFF616161);
  static const Color quickActionCardBackground = Color(0xFFE3F2FD);
  static const Color quickActionCardBorder = Color(0xFF90CAF9);
  static const Color openStatusColor = Color(0xFFD8ECFF);
  static const Color openStatusText = Color(0xA636D399);
  static const Color rideNeededStatusColor = Color(0x1AF87171);
  static const Color rideNeededStatusText = Color(0xFFF87171);
  static const Color toggleButtonActiveBg = Color(0xFF4285F4);
  static const Color toggleButtonActiveText = Colors.white;
  static const Color toggleButtonInactiveBg = Colors.white;
  static const Color toggleButtonInactiveText = Color(0xFF4285F4);
  static const Color toggleButtonBorder = Color(0xFFE0E0E0);
  static const Color goingButtonColor = Color(0xFF4CAF50); // Green for "Going"
  static const Color notGoingButtonColor = Color(0xFFF44336); // Red for "Not Going"
  static const Color chatButtonColor = Color(0xFFE3F2FD); // Light blue for chat button background
  static const Color chatButtonTextColor = Color(0xFF4285F4); // Blue for chat button text
  static const Color requestRideButtonColor = Color(0xFF5A8DEE); // Accent blue for Request Ride
  static const Color requestRideButtonTextColor = Colors.white;
  static const Color rideRequestCardBackground = Color(0xFFE3F2FD); // Light blue for ride request card
  static const Color rideRequestCardBorder = Color(0xFF90CAF9); // Slightly darker blue for card border
}

// --- CustomBottomNavigationBar (Unchanged) ---
class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Groups'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Availability'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: Colors.grey,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  int _selectedIndex = 1; // Assuming Events tab is selected
  bool _isJoining = true; // State for "I'm Joining" / "Decline" buttons
  String? _responseStatus;

  late Future<Event> _eventDetails;
  bool _isNavigating = false; // Flag to prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _eventDetails = EventService.fetchEventDetails(widget.eventId);
  }

  // Add event to Google Calendar
  Future<void> _addToGoogleCalendar(Event event) async {
    if (event.date.isEmpty || event.startTime.isEmpty || event.endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event date, start time, or end time is missing")),
      );
      return;
    }

    try {
      final DateTime? eventDate = DateFormat('yyyy-MM-dd').parse(event.date);
      final startTimeParts = event.startTime.split(':');
      final endTimeParts = event.endTime.split(':');

      final startDateTime = DateTime(
        eventDate!.year,
        eventDate.month,
        eventDate.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      final endDateTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End time must be after start time")),
        );
        return;
      }

      final String title = Uri.encodeComponent(event.title.isEmpty ? "Event" : event.title);
      final String details = Uri.encodeComponent(event.description.isEmpty ? "Details" : event.description);
      final String location = Uri.encodeComponent(event.location.isEmpty ? "Location" : event.location);

      String formatDateTime(DateTime dateTime) {
        return dateTime.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first;
      }

      final String start = formatDateTime(startDateTime);
      final String end = formatDateTime(endDateTime);

      final Uri url = Uri.parse(
        "https://calendar.google.com/calendar/u/0/r/eventedit"
            "?text=$title"
            "&details=$details"
            "&location=$location"
            "&dates=$start/$end",
      );

      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw 'Could not open Google Calendar';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening Google Calendar: $e")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing event details: $e")),
      );
    }
  }

  void _handleResponse(String responseType, Event event) {
    if (_isNavigating) return; // Prevent multiple response submissions

    EventService.sendResponse(widget.eventId, responseType).then((_) {
      final userEventsProvider = Provider.of<UserEventsProvider>(context, listen: false);
      if (responseType == 'going') {
        userEventsProvider.addGoingDate(event.date);
        _refreshEventDetails();
        _addToGoogleCalendar(event);
        setState(() {
          _isJoining = true;
        });
      } else {
        userEventsProvider.removeGoingDate(event.date);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have declined the event')),
        );
        setState(() {
          _isNavigating = true; // Set flag to prevent further actions
        });
        // Navigate immediately to prevent re-fetch
        context.go('/home'); // Or '/notifications'
      }
    }).catchError((error) {
      print('Error submitting response: $error');
      String errorMessage = 'Error submitting response: $error';
      if (error.toString().contains('You don\'t have permission to respond to this event')) {
        errorMessage = 'You are not authorized to respond to this event.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      setState(() {
        _isNavigating = true; // Set flag to prevent further actions
      });
      context.go('/home'); // Navigate away on error
    });
  }

  void _refreshEventDetails() {
    if (_isNavigating) return; // Skip refresh if navigating
    setState(() {
      _eventDetails = EventService.fetchEventDetails(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double titleFontSize = screenWidth * 0.055;
    final double appBarTitleFontSize = screenWidth * 0.05;
    final double subtitleFontSize = screenWidth * 0.04;
    final double bodyFontSize = screenWidth * 0.035;
    final double smallFontSize = screenWidth * 0.03;
    final double generalIconSize = screenWidth * 0.04;
    final double sectionIconSize = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (!_isNavigating) {
              setState(() {
                _isNavigating = true;
              });
              context.pop();
            }
          },
        ),
        title: Text(
          'Event Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: appBarTitleFontSize,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Event>(
        future: _eventDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error.toString().contains('403') ||
                snapshot.error.toString().contains('You don\'t have permission')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_isNavigating) {
                  setState(() {
                    _isNavigating = true;
                  });
                  context.go('/home');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You no longer have access to this event')),
                  );
                }
              });
              return const Center(child: CircularProgressIndicator());
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final event = snapshot.data!;
          final host = event.host;
          final responses = event.responses; // Changed variable name to avoid conflict
          final bool isRideNeeded = event.rideNeededForEvent;

          return SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Header Card
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: screenWidth * 0.03,
                          runSpacing: screenWidth * 0.015,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: generalIconSize,
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(width: screenWidth * 0.015),
                                Text(
                                  event.date,
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    color: AppColors.primaryBlue,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: generalIconSize,
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(width: screenWidth * 0.015),
                                Text(
                                  '${event.startTime} - ${event.endTime}',
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    color: AppColors.primaryBlue,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: generalIconSize,
                              color: const Color(0xFFF87171),
                            ),
                            SizedBox(width: screenWidth * 0.015),
                            Expanded(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                  fontSize: bodyFontSize,
                                  color: AppColors.textMedium,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                // Host Information Card
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: screenWidth * 0.06,
                              backgroundImage: host.profilePhotoUrl.isNotEmpty
                                  ? NetworkImage(host.profilePhotoUrl)
                                  : const AssetImage('assets/images/default_profile_picture.png') as ImageProvider,
                              onBackgroundImageError: (exception, stackTrace) {
                                print('Error loading host image: $exception');
                              },
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    host.fullName,
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (host.childrenNames.isNotEmpty)
                                    Text(
                                      "${host.childrenNames.join(", ")}'s Parent",
                                      style: TextStyle(
                                        fontSize: smallFontSize,
                                        color: AppColors.textMedium,
                                        fontFamily: 'Poppins',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isNavigating
                                    ? null
                                    : () {
                                  setState(() {
                                    _isJoining = true;
                                  });
                                  _handleResponse('going', event);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isJoining ? AppColors.goingButtonColor : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: BorderSide(
                                      color: _isJoining ? AppColors.goingButtonColor : AppColors.inputOutline,
                                    ),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'I\'m Joining',
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: _isJoining ? Colors.white : AppColors.primaryBlue,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isNavigating
                                    ? null
                                    : () {
                                  setState(() {
                                    _isJoining = false;
                                  });
                                  _handleResponse('not_going', event);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_isJoining ? AppColors.notGoingButtonColor : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: BorderSide(
                                      color: !_isJoining ? AppColors.notGoingButtonColor : AppColors.inputOutline,
                                    ),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Decline',
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: !_isJoining ? Colors.white : const Color(0xFFF87171),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: generalIconSize,
                              color: const Color(0xFF5A8DEE),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Flexible(
                              child: Text(
                                'Who\'s Joining',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.015,
                                vertical: screenWidth * 0.008,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlueBackground,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                '${event.goingCount} Going',
                                style: TextStyle(
                                  fontSize: smallFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryBlue,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: responses.length,
                  itemBuilder: (context, index) {
                    return _buildParticipantTile(context, responses[index], host);
                  },
                ),
                SizedBox(height: screenWidth * 0.04),
                if (isRideNeeded) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: sectionIconSize,
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            'Ride Requests',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(
                        color: AppColors.rideRequestCardBorder,
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                    color: AppColors.rideRequestCardBackground,
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image(
                                image: const AssetImage('assets/images/3d-house.png'),
                                height: screenWidth * 0.05,
                                width: screenWidth * 0.05,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: Text(
                                  'Available for ride home',
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          SizedBox(
                            width: double.infinity,
                            height: screenWidth * 0.1,
                            child: ElevatedButton(
                              onPressed: _isNavigating
                                  ? null
                                  : () {
                                sendRideRequest(
                                  event.id,
                                  'lol',
                                  'string',
                                  context,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.requestRideButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Send Request Ride',
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.requestRideButtonTextColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          SizedBox(
                            width: double.infinity,
                            height: screenWidth * 0.1,
                            child: ElevatedButton(
                              onPressed: _isNavigating
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RideSharingPage(
                                      eventId: event.id,
                                      eventdate: event.date,
                                      eventstartTime: event.startTime,
                                      eventendTime: event.endTime,
                                      eventlocation: event.location,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.requestRideButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Request Ride List',
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.requestRideButtonTextColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: screenWidth * 0.05),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    print("🔑 _getToken returned: $token");
    return token;
  }

  Future<void> sendRideRequest(
      String eventId,
      String pickupLocation,
      String specialInstructions,
      BuildContext context,
      ) async {
    final token = await _getToken();
    final String apiUrl = '${Urls.baseUrl}/event/events/$eventId/request_ride/';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'pickup_location': pickupLocation,
      'special_instructions': specialInstructions,
    });

    print('API URL: $apiUrl');
    print('Headers: $headers');
    print('Body: $body');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride request sent: ${responseData['status_display']}')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $errorMessage')),
        );
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Widget _buildParticipantTile(
      BuildContext context,
      Response response,
      Host host,
      ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double participantAvatarRadius = screenWidth * 0.05;
    final double participantNameFontSize = screenWidth * 0.038;
    final double participantDescFontSize = screenWidth * 0.03;
    final double statusTagFontSize = screenWidth * 0.03;

    String participantStatus = response.responseDisplay;
    if (response.userId == host.id) {
      participantStatus = 'Host';
    }

    Color statusColor;
    Color statusTextColor;
    switch (participantStatus) {
      case 'Going':
        statusColor = const Color(0x8036D399);
        statusTextColor = const Color(0xCC1B1D2A);
        break;
      case 'Not Going':
        statusColor = const Color(0x80F87171);
        statusTextColor = const Color(0xCC1B1D2A);
        break;
      case 'Host':
      default:
        statusColor = const Color(0xFF36D399);
        statusTextColor = const Color(0xFF1B1D2A);
        break;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Row(
          children: [
            CircleAvatar(
              radius: participantAvatarRadius,
              backgroundImage: response.profilePhotoUrl.isNotEmpty
                  ? NetworkImage(response.profilePhotoUrl)
                  : const AssetImage('assets/images/default_profile_picture.png') as ImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading participant image: $exception');
              },
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.username,
                    style: TextStyle(
                      fontSize: participantNameFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (response.childrenNames.isNotEmpty)
                    Text(
                      "${response.childrenNames.join(", ")}'s Parents",
                      style: TextStyle(
                        fontSize: participantDescFontSize,
                        color: AppColors.textMedium,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenWidth * 0.01,
              ),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                participantStatus,
                style: TextStyle(
                  fontSize: statusTagFontSize,
                  fontWeight: FontWeight.w500,
                  color: statusTextColor,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}