import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:circleslate/core/services/group/group_conversation_manager.dart';
import 'package:circleslate/core/services/user_search_service.dart';
import 'package:circleslate/data/models/user_search_result_model.dart';


class CreateGroupPage extends StatefulWidget {
  final String currentUserId;

  const CreateGroupPage({required this.currentUserId, super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<UserSearchResult> _selectedUsers = {};
  final _formKey = GlobalKey<FormState>();
  final UserSearchService _userSearchService = UserSearchService();
  List<UserSearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;



  @override
  void initState() {
    super.initState();
    debugPrint('[CreateGroupPage] Initialized with currentUserId: ${widget.currentUserId}');
    debugPrint('[CreateGroupPage] currentUserId length: ${widget.currentUserId.length}');
    debugPrint('[CreateGroupPage] currentUserId is empty: ${widget.currentUserId.isEmpty}');

    if (widget.currentUserId.isEmpty) {
      debugPrint('[CreateGroupPage] Warning: currentUserId is empty');
      setState(() {
        _errorMessage = 'User ID is missing. Please log in again.';
      });
    } else {
      debugPrint('[CreateGroupPage] currentUserId is valid: ${widget.currentUserId}');
    }
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
        _searchResults = results.where((user) => user.id.toString() != widget.currentUserId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error searching users: $e';
      });
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one member for the group.')),
        );
        return;
      }

      if (widget.currentUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID is missing. Please log in again.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final groupName = _groupNameController.text.trim();
        final participantIds = _selectedUsers.map((user) => user.id.toString()).toList();

        debugPrint('[CreateGroupPage] Creating group with currentUserId: ${widget.currentUserId}, participantIds: $participantIds');

        final newGroupChat = await GroupConversationManager.createGroupConversation(
          widget.currentUserId,
          participantIds,
          groupName,
        );

        if (mounted) {
          context.push(RoutePaths.groupConversationPage, extra: {
            'groupName': newGroupChat.name,
            'isGroupChat': true,
            'isCurrentUserAdminInGroup': true,
            'currentUserId': widget.currentUserId,
            'conversationId': newGroupChat.id,
          });
          _selectedUsers.clear();
          _groupNameController.clear();
          _searchController.clear();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            // _errorMessage = 'Failed to create group: $e';
          });
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Failed to create group: $e')),
          // );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }


  void _removeSelectedUser(UserSearchResult user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
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
          'Create Group',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group Name',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColorPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      hintText: 'Type group name',
                      hintStyle: const TextStyle(
                          color: AppColors.textColorSecondary, fontFamily: 'Poppins'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Group name cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Search Users',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColorPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      hintStyle: const TextStyle(
                          color: AppColors.textColorSecondary, fontFamily: 'Poppins'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                    ),
                  ),
                  const SizedBox(height: 16.0),
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
                                    : AssetImage(AppAssets.profilePicture) as ImageProvider,
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
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontFamily: 'Poppins'),
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
                        secondary: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: user.profilePhotoUrl != null
                                  ? NetworkImage(user.profilePhotoUrl!)
                                  : AssetImage(AppAssets.profilePicture) as ImageProvider,
                            ),
                            if (user.isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.onlineIndicator,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Create Group',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}