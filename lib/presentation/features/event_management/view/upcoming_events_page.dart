import 'package:circleslate/presentation/features/event_management/controllers/eventManagementControllers.dart';
import 'package:circleslate/presentation/features/event_management/models/eventsModels.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import go_router for navigation

// --- AppColors (Ideally from lib/core/constants/app_colors.dart) ---
// Defined here for self-containment in Canvas.
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
          final events = snapshot.data ?? [];

          //final itemsToShow = events.length > 4 ? 4 : events.length;

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
                //if (events.length > 4) _buildViewMoreAndAddButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    // Added BuildContext context
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
        shadowColor: Color(0x14000000), // No shadow for the card itself
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // CRITICAL CHANGE: Wrap event.title in Expanded
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1, // Ensure it doesn't wrap more than one line
                      overflow:
                          TextOverflow.ellipsis, // Add ellipsis if it overflows
                    ),
                  ),
                  // The status container will take its natural size
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
                      maxLines: 1, // Ensure status text doesn't wrap
                      overflow: TextOverflow
                          .ellipsis, // Add ellipsis if status is unexpectedly long
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
    // You might also need to make this row responsive if the text is very long
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8.0),
        Expanded(
          // CRITICAL CHANGE: Wrap Text in Expanded here too
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textMedium,
              fontFamily: 'Poppins',
            ),
            maxLines: 1, // Limit to one line
            overflow: TextOverflow.ellipsis, // Add ellipsis
          ),
        ),
      ],
    );
  }

  Widget _buildViewMoreAndAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.start, // Align to start, Expanded will push
        children: [
          Expanded(
            // Expanded to take available space and allow centering
            child: Center(
              // Center the ElevatedButton within the Expanded space
              child: SizedBox(
                // Wrap with SizedBox for fixed dimensions
                width: 72.0, // Set width as requested
                height: 32.0, // Set height as requested
                child: ElevatedButton(
                  onPressed: () {
                    // Handle "View More" action - in a real app, this would load more events
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loading more events...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: EdgeInsets
                        .zero, // Remove default padding if using SizedBox for size
                  ),
                  child: const Text(
                    'View More',
                    style: TextStyle(
                      fontSize: 10.0, // Keep the requested font size
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ),
          // const SizedBox(width: 0.0), // Spacing between the centered button and the right-aligned button
          Center(
            child: SizedBox(
              // This will naturally be on the right after the Expanded
              width: 40,
              height: 40,
              child: FloatingActionButton(
                heroTag: "addEventFab", // Unique tag for hero animation
                onPressed: () {
                  // Navigate to CreateEventPage
                  context.push(RoutePaths.createeventspage);
                  // context.go(RoutePaths.createeventspage);
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
