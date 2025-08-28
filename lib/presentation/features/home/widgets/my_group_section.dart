import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/endpoints.dart';
import '../../../common_providers/auth_provider.dart';
import '../../../routes/app_router.dart';

class MyGroupsSection extends StatefulWidget {
  const MyGroupsSection({Key? key}) : super(key: key);

  @override
  _MyGroupsSectionState createState() => _MyGroupsSectionState();
}

class _MyGroupsSectionState extends State<MyGroupsSection> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? get currentUserId {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) {
        debugPrint('No access token found in SharedPreferences');
        throw Exception('No access token found');
      }
      debugPrint('Access Token: $token');

      final response = await http.get(
        Uri.parse('${Urls.baseUrl}/chat/groups/user-groups/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('API Response Status Code: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> groups = data['groups'] ?? [];
        debugPrint('Groups from API: $groups');

        setState(() {
          _groups = groups
              .map((group) => {
            'id': group['id'],
            'name': group['name'],
            'isCurrentUserAdminInGroup': group['is_admin'] ?? false, // Fetch admin status
          })
              .toList();
          debugPrint('Processed Groups: $_groups');
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load groups: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching groups: $e');
      setState(() {
        _errorMessage = 'Error fetching groups: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double sectionTitleFontSize = screenWidth * 0.04;
    final double groupNameFontSize = screenWidth * 0.038;
    final double smallSpacing = screenWidth * 0.03;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Circles',
          style: TextStyle(
            fontSize: sectionTitleFontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.textColorPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: smallSpacing),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        if (!_isLoading && _errorMessage == null && _groups.isEmpty)
          const Text(
            'You are not a member of any groups.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textColorSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        if (!_isLoading && _errorMessage == null && _groups.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: screenWidth / (screenWidth * 0.3),
              crossAxisSpacing: screenWidth * 0.025,
              mainAxisSpacing: screenWidth * 0.025,
            ),
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return GestureDetector(
                onTap: () {
                  if (currentUserId == null || currentUserId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID is missing. Please log in again.')),
                    );
                    return;
                  }
                  context.push(
                    RoutePaths.groupConversationPage,
                    extra: {
                      'groupName': group['name'],
                      'isGroupChat': true,
                      'isCurrentUserAdminInGroup': group['isCurrentUserAdminInGroup'] ?? false,
                      'currentUserId': currentUserId,
                      'conversationId': group['id'],
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    border: Border.all(
                      color: AppColors.primaryBlue,
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      group['name'],
                      style: TextStyle(
                        color: AppColors.textColorPrimary,
                        fontFamily: 'Poppins',
                        fontSize: groupNameFontSize,
                      ),
                      textAlign: TextAlign.center,
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