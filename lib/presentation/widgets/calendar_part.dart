import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/common_providers/availability_provider.dart';
import '../../../presentation/common_providers/user_events_provider.dart';
import '../features/group_management/view/day_details_dialog.dart';

class CalendarPart extends StatefulWidget {
  final String? userId;
  final String? userName;
  final bool isReadOnly;

  const CalendarPart({Key? key, this.userId, this.isReadOnly = true, this.userName}) : super(key: key);

  @override
  State<CalendarPart> createState() => _CalendarPartState();
}

class _CalendarPartState extends State<CalendarPart> {
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCalendar();
    });
  }

  Future<void> _initializeCalendar() async {
    final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);
    final eventsProvider = Provider.of<UserEventsProvider>(context, listen: false);

    availabilityProvider.resetCalendarData();

    if (widget.userId != null) {
      availabilityProvider.setSelectedUserId(widget.userId!);
      eventsProvider.setSelectedUserId(widget.userId!);
    } else {
      availabilityProvider.setSelectedUserId('');
      eventsProvider.setSelectedUserId('');
    }

    try {
      await Future.wait([
        availabilityProvider.fetchMonthAvailabilityFromAPI(_currentYear, _currentMonth),
        eventsProvider.fetchGoingEvents(context, userId: widget.userId),
      ]);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error initializing calendar: $e');
    }
  }

  Future<void> _fetchMonthData() async {
    final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);
    final eventsProvider = Provider.of<UserEventsProvider>(context, listen: false);

    availabilityProvider.resetCalendarData();

    if (widget.userId != null) {
      availabilityProvider.setSelectedUserId(widget.userId!);
      eventsProvider.setSelectedUserId(widget.userId!);
    } else {
      availabilityProvider.setSelectedUserId('');
      eventsProvider.setSelectedUserId('');
    }

    try {
      await Future.wait([
        availabilityProvider.fetchMonthAvailabilityFromAPI(_currentYear, _currentMonth),
        eventsProvider.fetchGoingEvents(context, userId: widget.userId),
      ]);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error fetching month data: $e');
    }
  }

  Future<void> _showDayDetails(DateTime date) async {
    final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Loading day details..."),
            ],
          ),
        );
      },
    );

    try {
      await availabilityProvider.fetchDayDetails(date);
      if (!mounted) return;

      Navigator.of(context).pop();

      if (availabilityProvider.dayDetailsError != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text(availabilityProvider.dayDetailsError!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      } else if (availabilityProvider.selectedDayDetails != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return DayDetailsDialog(
              dayDetails: availabilityProvider.selectedDayDetails!,
              userName: widget.userName,
              isCurrentUser: widget.userId == null,
            );
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      debugPrint('Error showing day details: $e');
    }
  }

  void _goToNextMonth() async {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
    await _fetchMonthData();
  }

  void _goToPreviousMonth() async {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
    await _fetchMonthData();
  }

  void _onDateTap(DateTime date) async {
    final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);

    if (!widget.isReadOnly &&
        date.month == _currentMonth &&
        date.year == _currentYear) {
      availabilityProvider.toggleDateState(date.day);
      return;
    }

    await _showDayDetails(date);
  }

  @override
  Widget build(BuildContext context) {
    final availabilityProvider = Provider.of<AvailabilityProvider>(context);
    final userEventsProvider = Provider.of<UserEventsProvider>(context);

    if (availabilityProvider.isLoading || userEventsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availabilityProvider.errorMessage != null || userEventsProvider.errorMessage != null) {
      final errorMessage = availabilityProvider.errorMessage ?? userEventsProvider.errorMessage;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMonthData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final startDayOffset = firstDayOfMonth.weekday % 7;

    List<DateTime> calendarDates = [];

    for (int i = 0; i < startDayOffset; i++) {
      calendarDates.add(firstDayOfMonth.subtract(Duration(days: startDayOffset - i)));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      calendarDates.add(DateTime(_currentYear, _currentMonth, i));
    }

    while (calendarDates.length % 7 != 0) {
      calendarDates.add(calendarDates.last.add(const Duration(days: 1)));
    }

    // ✅ Precompute formatted dates (avoids heavy intl calls in itemBuilder)
    final formattedDates = calendarDates
        .map((d) => DateFormat('yyyy-MM-dd').format(d))
        .toList();

    // ✅ Cache screen width calculations (instead of recalculating per cell)
    final screenWidth = MediaQuery.of(context).size.width;
    final weekdayFontSize = screenWidth * 0.035;
    final dateNumberFontSize = screenWidth * 0.04;
    final cellSpacing = screenWidth * 0.01;
    final borderRadius = screenWidth * 0.02;

    final List<String> weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: _goToPreviousMonth),
            Text('${DateTime(_currentYear, _currentMonth).monthName} $_currentYear',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: _goToNextMonth),
          ],
        ),
        SizedBox(height: screenWidth * 0.02),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: cellSpacing,
            mainAxisSpacing: cellSpacing,
          ),
          itemCount: weekdays.length,
          itemBuilder: (context, index) => Center(
            child: Text(
              weekdays[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: weekdayFontSize,
                color: AppColors.textColorPrimary,
              ),
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: cellSpacing,
            mainAxisSpacing: cellSpacing,
          ),
          itemCount: calendarDates.length,
          itemBuilder: (context, index) {
            final date = calendarDates[index];
            final formattedDate = formattedDates[index];
            final bool isCurrentMonth = date.month == _currentMonth && date.year == _currentYear;

            final state = isCurrentMonth
                ? availabilityProvider.calendarDateStates[date.day] ?? 2
                : 2;

            Color bgColor;
            Color textColor;
            Color borderColor = Colors.transparent;
            Color? blobColor;

            if (isCurrentMonth) {
              switch (state) {
                case 0:
                  blobColor = AppColors.unavailableRed;
                  textColor = AppColors.dateText;
                  borderColor = AppColors.dateBackground;
                  break;
                case 1:
                  blobColor = AppColors.availableGreen;
                  textColor = AppColors.dateText;
                  borderColor = AppColors.dateBackground;
                  break;
                default:
                  blobColor = null;
                  textColor = AppColors.dateText;
                  borderColor = AppColors.dateBackground;
                  break;
              }
              bgColor = AppColors.dateBackground;
            } else {
              bgColor = AppColors.dateBackground.withOpacity(0.5);
              textColor = AppColors.dateText.withOpacity(0.5);
              borderColor = AppColors.dateBackground.withOpacity(0.5);
              blobColor = null;
            }

            final hasGoingEvent = userEventsProvider.goingEventDates.contains(formattedDate);

            return GestureDetector(
              onTap: () => _onDateTap(date),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: dateNumberFontSize,
                        ),
                      ),
                    ),
                  ),
                  if (blobColor != null)
                    Positioned(
                      top: screenWidth * 0.005,
                      left: screenWidth * 0.005,
                      child: Container(
                        width: screenWidth * 0.02,
                        height: screenWidth * 0.02,
                        decoration: BoxDecoration(color: blobColor, shape: BoxShape.circle),
                      ),
                    ),
                  if (hasGoingEvent)
                    Positioned(
                      bottom: screenWidth * 0.005,
                      right: screenWidth * 0.005,
                      child: Icon(
                        Icons.bookmark_add,
                        size: screenWidth * 0.04,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: screenWidth * 0.03),

// ✅ Legend Section
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Available Indicator
            Row(
              children: [
                Container(
                  width: screenWidth * 0.04,
                  height: screenWidth * 0.04,
                  decoration: BoxDecoration(
                    color: AppColors.availableGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: screenWidth * 0.015),
                const Text(
                  "Available",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(width: screenWidth * 0.08),

            // Unavailable Indicator
            Row(
              children: [
                Container(
                  width: screenWidth * 0.04,
                  height: screenWidth * 0.04,
                  decoration: BoxDecoration(
                    color: AppColors.unavailableRed,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: screenWidth * 0.015),
                const Text(
                  "Unavailable",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }
}

extension MonthName on DateTime {
  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
