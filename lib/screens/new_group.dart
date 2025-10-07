import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/model/user.dart';
import 'package:urchat_back_testing/service/api_service.dart';

class CreateGroupDialog extends StatefulWidget {
  final Function(GroupChatRoomDTO)? onGroupCreated;

  const CreateGroupDialog({Key? key, this.onGroupCreated}) : super(key: key);

  @override
  _CreateGroupDialogState createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<User> _searchResults = [];
  List<User> _selectedUsers = [];
  bool _isSearching = false;
  bool _isCreating = false;

  final ApiService apiService = Get.find<ApiService>();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await apiService.searchUsers(query);
      // Filter out already selected users and current user
      final filteredUsers = users
          .where((user) =>
              !_selectedUsers
                  .any((selected) => selected.username == user.username) &&
              user.username != apiService.currentUsername)
          .toList();

      setState(() {
        _searchResults = filteredUsers;
        _isSearching = false;
      });
    } catch (e) {
      print('❌ Error searching users: $e');
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _selectUser(User user) {
    setState(() {
      _selectedUsers.add(user);
      _searchResults.removeWhere((u) => u.username == user.username);
      _searchController.clear();
    });
  }

  void _removeUser(User user) {
    setState(() {
      _selectedUsers.removeWhere((u) => u.username == user.username);
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final participantUsernames =
          _selectedUsers.map((user) => user.username).toList();
      final newGroup = await apiService.createGroup(
        _groupNameController.text.trim(),
        participantUsernames,
      );

      // Notify parent about the new group
      widget.onGroupCreated?.call(newGroup);

      Navigator.of(context).pop(newGroup);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${newGroup.chatName}" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Widget _buildSelectedUsers() {
    if (_selectedUsers.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Selected Members',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _selectedUsers.length,
            itemBuilder: (context, index) {
              final user = _selectedUsers[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: _parseColor(user.pfpBg),
                          child: Text(
                            user.pfpIndex,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeUser(user),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return const SizedBox();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchController.text.length < 2
                ? 'Type at least 2 characters to search'
                : 'No users found',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Search Results',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final user = _searchResults[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _parseColor(user.pfpBg),
                child: Text(
                  user.pfpIndex,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.fullName),
              subtitle: Text('@${user.username}'),
              trailing: const Icon(Icons.add),
              onTap: () => _selectUser(user),
            );
          },
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5C4033),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group_add, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Create New Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isCreating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: _createGroup,
                      tooltip: 'Create Group',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Group Name Input
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _groupNameController,
                        decoration: const InputDecoration(
                          labelText: 'Group Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                      ),
                    ),

                    // Search for Users
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search users to add',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                        ),
                      ),
                    ),

                    // Selected Users
                    _buildSelectedUsers(),

                    // Search Results
                    _buildSearchResults(),

                    // Info text
                    if (_selectedUsers.isEmpty &&
                        _searchController.text.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Search for users and add them to create a group',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
