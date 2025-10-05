import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/endpoints.dart';

class AvailabilityProvider extends ChangeNotifier {
  static const String _apiUrl = "${Urls.baseUrl}/calendar/availability/";

  // -------------------- User Selection --------------------
  String? selectedUserId; // ID of user whose calendar we are viewing

  void setSelectedUserId(String userId) {
    selectedUserId = userId.isNotEmpty ? userId : null;
    print('AvailabilityProvider: Set selectedUserId to $selectedUserId');
    notifyListeners();
  }

  List<int> allUserIds = [];
  void setAllUserIds(List<int> userIds) {
    allUserIds = userIds;
    notifyListeners();
  }

  Future<void> fetchAllUsers() async {
    final token = await _getToken();
    if (token == null) {
      print("⚠ No token found.");
      errorMessage = 'Authentication token missing';
      notifyListeners();
      return;
    }

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.get(
        Uri.parse("${Urls.baseUrl}/users/"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        final List<int> ids = usersJson.map((user) => user["id"] as int).toList();

        setAllUserIds(ids);
        print("All User IDs: $allUserIds");
      } else {
        print("⚠ Failed to fetch users: ${response.statusCode}");
        errorMessage = 'Failed to fetch users: ${response.statusCode}';
      }
    } catch (e) {
      print("🔥 Error fetching users: $e");
      errorMessage = 'Error fetching users: $e';
    }
    notifyListeners();
  }

  // -------------------- Calendar & Availability --------------------
  Map<int, Map<String, dynamic>> apiAvailability = {};
  bool isLoading = false;
  String? errorMessage;

  // New properties for day details
  Map<String, dynamic>? selectedDayDetails;
  bool isDayDetailsLoading = false;
  String? dayDetailsError;

  final Map<int, int> _calendarDateStates = {for (int i = 1; i <= 31; i++) i: 2};
  final Map<int, int> _weeklyAvailability = {
    DateTime.sunday: 2,
    DateTime.monday: 2,
    DateTime.tuesday: 2,
    DateTime.wednesday: 2,
    DateTime.thursday: 2,
    DateTime.friday: 2,
    DateTime.saturday: 2,
  };
  final Map<int, String> _weeklyTimeRanges = {
    DateTime.sunday: 'Not Set',
    DateTime.monday: 'Not Set',
    DateTime.tuesday: 'Not Set',
    DateTime.wednesday: 'Not Set',
    DateTime.thursday: 'Not Set',
    DateTime.friday: 'Not Set',
    DateTime.saturday: 'Not Set',
  };

  // Track loaded month/year to avoid redundant fetches
  int? _loadedYear;
  int? _loadedMonth;

  Map<int, int> get calendarDateStates => _calendarDateStates;
  Map<int, int> get weeklyAvailability => _weeklyAvailability;
  Map<int, String> get weeklyTimeRanges => _weeklyTimeRanges;

  void resetCalendarData({bool clearCache = false}) {
    _calendarDateStates.clear();
    for (int i = 1; i <= 31; i++) {
      _calendarDateStates[i] = 2;
    }
    apiAvailability.clear();
    errorMessage = null;
    selectedDayDetails = null;
    dayDetailsError = null;
    if (clearCache) {
      _loadedYear = null;
      _loadedMonth = null;
    }
    print('AvailabilityProvider: Reset calendar data (clearCache: $clearCache)');
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  void updateDateState(int date, int newState) {
    if (_calendarDateStates.containsKey(date)) {
      _calendarDateStates[date] = newState;
      notifyListeners();
    }
  }

  void toggleDateState(int date) {
    if (_calendarDateStates.containsKey(date)) {
      int currentState = _calendarDateStates[date]!;
      int newState = currentState == 2 ? 1 : currentState == 1 ? 0 : 2;
      _calendarDateStates[date] = newState;
      notifyListeners();
    }
  }

  void setAvailabilityForDates(List<int> dates, int status) {
    for (int date in dates) {
      if (_calendarDateStates.containsKey(date)) _calendarDateStates[date] = status;
    }
    notifyListeners();
  }

  void setDayOfWeekAvailability(int dayOfWeek, int status, String timeRange) {
    if (_weeklyAvailability.containsKey(dayOfWeek)) {
      _weeklyAvailability[dayOfWeek] = status;
      _weeklyTimeRanges[dayOfWeek] = timeRange;
      notifyListeners();
    }
  }

  void resetWeeklyAvailability() {
    _weeklyAvailability.updateAll((key, value) => 2);
    _weeklyTimeRanges.updateAll((key, value) => 'Not Set');
    notifyListeners();
  }

  String _statusToString(int status) {
    switch (status) {
      case 1:
        return "available";
      case 0:
        return "busy";
      case 2:
        return "maybe";
      default:
        return "busy";
    }
  }

  String _repeatOptionToString(int option) {
    switch (option) {
      case 0:
        return "once";
      case 1:
        return "weekly";
      case 2:
        return "monthly";
      default:
        return "once";
    }
  }

  // -------------------- NEW: Fetch Day Details --------------------
  Future<void> fetchDayDetails(DateTime date) async {
    final token = await _getToken();
    if (token == null) {
      dayDetailsError = 'Authentication token missing';
      notifyListeners();
      return;
    }

    isDayDetailsLoading = true;
    dayDetailsError = null;
    selectedDayDetails = null;
    notifyListeners();

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final dateString = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      String url;
      if (selectedUserId != null) {
        // For other users: Use the user-day-availability endpoint
        url = "${Urls.baseUrl}/calendar/user-day-availability/$selectedUserId/?date=$dateString";
      } else {
        // For current user: Use the existing day endpoint
        url = "${Urls.baseUrl}/calendar/day/?date=$dateString";
      }

      print('Fetching day details from: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('Day details response status: ${response.statusCode}');
      print('Day details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (selectedUserId != null) {
          // Format the user-day-availability response
          selectedDayDetails = {
            'date': data['date'],
            'user_id': data['user_id'],
            'time_slots': data['time_slots'] ?? [],
            'notes': data['notes'] ?? '',
            'availability_id': data['availability_id'],
          };
        } else {
          // Format the current user day response
          selectedDayDetails = {
            'date': dateString,
            'time_slots': data['time_slots'] ?? [],
            'notes': data['notes'] ?? '',
          };
        }
      } else if (response.statusCode == 404) {
        // No availability data for this day
        selectedDayDetails = {
          'date': dateString,
          'time_slots': [],
          'notes': '',
          'message': 'No availability data for this date'
        };
      } else {
        dayDetailsError = 'Failed to fetch day details: ${response.statusCode}';
        print("⚠ $dayDetailsError");
      }
    } catch (e) {
      dayDetailsError = 'Error fetching day details: $e';
      print("🔥 $dayDetailsError");
    }

    isDayDetailsLoading = false;
    notifyListeners();
  }

  void clearDayDetails() {
    selectedDayDetails = null;
    dayDetailsError = null;
    notifyListeners();
  }

  Future<bool> saveAvailabilityToAPI({
    required int selectedStatus,
    required int selectedTimeSlotIndex,
    required int selectedRepeatOption,
    required String startDate,
    String? endDate,
    String? notes,
  }) async {
    final token = await _getToken();
    if (token == null) {
      errorMessage = 'Authentication token missing';
      notifyListeners();
      return false;
    }

    bool morningAvailable = selectedTimeSlotIndex == 0;
    bool afternoonAvailable = selectedTimeSlotIndex == 1;
    bool eveningAvailable = selectedTimeSlotIndex == 2;
    bool nightAvailable = selectedTimeSlotIndex == 3;

    final body = {
      "morning_available": morningAvailable,
      "morning_status": _statusToString(selectedStatus),
      "afternoon_available": afternoonAvailable,
      "afternoon_status": _statusToString(selectedStatus),
      "evening_available": eveningAvailable,
      "evening_status": _statusToString(selectedStatus),
      "night_available": nightAvailable,
      "night_status": _statusToString(selectedStatus),
      "repeat_schedule": _repeatOptionToString(selectedRepeatOption),
      "start_date": startDate,
      "end_date": endDate ?? "",
      "notes": notes ?? "",
    };

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      final response = await http.post(Uri.parse(_apiUrl), headers: headers, body: jsonEncode(body));
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Availability saved: ${response.body}");
        return true;
      } else {
        print("⚠ Failed to save: ${response.statusCode} - ${response.body}");
        errorMessage = 'Failed to save availability: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("🔥 Error saving availability: $e");
      errorMessage = 'Error saving availability: $e';
      notifyListeners();
      return false;
    }
  }

  // -------------------- NEW: Update Single Date Availability --------------------
  Future<void> updateSingleDateAvailability(int year, int month, int day, int newState) async {
    final token = await _getToken();
    if (token == null) {
      errorMessage = 'Authentication token missing';
      notifyListeners();
      return;
    }

    final dateString = "${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

    // Update local state immediately for responsiveness
    updateDateState(day, newState);

    // Save to API (using existing saveAvailabilityToAPI)
    bool success = await saveAvailabilityToAPI(
      selectedStatus: newState,
      selectedTimeSlotIndex: 0, // Default to morning; adjust based on your app's logic
      selectedRepeatOption: 0, // Once
      startDate: dateString,
      endDate: dateString,
      notes: '',
    );

    if (!success) {
      // Revert local state on failure
      updateDateState(day, 2); // Default to "maybe"
      print("⚠ Failed to update availability for $dateString");
    } else {
      print("✅ Updated availability for $dateString");
    }
  }

  // -------------------- Fetch Methods --------------------
  Future<void> fetchAvailabilityForUser(String userId) async {
    final token = await _getToken();
    if (token == null) {
      errorMessage = 'Authentication token missing';
      notifyListeners();
      return;
    }

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      print('Fetching user availability for user_id=$userId');
      final response = await http.get(
        Uri.parse("${Urls.baseUrl}/calendar/availability/?user_id=$userId"),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        apiAvailability = _mapApiData(data);
      } else {
        errorMessage = 'Failed to fetch user availability: ${response.statusCode}';
        print("⚠ $errorMessage");
      }
    } catch (e) {
      errorMessage = 'Error fetching user availability: $e';
      print("🔥 $errorMessage");
    }
    notifyListeners();
  }

  Map<int, Map<String, dynamic>> _mapApiData(List<dynamic> apiResponse) {
    final Map<int, Map<String, dynamic>> mapped = {};
    for (final item in apiResponse) {
      final date = DateTime.parse(item["start_date"]);
      final weekday = date.weekday;
      final slots = item["all_time_slots_with_status"] as Map<String, dynamic>;
      String selectedTimeRange = "Not Set";
      String statusDisplay = "Tentative";

      for (var slot in slots.values) {
        if (slot is Map && slot.containsKey("status_display")) {
          selectedTimeRange = slot["time"] ?? "Not Set";
          statusDisplay = slot["status_display"] ?? "Tentative";
          break;
        }
      }

      mapped[weekday] = {
        "status": _statusStringToCode(statusDisplay),
        "timeRange": selectedTimeRange,
      };
    }
    return mapped;
  }

  int _statusStringToCode(String status) {
    switch (status.toLowerCase()) {
      case "busy":
        return 0;
      case "available":
        return 1;
      case "maybe":
        return 2;
      default:
        return 2;
    }
  }

  // Updated fetchMonthAvailabilityFromAPI method
  Future<void> fetchMonthAvailabilityFromAPI(int year, int month) async {
    // Skip fetch if data is already loaded for this month/year
    if (_loadedYear == year && _loadedMonth == month && _calendarDateStates.isNotEmpty) {
      print('AvailabilityProvider: Data already loaded for $month/$year, skipping fetch');
      isLoading = false;
      notifyListeners();
      return;
    }

    final token = await _getToken();
    if (token == null) {
      errorMessage = 'Authentication token missing';
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    resetCalendarData(clearCache: true); // Explicitly clear cache for new month
    notifyListeners();

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };
      print('Fetching availability for $month/$year, user: $selectedUserId');

      final daysInMonth = DateTime(year, month + 1, 0).day;

      if (selectedUserId != null) {
        // For other users: Use the user-month-availability endpoint
        final url = "${Urls.baseUrl}/calendar/user-month-availability/$selectedUserId/";
        print('Fetching user month availability from: $url');

        final response = await http.get(Uri.parse(url), headers: headers);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Parse the month data
          if (data['days'] != null) {
            final days = data['days'] as List<dynamic>;

            for (var dayData in days) {
              final dateStr = dayData['date'] as String;
              final date = DateTime.parse(dateStr);

              if (date.month == month && date.year == year) {
                final day = date.day;
                final timeSlots = dayData['time_slots'] as List<dynamic>;

                // Determine overall status for the day
                int statusCode = 2; // default maybe/not set

                if (timeSlots.isNotEmpty) {
                  // Check if any slot is available
                  bool hasAvailable = false;
                  bool hasBusy = false;

                  for (var slot in timeSlots) {
                    final status = (slot['status'] ?? 'maybe').toLowerCase();
                    if (status == 'available') hasAvailable = true;
                    if (status == 'busy') hasBusy = true;
                  }

                  // Priority: available > busy > maybe
                  if (hasAvailable) {
                    statusCode = 1; // available
                  } else if (hasBusy) {
                    statusCode = 0; // busy
                  }
                }

                _calendarDateStates[day] = statusCode;
              }
            }
          }

          print("📅 Calendar data updated for user $selectedUserId: $_calendarDateStates");
        } else {
          errorMessage = 'Failed to fetch user availability: ${response.statusCode}';
          print("⚠ $errorMessage");
          print("Response body: ${response.body}");
        }
      } else {
        // For own user: Parallelize per-day fetches
        final List<Future<void>> fetchFutures = [];
        for (int day = 1; day <= daysInMonth; day++) {
          final dateString = "${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
          final url = "${Urls.baseUrl}/calendar/day/?date=$dateString";

          fetchFutures.add(
            http.get(Uri.parse(url), headers: headers).then((response) {
              int statusCode = 2; // default maybe
              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                final timeSlots = data["time_slots"] ?? [];
                if (timeSlots.isNotEmpty) {
                  final status = (timeSlots.first["status"] ?? "maybe").toLowerCase();
                  if (status == "busy") statusCode = 0;
                  if (status == "available") statusCode = 1;
                  if (status == "maybe") statusCode = 2;
                }
              } else {
                print("⚠ Failed to fetch day $dateString: ${response.statusCode}");
              }
              _calendarDateStates[day] = statusCode;
            }).catchError((e) {
              print("Error fetching day $dateString: $e");
              _calendarDateStates[day] = 2;
            }),
          );
        }
        await Future.wait(fetchFutures);
        print("📅 Calendar data updated for current user: $_calendarDateStates");
      }

      _loadedYear = year;
      _loadedMonth = month;

    } catch (e) {
      errorMessage = 'Error fetching month availability: $e';
      print("🔥 $errorMessage");
    }

    isLoading = false;
    notifyListeners();
  }
}