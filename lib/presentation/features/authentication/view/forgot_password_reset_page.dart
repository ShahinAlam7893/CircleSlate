import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/widgets/auth_input_field.dart';

class ForgotPasswordResetPage extends StatefulWidget {
  const ForgotPasswordResetPage({super.key});

  @override
  State<ForgotPasswordResetPage> createState() => _ForgotPasswordResetPageState();
}

class _ForgotPasswordResetPageState extends State<ForgotPasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
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

    final success = await authProvider.resetPassword(
      newPassword: _newPasswordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );

    if (success) {
      context.go('/pass_cng_succussful');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset failed.')),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(context),
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 10),
              _buildDescription(),
              const SizedBox(height: 30),
              _buildForm(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Back Button
  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.grey),
      onPressed: () => context.pop(),
    );
  }

  /// 🔹 Page Title
  Widget _buildHeader() {
    return const Center(
      child: Text(
        'Create a New Password',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textColorPrimary,
          fontFamily: 'Poppins',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 🔹 Description
  Widget _buildDescription() {
    return const Center(
      child: Text(
        'Your new password must be different from previously used passwords.',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textColorSecondary,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 🔹 Reset Password Form
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthInputField(
            controller: _newPasswordController,
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
              return null;
            },
          ),
          const SizedBox(height: 20),
          AuthInputField(
            controller: _confirmPasswordController,
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
    );
  }

  /// 🔹 Submit Button
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Consumer<AuthProvider>(
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
    );
  }
}
