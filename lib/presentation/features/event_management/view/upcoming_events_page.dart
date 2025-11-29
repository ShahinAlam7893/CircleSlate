import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:circleslate/presentation/features/event_management/controllers/eventManagementControllers.dart';
import 'package:circleslate/presentation/features/event_management/models/eventsModels.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Import go_router for navigation

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
}

class UpcomingEventsPage extends StatefulWidget {
  const UpcomingEventsPage({super.key});

  @override
  State<UpcomingEventsPage> createState() => _UpcomingEventsPageState();
}

class _UpcomingEventsPageState extends State<UpcomingEventsPage> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = EventService.fetchEvents();
  }

  List<Event> _getUpcomingEvents(List<Event> events) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    final upcomingEvents = events.where((event) {
      try {
        final eventDate = dateFormat.parse(event.date);
        final eventTime = timeFormat.parse(event.time);
        final eventDateTime = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          eventTime.hour,
          eventTime.minute,
        );
        return eventDateTime.isAfter(now);
      } catch (e) {
        return false; // Skip invalid events
      }
    }).toList();

    upcomingEvents.sort((a, b) {
      try {
        final aDate = dateFormat.parse(a.date);
        final aTime = timeFormat.parse(a.time);
        final aDateTime = DateTime(aDate.year, aDate.month, aDate.day, aTime.hour, aTime.minute);

        final bDate = dateFormat.parse(b.date);
        final bTime = timeFormat.parse(b.time);
        final bDateTime = DateTime(bDate.year, bDate.month, bDate.day, bTime.hour, bTime.minute);

        return aDateTime.compareTo(bDateTime);
      } catch (e) {
        return 0;
      }
    });

    return upcomingEvents;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          'Upcoming Events',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _eventsFuture = EventService.fetchEvents();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final events = _getUpcomingEvents(snapshot.data ?? []);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(context, events[index]);
                    },
                  ),
                ),
                // If you want "View More" and FAB, uncomment below:
                // if (events.length > 4) _buildViewMoreAndAddButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    Color statusBackgroundColor;
    Color statusTextColor;

    if (event.status == 'Open') {
      statusBackgroundColor = AppColors.openStatusColor;
      statusTextColor = AppColors.openStatusText;
    } else if (event.status == 'Ride Needed') {
      statusBackgroundColor = AppColors.rideNeededStatusColor;
      statusTextColor = AppColors.rideNeededStatusText;
    } else {
      statusBackgroundColor = Colors.grey[200]!;
      statusTextColor = Colors.grey[700]!;
    }

    return GestureDetector(
      onTap: () {
        print("Tapped event id: ${event.id}");
        context.push("${RoutePaths.eventDetails}/${event.id}");
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        elevation: 0,
        color: Colors.white,
        shadowColor: Color(0x14000000),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackgroundColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      event.status,
                      style: TextStyle(
                        fontSize: 10.0,
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
              const SizedBox(height: 12.0),
              _buildInfoRow(
                Icons.calendar_month,
                event.date,
                iconColor: Color(0xFF5A8DEE),
              ),
              const SizedBox(height: 8.0),
              _buildInfoRow(
                Icons.access_time,
                event.time,
                iconColor: Color(0xFFFFE082),
              ),
              const SizedBox(height: 8.0),
              _buildInfoRow(
                Icons.location_on_outlined,
                event.location,
                iconColor: Color(0xFFF87171),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textMedium,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildViewMoreAndAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 72.0,
                height: 32.0,
                child: ElevatedButton(
                  onPressed: () {
                    SnackbarUtils.showInfo(context, 'Loading more events...');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'View More',
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton(
                heroTag: "addEventFab",
                onPressed: () {
                  context.push(RoutePaths.createeventspage);
                },
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: const Icon(Icons.add, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
