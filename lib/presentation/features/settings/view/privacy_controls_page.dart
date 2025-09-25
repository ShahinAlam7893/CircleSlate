// import 'package:circleslate/core/constants/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart'; // For navigation
//
//
// class PrivacyControlsPage extends StatefulWidget {
//   const PrivacyControlsPage({super.key});
//
//   @override
//   State<PrivacyControlsPage> createState() => _PrivacyControlsPageState();
// }
//
// class _PrivacyControlsPageState extends State<PrivacyControlsPage> {
//   // State variables for each toggle switch
//   bool _profileVisibility = true;
//   bool _childrenInformation = true;
//   bool _availabilityStatus = true;
//   bool _chatMessages = true;
//   bool _rideRequests = true;
//   bool _openInvitations = true;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100], // Light grey background
//       appBar: AppBar(
//         backgroundColor: AppColors.primaryBlue,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             context.pop(); // Use pop for back navigation
//           },
//         ),
//         title: const Text(
//           'Privacy Controls',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20.0,
//             fontWeight: FontWeight.w500,
//             fontFamily: 'Poppins',
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Profile Section
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 8.0),
//               child: Text(
//                 'Profile',
//                 style: TextStyle(
//                   fontSize: 16.0,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textColorSecondary,
//                   fontFamily: 'Poppins',
//                 ),
//               ),
//             ),
//             _buildSettingsCard([
//               _buildToggleItem(
//                 context,
//                 'Profile Visibility',
//                 'Show your profile to group members',
//                 _profileVisibility,
//                     (bool newValue) {
//                   setState(() {
//                     _profileVisibility = newValue;
//                   });
//                   // Add logic to save this setting
//                   _showSettingUpdateSnackbar('Profile Visibility', newValue);
//                 },
//               ),
//               _buildToggleItem(
//                 context,
//                 'Children\'s Information',
//                 'Share children\'s names and ages',
//                 _childrenInformation,
//                     (bool newValue) {
//                   setState(() {
//                     _childrenInformation = newValue;
//                   });
//                   // Add logic to save this setting
//                   _showSettingUpdateSnackbar('Children\'s Information', newValue);
//                 },
//               ),
//               _buildToggleItem(
//                 context,
//                 'Availability Status',
//                 'Show when your children are available',
//                 _availabilityStatus,
//                     (bool newValue) {
//                   setState(() {
//                     _availabilityStatus = newValue;
//                   });
//                   // Add logic to save this setting
//                   _showSettingUpdateSnackbar('Availability Status', newValue);
//                 },
//                 isLast: true, // Mark as last item to remove bottom divider
//               ),
//             ]),
//             const SizedBox(height: 24.0),
//
//             // Communication Section
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 8.0),
//               child: Text(
//                 'Communication',
//                 style: TextStyle(
//                   fontSize: 16.0,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textColorSecondary,
//                   fontFamily: 'Poppins',
//                 ),
//               ),
//             ),
//             _buildSettingsCard([
//               _buildToggleItem(
//                 context,
//                 'Chat Messages',
//                 'Allow direct messages from other parents',
//                 _chatMessages,
//                     (bool newValue) {
//                   setState(() {
//                     _chatMessages = newValue;
//                   });
//                   // Add logic to save this setting
//                   _showSettingUpdateSnackbar('Chat Messages', newValue);
//                 },
//                 isLast: true, // Mark as last item to remove bottom divider
//               ),
//             ]),
//             const SizedBox(height: 24.0),
//
//             // Activities Section
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 8.0),
//               child: Text(
//                 'Activities',
//                 style: TextStyle(
//                   fontSize: 16.0,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textColorSecondary,
//                   fontFamily: 'Poppins',
//                 ),
//               ),
//             ),
//             _buildSettingsCard([
//               _buildToggleItem(
//                 context,
//                 'Ride Requests',
//                 'Share ride requests and offers',
//                 _rideRequests,
//                     (bool newValue) {
//                   setState(() {
//                     _rideRequests = newValue;
//                   });
//                   // Add logic to save this setting
//                   _showSettingUpdateSnackbar('Ride Requests', newValue);
//                 },
//               ),
//               _buildToggleItem(
//                 context,
//                 'Open Invitations',
//                 'See open invites from other parents',
//                 _openInvitations,
//                     (bool newValue) {
//                   setState(() {
//                     _openInvitations = newValue;
//                   });
//                   // Add logic to save this setting
//                   _showSettingUpdateSnackbar('Open Invitations', newValue);
//                 },
//                 isLast: true, // Mark as last item to remove bottom divider
//               ),
//             ]),
//             const SizedBox(height: 24.0),
//           ],
//         ),
//       ),
//       // The bottom navigation bar will be provided by SmoothNavigationWrapper
//     );
//   }
//
//   // Helper to build the card container for settings items
//   Widget _buildSettingsCard(List<Widget> items) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: items,
//       ),
//     );
//   }
//
//   // Helper to build each toggle switch item
//   Widget _buildToggleItem(
//       BuildContext context,
//       String title,
//       String subtitle,
//       bool value,
//       ValueChanged<bool> onChanged, {
//         bool isLast = false,
//       }) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 16.0,
//                         color: AppColors.textColorPrimary,
//                         fontFamily: 'Poppins',
//                       ),
//                     ),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: 12.0,
//                         color: AppColors.textColorSecondary,
//                         fontFamily: 'Poppins',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Switch(
//                 value: value,
//                 onChanged: onChanged,
//                 activeColor: AppColors.primaryBlue,
//                 inactiveThumbColor: Colors.grey,
//                 inactiveTrackColor: Colors.grey.withOpacity(0.3),
//               ),
//             ],
//           ),
//         ),
//         if (!isLast)
//           Divider(
//             height: 1,
//             thickness: 1,
//             color: Colors.grey.withOpacity(0.2),
//             indent: 16, // Indent to align with text
//             endIndent: 16, // Indent to align with text
//           ),
//       ],
//     );
//   }
//
//   // Helper to show a snackbar when a setting is updated
//   void _showSettingUpdateSnackbar(String settingName, bool value) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('$settingName turned ${value ? 'ON' : 'OFF'}'),
//         duration: const Duration(seconds: 1),
//       ),
//     );
//   }
// }
