// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../core/network/endpoints.dart';
//
// class UsersAvailabilityProvider extends ChangeNotifier {
//   Map<int, int> _calendarDateStates = {};
//   bool _isLoading = false;
//   String? _errorMessage;
//   String? _selectedUserId;
//
//   Map<int, int> get calendarDateStates => _calendarDateStates;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//
//   void resetCalendarData() {
//     _calendarDateStates.clear();
//     _isLoading = false;
//     _errorMessage = null;
//     print('UsersAvailabilityProvider: Reset calendar data');
//     notifyListeners();
//   }
//
//   void setSelectedUserId(String userId) {
//     _selectedUserId = userId;
//     print('UsersAvailabilityProvider: Set selectedUserId to $userId');
//     notifyListeners();
//   }
//
//   Future<void> fetchMonthAvailabilityForUser(int year, int month, String userId) async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();
//
//     print('UsersAvailabilityProvider: Fetching availability for $month/$year, user: $userId');
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('accessToken');
//       if (token == null) {
//         _errorMessage = 'Authentication token missing';
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
//
//       final response = await http.get(
//         Uri.parse('${Urls.baseUrl}/calendar/availability/?user_id=$userId'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       print('UsersAvailabilityProvider: Response status: ${response.statusCode}');
//       print('UsersAvailabilityProvider: Response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         _calendarDateStates.clear();
//
//         for (var item in data) {
//           final int day = DateTime.parse(item['date']).day;
//           final bool isAvailable = item['available_time_slots'] != null && item['available_time_slots'].isNotEmpty;
//           _calendarDateStates[day] = isAvailable ? 1 : 0;
//         }
//
//         // Fill missing days with 'maybe' status (2)
//         final daysInMonth = DateTime(year, month + 1, 0).day;
//         for (int i = 1; i <= daysInMonth; i++) {
//           _calendarDateStates.putIfAbsent(i, () => 2);
//         }
//
//         print('UsersAvailabilityProvider: Calendar data updated for $month/$year: $_calendarDateStates');
//       } else {
//         _errorMessage = 'Failed to load availability: ${response.statusCode}';
//       }
//     } catch (e) {
//       _errorMessage = 'Error fetching availability: $e';
//       print('UsersAvailabilityProvider: $_errorMessage');
//     }
//
//     _isLoading = false;
//     notifyListeners();
//   }
// }