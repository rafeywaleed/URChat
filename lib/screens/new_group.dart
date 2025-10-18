import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat/model/dto.dart';
import 'package:urchat/model/user.dart';
import 'package:urchat/service/api_service.dart';

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
      final users = await ApiService.searchUsers(query);
      // Filter out already selected users and current user
      final filteredUsers = users
          .where((user) =>
              !_selectedUsers
                  .any((selected) => selected.username == user.username) &&
              user.username != ApiService.currentUsername)
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
      final newGroup = await ApiService.createGroup(
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
        SizedBox(
          height: _getSelectedUsersHeight(),
          child: _isMobile(context)
              ? _buildSelectedUsersGrid()
              : _buildSelectedUsersList(),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildSelectedUsersList() {
    return ListView.builder(
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
                    radius: _getAvatarRadius(),
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
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: _getCloseIconSize(),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: _getUserNameWidth(),
                child: Text(
                  user.fullName,
                  style: TextStyle(fontSize: _getUserNameFontSize()),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedUsersGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridCrossAxisCount(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _selectedUsers.length,
      itemBuilder: (context, index) {
        final user = _selectedUsers[index];
        return Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: _parseColor(user.pfpBg),
                  radius: _getAvatarRadius(),
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
                      child: Icon(
                        Icons.close,
                        size: _getCloseIconSize(),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              user.fullName,
              style: TextStyle(fontSize: _getUserNameFontSize()),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return const SizedBox();
    }

    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: NesPixelRowLoadingIndicator()),
      );
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
            textAlign: TextAlign.center,
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
                radius: _getListAvatarRadius(),
                child: Text(
                  user.pfpIndex,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                user.fullName,
                style: TextStyle(fontSize: _getListTitleFontSize()),
              ),
              subtitle: Text(
                '@${user.username}',
                style: TextStyle(fontSize: _getListSubtitleFontSize()),
              ),
              trailing: Icon(Icons.add),
              onTap: () => _selectUser(user),
              contentPadding: EdgeInsets.symmetric(
                horizontal: _getListTileHorizontalPadding(),
              ),
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

  // Responsive helper methods
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;
  }

  double _getSelectedUsersHeight() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 120;
    if (width < 600) return 100;
    return 80;
  }

  double _getAvatarRadius() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 20;
    if (width < 600) return 18;
    return 16;
  }

  double _getListAvatarRadius() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 18;
    return 20;
  }

  double _getCloseIconSize() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 10;
    return 12;
  }

  double _getUserNameWidth() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 50;
    if (width < 600) return 55;
    return 60;
  }

  double _getUserNameFontSize() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 10;
    return 12;
  }

  double _getListTitleFontSize() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 14;
    return 16;
  }

  double _getListSubtitleFontSize() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 12;
    return 14;
  }

  double _getListTileHorizontalPadding() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 8;
    return 16;
  }

  int _getGridCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 4;
    if (width < 600) return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: _getDialogPadding(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _getMaxDialogWidth(),
          maxHeight: _getMaxDialogHeight(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(_getHeaderPadding()),
              decoration: BoxDecoration(
                color: const Color(0xFF5C4033),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: _getHeaderSpacing()),
                  Expanded(
                    child: Text(
                      'Create New Group',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getHeaderFontSize(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isCreating)
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: NesHourglassLoadingIndicator())
                  else
                    IconButton(
                      icon: NesIcon(
                        iconData: NesIcons.check,
                      ),
                      onPressed: _createGroup,
                      tooltip: 'Create Group',
                    ),
                  IconButton(
                    icon: NesIcon(
                      iconData: NesIcons.close,
                    ),
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
                      padding: EdgeInsets.all(_getContentPadding()),
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
                      padding: EdgeInsets.symmetric(
                          horizontal: _getContentPadding()),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search users to add',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          // suffixIcon: _isSearching
                          //     ? SizedBox(
                          //         width: 20,
                          //         height: 20,
                          //         child: NesTerminalLoadingIndicator())
                          //     : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Selected Users
                    _buildSelectedUsers(),

                    // Search Results
                    _buildSearchResults(),

                    // Info text
                    if (_selectedUsers.isEmpty &&
                        _searchController.text.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(_getContentPadding()),
                        child: Text(
                          'Search for users and add them to create a group',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: _getInfoTextFontSize(),
                          ),
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

  // Additional responsive helper methods
  EdgeInsets _getDialogPadding() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return const EdgeInsets.all(8);
    if (width < 600) return const EdgeInsets.all(12);
    return const EdgeInsets.all(20);
  }

  double _getMaxDialogWidth() {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return width - 32;
    return 500;
  }

  double _getMaxDialogHeight() {
    final height = MediaQuery.of(context).size.height;
    if (height < 600) return height - 50;
    return 600;
  }

  double _getHeaderPadding() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 12;
    return 16;
  }

  double _getHeaderIconSize() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 20;
    return 24;
  }

  double _getHeaderSpacing() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 8;
    return 12;
  }

  double _getHeaderFontSize() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 16;
    return 18;
  }

  double _getActionIconSize() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 18;
    return 24;
  }

  double _getContentPadding() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 12;
    return 16;
  }

  double _getInfoTextFontSize() {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 12;
    return 14;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
