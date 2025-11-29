import 'dart:convert';
import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/services/user_search_service.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';
import 'package:circleslate/data/models/user_search_result_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DirectInvitePage extends StatefulWidget {
  const DirectInvitePage({super.key});

  @override
  State<DirectInvitePage> createState() => _DirectInvitePageState();
}

class _DirectInvitePageState extends State<DirectInvitePage> {
  final TextEditingController _searchController = TextEditingController();
  final UserSearchService _userSearchService = UserSearchService();
  final Set<UserSearchResult> _selectedUsers = {};
  List<UserSearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _invitesJson; // store selected users as JSON

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _userSearchService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error searching users: $e';
      });
    }
  }

  void _removeSelectedUser(UserSearchResult user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  void _sendInvites() {
    if (_selectedUsers.isEmpty) {
      SnackbarUtils.showWarning(context, 'Please select at least one user to invite.');
      return;
    }

    // Step 2: Save only selected user IDs as JSON in singleton
    final idsList = _selectedUsers.map((u) => u.id).toList();
    InviteStorage().invitesJson = jsonEncode(idsList);

    debugPrint(
      '[DirectInvitePage] Invites JSON (IDs only): ${InviteStorage().invitesJson}',
    );

    SnackbarUtils.showSuccess(context, 'Invites saved globally as JSON!');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userSearchService.dispose();
    super.dispose();
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
          'Direct Invite',
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
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _isLoading
                ? null
                : () {
                    // Send invites first
                    _sendInvites();

                    // Then navigate back
                    Navigator.pop(context);
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                hintStyle: const TextStyle(
                  color: AppColors.textColorSecondary,
                  fontFamily: 'Poppins',
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textColorSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Members',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColorPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8.0),
                if (_selectedUsers.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _selectedUsers.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: AppColors.textColorPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            avatar: CircleAvatar(
                              radius: 14,
                              backgroundImage: user.profilePhotoUrl != null
                                  ? NetworkImage(user.profilePhotoUrl!)
                                  : AssetImage(AppAssets.profilePicture)
                                        as ImageProvider,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeSelectedUser(user),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Text(
                    'No members selected',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textColorSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                    color: Colors.white,
                    child: CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: AppColors.primaryBlue,
                      checkColor: Colors.white,
                      value: _selectedUsers.contains(user),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedUsers.add(user);
                          } else {
                            _selectedUsers.remove(user);
                          }
                        });
                      },
                      title: Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      subtitle: Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textColorSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      secondary: CircleAvatar(
                        radius: 24,
                        backgroundImage: user.profilePhotoUrl != null
                            ? NetworkImage(user.profilePhotoUrl!)
                            : AssetImage(AppAssets.profilePicture)
                                  as ImageProvider,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// lib/core/services/invite_storage.dart
class InviteStorage {
  // Step 2: Singleton to store invites JSON globally
  static final InviteStorage _instance = InviteStorage._internal();
  factory InviteStorage() => _instance;
  InviteStorage._internal();

  String? invitesJson; // Stores JSON of selected user IDs
}
