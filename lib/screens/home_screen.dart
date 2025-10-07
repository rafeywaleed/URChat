// screens/homescreen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urchat_back_testing/controllers/chat_controller.dart';
import 'package:urchat_back_testing/controllers/auth_controller.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/screens/auth_screen.dart';
import 'package:urchat_back_testing/screens/chatting.dart';
import 'package:urchat_back_testing/screens/group_pfp_dialog.dart';
import 'package:urchat_back_testing/screens/new_group.dart';
import 'package:urchat_back_testing/screens/profile_screen.dart';
import 'package:urchat_back_testing/screens/search_delegate.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';

class Homescreen extends StatefulWidget {
  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen>
    with SingleTickerProviderStateMixin {
  final ChatController chatController = Get.find<ChatController>();
  final AuthController authController = Get.find<AuthController>();

  final Color _beige = const Color(0xFFF5F5DC);
  final Color _brown = const Color(0xFF5C4033);
  final ApiService apiService = Get.find<ApiService>();

  // Tab controller for chats vs invitations
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Check if we're on mobile screen
  bool get _isMobileScreen {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width < 768; // Typical tablet breakpoint
  }

  // Check if we're on tablet or desktop
  bool get _isLargeScreen {
    return !_isMobileScreen;
  }

  Widget _buildChatListItem(ChatRoom chat) {
    return Obx(() {
      final isSelected =
          chatController.selectedChat.value?.chatId == chat.chatId;

      return Hero(
        tag: chat.chatId,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? _brown.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: _brown.withOpacity(0.3), width: 1)
                : null,
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _parseColor(chat.pfpBg),
              child: Text(
                chat.pfpIndex,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              chat.chatName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _brown,
              ),
            ),
            subtitle: Text(
              chat.lastMessage.isNotEmpty
                  ? chat.lastMessage
                  : 'No messages yet',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? _brown.withOpacity(0.8) : Colors.grey[700],
              ),
            ),
            trailing: Text(
              _formatTime(chat.lastActivity),
              style: TextStyle(
                color: isSelected ? _brown : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: () => _selectChat(chat),
          ),
        ),
      );
    });
  }

  Widget _buildInvitationListItem(ChatRoom invitation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(invitation.pfpBg),
          child: Text(
            invitation.pfpIndex,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          invitation.chatName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _brown,
          ),
        ),
        subtitle: Text(
          'Group Invitation',
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => chatController.acceptGroupInvitation(invitation),
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () =>
                  chatController.declineGroupInvitation(invitation),
              tooltip: 'Decline',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    return Obx(() {
      return Container(
        width: _isLargeScreen ? 350 : double.infinity,
        decoration: BoxDecoration(
          color: _beige,
          border: _isLargeScreen
              ? Border(
                  right: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Column(
          children: [
            // Connection status bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    chatController.isConnected.value
                        ? Icons.circle
                        : Icons.circle_outlined,
                    size: 12,
                    color: chatController.isConnected.value
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatController.isConnected.value
                          ? 'Connected'
                          : 'Connecting...',
                      style: TextStyle(
                        color: chatController.isConnected.value
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: _brown),
                    onPressed: () {
                      Get.to(() => SearchScreen())?.then((_) {
                        chatController.loadFreshChats();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Tab bar for Chats vs Invitations
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: _brown,
                unselectedLabelColor: Colors.grey,
                indicatorColor: _brown,
                tabs: [
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat, size: 18),
                        SizedBox(width: 4),
                        Text('Chats'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_add, size: 18),
                        const SizedBox(width: 4),
                        const Text('Invitations'),
                        if (chatController.groupInvitations.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chatController.groupInvitations.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Chats Tab
                  RefreshIndicator(
                    backgroundColor: _beige,
                    color: _brown,
                    onRefresh: () async {
                      chatController.loadFreshChats();
                    },
                    child: Obx(() {
                      if (chatController.chats.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: _brown.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No chats yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _brown.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Start a conversation by searching for users',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _brown.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: chatController.chats.length,
                          itemBuilder: (context, index) {
                            final chat = chatController.chats[index];
                            return _buildChatListItem(chat);
                          },
                        );
                      }
                    }),
                  ),

                  // Invitations Tab
                  Obx(() {
                    if (chatController.isLoadingInvitations.value) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(_brown),
                            ),
                            const SizedBox(height: 16),
                            const Text('Loading invitations...'),
                          ],
                        ),
                      );
                    } else if (chatController.groupInvitations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_add_outlined,
                              size: 64,
                              color: _brown.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No invitations',
                              style: TextStyle(
                                fontSize: 16,
                                color: _brown.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'You have no pending group invitations',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _brown.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return RefreshIndicator(
                        backgroundColor: _beige,
                        color: _brown,
                        onRefresh: () async {
                          chatController.loadGroupInvitations();
                        },
                        child: ListView.builder(
                          itemCount: chatController.groupInvitations.length,
                          itemBuilder: (context, index) {
                            final invitation =
                                chatController.groupInvitations[index];
                            return _buildInvitationListItem(invitation);
                          },
                        ),
                      );
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyChatView() {
    return Expanded(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 120,
                color: _brown.withOpacity(0.2),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to URChat',
                style: TextStyle(
                  fontSize: 24,
                  color: _brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select a chat from the list to start messaging',
                style: TextStyle(
                  fontSize: 16,
                  color: _brown.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'or start a new conversation',
                style: TextStyle(
                  color: _brown.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectChat(ChatRoom chat) {
    print('👆 Selecting chat: ${chat.chatName} (ID: ${chat.chatId})');
    chatController.selectChat(chat);

    if (_isMobileScreen) {
      Get.to(() => URChatApp(
            chatRoom: chat,
          ));
    }
  }

  void _showCreateGroupDialog() async {
    final newGroup = await Get.dialog<GroupChatRoomDTO>(
      CreateGroupDialog(
        onGroupCreated: (GroupChatRoomDTO group) {
          ChatRoom chatRoom = ChatRoom(
            chatId: group.chatId,
            chatName: group.chatName,
            isGroup: true,
            lastMessage: '',
            lastActivity: DateTime.now(),
            pfpIndex: group.pfpIndex,
            pfpBg: group.pfpBg,
            themeIndex: 0,
            isDark: true,
          );
          // The group will be added to chats list via WebSocket update
          // or we can manually refresh
          chatController.loadFreshChats();
        },
      ),
    );

    if (newGroup != null) {
      // Optionally select the new group
      // _selectChat(newGroup);
    }
  }

  Widget _buildSelectedChatView() {
    return Obx(() {
      if (chatController.selectedChat.value == null)
        return _buildEmptyChatView();

      return Expanded(
        child: URChatApp(
          key: ValueKey(chatController.selectedChat.value!.chatId),
          chatRoom: chatController.selectedChat.value!,
        ),
      );
    });
  }

  Widget _buildMobileLayout() {
    return Obx(() {
      if (chatController.showChatScreen.value &&
          chatController.selectedChat.value != null) {
        // Show chat screen on mobile
        return _buildSelectedChatView();
      } else {
        // Show chat list on mobile
        return _buildChatsList();
      }
    });
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildChatsList(),
        Obx(() {
          return chatController.selectedChat.value != null
              ? _buildSelectedChatView()
              : _buildEmptyChatView();
        }),
      ],
    );
  }

  void _handleBackButton() {
    if (chatController.showChatScreen.value) {
      chatController.deselectChat();
    }
  }

  void _logout() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: _brown)),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              chatController.webSocketService.disconnect();
              await apiService.logout();
              Get.offAll(() => AuthScreen());
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      print('⚠️ Error parsing color: $colorString, using default');
      return const Color(0xFF4CAF50);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: _beige,
        appBar: AppBar(
          backgroundColor: _brown,
          foregroundColor: Colors.white,
          title: const Text(
            'URChat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: _isMobileScreen && chatController.showChatScreen.value
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBackButton,
                )
              : null,
          actions: [
            if (!_isMobileScreen || !chatController.showChatScreen.value) ...[
              IconButton(
                icon: const Icon(Icons.wifi_find),
                onPressed: chatController.testWebSocketConnection,
              ),
              IconButton(
                icon: const Icon(Icons.group_add),
                onPressed: _showCreateGroupDialog,
                tooltip: 'Create Group',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'profile') {
                    Get.to(() => ProfileScreen());
                  } else if (value == 'logout') {
                    _logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: _brown),
                        const SizedBox(width: 8),
                        const Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: chatController.isLoading.value
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_brown),
                    ),
                    const SizedBox(height: 16),
                    const Text('Loading chats...'),
                  ],
                ),
              )
            : chatController.errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading chats',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          chatController.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: chatController.loadFreshChats,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brown,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _isMobileScreen
                    ? _buildMobileLayout()
                    : _buildDesktopLayout(),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
