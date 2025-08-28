import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/presentation/common_providers/availability_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  int _selectedStatus = 1;
  int _selectedDayIndex = 0;
  int _selectedTimeSlotIndex = -1;
  int _selectedRepeatOption = 0;

  List<Map<String, String>> _generateCurrentWeekDays() {
    final now = DateTime.now();

    // Find the Sunday of the current week
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    // Create a list for 7 days
    return List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      return {"day": _getDayName(date.weekday), "date": date.day.toString()};
    });
  }

  String _getDayName(int weekday) {
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return days[weekday % 7];
  }

  List<String> _timeSlots = [
    'Morning\n8:00-12:00',
    'Afternoon\n12:00-5:00',
    'Evening\n5:00-8:00',
    'Night\n8:00-10:00',
  ];

  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  List<Map<String, String>> _days = [];

  @override
  void initState() {
    super.initState();
    _days = _generateCurrentWeekDays();
    // Load current month availability on page open
    Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    ).fetchMonthAvailabilityFromAPI(_currentYear, _currentMonth);
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
    Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    ).fetchMonthAvailabilityFromAPI(_currentYear, _currentMonth);
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
    Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    ).fetchMonthAvailabilityFromAPI(_currentYear, _currentMonth);
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to make elements responsive
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Center(
          child: const Text(
            'Availability Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textColorPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16.0),
            // We need to ensure the status cards also adapt to smaller screens
            // Use Flexible or Expanded for status cards if they overflow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  // Use Flexible for each status card
                  child: _buildStatusCard(
                    status: 1,
                    title: 'Available',
                    subtitle: 'for playdates',
                    icon: Icons.check_circle,
                    iconColor: const Color(0xFF36D399),
                    borderColor: const Color(0xFF36D399),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02), // Small responsive gap
                Flexible(
                  child: _buildStatusCard(
                    status: 0,
                    title: 'Busy',
                    subtitle: 'not available',
                    icon: Icons.event_busy,
                    iconColor: AppColors.unavailableRed,
                    borderColor: const Color(0x14F87171),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02), // Small responsive gap
                Flexible(
                  child: _buildStatusCard(
                    status: 2,
                    title: 'Maybe',
                    subtitle: 'available',
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFFFFE082),
                    borderColor: const Color(0x14FFE082),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),

            // ⬇️ DAY SELECTOR
            const Text(
              'Choose Days Available',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textColorPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16.0),
            _buildDaySelector(screenWidth), // Pass screenWidth to the method

            const SizedBox(height: 30.0),

            // ⬇️ TIME SLOT SELECTOR
            const Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textColorPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16.0),
            _buildTimeSlotSelector(screenWidth), // Pass screenWidth

            const SizedBox(height: 30.0),
            const Text(
              'Repeat Schedule',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textColorPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16.0),
            _buildRepeatScheduleOptions(),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  context.push('/availability_preview');
                },
                style: ElevatedButton.styleFrom(
                  shadowColor: Color(0x1A000000),
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 20.0,
                  ), // Added horizontal padding
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(color: Colors.white, fontSize: 14.0),
                ),
              ),
            ),

            const SizedBox(height: 30.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final provider = Provider.of<AvailabilityProvider>(
                        context,
                        listen: false,
                      );


                      final now = DateTime.now();
                      final year = now.year;
                      final month = now.month.toString().padLeft(2, '0');
                      String selectedDay = padDay(
                        _days[_selectedDayIndex]["date"]!,
                      );
                      String startDate = "$year-$month-$selectedDay";

                      final endDateObj = DateTime(
                        year,
                        int.parse(month),
                        int.parse(selectedDay),
                      );
                      String endDate =
                          "${endDateObj.year}-${endDateObj.month.toString().padLeft(2, '0')}-${endDateObj.day.toString().padLeft(2, '0')}";

                      // 🚀 Call API
                      bool success = await provider.saveAvailabilityToAPI(
                        selectedStatus: _selectedStatus,
                        selectedTimeSlotIndex: _selectedTimeSlotIndex,
                        selectedRepeatOption: _selectedRepeatOption,
                        startDate: startDate,
                        endDate: endDate,
                        notes: null,
                        // token: null, // Later: fetch from SharedPreferences
                      );

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Availability Saved!')),
                        );
                        context.push('/up_coming_events');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to save availability'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String padDay(String day) {
    return day.length == 1 ? '0$day' : day;
  }

  // ⬇️ STATUS CARD (Added responsive width to inner Container)
  Widget _buildStatusCard({
    required int status,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
  }) {
    bool isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        // Removed fixed width: 100
        padding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 4.0,
        ), // Reduced horizontal padding
        decoration: BoxDecoration(
          color: isSelected ? borderColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 26), // Reduced icon size
            const SizedBox(height: 6.0), // Reduced spacing
            Text(
              title,
              style: TextStyle(
                fontSize: 13.0, // Reduced font size
                fontWeight: FontWeight.bold,
                color: isSelected ? iconColor : AppColors.textColorPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10.0, // Reduced font size
                fontWeight: FontWeight.w500,
                color: Color(0xCC1B1D2A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ⬇️ DAY SELECTOR (Modified to use Expanded for each day cell)
  Widget _buildDaySelector(double screenWidth) {
    // Accepts screenWidth
    return Container(
      padding: const EdgeInsets.all(10.0), // Slightly reduced overall padding
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Still use spaceBetween
        children: List.generate(_days.length, (index) {
          bool isSelected = _selectedDayIndex == index;
          return Expanded(
            // <-- CRITICAL CHANGE: Use Expanded for each day item
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
              },
              child: Container(
                // No fixed width here, Expanded will manage it
                padding: EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: screenWidth * 0.005,
                ), // Make horizontal padding very small and responsive
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Ensure Column takes min height
                  children: [
                    Text(
                      _days[index]["day"]!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:
                            screenWidth * 0.035, // Responsive font size for day
                        color: isSelected ? Colors.blue : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      _days[index]["date"]!,
                      style: TextStyle(
                        fontSize:
                            screenWidth * 0.03, // Responsive font size for date
                        color: isSelected
                            ? Colors.blue
                            : AppColors.textColorPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ⬇️ TIME SLOT SELECTOR (Added responsive adjustments)
  Widget _buildTimeSlotSelector(double screenWidth) {
    // Accepts screenWidth
    return Container(
      padding: const EdgeInsets.all(10.0), // Slightly reduced overall padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 10, // Reduced spacing
        crossAxisSpacing: 10, // Reduced spacing
        childAspectRatio:
            (screenWidth / 2 - 20) /
            (screenWidth * 0.18), // Responsive aspect ratio
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(_timeSlots.length, (index) {
          bool isSelected = _selectedTimeSlotIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeSlotIndex = index;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0x80D8ECFF)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5A8DEE)
                      : const Color(0x1A1B1D2A),
                ),
              ),
              child: Text(
                _timeSlots[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize:
                      screenWidth * 0.035, // Responsive font size for time slot
                  color: isSelected
                      ? AppColors.buttonPrimary
                      : AppColors.textColorPrimary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRepeatScheduleOptions() {
    final List<String> options = [
      'Just this once',
      'Repeat weekly',
      'Repeat monthly',
      // 'Custom schedule',
    ];

    return Container(
      // Using horizontal padding from build method for consistency
      // And reduced vertical margin
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0), // Slightly reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repeat Schedule',
            style: TextStyle(
              fontSize: 15.0, // Slightly reduced font size
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10.0), // Reduced spacing
          ...List.generate(options.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6.0), // Reduced margin
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedRepeatOption == index
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: RadioListTile<int>(
                title: Text(
                  options[index],
                  style: const TextStyle(
                    fontSize: 13.0, // Slightly reduced font size
                    color: AppColors.textColorPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                value: index,
                groupValue: _selectedRepeatOption,
                onChanged: (int? value) {
                  setState(() {
                    _selectedRepeatOption = value!;
                  });
                },
                activeColor: AppColors.primaryBlue,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ), // Reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
