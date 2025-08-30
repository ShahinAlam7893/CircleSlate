import 'dart:io';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/data/services/api_base_helper.dart'; // Ensure this is correctly imported if needed
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // REQUIRED for image picking
import 'package:provider/provider.dart';
import 'dart:convert'; // REQUIRED for jsonEncode/decode if used directly here, but AuthProvider handles it
import '../../../common_providers/auth_provider.dart';

class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final bool isPassword;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;

  const AuthInputField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.suffixIcon,
    this.validator,
    this.readOnly = false,
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
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      validator: widget.validator,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.inputOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.inputOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textColorSecondary, fontSize: 11.0, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: AppColors.textColorSecondary, fontSize: 10),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: AppColors.textColorSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        )
            : widget.suffixIcon,
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String initialFullName;
  final String initialEmail;
  final String initialMobile;
  final List<Map<String, String>> initialChildren;
  final String initialProfileImageUrl;

  const EditProfilePage({
    super.key,
    required this.initialFullName,
    required this.initialEmail,
    required this.initialMobile,
    required this.initialChildren,
    required this.initialProfileImageUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late List<TextEditingController> _childNameControllers;
  late List<TextEditingController> _childAgeControllers;
  late String _currentProfileImageUrl;
  File? _pickedImageFile;

  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialFullName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _mobileController = TextEditingController(text: widget.initialMobile);
    _currentProfileImageUrl = widget.initialProfileImageUrl;

    _childNameControllers = [];
    _childAgeControllers = [];

    Future.microtask(() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.fetchUserProfile();
      final profile = authProvider.userProfile ?? {};

      final children = (profile["profile"]?["children"] as List?) ?? [];
      if (children.isNotEmpty) {
        setState(() {
          _childNameControllers = children
              .map((c) => TextEditingController(text: c["name"] ?? ""))
              .toList();
          _childAgeControllers = children
              .map((c) => TextEditingController(text: c["age"]?.toString() ?? ""))
              .toList();
        });
      } else {
        setState(() {
          _childNameControllers = [TextEditingController()];
          _childAgeControllers = [TextEditingController()];
        });
      }

      if (profile["profile_photo"] != null && profile["profile_photo"].toString().isNotEmpty) {
        setState(() {
          _currentProfileImageUrl = profile["profile_photo"];
        });
      }
    });
  }


  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    for (var c in _childNameControllers) c.dispose();
    for (var c in _childAgeControllers) c.dispose();
    super.dispose();
  }

  void _addChildField() {
    setState(() {
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
    });
  }

  // --- IMAGE PICKING LOGIC ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Allows picking an image from the gallery. imageQuality helps reduce file size.
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path); // Store the picked image file
        _currentProfileImageUrl = ''; // Clear the network image URL as a new image is selected
      });
    }
  }



  // Save profile with proper API integration
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isLoggedIn) {
          _showErrorMessage('Please login first');
          if (mounted) context.go('/login');
          return;
        }

        // Prepare update data
        Map<String, dynamic> updateData = {
          'full_name': _fullNameController.text.trim(),
          'phone_number': _mobileController.text.trim(),
        };

        // Add profile image if selected
        if (_pickedImageFile != null) {
          updateData['profile_image'] = _pickedImageFile!.path;
        }

        // Update profile
        bool profileUpdated = await authProvider.updateUserProfile(updateData);

        if (profileUpdated) {
          // Refresh user data to get the latest profile photo URL
          await authProvider.refreshUserData();

          // Update local profile image URL
          setState(() {
            _currentProfileImageUrl = authProvider.userProfile?['profile_photo'] ?? _currentProfileImageUrl;
          });

          // Add children by calling API individually
          bool allChildrenSuccess = true;
          for (int i = 0; i < _childNameControllers.length; i++) {
            String name = _childNameControllers[i].text.trim();
            int age = int.tryParse(_childAgeControllers[i].text.trim()) ?? 0;

            if (name.isNotEmpty && age > 0) {
              bool success = await authProvider.addChild(name, age);
              if (!success) {
                allChildrenSuccess = false;
                _showErrorMessage('Failed to add child $name');
              }
            }
          }

          if (mounted) {
            // Return updated data to profile page
            final updatedData = {
              'fullName': _fullNameController.text.trim(),
              'email': _emailController.text.trim(),
              'mobile': _mobileController.text.trim(),
              'children': _childNameControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                return {
                  'name': controller.text.trim(),
                  'age': _childAgeControllers[index].text.trim(),
                };
              }).toList(),
              'profileImageUrl': authProvider.userProfile?['profile_photo'] ?? _currentProfileImageUrl,
            };

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // Pop with updated data
            context.pop(updatedData);
          }
        } else {
          _showErrorMessage('Failed to update profile');
        }
      } catch (e) {
        _showErrorMessage('Error updating profile: $e');
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _pickedImageFile != null
                          ? FileImage(_pickedImageFile!)
                          : (_currentProfileImageUrl.isNotEmpty
                          ? NetworkImage(_currentProfileImageUrl)
                          : null) as ImageProvider?,
                      onBackgroundImageError: _currentProfileImageUrl.isNotEmpty
                          ? (exception, stackTrace) {
                        print('❌ Failed to load profile image: $exception');
                        setState(() {
                          _currentProfileImageUrl = '';
                        });
                      }
                          : null,
                      child: _pickedImageFile == null && _currentProfileImageUrl.isEmpty
                          ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage, // Tapping this icon calls _pickImage()
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Full Name
              const Text(
                'Full Name',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColorPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              AuthInputField(
                controller: _fullNameController,
                labelText: '',
                hintText: 'Your full name',
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 20.0),

              // Email
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColorPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              AuthInputField(
                controller: _emailController,
                labelText: '',
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 20.0),

              // Mobile
              const Text(
                'Mobile',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColorPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              AuthInputField(
                controller: _mobileController,
                labelText: '',
                hintText: 'Mobile',
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Enter mobile' : null,
              ),
              const SizedBox(height: 20.0),

              // My Children
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Children',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _addChildField,
                    child: const Text(
                      '+ Add Another Child',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.inputOutline, width: 1),
                ),
                child: Column(
                  children: List.generate(
                    _childNameControllers.length,
                        (i) => _buildChildInputField(i),
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildChildInputField(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AuthInputField(
              controller: _childNameControllers[index],
              labelText: 'Child\'s Name',
              hintText: 'Enter name',
              validator: (v) {
                // Optional: If empty, skip validation
                if (v == null || v.trim().isEmpty) return null;

                // Example: If not empty, check length
                if (v.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            flex: 1,
            child: AuthInputField(
              controller: _childAgeControllers[index],
              labelText: 'Age',
              hintText: 'Age',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional

                final age = int.tryParse(v.trim());
                if (age == null || age <= 0) {
                  return 'Enter a valid age';
                }
                return null;
              },

            ),
          ),
          if (index > 0)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeChildField(index),
            ),
        ],
      ),
    );
  }
}
