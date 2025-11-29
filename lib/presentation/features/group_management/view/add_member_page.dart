import 'package:circleslate/core/constants/app_assets.dart';
import 'package:circleslate/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/user_search_service.dart';
import '../../../../data/models/user_search_result_model.dart';
import 'package:circleslate/core/utils/snackbar_utils.dart';

class AddMemberPage extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final List<String> existingMemberIds; // To prevent re-adding existing members

  const AddMemberPage({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    this.existingMemberIds = const [],
  });

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserSearchService _userSearchService = UserSearchService();

  List<UserSearchResult> _searchResults = [];
  List<UserSearchResult> _selectedUsers = [];
  bool _isSearching = false;
  String? _searchError;
  bool _isAddingMembers = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _userSearchService.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    if (query.length < 2) {
      return; // Wait for at least 2 characters
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    _performSearch(query);
  }

  void _performSearch(String query) async {
    try {
      final results = await _userSearchService.searchUsers(query);
      if (mounted) {
        // Filter out current user and existing members
        final filteredResults = results.where((user) {
          return user.id != widget.currentUserId &&
              !widget.existingMemberIds.contains(user.id);
        }).toList();

        setState(() {
          _searchResults = filteredResults;
          _isSearching = false;
          _searchError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
          _searchError = 'Search failed: ${e.toString()}';
        });
      }
    }
  }

  void _toggleUserSelection(UserSearchResult user) {
    setState(() {
      if (_selectedUsers.any((u) => u.id == user.id)) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  bool _isUserSelected(UserSearchResult user) {
    return _selectedUsers.any((u) => u.id == user.id);
  }

  void _addSelectedMembers() async {
    if (_selectedUsers.isEmpty) {
      SnackbarUtils.showWarning(context, 'Please select at least one user to add');
      return;
    }

    setState(() => _isAddingMembers = true);

    try {
      // Return the list of selected user IDs to the parent page
      final userIds = _selectedUsers.map((user) => user.id).toList();
      Navigator.pop(context, userIds);
    } catch (e) {
      setState(() => _isAddingMembers = false);
      SnackbarUtils.showError(context, 'Error: ${e.toString()}');
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedUsers.clear();
    });
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Members',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedUsers.isNotEmpty)
            TextButton(
              onPressed: _clearSelection,
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                hintStyle: const TextStyle(
                    color: AppColors.textColorSecondary,
                    fontFamily: 'Poppins'
                ),
                prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textColorPrimary
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0
                ),
              ),
            ),
          ),

          // Selected Users Count
          if (_selectedUsers.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: AppColors.primaryBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '${_selectedUsers.length} user(s) selected',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8.0),

          // Search Results
          Expanded(
            child: _buildSearchContent(),
          ),

          // Add Members Button
          if (_selectedUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAddingMembers ? null : _addSelectedMembers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)
                    ),
                    elevation: 3,
                  ),
                  child: _isAddingMembers
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Add ${_selectedUsers.length} Member${_selectedUsers.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Start typing to search for users',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.trim().length < 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Type at least 2 characters to search',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Searching for users...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text.trim()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserSearchItem(user);
      },
    );
  }

  Widget _buildUserSearchItem(UserSearchResult user) {
    final isSelected = _isUserSelected(user);
    final isExistingMember = widget.existingMemberIds.contains(user.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 0,
      color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user.profilePhotoUrl != null
                  ? NetworkImage(user.profilePhotoUrl!)
                  : const AssetImage(AppAssets.johnProfile) as ImageProvider,
            ),
            if (user.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.primaryBlue : const Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.textColorSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            if (isExistingMember)
              Text(
                'Already a member',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
          ],
        ),
        trailing: isExistingMember
            ? Icon(
          Icons.check_circle,
          color: Colors.orange[600],
          size: 24,
        )
            : Checkbox(
          value: isSelected,
          onChanged: (bool? value) {
            _toggleUserSelection(user);
          },
          activeColor: AppColors.primaryBlue,
        ),
        onTap: isExistingMember ? null : () => _toggleUserSelection(user),
        enabled: !isExistingMember,
      ),
    );
  }
}