import 'package:flutter/material.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/screens/group_pfp_dialog.dart';
import 'package:urchat_back_testing/screens/user_profile.dart';
import 'package:urchat_back_testing/service/api_service.dart';

import '../model/chat_room.dart';

class GroupManagementScreen extends StatefulWidget {
  final ChatRoom group;

  const GroupManagementScreen({required this.group});

  @override
  _GroupManagementScreenState createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  late Future<GroupChatRoomDTO> _groupDetailsFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _groupDetailsFuture = ApiService.getGroupDetails(widget.group.chatId);
  }

  void _refreshGroupDetails() {
    setState(() {
      _groupDetailsFuture = ApiService.getGroupDetails(widget.group.chatId);
    });
  }

  Future<void> _inviteUser(String username) async {
    try {
      await ApiService.inviteToGroup(widget.group.chatId, username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation sent to $username')),
      );
      _refreshGroupDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to invite user: $e')),
      );
    }
  }

  Future<void> _removeUser(String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content:
            Text('Are you sure you want to remove $username from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.removeFromGroup(widget.group.chatId, username);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User removed from group')),
        );
        _refreshGroupDetails();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove user: $e')),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.leaveGroup(widget.group.chatId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left the group')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave group: $e')),
        );
      }
    }
  }

  // Helper method to check if current user is admin
  bool _isCurrentUserAdmin(GroupChatRoomDTO groupDetails) {
    return groupDetails.adminUsername == ApiService.currentUsername;
  }

  Widget _buildMemberList(GroupChatRoomDTO groupDetails) {
    final isCurrentUserAdmin = _isCurrentUserAdmin(groupDetails);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Group Members (${groupDetails.groupMembers.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...groupDetails.groupMembers
            .map(
              (member) => ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => OtherUserProfileScreen(
                            username: member.username,
                            fromChat: true,
                          )),
                ),
                leading: CircleAvatar(
                  backgroundColor: _parseColor(member.pfpBg),
                  child: Text(member.pfpIndex,
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(member.fullName),
                subtitle: Text('@${member.username}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (member.username == groupDetails.adminUsername)
                      Chip(
                        label: const Text('Admin'),
                        backgroundColor: Colors.blue[100],
                      ),
                    if (isCurrentUserAdmin &&
                        member.username != groupDetails.adminUsername)
                      IconButton(
                        icon:
                            const Icon(Icons.person_remove, color: Colors.red),
                        onPressed: () => _removeUser(member.username),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildPendingInvitations(groupDetails) {
    List<GroupMembersDTO> pending = groupDetails.memberRequests;
    final isCurrentUserAdmin = _isCurrentUserAdmin(groupDetails);

    if (pending.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Pending Invitations (${pending.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...pending
            .map((invite) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _parseColor(invite.pfpBg),
                    child: Text(invite.pfpIndex,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(invite.fullName),
                  subtitle: Text('@${invite.username}'),
                  trailing: isCurrentUserAdmin
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            // Optionally add functionality to cancel invitation
                            _showCancelInvitationDialog(invite.username);
                          },
                        )
                      : null,
                ))
            .toList(),
      ],
    );
  }

  Future<void> _showCancelInvitationDialog(String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invitation'),
        content: Text(
            'Are you sure you want to cancel the invitation to $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Invitation',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Note: You might need to add an API endpoint to cancel invitations
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Canceling invitations feature coming soon')),
      );
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshGroupDetails,
          ),
        ],
      ),
      body: FutureBuilder<GroupChatRoomDTO>(
        future: _groupDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final groupDetails = snapshot.data!;
          final isCurrentUserAdmin = _isCurrentUserAdmin(groupDetails);

          return ListView(
            children: [
              // Group Info Header
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _parseColor(groupDetails.pfpBg),
                  child: Text(groupDetails.pfpIndex,
                      style: const TextStyle(color: Colors.white)),
                  radius: 30,
                ),
                title: Text(
                  groupDetails.chatName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group • ${groupDetails.groupMembers.length} members'),
                    Text(
                      'Admin: ${groupDetails.adminUsername}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Invite Section - Only show for admin
              if (isCurrentUserAdmin)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invite Users',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Enter username to invite',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: () {
                              if (_searchController.text.isNotEmpty) {
                                _inviteUser(_searchController.text.trim());
                                _searchController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Members List
              _buildMemberList(groupDetails),

              // Pending Invitations
              _buildPendingInvitations(groupDetails),

              // Leave Group Button - Only show for non-admin users
              if (!isCurrentUserAdmin)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _leaveGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Leave Group'),
                  ),
                ),

              // Admin Leave Warning
              if (isCurrentUserAdmin)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Note: As admin, you cannot leave the group. '
                    'You must transfer admin rights first or delete the group.',
                    style: TextStyle(color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Group Actions Section for Admin
              if (isCurrentUserAdmin)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Actions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Add transfer admin functionality
                              _showTransferAdminDialog(groupDetails);
                            },
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Transfer Admin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Add change group picture functionality
                              _showChangeGroupPictureDialog();
                            },
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Change Picture'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showTransferAdminDialog(GroupChatRoomDTO groupDetails) async {
    final nonAdminMembers = groupDetails.groupMembers
        .where((member) => member.username != groupDetails.adminUsername)
        .toList();

    if (nonAdminMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other members to transfer admin to')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Admin Role'),
        content: const Text('Select a member to transfer admin role to:'),
        actions: [
          ...nonAdminMembers
              .map((member) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _parseColor(member.pfpBg),
                      child: Text(member.pfpIndex,
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(member.fullName),
                    subtitle: Text('@${member.username}'),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmTransferAdmin(member.username);
                    },
                  ))
              .toList(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmTransferAdmin(String newAdminUsername) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Text(
            'Are you sure you want to transfer admin role to $newAdminUsername?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Transfer', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Note: You'll need to add an API endpoint for transferring admin
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin transfer feature coming soon')),
      );
    }
  }

  void _showChangeGroupPictureDialog() {
    // You can reuse the GroupPfpDialog we created earlier
    showDialog(
      context: context,
      builder: (context) => GroupPfpDialog(group: widget.group),
    ).then((updatedGroup) {
      if (updatedGroup != null) {
        _refreshGroupDetails();
      }
    });
  }
}
