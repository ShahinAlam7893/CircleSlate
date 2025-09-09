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
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);
      final eventsProvider = Provider.of<UserEventsProvider>(context, listen: false);
      availabilityProvider.resetCalendarData();

      if (widget.userId != null) {
        availabilityProvider.setSelectedUserId(widget.userId!);
        eventsProvider.setSelectedUserId(widget.userId!);
        print('CalendarPart: Set selectedUserId to ${widget.userId}');
      } else {
        availabilityProvider.setSelectedUserId('');
        eventsProvider.setSelectedUserId('');
        print('CalendarPart: Viewing current user\'s calendar');
      }

      await availabilityProvider.fetchMonthAvailabilityFromAPI(_currentYear, _currentMonth);
      await eventsProvider.fetchGoingEvents(context, userId: widget.userId);
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
    _fetchMonthData();
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
    _fetchMonthData();
  }

  void _fetchMonthData() {
    if (!mounted) return;

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

    availabilityProvider.fetchMonthAvailabilityFromAPI(_currentYear, _currentMonth);
    eventsProvider.fetchGoingEvents(context, userId: widget.userId);
  }

  void _onDateTap(DateTime date) async {
    if (!mounted || _isDialogShown) return; // Prevent multiple dialog openings

    final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);

    // If not read-only and current month, allow editing
    if (!widget.isReadOnly &&
        date.month == _currentMonth &&
        date.year == _currentYear) {
      availabilityProvider.toggleDateState(date.day);
      return;
    }

    // For read-only or viewing details, show day details dialog
    await _showDayDetails(date);
  }

  Future<void> _showDayDetails(DateTime date) async {
    if (!mounted || _isDialogShown) return;

    _isDialogShown = true;
    final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);

    try {
      // Single dialog approach with better state management
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return _DayDetailsDialogWrapper(
            date: date,
            availabilityProvider: availabilityProvider,
            userName: widget.userName,
            isCurrentUser: widget.userId == null,
          );
        },
      );
    } catch (e) {
      print('Error showing day details dialog: $e');
    } finally {
      if (mounted) {
        _isDialogShown = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availabilityProvider = Provider.of<AvailabilityProvider>(context);
    final userEventsProvider = Provider.of<UserEventsProvider>(context);

    if (availabilityProvider.isLoading || userEventsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availabilityProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${availabilityProvider.errorMessage}',
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

    if (userEventsProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${userEventsProvider.errorMessage}',
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

    // Previous month dates
    for (int i = 0; i < startDayOffset; i++) {
      calendarDates.add(firstDayOfMonth.subtract(Duration(days: startDayOffset - i)));
    }

    // Current month dates
    for (int i = 1; i <= daysInMonth; i++) {
      calendarDates.add(DateTime(_currentYear, _currentMonth, i));
    }

    // Fill remaining to make full weeks
    while (calendarDates.length % 7 != 0) {
      calendarDates.add(calendarDates.last.add(const Duration(days: 1)));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final double weekdayFontSize = screenWidth * 0.035;
    final double dateNumberFontSize = screenWidth * 0.04;
    final double cellSpacing = screenWidth * 0.01;
    final double borderRadius = screenWidth * 0.02;

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

        // Weekday labels
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

        // Calendar grid
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
            final bool isCurrentMonth = date.month == _currentMonth && date.year == _currentYear;
            final formattedDate = DateFormat('yyyy-MM-dd').format(date);

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
      ],
    );
  }
}

// Separate wrapper widget for better state management
class _DayDetailsDialogWrapper extends StatefulWidget {
  final DateTime date;
  final dynamic availabilityProvider;
  final String? userName;
  final bool isCurrentUser;

  const _DayDetailsDialogWrapper({
    required this.date,
    required this.availabilityProvider,
    this.userName,
    required this.isCurrentUser,
  });

  @override
  State<_DayDetailsDialogWrapper> createState() => _DayDetailsDialogWrapperState();
}

class _DayDetailsDialogWrapperState extends State<_DayDetailsDialogWrapper> {
  late Future<void> _fetchFuture;

  @override
  void initState() {
    super.initState();
    _fetchFuture = widget.availabilityProvider.fetchDayDetails(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _fetchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading state
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Loading day details..."),
              ],
            ),
          );
        } else {
          // Check for errors after the future completes
          if (widget.availabilityProvider.dayDetailsError != null) {
            // Error state
            return AlertDialog(
              title: const Text("Error"),
              content: Text(widget.availabilityProvider.dayDetailsError!),
              actions: [
                TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          } else if (widget.availabilityProvider.selectedDayDetails != null) {
            // Success state - show day details
            return DayDetailsDialog(
              dayDetails: widget.availabilityProvider.selectedDayDetails!,
              userName: widget.userName,
              isCurrentUser: widget.isCurrentUser,
            );
          } else {
            // Fallback state
            return AlertDialog(
              title: const Text("No Details"),
              content: const Text("No details available for this day."),
              actions: [
                TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          }
        }
      },
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