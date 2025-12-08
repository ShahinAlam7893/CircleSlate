// lib/presentation/home/widgets/my_groups_section.dart

import 'dart:convert';

import 'package:circleslate/core/errors/snackbar_service.dart';
import 'package:circleslate/data/services/api_base_helper.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/endpoints.dart';
import '../../../common_providers/auth_provider.dart';


class MyGroupsSection extends StatefulWidget {
  const MyGroupsSection({Key? key}) : super(key: key);

  @override
  State<MyGroupsSection> createState() => _MyGroupsSectionState();
}

class _MyGroupsSectionState extends State<MyGroupsSection> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;

  late final ApiBaseHelper _apiHelper; // ← Now safe

  @override
  void initState() {
    super.initState();
    // Pass context so snackbars work automatically
    _apiHelper = ApiBaseHelper(context: context);
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _groups.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null || token.isEmpty) {
        SnackbarService.showError(context, 'Please log in again');
        setState(() => _isLoading = false);
        return;
      }

      // ← THIS IS THE ONLY CHANGE: use safe API call
      final response = await _apiHelper.get(
        Urls.userGroups,
        token: token,
      );

      final data = json.decode(response.body);
      final List<dynamic> groupsList = data['groups'] ?? [];

      setState(() {
        _groups = groupsList
            .map((g) => {
                  'id': g['id'].toString(),
                  'name': g['name'] ?? 'Unnamed Group',
                  'isCurrentUserAdminInGroup': g['is_admin'] == true,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      // ← ALL errors are now caught safely by ApiBaseHelper
      // No need to handle SocketException, Timeout, etc. manually
      // Snackbar already shown inside ApiBaseHelper
      setState(() => _isLoading = false);
    }
  }

  String? get currentUserId {
    return Provider.of<AuthProvider>(context, listen: false).currentUserId;
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

        // Loading
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),

        // Empty state
        if (!_isLoading && _groups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'You are not a member of any groups yet.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColorSecondary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Groups Grid
        if (!_isLoading && _groups.isNotEmpty)
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
                    SnackbarService.showError(context, 'Please log in again');
                    return;
                  }

                  context.push(
                    RoutePaths.groupConversationPage,
                    extra: {
                      'groupName': group['name'],
                      'isGroupChat': true,
                      'isCurrentUserAdminInGroup': group['isCurrentUserAdminInGroup'],
                      'currentUserId': currentUserId,
                      'conversationId': group['id'],
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        group['name'],
                        style: TextStyle(
                          color: AppColors.textColorPrimary,
                          fontFamily: 'Poppins',
                          fontSize: groupNameFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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