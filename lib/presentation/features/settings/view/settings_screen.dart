import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // For navigation
import 'package:provider/provider.dart';
import '../../../common_providers/auth_provider.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Function to show the logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext scaffoldContext) {
    showDialog(
      context: scaffoldContext,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.unavailableRed,
                  size: 60.0,
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Are you sure you want to Log Out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColorPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'This action cannot be undone. Are you sure you want to continue?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: AppColors.textColorSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          side: const BorderSide(color: AppColors.primaryBlue, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryBlue,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();

                          // Use the scaffold context to show SnackBar
                          SnackbarUtils.showLoading(scaffoldContext, 'Logging Out...');

                          // Perform logout
                          final authProvider = Provider.of<AuthProvider>(scaffoldContext, listen: false);
                          await authProvider.logout();

                          // Navigate to login page
                          if (scaffoldContext.mounted) {
                            scaffoldContext.go(RoutePaths.login);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.unavailableRed,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,

        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        // No chat icon in the settings page screenshot, so removing it.
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Account',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            _buildSettingsCard([
              _buildSettingsItem(
                context,
                'Profile',
                Icons.person_outline,
                    () => context.push(RoutePaths.profile),
              ),
              _buildSettingsItem(
                context,
                'Change Password',
                Icons.lock_outline,
                    () => context.push(RoutePaths.resetPasswordPage),
              ),
              // _buildSettingsItem(
              //   context,
              //   'Privacy Controls',
              //   Icons.privacy_tip_outlined,
              //       () => context.push(RoutePaths.privacyControls),
              // ),
            ]),
            const SizedBox(height: 24.0),

            // Support & Legal Section
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Support & Legal',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            _buildSettingsCard([
              _buildSettingsItem(
                context,
                'Privacy Policy',
                Icons.policy_outlined,
                    () => context.push(RoutePaths.privacyPolicy),
              ),
              _buildSettingsItem(
                context,
                'Terms & Conditions',
                Icons.description_outlined,
                    () => context.push(RoutePaths.termsAndConditions),
              ),
            ]),
            const SizedBox(height: 24.0),

            // Account Actions Section
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Account Actions',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            _buildSettingsCard([
              _buildSettingsItem(
                context,
                'Delete Account',
                Icons.delete_outline,
                    () {
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text('Delete Account Tapped')),
                  // );
                  context.push(RoutePaths.deleteAccount);
                },
              ),
              _buildSettingsItem(
                context,
                'Logout',
                Icons.logout,
                    () => _showLogoutConfirmationDialog(context), // Call the logout dialog
                isLast: true, // Mark as last item to remove bottom divider
              ),
            ]),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
      // The bottom navigation bar will be provided by SmoothNavigationWrapper
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSettingsItem(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap, {
        bool isLast = false,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                // Icon (optional, based on screenshot, it's not present for these items)
                // Icon(icon, color: AppColors.textMedium, size: 24),
                // const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: AppColors.textColorPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
              ],
            ),
            if (!isLast)
              Divider(
                height: 24,
                thickness: 1,
                color: Colors.grey.withOpacity(0.2),
                indent: 0, // No indent for the divider
                endIndent: 0, // No end indent for the divider
              ),
          ],
        ),
      ),
    );
  }
}
