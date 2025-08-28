import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/features/event_management/controllers/eventManagementControllers.dart';
import 'package:circleslate/presentation/features/event_management/models/eventsModels.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserEventsProvider extends ChangeNotifier {
  Set<String> _goingEventDates = {}; // Store dates as 'yyyy-MM-dd'
  bool isLoading = false;
  String? errorMessage;
  String? selectedUserId;

  Set<String> get goingEventDates => _goingEventDates;

  void setSelectedUserId(String userId) {
    selectedUserId = userId.isNotEmpty ? userId : null;
    print('UserEventsProvider: Set selectedUserId to $selectedUserId');
    notifyListeners();
  }

  // Fetch all events where user is "going"
  Future<void> fetchGoingEvents(BuildContext context, {String? userId}) async {
    isLoading = true;
    errorMessage = null;
    _goingEventDates.clear();
    notifyListeners();

    // Use provided userId if available, otherwise fall back to AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final effectiveUserId = userId ?? authProvider.userProfile?['id']?.toString();
    if (effectiveUserId == null) {
      print("UserEventsProvider: No userId provided and no userId in AuthProvider");
      errorMessage = 'No user ID available';
      isLoading = false;
      notifyListeners();
      return;
    }

    print('UserEventsProvider: Fetching events for user ID: $effectiveUserId');

    try {
      List<Event> events = await EventService.fetchEvents();
      final goingEvents = events
          .where((event) => event.responses.any((resp) => resp.userId == effectiveUserId && resp.responseDisplay == 'Going'))
          .toList();

      _goingEventDates = goingEvents.map((event) => event.date).toSet();
      print('UserEventsProvider: Fetched ${_goingEventDates.length} going events for user $effectiveUserId');
      print('UserEventsProvider: Going event dates: $_goingEventDates');
    } catch (e) {
      errorMessage = 'Error fetching events: $e';
      print('UserEventsProvider: $errorMessage');
    }

    isLoading = false;
    notifyListeners();
  }

  // Add a date when user marks "going"
  void addGoingDate(String date) {
    _goingEventDates.add(date);
    notifyListeners();
  }

  // Remove a date when user marks "not_going"
  void removeGoingDate(String date) {
    _goingEventDates.remove(date);
    notifyListeners();
  }
}