import 'package:flutter/material.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/screens/auth_screen.dart';
import 'package:urchat_back_testing/screens/chatting.dart';
import 'package:urchat_back_testing/screens/group_pfp_dialog.dart';
import 'package:urchat_back_testing/screens/new_group.dart';
import 'package:urchat_back_testing/screens/profile_screen.dart';
import 'package:urchat_back_testing/screens/search_delegate.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/local_cache_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';

class Homescreen extends StatefulWidget {
  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen>
    with SingleTickerProviderStateMixin {
  final Color _beige = const Color(0xFFF5F5DC);
  final Color _brown = const Color(0xFF5C4033);

  List<ChatRoom> _chats = [];
  List<ChatRoom> _groupInvitations = [];
  bool _isLoading = true;
  bool _isLoadingInvitations = false;
  String _errorMessage = '';
  late WebSocketService _webSocketService;
  String? _selectedChatId;

  // Tab controller for chats vs invitations
  late TabController _tabController;

  // Track if we're showing chat details on mobile
  bool _showChatScreen = false;

  ChatRoom? get _selectedChat {
    if (_selectedChatId == null) return null;
    try {
      return _chats.firstWhere((chat) => chat.chatId == _selectedChatId);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeWebSocket();
    _loadInitialData();
  }

  void _initializeWebSocket() {
    print('🔌 Initializing WebSocket...');

    _webSocketService = WebSocketService(
      onMessageReceived: _handleNewMessage,
      onChatListUpdated: _handleChatListUpdate,
      onTyping: (data) {
        print('⌨️ Typing: $data');
      },
      onReadReceipt: (data) {
        print('👀 Read receipt: $data');
      },
    );

    _webSocketService.connect();
    _testWebSocketConnection();
  }

  void _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load chats and invitations in parallel
      await Future.wait([
        _loadChats(),
        _loadGroupInvitations(),
      ] as Iterable<Future>);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading initial data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  void _loadChats() async {
    try {
      // Try cache first
      final cachedChats = await LocalCacheService.getCachedChats();

      if (cachedChats != null && cachedChats.isNotEmpty) {
        print('📦 Loading chats from cache');
        setState(() {
          _chats = cachedChats;
          _errorMessage = '';
        });

        // Load fresh data in background
        _loadFreshChats();
      } else {
        _loadFreshChats();
      }
    } catch (e) {
      print('❌ Error loading initial chats: $e');
      setState(() {
        _errorMessage = 'Failed to load chats: $e';
      });
    }
  }

  void _loadFreshChats() async {
    print('🔄 Fetching fresh chats from API...');
    try {
      final chats = await ApiService.getUserChats();
      chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

      for (var chat in chats) {
        print(
            '   Chat: ${chat.chatName}, Chat ID: ${chat.chatId}, pfp: ${chat.pfpIndex}, bg: ${chat.pfpBg}');
      }

      // Cache the chats
      await LocalCacheService.cacheChats(chats);

      if (mounted) {
        setState(() {
          _chats = chats;
          _errorMessage = '';
        });
      }
    } catch (e) {
      print('❌ Error loading fresh chats: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load chats: $e';
        });
      }
    }
  }

  void _loadGroupInvitations() async {
    try {
      setState(() {
        _isLoadingInvitations = true;
      });

      final invitations = await ApiService.getGroupInvitations();

      if (mounted) {
        setState(() {
          _groupInvitations = invitations;
          _isLoadingInvitations = false;
        });
      }
    } catch (e) {
      print('❌ Error loading group invitations: $e');
      if (mounted) {
        setState(() {
          _isLoadingInvitations = false;
        });
      }
    }
  }

  void _loadChatsFromApi() async {
    print('🔄 Reloading chats from API...');
    _loadFreshChats();
  }

  void _handleNewMessage(Message message) {
    print('💬 New message received: ${message.content}');
    // Don't manually update chat order - wait for WebSocket update from backend
  }

  void _handleChatListUpdate(List<ChatRoom> updatedChats) {
    print(
        '🔄 Real-time chat list update received: ${updatedChats.length} chats');

    setState(() {
      _chats = updatedChats;
      _errorMessage = '';

      // Update selected chat reference if it exists
      if (_selectedChatId != null) {
        try {
          final updatedSelectedChat = _chats.firstWhere(
            (chat) => chat.chatId == _selectedChatId,
          );
          // The Key in ChatScreen will handle the widget recreation
        } catch (e) {
          print('⚠️ Selected chat no longer exists: $_selectedChatId');
          _selectedChatId = null;
          _showChatScreen = false;
        }
      }
    });
  }

  void _selectChat(ChatRoom chat) {
    print('👆 Selecting chat: ${chat.chatName} (ID: ${chat.chatId})');
    setState(() {
      _selectedChatId = chat.chatId;
      _showChatScreen = true;
    });

    _webSocketService.subscribeToChatRoom(chat.chatId);
  }

  void _refreshSelectedChat() {
    if (_selectedChatId != null) {
      setState(() {
        // This will force ChatThemeWrapper to rebuild with updated theme
      });
    }
    _loadChatsFromApi();
  }

  void _deselectChat() {
    print('👈 Deselecting chat');
    if (_selectedChatId != null) {
      _webSocketService.unsubscribeFromChatRoom(_selectedChatId!);
    }
    setState(() {
      _selectedChatId = null;
      _showChatScreen = false;
    });
  }

  void _handleBackButton() {
    if (_showChatScreen) {
      _deselectChat();
    }
  }

  // Group invitation methods
  Future<void> _acceptGroupInvitation(ChatRoom invitation) async {
    try {
      await ApiService.acceptGroupInvitation(invitation.chatId);

      // Remove from invitations and add to chats
      setState(() {
        _groupInvitations.removeWhere((inv) => inv.chatId == invitation.chatId);
      });

      // Reload chats to include the newly accepted group
      _loadFreshChats();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${invitation.chatName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error accepting group invitation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineGroupInvitation(ChatRoom invitation) async {
    try {
      await ApiService.declineGroupInvitation(invitation.chatId);

      // Remove from invitations
      setState(() {
        _groupInvitations.removeWhere((inv) => inv.chatId == invitation.chatId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Declined invitation to ${invitation.chatName}'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ Error declining group invitation: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline invitation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final isSelected = _selectedChatId == chat.chatId;

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
            chat.lastMessage.isNotEmpty ? chat.lastMessage : 'No messages yet',
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
              onPressed: () => _acceptGroupInvitation(invitation),
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _declineGroupInvitation(invitation),
              tooltip: 'Decline',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    print("🔍 Building chats list UI...");
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
                  _webSocketService.isConnected
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 12,
                  color: _webSocketService.isConnected
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _webSocketService.isConnected
                        ? 'Connected'
                        : 'Connecting...',
                    style: TextStyle(
                      color: _webSocketService.isConnected
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: _brown),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    ).then((_) {
                      _loadChatsFromApi();
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
                      if (_groupInvitations.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _groupInvitations.length.toString(),
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
                    _loadChatsFromApi();
                  },
                  child: _chats.isEmpty
                      ? Center(
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
                        )
                      : ListView.builder(
                          itemCount: _chats.length,
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            return _buildChatListItem(chat);
                          },
                        ),
                ),

                // Invitations Tab
                _isLoadingInvitations
                    ? Center(
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
                      )
                    : _groupInvitations.isEmpty
                        ? Center(
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
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
                          )
                        : RefreshIndicator(
                            backgroundColor: _beige,
                            color: _brown,
                            onRefresh: () async {
                              _loadGroupInvitations();
                            },
                            child: ListView.builder(
                              itemCount: _groupInvitations.length,
                              itemBuilder: (context, index) {
                                final invitation = _groupInvitations[index];
                                return _buildInvitationListItem(invitation);
                              },
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
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

  void _showCreateGroupDialog() async {
    final newGroup = await showDialog<GroupChatRoomDTO>(
      context: context,
      builder: (context) => CreateGroupDialog(
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
          _loadChatsFromApi();
        },
      ),
    );

    if (newGroup != null) {
      // Optionally select the new group
      // _selectChat(newGroup);
    }
  }

  // void _showGroupPfpDialog(ChatRoom group) async {
  //   final updatedGroup = await showDialog<ChatRoom>(
  //     context: context,
  //     builder: (context) => GroupPfpDialog(group: group),
  //   );

  //   if (updatedGroup != null) {
  //     // Update the group in the chats list
  //     setState(() {
  //       final index =
  //           _chats.indexWhere((chat) => chat.chatId == updatedGroup.chatId);
  //       if (index != -1) {
  //         _chats[index] = updatedGroup;
  //       }
  //     });
  //   }
  // }

  Widget _buildSelectedChatView() {
    if (_selectedChat == null) return _buildEmptyChatView();

    return Expanded(
      child: URChatApp(
          key: ValueKey(_selectedChat!.chatId),
          chatRoom: _selectedChat!,
          webSocketService: _webSocketService),
    );
  }

  Widget _buildMobileLayout() {
    if (_showChatScreen && _selectedChat != null) {
      // Show chat screen on mobile
      return _buildSelectedChatView();
    } else {
      // Show chat list on mobile
      return _buildChatsList();
    }
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildChatsList(),
        _selectedChatId != null
            ? _buildSelectedChatView()
            : _buildEmptyChatView(),
      ],
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
        leading: _isMobileScreen && _showChatScreen
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _handleBackButton,
              )
            : null,
        actions: [
          if (!_isMobileScreen || !_showChatScreen) ...[
            IconButton(
              icon: const Icon(Icons.wifi_find),
              onPressed: () {
                print('🔍 === MANUAL WEB SOCKET TEST ===');
                print('   Current chats: ${_chats.length}');
                print(
                    '   WebSocket connected: ${_webSocketService.isConnected}');
                print('   Selected chat: $_selectedChatId');

                _loadChatsFromApi();

                print('   Testing message reception...');
              },
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
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
      body: _isLoading
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
          : _errorMessage.isNotEmpty
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
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChatsFromApi,
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
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _brown)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _webSocketService.disconnect();
              await ApiService.logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => AuthScreen()));
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _webSocketService.disconnect();
    super.dispose();
  }

  void _testWebSocketConnection() {
    print('🔍 === WEB SOCKET CONNECTION TEST ===');
    print('   ✅ WebSocketService created: ${_webSocketService != null}');
    print('   ✅ Connected: ${_webSocketService.isConnected}');
    print(
        '   ✅ onChatListUpdated callback: ${_webSocketService.onChatListUpdated != null}');

    // Test after connection is established
    Future.delayed(const Duration(seconds: 3), () {
      if (_webSocketService.isConnected) {
        print('🎉 WebSocket is connected and ready!');
        print('   📡 Should receive updates on: /user/queue/chats/update');
      } else {
        print('❌ WebSocket failed to connect');
      }
    });
  }
}
