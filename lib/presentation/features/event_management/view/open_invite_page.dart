import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For date and time formatting

class OpenInvitePage extends StatefulWidget {
  const OpenInvitePage({super.key});

  @override
  State<OpenInvitePage> createState() => _OpenInvitePageState();
}

class _OpenInvitePageState extends State<OpenInvitePage> {
  final TextEditingController _activityTitleController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _selectedIndex = 2; // Assuming 'Groups' is the 3rd tab (index 2)

  @override
  void dispose() {
    _activityTitleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textColorPrimary, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textColorPrimary, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  void _postOpenInvite() {
    if (_formKey.currentState!.validate()) {
      // Logic to post the open invite
      SnackbarUtils.showSuccess(context, 'Open Invite Posted!');
      // You would typically send this data to a backend
      print('Activity Title: ${_activityTitleController.text}');
      print('Date: ${_dateController.text}');
      print('Time: ${_timeController.text}');
      print('Location: ${_locationController.text}');
      print('Description: ${_descriptionController.text}');

      // Optionally, navigate back or clear fields
      Navigator.of(context).pop();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        context.go(RoutePaths.home);
      } else if (index == 1) {
        context.go(RoutePaths.upcomingeventspage);
      } else if (index == 2) {
        context.go(RoutePaths.groupManagement);
      } else if (index == 3) {
        // context.go(RoutePaths.availability);
      } else if (index == 4) {
        // context.go(RoutePaths.settings);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Open Invite',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Color(0x0D5A8DEE),
                  // color: AppColors.buttonPrimary,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.quickActionCardBorder,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      AppAssets
                          .openInviteIcon, // Placeholder for the small icon
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.group_add, // Fallback icon
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: AppColors.textColorPrimary,
                            fontFamily: 'Poppins',
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Open Invite: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Anyone in this group can join this activity. Perfect for group outings and community events!',
                              style: TextStyle(
                                color: AppColors.textColorSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Activity Title
              const Text(
                'Activity Title *',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColorPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _activityTitleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Museum Visit, Park Playdate...',
                  hintStyle: const TextStyle(
                    color: AppColors.textColorSecondary,
                    fontFamily: 'Poppins',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an activity title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),

              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date *',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColorPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: InputDecoration(
                            hintText: '07/15/2025',
                            hintStyle: const TextStyle(
                              color: AppColors.textColorSecondary,
                              fontFamily: 'Poppins',
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select a date';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time *',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColorPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _timeController,
                          readOnly: true,
                          onTap: () => _selectTime(context),
                          decoration: InputDecoration(
                            hintText: '11:02 AM',
                            hintStyle: const TextStyle(
                              color: AppColors.textColorSecondary,
                              fontFamily: 'Poppins',
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            suffixIcon: Icon(
                              Icons.access_time_outlined,
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select a time';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // Location
              const Text(
                'Location *',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColorPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Enter location...',
                  hintStyle: const TextStyle(
                    color: AppColors.textColorSecondary,
                    fontFamily: 'Poppins',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),

              // Description (Optional)
              const Text(
                'Description (Optional)',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColorPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tell other about this activity....',
                  hintStyle: const TextStyle(
                    color: AppColors.textColorSecondary,
                    fontFamily: 'Poppins',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 40.0),

              // Post Open Invite Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _postOpenInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Post Open Invite',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
