// import 'package:circleslate/core/constants/app_assets.dart';
// import 'package:circleslate/core/constants/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:circleslate/core/constants/shared_utilities.dart';
// import 'package:circleslate/presentation/common_providers/availability_provider.dart';
// import 'package:intl/intl.dart'; // For date formatting
// import 'package:circleslate/presentation/common_providers/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../core/services/notification_service.dart';
// import '../../../../presentation/common_providers/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../widgets/calendar_part.dart';
// import '../widgets/defult_group_section.dart';
// import '../widgets/my_group_section.dart';
//
// class NotificationIconWithBadge extends StatefulWidget {
//   final double iconSize;
//   final VoidCallback onPressed;
//
//   const NotificationIconWithBadge({
//     Key? key,
//     required this.iconSize,
//     required this.onPressed,
//   }) : super(key: key);
//
//   @override
//   State<NotificationIconWithBadge> createState() =>
//       _NotificationIconWithBadgeState();
// }
//
// class _NotificationIconWithBadgeState extends State<NotificationIconWithBadge> {
//   final NotificationService _notificationService = NotificationService();
//   int _unreadCount = 0;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUnreadCount();
//     // Refresh count every 30 seconds for real-time updates
//     _startPeriodicRefresh();
//   }
//
//   Future<void> _loadUnreadCount() async {
//     if (_isLoading) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final count = await _notificationService.getUnreadCount();
//       if (mounted) {
//         setState(() {
//           _unreadCount = count;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error loading unread count: $e");
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   void _startPeriodicRefresh() {
//     // Refresh unread count every 30 seconds
//     Future.delayed(const Duration(seconds: 30), () {
//       if (mounted) {
//         _loadUnreadCount();
//         _startPeriodicRefresh();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         widget.onPressed();
//         // Refresh count after navigating to notifications
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted) {
//             _loadUnreadCount();
//           }
//         });
//       },
//       child: Stack(
//         children: [
//           Icon(Icons.notifications, color: Colors.white, size: widget.iconSize),
//
//           //if (_unreadCount > 0)
//           Positioned(
//             right: 0,
//             top: 0,
//             child: Container(
//               padding: EdgeInsets.all(
//                 widget.iconSize * 0.1,
//               ), // Responsive padding
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.3),
//                     blurRadius: 3,
//                     offset: const Offset(0, 1),
//                   ),
//                 ],
//               ),
//               constraints: const BoxConstraints(minWidth: 0, minHeight: 10),
//               child: Text(
//                 _unreadCount.toString(),
//
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
//
// class HeaderSection extends StatefulWidget {
//   const HeaderSection({Key? key}) : super(key: key);
//
//   @override
//   State<HeaderSection> createState() => _HeaderSectionState();
// }
//
// class _HeaderSectionState extends State<HeaderSection> {
//   String childName = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadChildren();
//   }
//
//   Future<void> _loadChildren() async {
//     final authProvider = context.read<AuthProvider>();
//     final children = await authProvider.fetchChildren();
//
//     if (children.isNotEmpty && mounted) {
//       setState(() {
//         childName = children.first['name'] ?? '';
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//
//     if (authProvider.isLoading) {
//       return const CircularProgressIndicator();
//     }
//
//     final profile = authProvider.userProfile ?? {};
//     final fullName = profile["full_name"] ?? "";
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Hello, $fullName!",
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w400,
//             color: Colors.white,
//             fontFamily: 'Poppins',
//           ),
//         ),
//         if (childName.isNotEmpty)
//           Text(
//             "Manage $childName’s activities",
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w400,
//               color: Color(0xCCFFFFFF),
//               fontFamily: 'Poppins',
//             ),
//           ),
//       ],
//     );
//   }
// }
//
// // --- AuthInputField --- (Copied from previous response for self-containment)
// class AuthInputField extends StatefulWidget {
//   final TextEditingController controller;
//   final String labelText;
//   final String hintText;
//   final TextInputType keyboardType;
//   final bool isPassword;
//   final Widget? suffixIcon;
//   final String? Function(String?)? validator;
//   final int maxLines;
//
//   const AuthInputField({
//     Key? key,
//     required this.controller,
//     required this.labelText,
//     required this.hintText,
//     this.keyboardType = TextInputType.text,
//     this.isPassword = false,
//     this.suffixIcon,
//     this.validator,
//     this.maxLines = 1,
//   }) : super(key: key);
//
//   @override
//   _AuthInputFieldState createState() => _AuthInputFieldState();
// }
//
// class _AuthInputFieldState extends State<AuthInputField> {
//   bool _obscureText = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _obscureText = widget.isPassword;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final double labelFontSize = screenWidth * 0.032;
//     final double hintFontSize = screenWidth * 0.03;
//     final double inputContentPaddingVertical = screenWidth * 0.035;
//     final double inputContentPaddingHorizontal = screenWidth * 0.04;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           widget.labelText,
//           style: TextStyle(
//             color: AppColors.textColorSecondary,
//             fontSize: labelFontSize,
//             fontWeight: FontWeight.w500,
//             fontFamily: 'Poppins',
//           ),
//         ),
//         SizedBox(height: screenWidth * 0.02),
//         TextFormField(
//           controller: widget.controller,
//           keyboardType: widget.keyboardType,
//           obscureText: _obscureText,
//           validator: widget.validator,
//           maxLines: widget.maxLines,
//           decoration: InputDecoration(
//             hintText: widget.hintText,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.01),
//               borderSide: const BorderSide(
//                 color: AppColors.inputOutline,
//                 width: 1,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.01),
//               borderSide: const BorderSide(
//                 color: AppColors.inputOutline,
//                 width: 1,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.01),
//               borderSide: const BorderSide(
//                 color: AppColors.primaryBlue,
//                 width: 1.5,
//               ),
//             ),
//             hintStyle: TextStyle(
//               color: AppColors.inputHintColor,
//               fontSize: hintFontSize,
//               fontWeight: FontWeight.w400,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: EdgeInsets.symmetric(
//               vertical: inputContentPaddingVertical,
//               horizontal: inputContentPaddingHorizontal,
//             ),
//             suffixIcon: widget.isPassword
//                 ? IconButton(
//                     icon: Icon(
//                       _obscureText ? Icons.visibility : Icons.visibility_off,
//                       color: AppColors.textColorSecondary,
//                       size: screenWidth * 0.05,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscureText = !_obscureText;
//                       });
//                     },
//                   )
//                 : (widget.suffixIcon != null
//                       ? SizedBox(
//                           width: screenWidth * 0.08,
//                           height: screenWidth * 0.08,
//                           child: FittedBox(
//                             fit: BoxFit.scaleDown,
//                             child: widget.suffixIcon,
//                           ),
//                         )
//                       : null),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // --- PlaceholderScreen for other routes, kept here for self-containment
// class PlaceholderScreen extends StatelessWidget {
//   final String title;
//   const PlaceholderScreen({Key? key, required this.title}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         backgroundColor: AppColors.buttonPrimary,
//       ),
//       body: Center(
//         child: Text(
//           'Welcome to the $title Page!',
//           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
//
//
//   int _getCurrentIndex(BuildContext context) {
//     final String location = GoRouter.of(
//       context,
//     ).routerDelegate.currentConfiguration.uri.toString();
//     if (location == '/home') return 0;
//     if (location == '/up_coming_events') return 1;
//     if (location == '/group_chat') return 2;
//     if (location == '/availability') return 3;
//     if (location == '/settings') return 4;
//     return 0; // Default
//   }
// }
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0; // For the bottom navigation bar
//
//   // Controllers for Child Information
//   final List<TextEditingController> _childNameControllers = [
//     TextEditingController(),
//   ];
//   final List<TextEditingController> _childAgeControllers = [
//     TextEditingController(),
//   ];
//
//   // State for Join Groups checkboxes
//   final Map<String, bool> _groupSelections = {
//     'Kindergarten': false,
//     '1st Grade': false,
//     '2nd Grade': false,
//     '3rd Grade': false,
//     '4th Grade': false,
//     'Soccer Team': false,
//     'Moms Group': false,
//     'Dads Group': false,
//     'Basketball': false,
//     'Art Class': false,
//   };
//
//   @override
//   void dispose() {
//     for (var controller in _childNameControllers) {
//       controller.dispose();
//     }
//     for (var controller in _childAgeControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
//
//   void _addChildField() {
//     setState(() {
//       _childNameControllers.add(TextEditingController());
//       _childAgeControllers.add(TextEditingController());
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(
//       context,
//     ).size.height; // Not directly used here, but good for context
//
//     // Responsive font sizes
//     final double headerNameFontSize = screenWidth * 0.055;
//     final double headerSubtitleFontSize = screenWidth * 0.035;
//     final double availabilityTextFontSize = screenWidth * 0.032;
//     final double quickActionTitleFontSize = screenWidth * 0.045;
//     final double sectionTitleFontSize = screenWidth * 0.04;
//     final double childInfoAddChildFontSize = screenWidth * 0.03;
//     final double childInfoChildNumFontSize = screenWidth * 0.035;
//     final double groupSelectionHintFontSize = screenWidth * 0.025;
//     final double groupNameFontSize = screenWidth * 0.038;
//     final double calendarMonthFontSize = screenWidth * 0.05;
//     final double weekdayFontSize = screenWidth * 0.038;
//     final double calendarDateFontSize = screenWidth * 0.04;
//     final double legendFontSize = screenWidth * 0.032;
//     final double saveButtonFontSize = screenWidth * 0.04;
//
//     // Responsive spacing
//     final double largeSpacing = screenWidth * 0.05;
//     final double mediumSpacing = screenWidth * 0.04;
//     final double smallSpacing = screenWidth * 0.03;
//     final double extraSmallSpacing = screenWidth * 0.02;
//
//     // Watch the AvailabilityProvider for changes
//     final availabilityProvider = Provider.of<AvailabilityProvider>(context);
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // Top Header Section
//           Container(
//             padding: EdgeInsets.fromLTRB(
//               screenWidth * 0.06,
//               screenHeight * 0.05,
//               screenWidth * 0.06,
//               screenHeight * 0.03,
//             ), // Responsive padding
//             decoration: BoxDecoration(
//               color: AppColors.buttonPrimary,
//               borderRadius: BorderRadius.vertical(
//                 bottom: Radius.circular(screenWidth * 0.05),
//               ), // Responsive border radius
//             ),
//             child: SafeArea(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment
//                         .spaceBetween, // Changed to spaceBetween
//                     children: [
//                       // This inner Row groups the profile picture and text
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment
//                             .start, // Keep this inner row content aligned to start
//                         children: [
//                           GestureDetector(
//                             onTap: () {
//                               context.push(
//                                 '/profile',
//                               ); // Replace with your actual profile route
//                             },
//                             child: Container(
//                               width:
//                                   screenWidth *
//                                   0.12, // Responsive profile picture size
//                               height: screenWidth * 0.12,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Colors.white,
//                                   width: screenWidth * 0.005,
//                                 ), // Responsive border width
//                               ),
//                               child: ClipOval(
//                                 child: Consumer<AuthProvider>(
//                                   builder: (context, auth, _) {
//                                     final photo =
//                                         auth.userProfile?["profile_photo"] ??
//                                         "";
//
//                                     if (photo.toString().isNotEmpty) {
//                                       final imageUrl =
//                                           photo.toString().startsWith("http")
//                                           ? photo.toString()
//                                           : "http://10.10.13.27:8000$photo";
//
//                                       return Image.network(
//                                         imageUrl,
//                                         fit: BoxFit.cover,
//                                         errorBuilder:
//                                             (context, error, stackTrace) {
//                                               return Icon(
//                                                 Icons.person,
//                                                 size: screenWidth * 0.09,
//                                                 color: Colors.white,
//                                               );
//                                             },
//                                       );
//                                     } else {
//                                       return Icon(
//                                         Icons.person,
//                                         size: screenWidth * 0.09,
//                                         color: Colors.white,
//                                       );
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           SizedBox(
//                             width: screenWidth * 0.03,
//                           ), // Responsive spacing
//                           const HeaderSection(),
//                         ],
//                       ),
//                       // Notification Bell Icon (New addition)
//                       NotificationIconWithBadge(
//                         iconSize: screenWidth * 0.06,
//                         onPressed: () {
//                           context.pushReplacement('/notifications');
//                         },
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: largeSpacing), // Responsive spacing
//
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.circle,
//                         size: screenWidth * 0.03,
//                         color: Colors.green,
//                       ), // Responsive icon size
//                       SizedBox(width: extraSmallSpacing), // Responsive spacing
//                       Text(
//                         'Available for playdates',
//                         style: TextStyle(
//                           fontSize:
//                               availabilityTextFontSize, // Responsive font size
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                           fontFamily: 'Poppins',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Main Content Area (Scrollable)
//           Expanded(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.symmetric(
//                 horizontal: screenWidth * 0.06,
//                 vertical: mediumSpacing,
//               ), // Responsive padding
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Quick Actions',
//                     style: TextStyle(
//                       fontSize:
//                           quickActionTitleFontSize, // Responsive font size
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.textColorPrimary,
//                       fontFamily: 'Poppins',
//                     ),
//                   ),
//                   SizedBox(height: smallSpacing), // Responsive spacing
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildQuickActionCard(
//                           context: context, // Pass context
//                           icon: Image.asset(
//                             AppAssets.plusIcon,
//                             width: screenWidth * 0.06,
//                             height: screenWidth * 0.06,
//                             errorBuilder: (context, error, stackTrace) => Icon(
//                               Icons.add_circle_outline,
//                               size: screenWidth * 0.06,
//                               color: AppColors.primaryBlue,
//                             ),
//                           ), // Responsive icon size
//                           title: 'Add Event',
//                           onTap: () {
//                             context.push('/create_event');
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text('Add Event Tapped')),
//                             );
//                           },
//                         ),
//                       ),
//                       SizedBox(width: smallSpacing), // Responsive spacing
//                       Expanded(
//                         child: _buildQuickActionCard(
//                           context: context, // Pass context
//                           icon: Image.asset(
//                             AppAssets.eventCalendarIcon,
//                             width: screenWidth * 0.06,
//                             height: screenWidth * 0.06,
//                             errorBuilder: (context, error, stackTrace) => Icon(
//                               Icons.calendar_month,
//                               size: screenWidth * 0.06,
//                               color: AppColors.primaryBlue,
//                             ),
//                           ), // Responsive icon size
//                           title: 'View Events',
//                           onTap: () {
//                             context.push('/up_coming_events');
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('View Events Tapped'),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: mediumSpacing), // Responsive spacing
//                   // Child Information Section
//                   Container(
//                     padding: EdgeInsets.all(
//                       screenWidth * 0.04,
//                     ), // Responsive padding
//                     decoration: BoxDecoration(
//                       border: Border.all(color: AppColors.primaryBlue),
//                       borderRadius: BorderRadius.circular(
//                         screenWidth * 0.03,
//                       ), // Responsive border radius
//                       color: const Color(0x26D8ECFF),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 6,
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Child Information *',
//                               style: TextStyle(
//                                 fontSize:
//                                     sectionTitleFontSize, // Responsive font size
//                                 fontWeight: FontWeight.w500,
//                                 color: AppColors.textColorPrimary,
//                                 fontFamily: 'Poppins',
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: _addChildField,
//                               child: Container(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: screenWidth * 0.025,
//                                   vertical: screenWidth * 0.01,
//                                 ), // Responsive padding
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(
//                                     screenWidth * 0.015,
//                                   ), // Responsive border radius
//                                   color: const Color(0xFFD8ECFF),
//                                 ),
//                                 child: Text(
//                                   '+ Add Another Child',
//                                   style: TextStyle(
//                                     fontSize:
//                                         childInfoAddChildFontSize, // Responsive font size
//                                     fontWeight: FontWeight.w400,
//                                     color: AppColors.primaryBlue,
//                                     fontFamily: 'Poppins',
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: smallSpacing), // Responsive spacing
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: _childNameControllers.length,
//                           itemBuilder: (context, index) {
//                             return Padding(
//                               padding: EdgeInsets.only(
//                                 bottom: screenWidth * 0.04,
//                               ), // Responsive padding
//                               child: Stack(
//                                 clipBehavior: Clip.none,
//                                 children: [
//                                   Container(
//                                     padding: EdgeInsets.all(
//                                       screenWidth * 0.04,
//                                     ), // Responsive padding
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(
//                                         screenWidth * 0.03,
//                                       ), // Responsive border radius
//                                       border: Border.all(
//                                         color: AppColors.primaryBlue,
//                                       ),
//                                       color: Colors.white,
//                                     ),
//                                     child: Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           flex: 2,
//                                           child: AuthInputField(
//                                             controller:
//                                                 _childNameControllers[index],
//                                             labelText: 'Child\'s Name',
//                                             hintText: 'Child\'s name please..',
//                                           ),
//                                         ),
//                                         SizedBox(
//                                           width: screenWidth * 0.03,
//                                         ), // Responsive spacing
//                                         Expanded(
//                                           flex: 1,
//                                           child: AuthInputField(
//                                             controller:
//                                                 _childAgeControllers[index],
//                                             labelText: 'Age',
//                                             hintText: 'Age',
//                                             keyboardType: TextInputType.number,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   Positioned(
//                                     top:
//                                         -screenWidth *
//                                         0.025, // Responsive position
//                                     left:
//                                         screenWidth *
//                                         0.04, // Responsive position
//                                     child: Container(
//                                       padding: EdgeInsets.symmetric(
//                                         horizontal: screenWidth * 0.025,
//                                         vertical: screenWidth * 0.01,
//                                       ), // Responsive padding
//                                       decoration: BoxDecoration(
//                                         color: AppColors.primaryBlue,
//                                         borderRadius: BorderRadius.circular(
//                                           screenWidth * 0.05,
//                                         ), // Responsive border radius
//                                       ),
//                                       child: Text(
//                                         'Child ${index + 1}',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize:
//                                               childInfoChildNumFontSize, // Responsive font size
//                                           fontWeight: FontWeight.w500,
//                                           fontFamily: 'Poppins',
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   if (index > 0)
//                                     Positioned(
//                                       top:
//                                           -screenWidth *
//                                           0.025, // Responsive position
//                                       right:
//                                           screenWidth *
//                                           0.005, // Responsive position
//                                       child: Container(
//                                         height:
//                                             screenWidth *
//                                             0.05, // Responsive size
//                                         width: screenWidth * 0.05,
//                                         decoration: BoxDecoration(
//                                           color: Colors.red,
//                                           shape: BoxShape.circle,
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: Colors.black.withOpacity(
//                                                 0.1,
//                                               ),
//                                               blurRadius: 2,
//                                             ),
//                                           ],
//                                         ),
//                                         child: IconButton(
//                                           constraints: const BoxConstraints(),
//                                           padding: EdgeInsets.all(
//                                             screenWidth * 0.01,
//                                           ), // Responsive padding
//                                           icon: Icon(
//                                             Icons.close_rounded,
//                                             color: Colors.white,
//                                             size: screenWidth * 0.03,
//                                           ), // Responsive icon size
//                                           onPressed: () {
//                                             setState(() {
//                                               _childNameControllers[index]
//                                                   .dispose();
//                                               _childAgeControllers[index]
//                                                   .dispose();
//                                               _childNameControllers.removeAt(
//                                                 index,
//                                               );
//                                               _childAgeControllers.removeAt(
//                                                 index,
//                                               );
//                                             });
//                                           },
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                         Center(
//                           child: ElevatedButton(
//                             onPressed: () async {
//                               final authProvider = context.read<AuthProvider>();
//
//                               bool allSuccess = true;
//
//                               // Loop through each child entry
//                               for (
//                                 int i = 0;
//                                 i < _childNameControllers.length;
//                                 i++
//                               ) {
//                                 String name = _childNameControllers[i].text
//                                     .trim();
//                                 String ageText = _childAgeControllers[i].text
//                                     .trim();
//
//                                 if (name.isEmpty || ageText.isEmpty) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text(
//                                         "Please fill in all child details.",
//                                       ),
//                                     ),
//                                   );
//                                   allSuccess = false;
//                                   continue;
//                                 }
//
//                                 int age = int.tryParse(ageText) ?? 0;
//                                 bool success = await authProvider.addChild(
//                                   name,
//                                   age,
//                                 );
//
//                                 if (!success) {
//                                   allSuccess = false;
//                                 }
//                               }
//
//                               if (allSuccess) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                       "Children saved successfully!",
//                                     ),
//                                   ),
//                                 );
//
//                                 // Refresh children list in Home Page
//                                 final children = await authProvider
//                                     .fetchChildren();
//                                 setState(() {
//                                   // Optionally update local state if you show them immediately
//                                 });
//
//                                 // Clear text fields
//                                 setState(() {
//                                   _childNameControllers.clear();
//                                   _childAgeControllers.clear();
//                                   _addChildField(); // Add at least one empty row
//                                 });
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                       "Some children could not be saved.",
//                                     ),
//                                   ),
//                                 );
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               shadowColor: const Color(0x1A000000),
//                               backgroundColor: AppColors.primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(
//                                   screenWidth * 0.02,
//                                 ),
//                               ),
//                               padding: EdgeInsets.symmetric(
//                                 vertical: screenWidth * 0.025,
//                                 horizontal: screenWidth * 0.1,
//                               ),
//                             ),
//                             child: Text(
//                               'Save',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: saveButtonFontSize,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 30), // Responsive spacing
//
//
//                   // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//                   const MyGroupsSection(), // Placeholder for MyGroupsSection
//
//                   // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//
//
//                   // // Calendar Section
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: CalendarPart(),
//                   ),
//                   SizedBox(height: largeSpacing), // Added spacing for bottom
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuickActionCard({
//     required BuildContext context, // Added context
//     required Widget icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final double cardPadding = screenWidth * 0.05; // Responsive padding
//     final double iconTextSpacing = screenWidth * 0.025; // Responsive spacing
//     final double titleFontSize = screenWidth * 0.04; // Responsive font size
//
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.all(cardPadding), // Responsive padding
//         decoration: BoxDecoration(
//           color: AppColors.quickActionCardBackground,
//           borderRadius: BorderRadius.circular(
//             screenWidth * 0.03,
//           ), // Responsive border radius
//           border: Border.all(
//             color: AppColors.quickActionCardBorder,
//             width: 1.0,
//           ),
//         ),
//         child: Column(
//           children: [
//             icon,
//             SizedBox(height: iconTextSpacing), // Responsive spacing
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: titleFontSize, // Responsive font size
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.textColorPrimary,
//                 fontFamily: 'Poppins',
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCheckboxTile(BuildContext context, String title) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final double titleFontSize = screenWidth * 0.038; // Responsive font size
//
//     return Container(
//       decoration: BoxDecoration(
//         color: _groupSelections[title]!
//             ? AppColors.primaryBlue.withOpacity(0.1)
//             : Colors.white,
//         borderRadius: BorderRadius.circular(
//           screenWidth * 0.02,
//         ), // Responsive border radius
//         border: Border.all(
//           color: _groupSelections[title]!
//               ? AppColors.primaryBlue
//               : AppColors.inputOutline,
//           width: 1.0,
//         ),
//       ),
//       child: CheckboxListTile(
//         title: Text(
//           title,
//           style: TextStyle(
//             color: _groupSelections[title]!
//                 ? AppColors.primaryBlue
//                 : AppColors.textColorPrimary,
//             fontFamily: 'Poppins',
//             fontSize: titleFontSize, // Responsive font size
//           ),
//         ),
//         value: _groupSelections[title],
//         onChanged: (bool? newValue) {
//           setState(() {
//             _groupSelections[title] = newValue!;
//           });
//         },
//         controlAffinity: ListTileControlAffinity.leading,
//         activeColor: AppColors.primaryBlue,
//         checkColor: Colors.white,
//         contentPadding:
//             EdgeInsets.zero, // Keep zero for tight fit inside the container
//       ),
//     );
//   }
//
//   Widget _buildCalendarGrid(
//     BuildContext context,
//     Map<int, int> calendarDateStates,
//   ) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final double weekdayFontSize =
//         screenWidth * 0.035; // Responsive weekday font size
//     final double dateNumberFontSize =
//         screenWidth * 0.04; // Responsive date number font size
//     final double cellSpacing =
//         screenWidth * 0.01; // Responsive spacing between cells
//     final double borderRadius =
//         screenWidth * 0.02; // Responsive border radius for date cells
//
//     final List<String> weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
//     final List<DateTime> calendarDates = [];
//
//     DateTime startDate = DateTime(
//       2025,
//       6,
//       29,
//     ); // Start from the Sunday before July 1st
//
//     for (int i = 0; i < 35; i++) {
//       // Display 5 weeks (7 days * 5 rows = 35 days)
//       calendarDates.add(startDate.add(Duration(days: i)));
//     }
//
//     return Column(
//       children: [
//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 7,
//             childAspectRatio: 1.0,
//             crossAxisSpacing: cellSpacing, // Responsive spacing
//             mainAxisSpacing: cellSpacing, // Responsive spacing
//           ),
//           itemCount: weekdays.length,
//           itemBuilder: (context, index) {
//             return Center(
//               child: Text(
//                 weekdays[index],
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: weekdayFontSize, // Responsive font size
//                   color: AppColors.textColorPrimary,
//                 ),
//               ),
//             );
//           },
//         ),
//         SizedBox(height: screenWidth * 0.02), // Responsive spacing
//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 7,
//             childAspectRatio: 1.0,
//             crossAxisSpacing: cellSpacing, // Responsive spacing
//             mainAxisSpacing: cellSpacing, // Responsive spacing
//           ),
//           itemCount: calendarDates.length,
//           itemBuilder: (context, index) {
//             final date = calendarDates[index];
//             final bool isCurrentMonth = date.month == 7 && date.year == 2025;
//
//             final state = isCurrentMonth
//                 ? calendarDateStates[date.day] ?? 2
//                 : 2;
//
//             Color bgColor = Colors.transparent;
//             Color borderColor = Colors.transparent;
//             Color textColor = AppColors.dateText;
//
//             if (isCurrentMonth) {
//               switch (state) {
//                 case 0: // Unavailable
//                   bgColor = AppColors.unavailableRed;
//                   textColor = Colors.white;
//                   break;
//                 case 1: // Available
//                   bgColor = AppColors.availableGreen;
//                   textColor = Colors.white;
//                   break;
//                 case 2: // Default/Inactive
//                 default:
//                   bgColor = AppColors.dateBackground;
//                   textColor = AppColors.dateText;
//                   break;
//               }
//             } else {
//               bgColor = AppColors.dateBackground.withOpacity(0.5);
//               textColor = AppColors.dateText.withOpacity(0.5);
//             }
//
//             return GestureDetector(
//               onTap: isCurrentMonth
//                   ? () {
//                       Provider.of<AvailabilityProvider>(
//                         context,
//                         listen: false,
//                       ).toggleDateState(date.day);
//                     }
//                   : null,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: bgColor,
//                   border: Border.all(color: borderColor, width: 1.5),
//                   borderRadius: BorderRadius.circular(
//                     borderRadius,
//                   ), // Responsive border radius
//                 ),
//                 child: Center(
//                   child: Text(
//                     '${date.day}',
//                     style: TextStyle(
//                       color: textColor,
//                       fontWeight: FontWeight.bold,
//                       fontSize: dateNumberFontSize, // Responsive font size
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }


import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/core/constants/shared_utilities.dart';
import 'package:circleslate/presentation/common_providers/availability_provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../presentation/common_providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/calendar_part.dart';
import '../widgets/my_group_section.dart';

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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 0, minHeight: 10),
              child: Text(
                _unreadCount.toString(),

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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

    if (authProvider.isLoading) {
      return const CircularProgressIndicator();
    }

    final profile = authProvider.userProfile ?? {};
    final fullName = profile["full_name"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, $fullName!",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        if (childName.isNotEmpty)
          Text(
            "Manage $childName's activities",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xCCFFFFFF),
              fontFamily: 'Poppins',
            ),
          ),
      ],
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
                color: AppColors.textColorSecondary,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(
      context,
    ).size.height; // Not directly used here, but good for context

    // Responsive font sizes
    final double headerNameFontSize = screenWidth * 0.055;
    final double headerSubtitleFontSize = screenWidth * 0.035;
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
          // Top Header Section
          Container(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.06,
              screenHeight * 0.05,
              screenWidth * 0.06,
              screenHeight * 0.03,
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
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Changed to spaceBetween
                    children: [
                      // This inner Row groups the profile picture and text
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .start, // Keep this inner row content aligned to start
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.push(
                                '/profile',
                              ); // Replace with your actual profile route
                            },
                            child: Container(
                              width:
                              screenWidth *
                                  0.12, // Responsive profile picture size
                              height: screenWidth * 0.12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: screenWidth * 0.005,
                                ), // Responsive border width
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
                                          : "http://10.10.13.27:8000$photo";

                                      return Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: screenWidth * 0.09,
                                            color: Colors.white,
                                          );
                                        },
                                      );
                                    } else {
                                      return Icon(
                                        Icons.person,
                                        size: screenWidth * 0.09,
                                        color: Colors.white,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            width: screenWidth * 0.03,
                          ), // Responsive spacing
                          const HeaderSection(),
                        ],
                      ),
                      // Notification Bell Icon (New addition)
                      NotificationIconWithBadge(
                        iconSize: screenWidth * 0.06,
                        onPressed: () {
                          context.pushReplacement('/notifications');
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: largeSpacing), // Responsive spacing

                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: screenWidth * 0.03,
                        color: Colors.green,
                      ), // Responsive icon size
                      SizedBox(width: extraSmallSpacing), // Responsive spacing
                      Text(
                        'Available for activities',
                        style: TextStyle(
                          fontSize:
                          availabilityTextFontSize, // Responsive font size
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
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
                      fontSize:
                      quickActionTitleFontSize, // Responsive font size
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add Event Tapped')),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: smallSpacing), // Responsive spacing
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('View Events Tapped'),
                              ),
                            );
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
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
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
                            Text(
                              'Add Child Information',
                              style: TextStyle(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                fontFamily: 'Poppins',
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
                              Text(
                                'Child Information *',
                                style: TextStyle(
                                  fontSize: sectionTitleFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textColorPrimary,
                                  fontFamily: 'Poppins',
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
                                    borderRadius: BorderRadius.circular(screenWidth * 0.015),
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
                                padding: EdgeInsets.only(bottom: screenWidth * 0.04),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(screenWidth * 0.04),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                        border: Border.all(color: AppColors.primaryBlue),
                                        color: Colors.white,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: AuthInputField(
                                              controller: _childNameControllers[index],
                                              labelText: 'Child\'s Name',
                                              hintText: 'Child\'s name please..',
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          Expanded(
                                            flex: 1,
                                            child: AuthInputField(
                                              controller: _childAgeControllers[index],
                                              labelText: 'Age',
                                              hintText: 'Age',
                                              keyboardType: TextInputType.number,
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
                                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
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
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.all(screenWidth * 0.01),
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: screenWidth * 0.03,
                                          ),
                                          onPressed: () => _removeChildField(index),
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
                                final authProvider = context.read<AuthProvider>();
                                bool allSuccess = true;

                                // Loop through each child entry
                                for (int i = 0; i < _childNameControllers.length; i++) {
                                  String name = _childNameControllers[i].text.trim();
                                  String ageText = _childAgeControllers[i].text.trim();

                                  if (name.isEmpty || ageText.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please fill in all child details."),
                                      ),
                                    );
                                    allSuccess = false;
                                    continue;
                                  }

                                  int age = int.tryParse(ageText) ?? 0;
                                  bool success = await authProvider.addChild(name, age);

                                  if (!success) {
                                    allSuccess = false;
                                  }
                                }

                                if (allSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Children saved successfully!"),
                                    ),
                                  );

                                  // Refresh children list in Home Page
                                  final children = await authProvider.fetchChildren();

                                  // Clear text fields and hide section
                                  setState(() {
                                    for (var controller in _childNameControllers) {
                                      controller.dispose();
                                    }
                                    for (var controller in _childAgeControllers) {
                                      controller.dispose();
                                    }
                                    _childNameControllers.clear();
                                    _childAgeControllers.clear();
                                    _showChildInfoSection = false; // Hide the section after saving
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Some children could not be saved."),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shadowColor: const Color(0x1A000000),
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
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

                  const MyGroupsSection(), // Placeholder for MyGroupsSection

                  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++


                  Padding(
                    padding: const EdgeInsets.all(8.0),
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

    DateTime startDate = DateTime(
      2025,
      6,
      29,
    );

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


