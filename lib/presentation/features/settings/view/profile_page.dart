import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/presentation/features/settings/view/edit_profile_page.dart'
    hide AppColors, AppAssets;
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // ✅ For AuthProvider
import '../../../common_providers/auth_provider.dart'; // ✅ Your AuthProvider

// --- AuthInputField (Unchanged) ---
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
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textColorSecondary,
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textColorSecondary,
          fontSize: 10,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: 16.0,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black,
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
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = '';
  String _email = '';
  String _mobile = '';
  String _profileImageUrl = '';
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  bool _isLoadingChildren = true; // ✅ Track loading state for children

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    // Add a timeout to prevent infinite loading
    _addLoadingTimeout();
  }

  /// Add timeout to prevent infinite loading
  void _addLoadingTimeout() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoadingChildren) {
        setState(() {
          _isLoadingChildren = false;
        });
        debugPrint("⚠️ Children loading timeout - forcing state to false");
      }
    });
  }

  /// ✅ Fetch profile and children
  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _isLoadingChildren = true;
    });

    final authProvider = context.read<AuthProvider>();
    
    // First try to load from cache for immediate display
    final cachedProfile = authProvider.getCachedUserProfile();
    if (cachedProfile != null) {
      _updateLocalDataFromProfile(cachedProfile);
      setState(() => _isLoadingChildren = false);
    }
    
    // Then fetch fresh data from API
    final success = await authProvider.fetchUserProfile();

    if (success && mounted) {
      final profile = authProvider.userProfile ?? {};
      _updateLocalDataFromProfile(profile);
      setState(() {
        _isLoading = false;
        _isLoadingChildren = false;
      });
      debugPrint("✅ Loaded Profile: $_fullName, $_email, $_mobile, $_children");
    } else {
      debugPrint("❌ Failed to fetch profile data.");
      setState(() {
        _isLoading = false;
        _isLoadingChildren = false;
      });
    }
  }

  /// Update local data from profile
  void _updateLocalDataFromProfile(Map<String, dynamic> profile) {
    // ✅ Children inside profile["children"]
    final childrenList = (profile["children"] as List?) ?? [];

    // ✅ Ensure profile image is absolute URL
    String imageUrl = profile['profile_photo'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith("http")) {
      imageUrl = "http://72.60.26.57${imageUrl}";
    }

    setState(() {
      _fullName = profile['full_name'] ?? '';
      _email = profile['email'] ?? '';
      _mobile = profile['phone_number'] ?? '';
      _profileImageUrl = imageUrl;
      _children = childrenList.map((child) {
        return {
          'name': child['name']?.toString() ?? '',
          'age': child['age']?.toString() ?? '',
        };
      }).toList();
      _isLoadingChildren = false; // Set loading to false when data is updated
    });
    
    debugPrint("✅ Children data updated: ${_children.length} children, loading: $_isLoadingChildren");
  }

  /// ✅ Add new child & refresh
  Future<void> _addNewChild(String name, int age) async {
    //final success = await AuthProvider.addChild(name, age);
    // if (success) {
    //   await _fetchProfileData(); // refresh children after adding
    // }
  }

  /// Refresh children data specifically
  Future<void> _refreshChildrenData() async {
    setState(() => _isLoadingChildren = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final profile = authProvider.userProfile;
      
      if (profile != null) {
        _updateLocalDataFromProfile(profile);
        debugPrint("✅ Children data refreshed from AuthProvider");
      } else {
        // If no profile data, try to fetch it
        debugPrint("⚠️ No profile data found, fetching fresh data...");
        await _fetchProfileData();
      }
    } catch (e) {
      debugPrint("❌ Error refreshing children data: $e");
      setState(() => _isLoadingChildren = false);
    }
  }

  /// Force refresh children data (for debugging/testing)
  void _forceRefreshChildren() {
    debugPrint("🔄 Force refreshing children data...");
    _refreshChildrenData();
  }


  // void _showLogoutConfirmationDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12.0),
  //         ),
  //         elevation: 0,
  //         backgroundColor: Colors.white,
  //         child: Padding(
  //           padding: const EdgeInsets.all(24.0),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Icon(
  //                 Icons.error_outline,
  //                 color: AppColors.unavailableRed,
  //                 size: 60.0,
  //               ),
  //               const SizedBox(height: 20.0),
  //               const Text(
  //                 'Are you sure you want to Log Out?',
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   fontSize: 16.0,
  //                   fontWeight: FontWeight.w600,
  //                   color: AppColors.textColorPrimary,
  //                   fontFamily: 'Poppins',
  //                 ),
  //               ),
  //               const SizedBox(height: 10.0),
  //               const Text(
  //                 'This action cannot be undone. Are you sure you want to continue?',
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   fontSize: 12.0,
  //                   fontWeight: FontWeight.w400,
  //                   color: AppColors.textColorSecondary,
  //                   fontFamily: 'Poppins',
  //                 ),
  //               ),
  //               const SizedBox(height: 30.0),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                 children: [
  //                   Expanded(
  //                     child: OutlinedButton(
  //                       onPressed: () => Navigator.of(context).pop(),
  //                       style: OutlinedButton.styleFrom(
  //                         padding: const EdgeInsets.symmetric(vertical: 12.0),
  //                         side: const BorderSide(
  //                           color: AppColors.primaryBlue,
  //                           width: 1,
  //                         ),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8.0),
  //                         ),
  //                       ),
  //                       child: const Text(
  //                         'Cancel',
  //                         style: TextStyle(
  //                           fontSize: 12.0,
  //                           fontWeight: FontWeight.w600,
  //                           color: AppColors.primaryBlue,
  //                           fontFamily: 'Poppins',
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 16.0),
  //                   Expanded(
  //                     child: ElevatedButton(
  //                       onPressed: () {
  //                         Navigator.of(context).pop();
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           const SnackBar(content: Text('Logging Out...')),
  //                         );
  //                         context.go(RoutePaths.login);
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: AppColors.unavailableRed,
  //                         padding: const EdgeInsets.symmetric(vertical: 12.0),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8.0),
  //                         ),
  //                         elevation: 3,
  //                       ),
  //                       child: const Text(
  //                         'Log Out',
  //                         style: TextStyle(
  //                           fontSize: 12.0,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.white,
  //                           fontFamily: 'Poppins',
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.buttonPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () async {
              final updatedData = await context.push<Map<String, dynamic>>(
                RoutePaths.editProfile,
                extra: {
                  'fullName': _fullName,
                  'email': _email,
                  'mobile': _mobile,
                  'children': _children,
                  'profileImageUrl': _profileImageUrl,
                },
              );

              if (updatedData != null) {
                // First update local state with new data for immediate UI update
                setState(() {
                  _fullName = updatedData['fullName'] ?? _fullName;
                  _email = updatedData['email'] ?? _email;
                  _mobile = updatedData['mobile'] ?? _mobile;
                  _children = (updatedData['children'] as List?)?.map((child) {
                    return {
                      'name': child['name']?.toString() ?? '',
                      'age': child['age']?.toString() ?? '',
                    };
                  }).toList() ?? _children;
                  _profileImageUrl = updatedData['profileImageUrl']?.toString() ?? _profileImageUrl;
                  _isLoadingChildren = false;
                });

                // Force refresh from API to ensure data consistency
                final authProvider = context.read<AuthProvider>();
                await authProvider.refreshUserData();
                
                // Update local state with fresh API data
                final freshProfile = authProvider.userProfile;
                if (freshProfile != null && mounted) {
                  _updateLocalDataFromProfile(freshProfile);
                }

                SnackbarUtils.showSuccess(
                  context,
                  'Profile updated successfully!',
                );
              } else {
                // If no data returned, force refresh to get latest data
                await _fetchProfileData();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImageUrl.isNotEmpty
                              ? (_profileImageUrl.startsWith("http")
                                    ? NetworkImage(_profileImageUrl)
                                    : AssetImage(_profileImageUrl)
                                          as ImageProvider)
                              : null,
                          child: _profileImageUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                )
                              : null,
                        ),
                        // // TODO: Add child name to the profile page
                        // Positioned(
                        //   bottom: 0,
                        //   right: 0,
                        //   child: Container(
                        //     padding: const EdgeInsets.all(4),
                        //     decoration: BoxDecoration(
                        //       color: AppColors.primaryBlue,
                        //       shape: BoxShape.circle,
                        //       border: Border.all(color: Colors.white, width: 2),
                        //     ),
                        //     child: const Icon(
                        //       Icons.camera_alt,
                        //       color: Colors.white,
                        //       size: 20,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Full Name
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColorPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  AuthInputField(
                    controller: TextEditingController(text: _fullName),
                    labelText: '',
                    hintText: '',
                    readOnly: true,
                  ),
                  const SizedBox(height: 20.0),

                  // Email
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColorPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  AuthInputField(
                    controller: TextEditingController(text: _email),
                    labelText: '',
                    hintText: '',
                    readOnly: true,
                  ),
                  const SizedBox(height: 20.0),

                  // Mobile
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Mobile',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColorPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  AuthInputField(
                    controller: TextEditingController(text: _mobile),
                    labelText: '',
                    hintText: '',
                    readOnly: true,
                  ),
                  const SizedBox(height: 20.0),

                  // My Children
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: const Text(
                      'My Children',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColorPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.inputOutline,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoadingChildren
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8.0),
                                Text(
                                  'Loading children...',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: AppColors.textColorSecondary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _children.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.child_care_outlined,
                                      size: 48,
                                      color: AppColors.textColorSecondary,
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      "No children added yet.",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.textColorSecondary,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    Text(
                                      "Add children in Edit Profile",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.textColorSecondary,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: _children.map((child) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.child_care,
                                          size: 20,
                                          color: AppColors.primaryBlue,
                                        ),
                                        const SizedBox(width: 8.0),
                                        Expanded(
                                          child: Text(
                                            '${child['name']} (${child['age']} years old)',
                                            style: const TextStyle(
                                              fontSize: 16.0,
                                              color: AppColors.textColorPrimary,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                  ),


                  const SizedBox(height: 30.0),

                  // Log Out Button
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: () => _showLogoutConfirmationDialog(context),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: AppColors.unavailableRed,
                  //       padding: const EdgeInsets.symmetric(vertical: 16.0),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12.0),
                  //       ),
                  //       elevation: 3,
                  //     ),
                  //     child: const Text(
                  //       'Log Out',
                  //       style: TextStyle(
                  //         fontSize: 18.0,
                  //         fontWeight: FontWeight.bold,
                  //         color: Colors.white,
                  //         fontFamily: 'Poppins',
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
    );
  }
}
