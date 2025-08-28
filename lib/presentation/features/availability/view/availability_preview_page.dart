import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/presentation/common_providers/availability_provider.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvailabilityPreviewPage extends StatefulWidget {
  const AvailabilityPreviewPage({super.key});

  @override
  State<AvailabilityPreviewPage> createState() =>
      _AvailabilityPreviewPageState();
}

class _AvailabilityPreviewPageState extends State<AvailabilityPreviewPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token != null && token.isNotEmpty) {
      final provider = Provider.of<AvailabilityProvider>(context, listen: false);

      if (provider.selectedUserId != null) {
        // Fetch availability for the selected user
        await provider.fetchAvailabilityForUser(provider.selectedUserId!);
      } else {
        // Fallback: fetch own availability
        await provider.fetchMonthAvailabilityFromAPI(
          DateTime.now().year,
          DateTime.now().month,
        );
      }
    }

    setState(() => _isLoading = false);
  }


  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Busy';
      case 1:
        return 'Available';
      case 2:
      default:
        return 'Tentative';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return AppColors.unavailableRed;
      case 1:
        return AppColors.availableGreen;
      case 2:
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive font sizes
    final double appBarTitleFontSize = screenWidth * 0.045;
    final double sectionTitleFontSize = screenWidth * 0.04;
    final double dayNameFontSize = screenWidth * 0.038;
    final double statusTextFontSize = screenWidth * 0.032;

    // Responsive spacing
    final double mainPadding = screenWidth * 0.06;
    final double sectionSpacing = screenWidth * 0.04;
    final double itemVerticalPadding = screenWidth * 0.02;
    final double statusPaddingHorizontal = screenWidth * 0.025;
    final double statusPaddingVertical = screenWidth * 0.012;
    final double borderRadiusSmall = screenWidth * 0.03;
    final double borderRadiusMedium = screenWidth * 0.05;
    final double fabSize = screenWidth * 0.14;
    final double fabIconSize = screenWidth * 0.07;

    // Watch the AvailabilityProvider for changes
    final availabilityProvider = Provider.of<AvailabilityProvider>(context);

    // Get today's weekday to highlight "Today"
    final int todayWeekday = DateTime.now().weekday;

    // Weekdays mapping
    final List<Map<String, dynamic>> weekDaysData = [
      {'name': 'Sunday', 'weekday': DateTime.sunday},
      {'name': 'Monday', 'weekday': DateTime.monday},
      {'name': 'Tuesday', 'weekday': DateTime.tuesday},
      {'name': 'Wednesday', 'weekday': DateTime.wednesday},
      {'name': 'Thursday', 'weekday': DateTime.thursday},
      {'name': 'Friday', 'weekday': DateTime.friday},
      {'name': 'Saturday', 'weekday': DateTime.saturday},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.buttonPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: screenWidth * 0.06,
          ),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(
          'Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: appBarTitleFontSize,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(mainPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week\'s Availability',
                    style: TextStyle(
                      fontSize: sectionTitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColorPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(borderRadiusSmall),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: weekDaysData.length,
                      itemBuilder: (context, index) {
                        final dayName = weekDaysData[index]['name'];
                        final dayWeekday = weekDaysData[index]['weekday'];
                        final isToday = dayWeekday == todayWeekday;

                        // Get API data
                        final apiData = availabilityProvider.apiAvailability;
                        final int status = apiData[dayWeekday]?['status'] ?? 2;
                        final String timeRange =
                            apiData[dayWeekday]?['timeRange'] ?? 'Not Set';

                        final String statusText = _getStatusText(status);
                        final Color statusColor = _getStatusColor(status);

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: itemVerticalPadding,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isToday ? '$dayName (Today)' : dayName,
                                style: TextStyle(
                                  fontSize: dayNameFontSize,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: AppColors.textColorPrimary,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: statusPaddingHorizontal,
                                  vertical: statusPaddingVertical,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    borderRadiusMedium,
                                  ),
                                  border: Border.all(
                                    color: statusColor,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  '$statusText $timeRange',
                                  style: TextStyle(
                                    fontSize: statusTextFontSize,
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.07),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: fabSize,
                      height: fabSize,
                      child: FloatingActionButton(
                        onPressed: () async {
                          // Go to edit page and refresh when back
                          await context.push('/availability');
                          _loadAvailability();
                        },
                        backgroundColor: AppColors.primaryBlue,
                        shape: const CircleBorder(),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: fabIconSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.toString();
    if (location == '/home') return 0;
    if (location == '/up_coming_events') return 1;
    if (location == '/group_chat') return 2;
    if (location == '/availability' || location == '/availability_preview') {
      return 3;
    }
    if (location == '/settings') return 4;
    return 0;
  }
}
