import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/widgets/auth_input_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      SnackbarUtils.showLoading(context, 'Processing...');

      print('Attempting login with email: ${_emailController.text}');
      final success = await authProvider.loginUser(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (success) {
        SnackbarUtils.showSuccess(context, 'Login successful!');
        context.go('/home');
      } else {
        SnackbarUtils.showError(
          context,
          authProvider.errorMessage ?? 'Login failed.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      AppAssets.calendarIcon,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.calendar_month,
                        color: AppColors.primaryBlue,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColorPrimary,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Sign in to continue Circle activities',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textColorSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30.0),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AuthInputField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          labelText: 'Email Address *',
                          hintText: 'Enter your email..',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20.0),
                        AuthInputField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          labelText: 'Password *',
                          hintText: 'Enter your password...',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Row(
                      //   children: [
                      //     SizedBox(
                      //       width: 24.0,
                      //       height: 24.0,
                      //       child: Checkbox(
                      //         value: _rememberMe,
                      //         onChanged: (bool? newValue) {
                      //           setState(() {
                      //             _rememberMe = newValue ?? false;
                      //           });
                      //         },
                      //         activeColor: AppColors.primaryBlue,
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(4.0),
                      //         ),
                      //         side: const BorderSide(
                      //           color: AppColors.inputOutline,
                      //           width: 1.5,
                      //         ),
                      //       ),
                      //     ),
                      //     const SizedBox(width: 8.0),
                      //     const Text(
                      //       'Remember me',
                      //       style: TextStyle(
                      //         fontSize: 14.0,
                      //         color: AppColors.textColorSecondary,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      GestureDetector(
                        onTap: () {
                          context.push('/forgot-password');
                        },
                        child: const Text(
                          'Forget Password?',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () {
                              // FocusScope.of(context).unfocus();
                              _emailFocusNode.unfocus();
                              _passwordFocusNode.unfocus();
                              _handleLogin(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 3,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(fontSize: 15.0, color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push('/signup');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
