import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:circleslate/presentation/common_providers/availability_provider.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
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
  bool _isCancelLoading = false;
  bool _isSaveLoading = false;

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
            // Status cards with professional spacing for two cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.only(right: screenWidth * 0.04),
                    child: _buildStatusCard(
                      status: 1,
                      title: 'Available',
                      subtitle: 'for playdates',
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF36D399),
                      borderColor: const Color(0xFF36D399),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.only(left: screenWidth * 0.04),
                    child: _buildStatusCard(
                      status: 0,
                      title: 'Busy',
                      subtitle: 'not available',
                      icon: Icons.event_busy,
                      iconColor: AppColors.unavailableRed,
                      borderColor: const Color(0x14F87171),
                    ),
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

            // Center(
            //   child: ElevatedButton(
            //     onPressed: () {
            //       context.push('/availability_preview');
            //     },
            //     style: ElevatedButton.styleFrom(
            //       shadowColor: Color(0x1A000000),
            //       backgroundColor: AppColors.primaryBlue,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8.0),
            //       ),
            //       padding: const EdgeInsets.symmetric(
            //         vertical: 10.0,
            //         horizontal: 20.0,
            //       ), // Added horizontal padding
            //     ),
            //     child: const Text(
            //       'Preview',
            //       style: TextStyle(color: Colors.white, fontSize: 14.0),
            //     ),
            //   ),
            // ),

            const SizedBox(height: 30.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCancelLoading || _isSaveLoading ? null : () async {
                      setState(() {
                        _isCancelLoading = true;
                      });
                      
                      try {
                        // Add a small delay to show the loading state
                        await Future.delayed(const Duration(milliseconds: 300));
                        context.pop();
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isCancelLoading = false;
                          });
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isCancelLoading || _isSaveLoading 
                            ? Colors.grey.shade400 
                            : AppColors.primaryBlue
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: _isCancelLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                            ),
                          )
                        : const Text(
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
                    onPressed: _isCancelLoading || _isSaveLoading ? null : () async {
                      setState(() {
                        _isSaveLoading = true;
                      });

                      try {
                        final provider = Provider.of<AvailabilityProvider>(
                          context,
                          listen: false,
                        );

                        final now = DateTime.now();
                        final year = now.year;
                        final month = now.month.toString().padLeft(2, '0');
                        String selectedDay = padDay(_days[_selectedDayIndex]["date"]!);
                        String startDate = "$year-$month-$selectedDay";

                        // Calculate end_date based on repeat option
                        String endDate;
                        final startDateObj = DateTime(year, int.parse(month), int.parse(selectedDay));

                        if (_selectedRepeatOption == 0) {
                          // Just this once - same as start date
                          endDate = startDate;
                        } else if (_selectedRepeatOption == 1) {
                          // Repeat weekly - extend for 12 weeks (3 months)
                          final endDateObj = startDateObj.add(Duration(days: 7 * 12));
                          endDate = "${endDateObj.year}-${endDateObj.month.toString().padLeft(2, '0')}-${endDateObj.day.toString().padLeft(2, '0')}";
                        } else if (_selectedRepeatOption == 2) {
                          // Repeat monthly - extend for 12 months (1 year)
                          final endDateObj = DateTime(
                            startDateObj.year + 1,
                            startDateObj.month,
                            startDateObj.day,
                          );
                          endDate = "${endDateObj.year}-${endDateObj.month.toString().padLeft(2, '0')}-${endDateObj.day.toString().padLeft(2, '0')}";
                        } else {
                          endDate = startDate;
                        }

                        // Helper function to map repeat option to API value
                        String getRepeatScheduleValue(int option) {
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

                        // 📝 Log API Request Data
                        final requestData = {
                          'selectedStatus': _selectedStatus,
                          'selectedTimeSlot': _timeSlots[_selectedTimeSlotIndex],
                          'selectedTimeSlotIndex': _selectedTimeSlotIndex,
                          'selectedRepeatOption': _selectedRepeatOption,
                          'repeatOptionText': _selectedRepeatOption == 0 
                              ? 'Just this once' 
                              : _selectedRepeatOption == 1 
                                  ? 'Repeat weekly' 
                                  : 'Repeat monthly',
                          'repeatScheduleValue': getRepeatScheduleValue(_selectedRepeatOption),
                          'startDate': startDate,
                          'endDate': endDate,
                          'selectedDay': _days[_selectedDayIndex],
                          'notes': null,
                        };
                        
                        print('🚀 API CALL - Save Availability Request Data:');
                        print('═══════════════════════════════════════════════');
                        print('🌐 API Endpoint: https://app.circleslate.com/api/calendar/availability/');
                        print('📋 Method: POST');
                        print('📊 Request Data:');
                        print('  Status: ${requestData['selectedStatus']}');
                        print('  Time Slot: ${requestData['selectedTimeSlot']}');
                        print('  Time Slot Index: ${requestData['selectedTimeSlotIndex']}');
                        print('  Repeat Option: ${requestData['repeatOptionText']} (${requestData['selectedRepeatOption']})');
                        print('  🔄 repeat_schedule: "${requestData['repeatScheduleValue']}"');
                        print('  Start Date: ${requestData['startDate']}');
                        print('  End Date: ${requestData['endDate']}');
                        print('  Selected Day: ${requestData['selectedDay']}');
                        print('  Notes: ${requestData['notes']}');
                        print('═══════════════════════════════════════════════');

                        // 🚀 Call API
                        bool success = await provider.saveAvailabilityToAPI(
                          selectedStatus: _selectedStatus,
                          selectedTimeSlotIndex: _selectedTimeSlotIndex,
                          selectedRepeatOption: _selectedRepeatOption,
                          startDate: startDate,
                          endDate: endDate,
                          notes: null,
                        );

                        // 📝 Log API Response
                        print('📥 API RESPONSE - Save Availability:');
                        print('═══════════════════════════════════════════════');
                        print('🌐 API Endpoint: https://app.circleslate.com/api/calendar/availability/');
                        print('📋 Method: POST');
                        print('✅ Success: $success');
                        print('⏰ Response Time: ${DateTime.now().toIso8601String()}');
                        print('📊 Status: ${success ? 'API call completed successfully' : 'API call failed'}');
                        print('═══════════════════════════════════════════════');

                        if (success) {
                          SnackbarUtils.showSuccess(context, 'Availability Saved!');
                          context.pushNamed(AppRoutes.home);
                        } else {
                          SnackbarUtils.showError(context, 'Failed to save availability');
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSaveLoading = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCancelLoading || _isSaveLoading 
                          ? Colors.grey.shade400 
                          : AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: _isSaveLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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

  // ⬇️ STATUS CARD (Optimized for two-card professional layout)
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
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 16.0,
        ), // Increased padding for better appearance
        decoration: BoxDecoration(
          color: isSelected ? borderColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16.0), // Increased border radius
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? borderColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 32), // Increased icon size
            const SizedBox(height: 12.0), // Increased spacing
            Text(
              title,
              style: TextStyle(
                fontSize: 16.0, // Increased font size
                fontWeight: FontWeight.bold,
                color: isSelected ? iconColor : AppColors.textColorPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.0, // Increased font size
                fontWeight: FontWeight.w500,
                color: Color(0xCC1B1D2A),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
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
