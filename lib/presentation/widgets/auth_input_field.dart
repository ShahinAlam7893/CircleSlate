// lib/presentation/widgets/auth_input_field.dart
import 'package:flutter/material.dart';
import 'package:circleslate/core/constants/app_colors.dart'; // Make sure this path is correct

class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final bool isPassword; // Set to true for password fields
  final Widget? suffixIcon; // For custom suffix icons if needed
  final String? Function(String?)? validator; // Added validator property

  const AuthInputField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.suffixIcon,
    this.validator, // Initialize validator
  }) : super(key: key);

  @override
  _AuthInputFieldState createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword; // Initially obscure if it's a password field
  }

  @override
  Widget build(BuildContext context) {
    return Column( // Wrapped in Column to place label text above the field
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: const TextStyle(
            color: AppColors.textColorPrimary, // Using textColorPrimary for label
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8), // Space between label and text field
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          validator: widget.validator, // Pass the validator to TextFormField
          style: const TextStyle(color: AppColors.textColorPrimary, fontSize: 16), // Text input style
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: AppColors.inputHintColor, fontSize: 10),
            filled: true,
            fillColor: Colors.white, // As per your latest code
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4), // Changed to 4.0 as per your latest code
              borderSide: BorderSide(color: AppColors.inputBorderColor, width: 1), // Using AppColors
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppColors.inputBorderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility, // Corrected icon logic
                color: AppColors.textColorPrimary, // Using AppColors.iconColor
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
                : widget.suffixIcon, // Use custom suffix if provided and not password
          ),
        ),
      ],
    );
  }
}