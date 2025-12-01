import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/endpoints.dart';

class AvailabilityProvider extends ChangeNotifier {
  static const String _apiUrl = Urls.calendarAvailability;

  // -------------------- Caching Strategy --------------------
  static const Duration _cacheExpiration = Duration(minutes: 5);
  DateTime? _lastFetchTime;

  // Cache for multiple users
  final Map<String, List<Map<String, dynamic>>> _userAvailabilityCache = {};
  final Map<String, DateTime> _userCacheTimestamp = {};

  // -------------------- User Selection --------------------
  String? selectedUserId;

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

  // Store raw availability records with their repeat schedules
  List<Map<String, dynamic>> availabilityRecords = [];

  // New properties for day details with caching
  final Map<String, Map<String, dynamic>> _dayDetailsCache = {};
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

  // Track loaded months for multiple users - now stores year-month combinations
  final Map<String, Set<String>> _loadedMonthsByUser = {};

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
      availabilityRecords.clear();
      _userAvailabilityCache.clear();
      _userCacheTimestamp.clear();
      _loadedMonthsByUser.clear();
      _dayDetailsCache.clear();
      _lastFetchTime = null;
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

  // -------------------- Check if cache is valid --------------------
  bool _isCacheValid(String userId) {
    final timestamp = _userCacheTimestamp[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  // -------------------- Apply Repeat Schedule Logic --------------------
  void _applyRepeatSchedules(int year, int month, {List<Map<String, dynamic>>? records}) {
    // Reset calendar states to default
    for (int i = 1; i <= 31; i++) {
      _calendarDateStates[i] = 2;
    }

    final recordsToUse = records ?? availabilityRecords;

    // Apply each availability record with its repeat schedule
    for (var record in recordsToUse) {
      final startDate = DateTime.parse(record['start_date']);
      final endDateStr = record['end_date'];
      final endDate = endDateStr != null && endDateStr.isNotEmpty
          ? DateTime.parse(endDateStr)
          : startDate;
      final repeatSchedule = record['repeat_schedule'] ?? 'once';

      // Get status from time slots
      int statusCode = 2;
      final timeSlots = record['all_time_slots_with_status'] as Map<String, dynamic>?;
      if (timeSlots != null && timeSlots.isNotEmpty) {
        final firstSlot = timeSlots.values.first;
        if (firstSlot is Map && firstSlot.containsKey('status_display')) {
          statusCode = _statusStringToCode(firstSlot['status_display'] ?? 'maybe');
        }
      }

      // Only process if the record is relevant to the viewing month
      if (repeatSchedule == 'once') {
        if (startDate.year == year && startDate.month == month) {
          _calendarDateStates[startDate.day] = statusCode;
        }
      } else if (repeatSchedule == 'weekly') {
        // Calculate if any weekly occurrence falls in this month
        DateTime currentDate = startDate;
        final monthStart = DateTime(year, month, 1);
        final monthEnd = DateTime(year, month + 1, 0);

        // Start from the first occurrence in or before this month
        while (currentDate.isAfter(monthStart)) {
          currentDate = currentDate.subtract(Duration(days: 7));
        }

        // Apply all occurrences in this month
        while (currentDate.isBefore(monthEnd.add(Duration(days: 1))) &&
            currentDate.isBefore(endDate.add(Duration(days: 1)))) {
          if (currentDate.year == year &&
              currentDate.month == month &&
              !currentDate.isBefore(startDate)) {
            _calendarDateStates[currentDate.day] = statusCode;
          }
          currentDate = currentDate.add(Duration(days: 7));
        }
      } else if (repeatSchedule == 'monthly') {
        // Check if this month falls within the range
        final currentMonthDate = DateTime(year, month, startDate.day);
        if (!currentMonthDate.isBefore(startDate) &&
            !currentMonthDate.isAfter(endDate)) {
          final daysInMonth = DateTime(year, month + 1, 0).day;
          if (startDate.day <= daysInMonth) {
            _calendarDateStates[startDate.day] = statusCode;
          }
        }
      }
    }

    print("📅 Applied repeat schedules for $month/$year: $_calendarDateStates");
  }

  // -------------------- Optimized Day Details with Caching --------------------
  Future<void> fetchDayDetails(DateTime date, {bool forceRefresh = false}) async {
    final dateString = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final cacheKey = "${selectedUserId ?? 'current'}_$dateString";

    // Check cache first
    if (!forceRefresh && _dayDetailsCache.containsKey(cacheKey)) {
      print("📦 Using cached day details for $dateString");
      selectedDayDetails = _dayDetailsCache[cacheKey];
      notifyListeners();
      return;
    }

    final token = await _getToken();
    if (token == null) {
      dayDetailsError = 'Authentication token missing';
      notifyListeners();
      return;
    }

    isDayDetailsLoading = true;
    dayDetailsError = null;
    notifyListeners();

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      String url;
      if (selectedUserId != null) {
        url = "${Urls.userDayAvailability}$selectedUserId/?date=$dateString";
      } else {
        url = "${Urls.dayAvailability}?date=$dateString";
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (selectedUserId != null) {
          selectedDayDetails = {
            'date': data['date'],
            'user_id': data['user_id'],
            'time_slots': data['time_slots'] ?? [],
            'notes': data['notes'] ?? '',
            'availability_id': data['availability_id'],
          };
        } else {
          selectedDayDetails = {
            'date': dateString,
            'time_slots': data['time_slots'] ?? [],
            'notes': data['notes'] ?? '',
          };
        }

        // Cache the result
        _dayDetailsCache[cacheKey] = selectedDayDetails!;
        print("💾 Cached day details for $dateString");
      } else if (response.statusCode == 404) {
        selectedDayDetails = {
          'date': dateString,
          'time_slots': [],
          'notes': '',
          'message': 'No availability data for this date'
        };
        _dayDetailsCache[cacheKey] = selectedDayDetails!;
      } else {
        dayDetailsError = 'Failed to fetch day details: ${response.statusCode}';
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

        // Invalidate cache for current user
        final userId = selectedUserId ?? 'current';
        _userAvailabilityCache.remove(userId);
        _userCacheTimestamp.remove(userId);
        _loadedMonthsByUser.remove(userId);
        _dayDetailsCache.clear(); // Clear day details cache

        // Add new record to local cache
        final newRecord = jsonDecode(response.body);
        availabilityRecords.add(newRecord);

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

  Future<void> updateSingleDateAvailability(int year, int month, int day, int newState) async {
    final dateString = "${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

    // Optimistic update
    updateDateState(day, newState);

    bool success = await saveAvailabilityToAPI(
      selectedStatus: newState,
      selectedTimeSlotIndex: 0,
      selectedRepeatOption: 0,
      startDate: dateString,
      endDate: dateString,
      notes: '',
    );

    if (!success) {
      updateDateState(day, 2);
      print("⚠ Failed to update availability for $dateString");
    }
  }

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

      final response = await http.get(
        Uri.parse("${Urls.userCalendarAvailability}?user_id=$userId"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        apiAvailability = _mapApiData(data);
      } else {
        errorMessage = 'Failed to fetch user availability: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Error fetching user availability: $e';
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

  // -------------------- Optimized Month Fetch with Smart Caching --------------------
  Future<void> fetchMonthAvailabilityFromAPI(int year, int month, {bool forceRefresh = false}) async {
    final userId = selectedUserId ?? 'current';
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    // Check if already loaded for this user and month
    if (!forceRefresh &&
        _loadedMonthsByUser.containsKey(userId) &&
        _loadedMonthsByUser[userId]!.contains(monthKey) &&
        _isCacheValid(userId)) {
      print('✅ Using cached data for $monthKey, user: $userId');
      // Just reapply the schedules from cached records
      if (_userAvailabilityCache.containsKey(userId)) {
        _applyRepeatSchedules(year, month, records: _userAvailabilityCache[userId]);
        notifyListeners();
      }
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
    notifyListeners();

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      if (selectedUserId != null) {
        // For other users: Use the user-month-availability endpoint
        final url = "${Urls.baseUrl}/calendar/user-month-availability/$selectedUserId/";
        print('🌐 Fetching user month availability from: $url');

        final response = await http.get(Uri.parse(url), headers: headers);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Reset states
          for (int i = 1; i <= 31; i++) {
            _calendarDateStates[i] = 2;
          }

          if (data['days'] != null) {
            final days = data['days'] as List<dynamic>;

            for (var dayData in days) {
              final dateStr = dayData['date'] as String;
              final date = DateTime.parse(dateStr);

              if (date.month == month && date.year == year) {
                final day = date.day;
                final timeSlots = dayData['time_slots'] as List<dynamic>;

                int statusCode = 2;

                if (timeSlots.isNotEmpty) {
                  bool hasAvailable = false;
                  bool hasBusy = false;

                  for (var slot in timeSlots) {
                    final status = (slot['status'] ?? 'maybe').toLowerCase();
                    if (status == 'available') hasAvailable = true;
                    if (status == 'busy') hasBusy = true;
                  }

                  if (hasAvailable) {
                    statusCode = 1;
                  } else if (hasBusy) {
                    statusCode = 0;
                  }
                }

                _calendarDateStates[day] = statusCode;
              }
            }
          }

          // Mark month as loaded
          _loadedMonthsByUser.putIfAbsent(userId, () => {}).add(monthKey);
          _userCacheTimestamp[userId] = DateTime.now();

          print("📅 Calendar data updated for user $selectedUserId");
        } else {
          errorMessage = 'Failed to fetch user availability: ${response.statusCode}';
          print("⚠ $errorMessage");
        }
      } else {
        // For own user: Fetch all availability records once and cache them
        if (!_userAvailabilityCache.containsKey(userId) || forceRefresh) {
          final availUrl = Urls.calendarAvailability;
          print('🌐 Fetching all availability records from: $availUrl');

          final availResponse = await http.get(Uri.parse(availUrl), headers: headers);

          if (availResponse.statusCode == 200) {
            final List<dynamic> data = jsonDecode(availResponse.body);
            availabilityRecords = data.map((item) => item as Map<String, dynamic>).toList();

            // Cache the records
            _userAvailabilityCache[userId] = availabilityRecords;
            _userCacheTimestamp[userId] = DateTime.now();

            print("📋 Fetched and cached ${availabilityRecords.length} availability records");
          } else {
            errorMessage = 'Failed to fetch availability: ${availResponse.statusCode}';
            print("⚠ $errorMessage");
            isLoading = false;
            notifyListeners();
            return;
          }
        } else {
          print("📦 Using cached availability records");
          availabilityRecords = _userAvailabilityCache[userId]!;
        }

        // Apply repeat schedules to current month
        _applyRepeatSchedules(year, month);

        // Mark month as loaded
        _loadedMonthsByUser.putIfAbsent(userId, () => {}).add(monthKey);
      }

    } catch (e) {
      errorMessage = 'Error fetching month availability: $e';
      print("🔥 $errorMessage");
    }

    isLoading = false;
    notifyListeners();
  }

  // -------------------- Preload Adjacent Months --------------------
  Future<void> preloadAdjacentMonths(int year, int month) async {
    // Preload previous and next month in background
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;

    // Don't await - run in background
    fetchMonthAvailabilityFromAPI(prevYear, prevMonth);
    fetchMonthAvailabilityFromAPI(nextYear, nextMonth);
  }
}