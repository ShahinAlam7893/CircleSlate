import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/widgets/auth_input_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
    final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();



  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resetting password...')),
    );

    final success = await authProvider.updatePassword(
      oldPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success) {
      context.go('/pass_cng_succussful');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(authProvider.errorMessage ?? 'Password reset failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create a New Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your new password must be different from the one you are currently using.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textColorSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              /// Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthInputField(
                      controller: _currentPasswordController,
                      focusNode:  _passwordFocusNode,
                      labelText: 'Old Password *',
                      hintText: 'Enter current password...',
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      }, 
                    ),
                    const SizedBox(height: 20),
                    AuthInputField(
                      controller: _newPasswordController,
                     focusNode:  _passwordFocusNode,
                      labelText: 'New Password *',
                      hintText: 'Enter new password...',
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        if (value == _currentPasswordController.text) {
                          return 'New password must be different from current password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AuthInputField(
                      controller: _confirmPasswordController,
                       focusNode:  _passwordFocusNode,
                      labelText: 'Confirm Password *',
                      hintText: 'Confirm new password...',
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              /// Submit button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handlePasswordReset(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
