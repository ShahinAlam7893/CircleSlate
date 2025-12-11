import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/presentation/common_providers/availability_provider.dart';
// For date formatting
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../widgets/calendar_part.dart';
import '../widgets/my_group_section.dart';
import '../../group_management/view/day_details_dialog.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationIconWithBadge extends StatefulWidget {
  final double iconSize;
  final VoidCallback onPressed;

  const NotificationIconWithBadge({
    Key? key,
    required this.iconSize,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<NotificationIconWithBadge> createState() =>
      _NotificationIconWithBadgeState();
}

class _NotificationIconWithBadgeState extends State<NotificationIconWithBadge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Refresh count every 30 seconds for real-time updates
    _startPeriodicRefresh();
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading unread count: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startPeriodicRefresh() {
    // Refresh unread count every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadUnreadCount();
        _startPeriodicRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        widget.onPressed();
        // Refresh count after navigating to notifications
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadUnreadCount();
          }
        });
      },
      child: Stack(
        children: [
          Icon(Icons.notifications, color: Colors.white, size: widget.iconSize),

          //if (_unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(
                widget.iconSize * 0.1,
              ), // Responsive padding
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(screenWidth * 0.03), // Responsive border radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: screenWidth * 0.04, // Responsive minimum width
                minHeight: screenWidth * 0.04, // Responsive minimum height
              ),
              child: Text(
                _unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.025, // Responsive font size
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class HeaderSection extends StatefulWidget {
  const HeaderSection({Key? key}) : super(key: key);

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  String childName = '';

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final authProvider = context.read<AuthProvider>();
    final children = await authProvider.fetchChildren();

    if (children.isNotEmpty && mounted) {
      setState(() {
        childName = children.first['name'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive font sizes
    final double headerNameFontSize = screenWidth * 0.045; // Reduced from 0.055
    final double headerSubtitleFontSize = screenWidth * 0.035; // Reduced from 0.04

    if (authProvider.isLoading) {
      return SizedBox(
        width: screenWidth * 0.05,
        height: screenWidth * 0.05,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final profile = authProvider.userProfile ?? {};
    final fullName = profile["full_name"] ?? "";

    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, $fullName!",
            style: TextStyle(
              fontSize: headerNameFontSize, // Responsive font size
              fontWeight: FontWeight.w400,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis, // Handle overflow
            maxLines: 1, // Limit to single line
          ),
          if (childName.isNotEmpty)
            Text(
              "Manage $childName's activities",
              style: TextStyle(
                fontSize: headerSubtitleFontSize, // Responsive font size
                fontWeight: FontWeight.w400,
                color: const Color(0xCCFFFFFF),
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis, // Handle overflow
              maxLines: 1, // Limit to single line
            ),
        ],
      ),
    );
  }
}

// --- AuthInputField --- (Copied from previous response for self-containment)
class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final bool isPassword;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;

  const AuthInputField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  _AuthInputFieldState createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double labelFontSize = screenWidth * 0.032;
    final double hintFontSize = screenWidth * 0.03;
    final double inputContentPaddingVertical = screenWidth * 0.035;
    final double inputContentPaddingHorizontal = screenWidth * 0.04;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: TextStyle(
            color: AppColors.textColorSecondary,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          validator: widget.validator,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
              borderSide: const BorderSide(
                color: AppColors.inputOutline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
              borderSide: const BorderSide(
                color: AppColors.inputOutline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            hintStyle: TextStyle(
              color: AppColors.inputHintColor,
              fontSize: hintFontSize,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              vertical: inputContentPaddingVertical,
              horizontal: inputContentPaddingHorizontal,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.black,
                size: screenWidth * 0.05,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
                : (widget.suffixIcon != null
                ? SizedBox(
              width: screenWidth * 0.08,
              height: screenWidth * 0.08,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: widget.suffixIcon,
              ),
            )
                : null),
          ),
        ),
      ],
    );
  }
}

// --- PlaceholderScreen for other routes, kept here for self-containment
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.buttonPrimary,
      ),
      body: Center(
        child: Text(
          'Welcome to the $title Page!',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
    if (location == '/availability') return 3;
    if (location == '/settings') return 4;
    return 0; // Default
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // For the bottom navigation bar

  // Controllers for Child Information
  final List<TextEditingController> _childNameControllers = [];
  final List<TextEditingController> _childAgeControllers = [];

  // State for showing/hiding child information section
  bool _showChildInfoSection = false;

  // State for Join Groups checkboxes
  final Map<String, bool> _groupSelections = {
    'Kindergarten': false,
    '1st Grade': false,
    '2nd Grade': false,
    '3rd Grade': false,
    '4th Grade': false,
    'Soccer Team': false,
    'Moms Group': false,
    'Dads Group': false,
    'Basketball': false,
    'Art Class': false,
  };

  @override
  void dispose() {
    for (var controller in _childNameControllers) {
      controller.dispose();
    }
    for (var controller in _childAgeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addChildField() {
    setState(() {
      _showChildInfoSection = true; // Show the section when adding a child
      _childNameControllers.add(TextEditingController());
      _childAgeControllers.add(TextEditingController());
    });
  }

  void _removeChildField(int index) {
    setState(() {
      _childNameControllers[index].dispose();
      _childAgeControllers[index].dispose();
      _childNameControllers.removeAt(index);
      _childAgeControllers.removeAt(index);

      // Hide section if no children left
      if (_childNameControllers.isEmpty) {
        _showChildInfoSection = false;
      }
    });
  }

  Future<void> _showAvailabilityDetails(DateTime date) async {
    final availabilityProvider = Provider.of<AvailabilityProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Show loading dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Loading availability details..."),
              ],
            ),
          );
        },
      );

      // Fetch day details
      await availabilityProvider.fetchDayDetails(date);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show day details dialog
      if (mounted) {
        if (availabilityProvider.dayDetailsError != null) {
          // Show error dialog
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
          // Show day details
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return DayDetailsDialog(
                dayDetails: availabilityProvider.selectedDayDetails!,
                userName: authProvider.userProfile?['full_name'],
                isCurrentUser: true,
              );
            },
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text("Failed to load availability details: $e"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive font sizes
    final double availabilityTextFontSize = screenWidth * 0.032;
    final double quickActionTitleFontSize = screenWidth * 0.045;
    final double sectionTitleFontSize = screenWidth * 0.04;
    final double childInfoAddChildFontSize = screenWidth * 0.03;
    final double childInfoChildNumFontSize = screenWidth * 0.035;
    final double groupSelectionHintFontSize = screenWidth * 0.025;
    final double groupNameFontSize = screenWidth * 0.038;
    final double calendarMonthFontSize = screenWidth * 0.05;
    final double weekdayFontSize = screenWidth * 0.038;
    final double calendarDateFontSize = screenWidth * 0.04;
    final double legendFontSize = screenWidth * 0.032;
    final double saveButtonFontSize = screenWidth * 0.04;

    // Responsive spacing
    final double largeSpacing = screenWidth * 0.05;
    final double mediumSpacing = screenWidth * 0.04;
    final double smallSpacing = screenWidth * 0.03;
    final double extraSmallSpacing = screenWidth * 0.02;

    // Watch the AvailabilityProvider for changes
    final availabilityProvider = Provider.of<AvailabilityProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Header Section (Responsive App Bar)
          Container(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.04, // Reduced horizontal padding
              screenHeight * 0.05,
              screenWidth * 0.04, // Reduced horizontal padding
              screenHeight * 0.02, // Reduced bottom padding
            ), // Responsive padding
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(screenWidth * 0.05),
              ), // Responsive border radius
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile picture and text section
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                context.push('/profile');
                              },
                              child: Container(
                                width: screenWidth * 0.11, // Slightly reduced
                                height: screenWidth * 0.11, // Slightly reduced
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: screenWidth * 0.005,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      final photo =
                                          auth.userProfile?["profile_photo"] ??
                                              "";

                                      if (photo.toString().isNotEmpty) {
                                        final imageUrl =
                                        photo.toString().startsWith("http")
                                            ? photo.toString()
                                            : "http:app.circleslate.com$photo";

                                        return Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: screenWidth * 0.08, // Responsive icon size
                                              color: Colors.white,
                                            );
                                          },
                                        );
                                      } else {
                                        return Icon(
                                          Icons.person,
                                          size: screenWidth * 0.08, // Responsive icon size
                                          color: Colors.white,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: screenWidth * 0.025), // Responsive spacing
                            const HeaderSection(),
                          ],
                        ),
                      ),
                      // Notification Bell Icon
                      NotificationIconWithBadge(
                        iconSize: screenWidth * 0.065, // Responsive icon size
                        onPressed: () {
                          final authProvider = context.read<AuthProvider>();
                          final userId =
                              authProvider.userProfile?['id']?.toString() ?? '';

                          if (userId.isNotEmpty) {
                            context.pushReplacement(
                              '/notifications',
                              extra: userId,
                            );
                          } else {
                            // Optionally handle if userId is null
                            SnackbarUtils.showWarning(context, "User not logged in");
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.03), // Responsive spacing

                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: screenWidth * 0.03,
                        color: Colors.green,
                      ), // Responsive icon size
                      SizedBox(width: extraSmallSpacing), // Responsive spacing
                      Flexible(
                        child: Text(
                          'Available for activities',
                          style: TextStyle(
                            fontSize: availabilityTextFontSize, // Responsive font size
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main Content Area (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: mediumSpacing,
              ), // Responsive padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: quickActionTitleFontSize, // Responsive font size
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColorPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: smallSpacing), // Responsive spacing
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context: context, // Pass context
                          icon: Image.asset(
                            AppAssets.plusIcon,
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.add_circle_outline,
                              size: screenWidth * 0.06,
                              color: AppColors.primaryBlue,
                            ),
                          ), // Responsive icon size
                          title: 'Add Event',
                          onTap: () {
                            context.push('/create_event');
                          },
                        ),
                      ),
                      SizedBox(width: smallSpacing),
                      Expanded(
                        child: _buildQuickActionCard(
                          context: context, // Pass context
                          icon: Image.asset(
                            AppAssets.eventCalendarIcon,
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.calendar_month,
                              size: screenWidth * 0.06,
                              color: AppColors.primaryBlue,
                            ),
                          ), // Responsive icon size
                          title: 'View Events',
                          onTap: () {
                            context.push('/up_coming_events');
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mediumSpacing), // Responsive spacing
                  // Add Child Button (Always visible)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryBlue),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      color: const Color(0x26D8ECFF),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: _addChildField,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenWidth * 0.03,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                          color: AppColors.primaryBlue,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Flexible(
                              child: Text(
                                'Add Child Information',
                                style: TextStyle(
                                  fontSize: sectionTitleFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Child Information Section (Conditionally visible)
                  if (_showChildInfoSection) ...[
                    SizedBox(height: mediumSpacing),
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryBlue),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        color: const Color(0x26D8ECFF),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Child Information *',
                                  style: TextStyle(
                                    fontSize: sectionTitleFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textColorPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: _addChildField,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.025,
                                    vertical: screenWidth * 0.01,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.015,
                                    ),
                                    color: const Color(0xFFD8ECFF),
                                  ),
                                  child: Text(
                                    '+ Add Another Child',
                                    style: TextStyle(
                                      fontSize: childInfoAddChildFontSize,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.primaryBlue,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: smallSpacing),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _childNameControllers.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: screenWidth * 0.04,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        screenWidth * 0.04,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.03,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primaryBlue,
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: AuthInputField(
                                              controller:
                                              _childNameControllers[index],
                                              labelText: 'Child\'s Name',
                                              hintText:
                                              'Child\'s name please..',
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          Expanded(
                                            flex: 1,
                                            child: AuthInputField(
                                              controller:
                                              _childAgeControllers[index],
                                              labelText: 'Age',
                                              hintText: 'Age',
                                              keyboardType:
                                              TextInputType.number,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: -screenWidth * 0.025,
                                      left: screenWidth * 0.04,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.025,
                                          vertical: screenWidth * 0.01,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.05,
                                          ),
                                        ),
                                        child: Text(
                                          'Child ${index + 1}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: childInfoChildNumFontSize,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -screenWidth * 0.025,
                                      right: screenWidth * 0.005,
                                      child: Container(
                                        height: screenWidth * 0.05,
                                        width: screenWidth * 0.05,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.all(
                                            screenWidth * 0.01,
                                          ),
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: screenWidth * 0.03,
                                          ),
                                          onPressed: () =>
                                              _removeChildField(index),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                final authProvider = context
                                    .read<AuthProvider>();
                                bool allSuccess = true;

                                // Loop through each child entry
                                for (
                                int i = 0;
                                i < _childNameControllers.length;
                                i++
                                ) {
                                  String name = _childNameControllers[i].text
                                      .trim();
                                  String ageText = _childAgeControllers[i].text
                                      .trim();

                                  if (name.isEmpty || ageText.isEmpty) {
                                    SnackbarUtils.showWarning(context, "Please fill in all child details.");
                                    allSuccess = false;
                                    continue;
                                  }

                                  int age = int.tryParse(ageText) ?? 0;
                                  bool success = await authProvider.addChild(
                                    name,
                                    age,
                                  );

                                  if (!success) {
                                    allSuccess = false;
                                  }
                                }

                                if (allSuccess) {
                                  SnackbarUtils.showSuccess(context, "Children saved successfully!");

                                  // Refresh children list in Home Page
                                  final children = await authProvider
                                      .fetchChildren();

                                  // Clear text fields and hide section
                                  setState(() {
                                    for (var controller
                                    in _childNameControllers) {
                                      controller.dispose();
                                    }
                                    for (var controller
                                    in _childAgeControllers) {
                                      controller.dispose();
                                    }
                                    _childNameControllers.clear();
                                    _childAgeControllers.clear();
                                    _showChildInfoSection =
                                    false; // Hide the section after saving
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Some children could not be saved.",
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shadowColor: const Color(0x1A000000),
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.02,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: screenWidth * 0.025,
                                  horizontal: screenWidth * 0.1,
                                ),
                              ),
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: saveButtonFontSize,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: mediumSpacing), // Responsive spacing
                  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                  const MyGroupsSection(),
                  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.02), // Responsive padding
                    child: CalendarPart(),
                  ),
                  SizedBox(height: largeSpacing), // Added spacing for bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context, // Added context
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double cardPadding = screenWidth * 0.05; // Responsive padding
    final double iconTextSpacing = screenWidth * 0.025; // Responsive spacing
    final double titleFontSize = screenWidth * 0.04; // Responsive font size

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPadding), // Responsive padding
        decoration: BoxDecoration(
          color: AppColors.quickActionCardBackground,
          borderRadius: BorderRadius.circular(
            screenWidth * 0.03,
          ), // Responsive border radius
          border: Border.all(
            color: AppColors.quickActionCardBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            icon,
            SizedBox(height: iconTextSpacing), // Responsive spacing
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize, // Responsive font size
                fontWeight: FontWeight.w500,
                color: AppColors.textColorPrimary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(BuildContext context, String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = screenWidth * 0.038; // Responsive font size

    return Container(
      decoration: BoxDecoration(
        color: _groupSelections[title]!
            ? AppColors.primaryBlue.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(
          screenWidth * 0.02,
        ), // Responsive border radius
        border: Border.all(
          color: _groupSelections[title]!
              ? AppColors.primaryBlue
              : AppColors.inputOutline,
          width: 1.0,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            color: _groupSelections[title]!
                ? AppColors.primaryBlue
                : AppColors.textColorPrimary,
            fontFamily: 'Poppins',
            fontSize: titleFontSize, // Responsive font size
          ),
        ),
        value: _groupSelections[title],
        onChanged: (bool? newValue) {
          setState(() {
            _groupSelections[title] = newValue!;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primaryBlue,
        checkColor: Colors.white,
        contentPadding:
        EdgeInsets.zero, // Keep zero for tight fit inside the container
      ),
    );
  }

  Widget _buildCalendarGrid(
      BuildContext context,
      Map<int, int> calendarDateStates,
      ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double weekdayFontSize =
        screenWidth * 0.035; // Responsive weekday font size
    final double dateNumberFontSize =
        screenWidth * 0.04; // Responsive date number font size
    final double cellSpacing =
        screenWidth * 0.01; // Responsive spacing between cells
    final double borderRadius =
        screenWidth * 0.02; // Responsive border radius for date cells

    final List<String> weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final List<DateTime> calendarDates = [];

    DateTime startDate = DateTime(2025, 6, 29);

    for (int i = 0; i < 35; i++) {
      // Display 5 weeks (7 days * 5 rows = 35 days)
      calendarDates.add(startDate.add(Duration(days: i)));
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: cellSpacing, // Responsive spacing
            mainAxisSpacing: cellSpacing, // Responsive spacing
          ),
          itemCount: weekdays.length,
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: weekdayFontSize, // Responsive font size
                  color: AppColors.textColorPrimary,
                ),
              ),
            );
          },
        ),
        SizedBox(height: screenWidth * 0.02), // Responsive spacing
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: cellSpacing, // Responsive spacing
            mainAxisSpacing: cellSpacing, // Responsive spacing
          ),
          itemCount: calendarDates.length,
          itemBuilder: (context, index) {
            final date = calendarDates[index];
            final bool isCurrentMonth = date.month == 7 && date.year == 2025;

            final state = isCurrentMonth
                ? calendarDateStates[date.day] ?? 2
                : 2;

            Color bgColor = Colors.transparent;
            Color borderColor = Colors.transparent;
            Color textColor = AppColors.dateText;

            if (isCurrentMonth) {
              switch (state) {
                case 0: // Unavailable
                  bgColor = AppColors.unavailableRed;
                  textColor = Colors.white;
                  break;
                case 1: // Available
                  bgColor = AppColors.availableGreen;
                  textColor = Colors.white;
                  break;
                case 2: // Default/Inactive
                default:
                  bgColor = AppColors.dateBackground;
                  textColor = AppColors.dateText;
                  break;
              }
            } else {
              bgColor = AppColors.dateBackground.withOpacity(0.5);
              textColor = AppColors.dateText.withOpacity(0.5);
            }

            return GestureDetector(
              onTap: isCurrentMonth
                  ? () {
                Provider.of<AvailabilityProvider>(
                  context,
                  listen: false,
                ).toggleDateState(date.day);
                
                // Show availability details popup
                _showAvailabilityDetails(date);
              }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(
                    borderRadius,
                  ), // Responsive border radius
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: dateNumberFontSize, // Responsive font size
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}