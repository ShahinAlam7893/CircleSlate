import 'dart:convert';

import 'package:circleslate/core/network/endpoints.dart';
import 'package:circleslate/presentation/features/event_management/view/direct_invite_page.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// --- AppColors ---
// Defined here for self-containment. In a real project, this would be a shared file.
class AppColors {
  static const Color primaryBlue = Color(0xFF4285F4);
  static const Color inputBorderColor = Colors.grey;
  static const Color textColorSecondary = Color(0xFF333333);
  static const Color inputHintColor = Colors.grey;
  static const Color lightBlueBackground = Color(
    0x1AD8ECFF,
  ); // Used for the checkbox container background
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
  static const Color openStatusText = Color(
    0xA636D399,
  ); // This color looks more green/teal in the image
  static const Color rideNeededStatusColor = Color(
    0x1AF87171,
  ); // Light red background
  static const Color rideNeededStatusText = Color(
    0xFFF87171,
  ); // Darker red text
  static const Color toggleButtonActiveBg = Color(
    0xFF4285F4,
  ); // Primary blue for active button background
  static const Color toggleButtonActiveText =
      Colors.white; // White text for active button
  static const Color toggleButtonInactiveBg =
      Colors.white; // White background for inactive button
  static const Color toggleButtonInactiveText = Color(
    0xFF4285F4,
  ); // Primary blue text for inactive button
  static const Color toggleButtonBorder = Color(
    0xFFE0E0E0,
  ); // Light grey border for inactive button
}

// --- AuthInputField ---
// Modified to have a static label above the text field
class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText; // This will now be the static title above the field
  final String hintText;
  final TextInputType keyboardType;
  final bool isPassword;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;

  const AuthInputField({
    Key? key,
    required this.controller,
    required this.labelText, // Used for the static title
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  _AuthInputFieldState createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Define font sizes and spacing relative to screenWidth
    final double labelFontSize = screenWidth * 0.032; // Smaller for labels
    final double hintFontSize = screenWidth * 0.03; // Even smaller for hints
    final double inputContentPaddingVertical =
        screenWidth * 0.035; // Vertical padding for input
    final double inputContentPaddingHorizontal =
        screenWidth * 0.04; // Horizontal padding for input

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText, // Static title above the text field
          style: TextStyle(
            color: AppColors.textColorSecondary,
            fontSize: labelFontSize, // Responsive font size
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: screenWidth * 0.02), // Responsive spacing
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          validator: widget.validator,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                screenWidth * 0.01,
              ), // Responsive border radius
              borderSide: const BorderSide(
                color: AppColors.inputOutline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                screenWidth * 0.01,
              ), // Responsive border radius
              borderSide: const BorderSide(
                color: AppColors.inputOutline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                screenWidth * 0.01,
              ), // Responsive border radius
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            hintStyle: TextStyle(
              color: AppColors.inputHintColor,
              fontSize: hintFontSize,
              fontWeight: FontWeight.w400,
            ), // Responsive font size
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              vertical: inputContentPaddingVertical,
              horizontal: inputContentPaddingHorizontal,
            ), // Responsive padding
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.black,
                size: screenWidth * 0.05, // Responsive icon size
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
                : (widget.suffixIcon != null
                ? SizedBox(
              width:
              screenWidth * 0.08, // Constrain suffix icon size
              height: screenWidth * 0.08,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: widget.suffixIcon,
              ),
            )
                : null),
          ),
        ),
      ],
    );
  }
}

// --- CreateEventPage ---
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _endtimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isOpenInvite = true;
  bool _rideNeeded = false;
  bool _addToGoogleCalendar = false;

  int _selectedIndex = 0;


  void _showInvalidDateDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey.shade50,
          title: const Text(
            "Invalid Event Date",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }


  @override
  void dispose() {
    _eventTitleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _endtimeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> createEvent() async {
    if (_dateController.text.isEmpty) {
      _showInvalidDateDialog("Please select a date for the event.");
      return;
    }
    DateTime eventDate;
    try {
      eventDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
    } catch (e) {
      _showInvalidDateDialog("Invalid date format.");
      return;
    }
    DateTime today = DateTime.now();
    DateTime todayOnlyDate = DateTime(today.year, today.month, today.day);

    if (eventDate.isBefore(todayOnlyDate)) {
      _showInvalidDateDialog("Event date cannot be in the past.");
      return;
    }

    final url = Uri.parse(Urls.Create_events);

    final invitesJson = InviteStorage().invitesJson;
    final List<int> invitees = invitesJson != null
        ? List<int>.from(
      jsonDecode(invitesJson).map(
            (item) => int.parse(item.toString()),
      ),
    )
        : [];

    print(invitees);

    // Collect form data
    final Map<String, dynamic> eventData = {
      "title": _eventTitleController.text,
      "date": _dateController.text,
      "start_time": _timeController.text,
      "end_time": _endtimeController.text,
      "location": _locationController.text,
      "description": _descriptionController.text,
      "event_type": _isOpenInvite ? "open" : "direct",
      "add_to_google_calendar": _addToGoogleCalendar,
      "ride_needed_for_event": _rideNeeded,
      "invitees": invitees,
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    print('[Create Event] Retrieved token: $token');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    print('Preparing to send data to API:');
    print('URL: $url');
    print('Headers: $headers');
    print('Event Data: ${json.encode(eventData)}');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(eventData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('Event created successfully!');
        final responseData = json.decode(response.body);
        print('Event ID: ${responseData['id']}');
      } else {
        print('Failed to create event. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (e) {
      print('Error creating event: $e');
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textDark, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      String formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00'; // HH:mm:ss
      setState(() {
        _timeController.text = formattedTime;
      });
    }
  }

  Future<void> _selectendTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textDark, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      String formattedEndTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00'; // HH:mm:ss
      setState(() {
        _endtimeController.text = formattedEndTime;
      });
    }
  }

  Future<void> _openGoogleCalendar() async {
    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _endtimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in date, start time, and end time")),
      );
      return;
    }

    try {
      final DateTime? eventDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
      final startTimeParts = _timeController.text.split(':');
      final endTimeParts = _endtimeController.text.split(':');

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

      // Encode event details for URL
      final String title = Uri.encodeComponent(
          _eventTitleController.text.isEmpty ? "Event" : _eventTitleController.text);
      final String details = Uri.encodeComponent(
          _descriptionController.text.isEmpty ? "Details" : _descriptionController.text);
      final String location = Uri.encodeComponent(
          _locationController.text.isEmpty ? "Location" : _locationController.text);

      String formatDateTime(DateTime dateTime) {
        return dateTime
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double appBarTitleFontSize = screenWidth * 0.05;
    final double sectionTitleFontSize =
        screenWidth * 0.038;
    final double buttonTextFontSize = screenWidth * 0.04;
    final double checkboxTextFontSize = screenWidth * 0.035;
    final double generalSpacing =
        screenWidth * 0.05;
    final double inputFieldSpacing =
        screenWidth * 0.04;
    final double horizontalSpacing =
        screenWidth * 0.04;

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
        title: Text(
          'Create Event',
          style: TextStyle(
            color: Colors.white,
            fontSize: appBarTitleFontSize, // Responsive font size
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          screenWidth * 0.06,
        ), // Responsive overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title
            AuthInputField(
              controller: _eventTitleController,
              labelText: 'Event Title *',
              hintText: 'Enter event title..',
            ),
            SizedBox(height: inputFieldSpacing), // Responsive spacing
            // Date and Time
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: AuthInputField(
                  controller: _dateController,
                  labelText: 'Date *',
                  hintText: '2025-01-30',
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    size: screenWidth * 0.045,
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ),
            ),
            Row(
              children: [
                // Responsive spacing
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context),
                    child: AbsorbPointer(
                      child: AuthInputField(
                        controller: _timeController,
                        labelText: 'Start Time *',
                        hintText: '11:02 AM',
                        suffixIcon: Icon(
                          Icons.access_time,
                          size: screenWidth * 0.045,
                        ), // Responsive icon size
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectendTime(context),
                    child: AbsorbPointer(
                      child: AuthInputField(
                        controller: _endtimeController,
                        labelText: 'End Time *',
                        hintText: '02:02 PM',
                        suffixIcon: Icon(
                          Icons.access_time,
                          size: screenWidth * 0.045,
                        ), // Responsive icon size
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: inputFieldSpacing), // Responsive spacing
            // Location
            AuthInputField(
              controller: _locationController,
              labelText: 'Location *',
              hintText: 'Enter location..',
            ),
            SizedBox(height: inputFieldSpacing), // Responsive spacing
            // Description (Optional)
            AuthInputField(
              controller: _descriptionController,
              labelText: 'Description (Optional)',
              hintText: 'Add event description..',
              maxLines: 4,
            ),
            SizedBox(height: generalSpacing), // Responsive spacing
            // Invite Type
            Text(
              'Invite Type *',
              style: TextStyle(
                fontSize: sectionTitleFontSize, // Responsive font size
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: screenWidth * 0.025), // Responsive spacing
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    context: context, // Pass context for responsive sizing
                    text: 'Open Invite',
                    isSelected: _isOpenInvite,
                    onTap: () {
                      setState(() {
                        _isOpenInvite = true;
                      });
                      // context.push(RoutePaths.openInvite);
                    },
                  ),
                ),
                SizedBox(width: horizontalSpacing), // Responsive spacing
                Expanded(
                  child: _buildToggleButton(
                    context: context, // Pass context for responsive sizing
                    text: 'Direct Invite',
                    isSelected: !_isOpenInvite,
                    onTap: () {
                      setState(() {
                        _isOpenInvite =
                        false; // Correctly set to false for Direct Invite
                      });
                      context.push(RoutePaths.directInvite);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: inputFieldSpacing), // Responsive spacing
            // Add Google Calendar Event
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.02,
              ), // Responsive padding
              decoration: BoxDecoration(
                color: AppColors.lightBlueBackground,
                borderRadius: BorderRadius.circular(
                  screenWidth * 0.03,
                ), // Responsive border radius
                border: Border.all(
                  color: AppColors.toggleButtonBorder,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ), // Responsive border radius
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.03,
                        ), // Responsive padding
                      ),
                      onPressed: _openGoogleCalendar,
                      child: const Text(
                        'Add to Google Calendar',
                        style: TextStyle(
                          fontSize: 12, // Responsive font size
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: inputFieldSpacing), // Responsive spacing
            // Ride needed for this event
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.02,
              ), // Responsive padding
              decoration: BoxDecoration(
                color: AppColors.lightBlueBackground,
                borderRadius: BorderRadius.circular(
                  screenWidth * 0.03,
                ), // Responsive border radius
                border: Border.all(
                  color: AppColors.toggleButtonBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: screenWidth * 0.06, // Responsive checkbox size
                    height: screenWidth * 0.06,
                    child: Checkbox(
                      value: _rideNeeded,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _rideNeeded = newValue!;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.01,
                        ), // Responsive border radius
                      ),
                      side: BorderSide(
                        color: AppColors.inputOutline,
                        width: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02), // Responsive spacing
                  Flexible(
                    // Ensure text itself is flexible
                    child: Text(
                      'Ride needed for this event',
                      style: TextStyle(
                        fontSize: checkboxTextFontSize, // Responsive font size
                        fontWeight: FontWeight.w400,
                        color: AppColors.textDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: generalSpacing), // Responsive spacing
            // Create Event Button
            SizedBox(
              width: double.infinity,
              height: screenWidth * 0.12, // Responsive height for button
              child: ElevatedButton(
                onPressed: () {
                  context.push('/up_coming_events');
                  createEvent();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      screenWidth * 0.03,
                    ), // Responsive border radius
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: screenWidth * 0.03,
                  ), // Responsive padding
                ),
                child: FittedBox(
                  // Use FittedBox to ensure text always fits
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Create Event',
                    style: TextStyle(
                      fontSize: buttonTextFontSize, // Responsive font size
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: generalSpacing), // Spacing for bottom nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required BuildContext context, // Added context to get screenWidth
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double toggleButtonTextFontSize =
        screenWidth * 0.038; // Responsive font size for toggle buttons
    final double toggleButtonVerticalPadding =
        screenWidth * 0.03; // Responsive padding

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: toggleButtonVerticalPadding,
        ), // Responsive padding
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.toggleButtonActiveBg
              : AppColors.toggleButtonInactiveBg,
          borderRadius: BorderRadius.circular(
            screenWidth * 0.02,
          ), // Responsive border radius
          border: Border.all(
            color: isSelected
                ? AppColors.toggleButtonActiveBg
                : AppColors.toggleButtonBorder,
            width: 1.0,
          ),
        ),
        child: Center(
          child: FittedBox(
            // Ensures text fits
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: toggleButtonTextFontSize, // Responsive font size
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.toggleButtonActiveText
                    : AppColors.toggleButtonInactiveText,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
    );
  }
}