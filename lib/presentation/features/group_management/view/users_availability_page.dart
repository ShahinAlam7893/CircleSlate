import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../common_providers/availability_provider.dart';
import '../../../common_providers/user_events_provider.dart';
import '../../../widgets/calendar_part.dart';

class UserAvailabilityCalendarPage extends StatelessWidget {
  final String userId;
  final String userName;

  const UserAvailabilityCalendarPage({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AvailabilityProvider>(
          create: (_) {
            final provider = AvailabilityProvider();
            provider.setSelectedUserId(userId);
            return provider;
          },
        ),
        ChangeNotifierProvider<UserEventsProvider>(
          create: (_) {
            final provider = UserEventsProvider();
            provider.setSelectedUserId(userId);
            return provider;
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("$userName's Availability",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryBlue,
        ),
        body: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);
              final eventsProvider = Provider.of<UserEventsProvider>(context, listen: false);
              await availabilityProvider.fetchMonthAvailabilityFromAPI(
                DateTime.now().year,
                DateTime.now().month,
              );
              await eventsProvider.fetchGoingEvents(context, userId: userId);
            });
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: CalendarPart(
                userId: userId,
                userName: userName,
                isReadOnly: true,
              ),
            );
          },
        ),
      ),
    );
  }
}