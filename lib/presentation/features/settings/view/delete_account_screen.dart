import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/constants/app_strings.dart';
import 'package:circleslate/presentation/widgets/primary_button.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;

  Future<void> _confirmDeleteAccount() async {
    debugPrint("══════ Delete Account button pressed ══════");

    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint("→ Calling authProvider.deleteAccount()");

    final success = await authProvider.deleteAccount();

    debugPrint("← deleteAccount() finished → success: $success");

    if (!mounted) {
      debugPrint("Widget is not mounted anymore → returning early");
      return;
    }

    setState(() {
      _isDeleting = false;
    });

    if (success) {
      debugPrint("Account deletion successful");
      SnackbarUtils.showSuccess(context, 'Account deleted successfully');
      // Clear navigation stack and go to login
      context.go(RoutePaths.login);
    } else {
      final errorMsg =
          authProvider.errorMessage ??
          'Failed to delete account. Please try again.';
      debugPrint("Delete failed: $errorMsg");
      SnackbarUtils.showError(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          AppStrings.deleteAccountTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Trash Can Icon
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 60,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 30),

              // Main Title
              const Text(
                AppStrings.deleteAccountTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Confirmation Text
              const Text(
                AppStrings.deleteAccountConfirmation,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textColorSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.shade300, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.deleteAccountWarning,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Delete Account Button - Only enable when not deleting
              AbsorbPointer(
                absorbing: _isDeleting,
                child: PrimaryButton(
                  text: _isDeleting
                      ? 'Deleting...'
                      : AppStrings.deleteAccountButton,
                  onPressed: _confirmDeleteAccount,
                  backgroundColor: Colors.red.shade600,
                  textColor: Colors.white,
                  isLoading: _isDeleting,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textColorSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    AppStrings.cancelDeleteButton,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
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