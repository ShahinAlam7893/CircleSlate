import 'dart:convert';
import 'package:circleslate/core/network/endpoints.dart';
import 'package:circleslate/presentation/features/group_management/view/users_availability_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/group_model.dart';
import '../../../common_providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';

class GroupManagementPage extends StatefulWidget {
  final String groupId;
  final String conversationId;
  final String currentUserId;
  final String role;
  // final bool isCurrentUserAdmin;
  final bool isCurrentUserAdminInGroup;

  const GroupManagementPage({
    super.key,
    required this.role,
    required this.groupId,
    required this.conversationId,
    required this.currentUserId,
    // required this.isCurrentUserAdmin,
    required this.isCurrentUserAdminInGroup,
  });

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  static const String _baseUrl = '${Urls.baseUrl}/api/chat/conversations/';

  bool _isLoading = false;
  bool _isActionLoading = false;
  // bool get _isCurrentUserAdmin => widget.isCurrentUserAdmin;
  bool get _isCurrentUserAdmin => widget.isCurrentUserAdminInGroup;
  String? _error;
  List<GroupMember> _members = [];
  List<GroupMember> _filteredMembers = [];
  String _groupName = '';

  String childName = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _fetchGroupDetails();
    _loadChildren();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    final authProvider = context.read<AuthProvider>();
    final children = await authProvider.fetchChildren();

    if (children.isNotEmpty && mounted) {
      setState(() {
        childName = children.first['name'] ?? '';
      });
    }
  }

  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredMembers = List.from(_members);
      } else {
        _filteredMembers = _members.where((m) {
          return m.name.toLowerCase().contains(q) ||
              m.email.toLowerCase().contains(q) ||
              m.children.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) {
      debugPrint('[GroupManagementPage] Access token not found.');
      return null;
    }
    debugPrint('[GroupManagementPage] Retrieved token.');
    return token;
  }

  Future<void> _fetchGroupDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _error = 'Authentication token missing. Please login again.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
      '${Urls.baseUrl}/api/chat/conversations/${widget.conversationId}/members/',
    );
    debugPrint(
      '[GroupManagementPage] Fetching group details from groupId ${widget.groupId}',
    );
    debugPrint(
      '[GroupManagementPage] Fetching group details from conversationId ${widget.conversationId}',
    );
    debugPrint('[GroupManagementPage] Fetching group details from $url');

    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('[GroupManagementPage] Response status: ${resp.statusCode}');
      debugPrint('[GroupManagementPage] Response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;

        // Extract group name from group_info
        if (body.containsKey('group_info')) {
          final groupInfo = body['group_info'] as Map<String, dynamic>;
          _groupName = (groupInfo['name'] ?? '').toString();
        }

        // Extract members array
        List<dynamic> membersJson = [];
        if (body.containsKey('members')) {
          membersJson = body['members'] as List<dynamic>;
        }

        debugPrint('[GroupManagementPage] Found ${membersJson.length} members');

        // Map to GroupMember
        final fetchedMembers = membersJson.map<GroupMember>((m) {
          final id = (m['id'] ?? '').toString();
          final name = (m['full_name'] ?? m['name'] ?? m['username'] ?? '')
              .toString();
          final email = (m['email'] ?? '').toString();
          final children = (m['children'] ?? '').toString();
          final imageUrl =
              (m['profile_photo_url'] ?? m['avatar'] ?? m['image_url'] ?? '')
                  .toString();
          final roleStr = (m['role'] ?? m['role_code'] ?? '')
              .toString()
              .toLowerCase();
          final isAdmin = roleStr == 'admin';

          debugPrint(
            '[GroupManagementPage] Processing member: $name (ID: $id, Role: $roleStr) is current user admin?=> $_isCurrentUserAdmin',
          );

          return GroupMember(
            id: id,
            name: name.isNotEmpty ? name : 'Unknown',
            email: email,
            children: children,
            imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            role: isAdmin ? MemberRole.admin : MemberRole.member,
          );
        }).toList();

        debugPrint(
          '[GroupManagementPage] Mapped ${fetchedMembers.length} members successfully',
        );

        setState(() {
          _members = fetchedMembers;
          _filteredMembers = List.from(_members);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load group: ${resp.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _error = 'Error fetching group: $e';
        _isLoading = false;
      });
      debugPrint('[GroupManagementPage] Error fetching group details: $e');
      debugPrint('[GroupManagementPage] Stack trace: $stackTrace');
    }
  }

  Future<void> _addMembers() async {
    debugPrint('[GroupManagementPage] _addMembers() called');

    if (!widget.isCurrentUserAdminInGroup) {
      debugPrint('[GroupManagementPage] User is not admin, cannot add members');
      showInfoDialog(
        context,
        "Action not allowed",
        "Only admins can add members.",
      );
      return;
    }

    // Get existing member IDs to prevent re-adding
    final existingMemberIds = _members.map((member) => member.id).toList();

    // Use groupId as conversationId if conversationId is empty
    final conversationIdToUse = widget.conversationId.isNotEmpty
        ? widget.conversationId
        : widget.groupId;

    debugPrint('[GroupManagementPage] Navigating to AddMemberPage');
    debugPrint('[GroupManagementPage] GroupId: ${widget.groupId}');
    debugPrint(
      '[GroupManagementPage] ConversationId: ${widget.conversationId}',
    );
    debugPrint(
      '[GroupManagementPage] ConversationIdToUse: $conversationIdToUse',
    );
    debugPrint('[GroupManagementPage] CurrentUserId: ${widget.currentUserId}');
    debugPrint('[GroupManagementPage] ExistingMemberIds: $existingMemberIds');

    final result = await context.push(
      RoutePaths.addmemberpage,
      extra: {
        'conversationId': conversationIdToUse,
        'currentUserId': widget.currentUserId,
        'existingMemberIds': existingMemberIds,
      },
    );

    debugPrint(
      '[GroupManagementPage] Returned from AddMemberPage with result: $result',
    );

    if (result == null || result is! List<String>) {
      debugPrint('[GroupManagementPage] No valid user IDs returned, aborting');
      return;
    }

    final userIds = result;
    if (userIds.isEmpty) {
      debugPrint('[GroupManagementPage] No user IDs to add, aborting');
      return;
    }

    await _performAddMembers(userIds, conversationIdToUse);
  }

  Future<void> _performAddMembers(
    List<String> userIds,
    String conversationId,
  ) async {
    final token = await _getToken();
    if (token == null) {
      debugPrint('[GroupManagementPage] Token missing, cannot add members');
      showInfoDialog(context, "Action not allowed", "Please login again.");
      return;
    }

    setState(() => _isActionLoading = true);

    final url = Uri.parse(
      '${Urls.baseUrl}/api/chat/conversations/${widget.conversationId}/add-members/',
    );

    debugPrint('[GroupManagementPage] Adding members to URL: $url');
    debugPrint('[GroupManagementPage] User IDs to add: $userIds');

    // Convert string IDs to integers for the API
    final userIdsAsInts = userIds.map((id) {
      final parsed = int.tryParse(id);
      debugPrint('[GroupManagementPage] Converting id "$id" to int: $parsed');
      return parsed ?? id;
    }).toList();

    final payload = {'user_ids': userIdsAsInts};

    debugPrint('[GroupManagementPage] Request payload: ${jsonEncode(payload)}');

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint(
        '[GroupManagementPage] Add members response status: ${resp.statusCode}',
      );

      debugPrint(
        '[GroupManagementPage] Add members response body: ${resp.body}',
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final responseData = jsonDecode(resp.body);

        // Parse the response to show detailed feedback
        final addedUsers = responseData['added_users'] as List<dynamic>? ?? [];
        final alreadyMembers =
            responseData['already_members'] as List<dynamic>? ?? [];

        String message = '';
        if (addedUsers.isNotEmpty) {
          message =
              'Added ${addedUsers.length} member(s): ${addedUsers.join(', ')}';
        }
        if (alreadyMembers.isNotEmpty) {
          if (message.isNotEmpty) message += '\n';
          message +=
              '${alreadyMembers.length} user(s) were already members: ${alreadyMembers.join(', ')}';
        }

        if (message.isEmpty) {
          message = 'Members processed successfully';
        }

        SnackbarUtils.showSuccess(context, message);

        // Refresh the group details to show new members
        await _fetchGroupDetails();
      } else {
        final errorMessage = resp.body.isNotEmpty
            ? 'Failed to add members\nOnly admins can add members.'
            : 'Failed to add members (${resp.statusCode})';

        debugPrint(
          '[GroupManagementPage] Failed to add members: $errorMessage',
        );
        SnackbarUtils.showError(context, errorMessage);
        // showInfoDialog(
        //   context,
        //   "Action not allowed",
        //   "Only admins can add members.",
        // );
      }
    } catch (e) {
      debugPrint('[GroupManagementPage] Error adding members: $e');
      SnackbarUtils.showError(context, 'Error adding members: $e');
    } finally {
      setState(() => _isActionLoading = false);
      debugPrint('[GroupManagementPage] _performAddMembers() finished');
    }
  }

  void showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(GroupMember member) async {
    if (!widget.isCurrentUserAdminInGroup) {
      showInfoDialog(
        context,
        "Action not allowed",
        "Only admins can remove members.",
      );
      return;
    }

    // Prevent removing yourself
    if (member.id == widget.currentUserId) {
      showInfoDialog(
        context,
        "Action not allowed",
        "You cannot remove yourself from the group.",
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.name} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await _getToken();
    if (token == null) {
      SnackbarUtils.showError(context, 'Authentication token missing.');
      return;
    }

    setState(() => _isActionLoading = true);
    final url = Uri.parse('$_baseUrl${widget.conversationId}/remove-member/');
    debugPrint('[GroupManagementPage] Removing member ${member.id} from $url');

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': int.tryParse(member.id) ?? member.id}),
      );

      debugPrint(
        '[GroupManagementPage] Remove member response status: ${resp.statusCode}',
      );
      debugPrint(
        '[GroupManagementPage] Remove member response body: ${resp.body}',
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        showInfoDialog(
          context,
          "Successful",
          "${member.name} has been removed from the group.",
        );
        await _fetchGroupDetails();
      } else {
        showInfoDialog(
          context,
          "Action not allowed",
          "You are not an admin to remove members.",
        );
      }
    } catch (e) {
      debugPrint('[GroupManagementPage] Error removing member: $e');
      SnackbarUtils.showError(context, 'Error removing member: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _promoteToAdmin(GroupMember member) async {
    if (!widget.isCurrentUserAdminInGroup) {
      showInfoDialog(
        context,
        "Action not allowed",
        "Only admins can promote members.",
      );
      return;
    }

    if (member.role == MemberRole.admin) {
      showInfoDialog(
        context,
        "Action not allowed",
        "${member.name} is already an admin.",
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text(
          'Are you sure you want to promote ${member.name} to admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Promote', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await _getToken();
    if (token == null) {
      SnackbarUtils.showError(context, 'Authentication token missing.');
      return;
    }

    setState(() => _isActionLoading = true);

    final url = Uri.parse(
      '${Urls.baseUrl}/api/chat/conversations/${widget.conversationId}/promote-admin/',
    );
    debugPrint(
      '[GroupManagementPage] Promoting member ${member.id} to admin at $url',
    );

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': int.tryParse(member.id) ?? member.id,
          'preserve_first_admin': true,
        }),
      );

      debugPrint(
        '[GroupManagementPage] Promote response status: ${resp.statusCode}',
      );
      debugPrint('[GroupManagementPage] Promote response body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        showInfoDialog(
          context,
          "Successful",
          "${member.name} is now an admin. They have all admin rights except removing the first admin.",
        );
        await _fetchGroupDetails();
      } else if (resp.statusCode == 403) {
        showInfoDialog(
          context,
          "Action not allowed",
          "You cannot promote members. Only admins have permission.",
        );
      } else {
        showInfoDialog(
          context,
          "Error",
          "Failed to promote member. Status code: ${resp.statusCode}",
        );
      }
    } catch (e) {
      debugPrint('[GroupManagementPage] Error promoting member: $e');
      SnackbarUtils.showError(context, 'Error promoting member: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _leaveGroup() async {
    if (!widget.isCurrentUserAdminInGroup) {
      showInfoDialog(
        context,
        "Action not allowed",
        "Admins cannot leave the group.",
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await _getToken();
    if (token == null) {
      SnackbarUtils.showError(context, 'Authentication token missing.');
      return;
    }

    setState(() => _isActionLoading = true);
    final url = Uri.parse('$_baseUrl${widget.conversationId}/leave/');
    debugPrint('[GroupManagementPage] Leaving group at $url');

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        '[GroupManagementPage] Leave group response status: ${resp.statusCode}',
      );
      debugPrint(
        '[GroupManagementPage] Leave group response body: ${resp.body}',
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        showInfoDialog(context, "Successful", "You have left the group.");
        context.push('/chat');
      } else {
        showInfoDialog(context, "Error", "Admin cannot leave the group.");
      }
    } catch (e) {
      debugPrint('[GroupManagementPage] Error leaving group: $e');
      SnackbarUtils.showError(context, 'Error leaving group: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _deleteGroup() async {
    if (!widget.isCurrentUserAdminInGroup) {
      showInfoDialog(
        context,
        "Action not allowed",
        "Only admins can delete the group.",
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await _getToken();
    if (token == null) {
      SnackbarUtils.showError(context, 'Authentication token missing.');
      return;
    }

    setState(() => _isActionLoading = true);
    final url = Uri.parse('$_baseUrl${widget.conversationId}/delete-group/');
    debugPrint('[GroupManagementPage] Deleting group at $url');

    try {
      final resp = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        '[GroupManagementPage] Delete group response status: ${resp.statusCode}',
      );
      debugPrint(
        '[GroupManagementPage] Delete group response body: ${resp.body}',
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        showInfoDialog(context, "Successful", "The group has been deleted.");
        context.push('/chat');
      } else {
        showInfoDialog(context, "Error", "Only admins can delete the group.");
      }
    } catch (e) {
      debugPrint('[GroupManagementPage] Error deleting group: $e');
      SnackbarUtils.showError(context, 'Error deleting group: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _changeGroupName() async {
    if (!widget.isCurrentUserAdminInGroup) {
      showInfoDialog(
        context,
        "Action not allowed",
        "Only admins can change group name.",
      );
      return;
    }

    final controller = TextEditingController(text: _groupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Group Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new group name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isEmpty) return;
              Navigator.pop(context, val);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (newName == null ||
        newName.trim().isEmpty ||
        newName.trim() == _groupName)
      return;

    final token = await _getToken();
    if (token == null) {
      SnackbarUtils.showError(context, 'Authentication token missing.');
      return;
    }

    setState(() => _isActionLoading = true);
    final url = Uri.parse(
      "${Urls.baseUrl}/chat/conversations/${widget.conversationId}/change-name/",
    );
    debugPrint(
      '[GroupManagementPage] Changing group name to "$newName" at $url',
    );

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': newName}),
      );

      debugPrint(
        '[GroupManagementPage] Change name response status: ${resp.statusCode}',
      );
      debugPrint(
        '[GroupManagementPage] Change name response body: ${resp.body}',
      );

      if (resp.statusCode == 200) {
        setState(() {
          _groupName = newName;
        });
        SnackbarUtils.showSuccess(context, 'Group name changed.');
      } else {
        showInfoDialog(
          context,
          "Action not allowed",
          "Only admins can change group name.",
        );
      }
    } catch (e) {
      debugPrint('[GroupManagementPage] Error changing group name: $e');
      SnackbarUtils.showError(context, 'Error changing group name: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _showUserAvailabilityCalendar(GroupMember member) async {
    print('Navigating to calendar for user: ${member.id} (${member.name})');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserAvailabilityCalendarPage(
          userId: member.id,
          userName: member.name,
        ),
      ),
    );
  }

  Widget _buildMemberTile(GroupMember member) {
    final isAdmin = member.role == MemberRole.admin;
    final isCurrentUser = member.id == widget.currentUserId;
    final isCurrentUserAdmin = isAdmin && isCurrentUser;

    print(member.id);
    print(member.role);
    print(widget.currentUserId);

    print('isCurrentUserAdmin XYZ $isCurrentUserAdmin');

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        leading: GestureDetector(
          onTap: () => _showUserAvailabilityCalendar(member),
          child: CircleAvatar(
            radius: 24.r,
            backgroundImage:
                member.imageUrl != null && member.imageUrl!.isNotEmpty
                ? Image.network(member.imageUrl!).image
                : const AssetImage('assets/images/default_avatar.png'),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showUserAvailabilityCalendar(member),
                child: Text(
                  member.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.blue.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                isAdmin ? 'Admin' : 'Member',
                style: TextStyle(
                  color: isAdmin ? Colors.blue.shade700 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            'Children: ${member.children}\n${member.email}',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        isThreeLine: true,
        tileColor: isAdmin ? Colors.blue.withOpacity(0.04) : null,
        trailing: !isCurrentUserAdmin
            ? PopupMenuButton<String>(
                iconSize: 24.sp,
                onSelected: (v) async {
                  if (v == 'promote') {
                    await _promoteToAdmin(member);
                  } else if (v == 'remove') {
                    await _removeMember(member);
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];
                  if (!isAdmin) {
                    items.add(
                      PopupMenuItem(
                        value: 'promote',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Promote to Admin',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  items.add(
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_circle_outline,
                            size: 20.sp,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  return items;
                },
              )
            : null,
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _fetchGroupDetails();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.isCurrentUserAdminInGroup);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _groupName.isNotEmpty ? _groupName : 'Group Management',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (_isActionLoading) return;
              switch (value) {
                case 'edit':
                  _changeGroupName();
                  break;
                case 'delete':
                  _deleteGroup();
                  break;
                case 'leave':
                  _leaveGroup();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Edit Group"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Delete Group"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Leave Group"),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search members or children',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applySearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Members (${_filteredMembers.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (widget.isCurrentUserAdminInGroup)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _isActionLoading ? null : _addMembers,
                            child: _isActionLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _filteredMembers.isEmpty
                  ? const Center(child: Text('No members found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredMembers.length,
                      itemBuilder: (context, idx) {
                        final member = _filteredMembers[idx];
                        return _buildMemberTile(member);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
