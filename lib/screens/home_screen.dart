import 'dart:async';
import 'dart:ui';

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
import 'package:flutter_animate/flutter_animate.dart';

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
  String? _hoveredChatId;

  // Theme colors based on the mono-classy palette
  final Color _accent = const Color(0xFF4E342E);
  final Color _secondaryAccent = const Color(0xFF6D4C41);
  final Color _bgLight = const Color(0xFFFDFBF8);
  final Color _surface = Colors.white;
  final Color _mutedText = Colors.black87;
  final Color _highlight = Color(0xFF4E342E);

  // For message notifications
  final List<Map<String, dynamic>> _messageNotifications = [];
  OverlayEntry? _notificationOverlay;

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

  final _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4E342E),
      secondary: Color(0xFF6D4C41),
      background: Color(0xFFFDFBF8),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: const Color(0xFFFDFBF8),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
      bodyMedium: TextStyle(fontSize: 15, color: Colors.black87),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white.withOpacity(0.7),
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeWebSocket();
    _loadInitialData();

    Timer.periodic(Duration(seconds: 10), (timer) {
      _debugSubscriptions();
    });
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

      await Future.wait([
        _loadChats(),
        _loadGroupInvitations(),
      ] as Iterable<Future>);

      setState(() {
        _isLoading = false;
      });

      // Debug: show current subscriptions
      _debugSubscriptions();
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
      final cachedChats = await LocalCacheService.getCachedChats();

      if (cachedChats != null && cachedChats.isNotEmpty) {
        print('📦 Loading chats from cache');
        setState(() {
          _chats = cachedChats;
          _errorMessage = '';
        });
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

    // FIX: Simplify the notification logic
    final bool shouldShowNotification = _selectedChatId != message.chatId;

    if (shouldShowNotification) {
      _showMessageNotification(message);
    }

    // Also update the chat list to show new message preview
    _refreshChatListForMessage(message);
  }

// Add this method to refresh chat list when new message arrives
  void _refreshChatListForMessage(Message message) {
    // Find and update the chat that received the message
    final chatIndex =
        _chats.indexWhere((chat) => chat.chatId == message.chatId);
    if (chatIndex != -1) {
      setState(() {
        // _chats[chatIndex] = _chats[chatIndex].copyWith(
        //   lastMessage: message.content,
        //   lastActivity: message.timestamp,
        // );
        // Sort by last activity
        _chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      });
    }
  }

  bool _isChatScreenFocused() {
    // Check if the chat screen is currently focused/visible
    // This is a simplified check - you might want to enhance this
    return _showChatScreen && _selectedChatId != null;
  }

  void _handleChatListUpdate(List<ChatRoom> updatedChats) {
    print(
        '🔄 Real-time chat list update received: ${updatedChats.length} chats');

    setState(() {
      _chats = updatedChats;
      _errorMessage = '';

      if (_selectedChatId != null) {
        try {
          _chats.firstWhere((chat) => chat.chatId == _selectedChatId);
        } catch (e) {
          print('⚠️ Selected chat no longer exists: $_selectedChatId');
          _selectedChatId = null;
          _showChatScreen = false;
        }
      }
    });
  }

  void _selectChat(ChatRoom chat) {
    if (_selectedChatId == chat.chatId && _showChatScreen) {
      _deselectChat();
      return;
    }

    print('👆 Selecting chat: ${chat.chatName} (ID: ${chat.chatId})');

    // Force unsubscribe first, then subscribe to ensure clean state
    if (_selectedChatId != null) {
      _webSocketService.unsubscribeFromChatRoom(_selectedChatId!);
    }

    // Subscribe to the new chat
    _webSocketService.subscribeToChatRoom(chat.chatId);

    setState(() {
      _selectedChatId = chat.chatId;
      _showChatScreen = true;
    });

    // Debug current subscriptions
    _debugSubscriptions();
  }

  void _debugSubscriptions() {
    print(
        '🔍 CURRENT SUBSCRIPTIONS: ${_webSocketService.getSubscribedChats()}');
  }

  void _refreshSelectedChat() {
    if (_selectedChatId != null) {
      setState(() {});
    }
    _loadChatsFromApi();
  }

  void _deselectChat() {
    print('👈 Deselecting chat');
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

      setState(() {
        _groupInvitations.removeWhere((inv) => inv.chatId == invitation.chatId);
      });

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
    return mediaQuery.size.width < 768;
  }

  // Check if we're on tablet or desktop
  bool get _isLargeScreen {
    return !_isMobileScreen;
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _accent,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _mutedText,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.chat_rounded, size: 20),
            text: "Chats",
          ),
          Tab(
            icon: Icon(Icons.group_rounded, size: 20),
            text: "Invitations",
          ),
        ],
      ),
    );
  }

  void _showMessageNotification(Message message) {
    // Don't show notification if we're currently viewing this chat
    if (_selectedChatId == message.chatId && _showChatScreen) {
      print('🔕 Skipping notification - currently viewing this chat');
      return;
    }

    // Find the chat room for this message
    final chatRoom = _chats.firstWhere(
      (chat) => chat.chatId == message.chatId,
      orElse: () => ChatRoom(
        chatId: message.chatId,
        chatName: 'Unknown Chat',
        isGroup: false,
        lastMessage: '',
        lastActivity: DateTime.now(),
        pfpIndex: '💬',
        pfpBg: '#4CAF50',
        themeIndex: 0,
        isDark: true,
      ),
    );

    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'chatName': chatRoom.chatName,
      'message': message.content,
      'sender': message.sender,
      'chatId': message.chatId,
      'timestamp': DateTime.now(),
    };

    print(
        '🔔 Showing notification: ${notification['chatName']} - ${notification['message']}');

    setState(() {
      _messageNotifications.add(notification);
    });

    // Auto-remove after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _messageNotifications
              .removeWhere((n) => n['id'] == notification['id']);
        });
      }
    });
  }

  Widget _buildMessageNotifications() {
    if (_messageNotifications.isEmpty) return SizedBox();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Column(
        children: _messageNotifications.map((notification) {
          return _buildGlassNotification(notification);
        }).toList(),
      ),
    );
  }

  Widget _buildGlassNotification(Map<String, dynamic> notification) {
    return GestureDetector(
      onTap: () {
        // Find and select the chat when notification is tapped
        final chat = _chats.firstWhere(
          (chat) => chat.chatId == notification['chatId'],
          orElse: () => ChatRoom(
            chatId: notification['chatId'],
            chatName: notification['chatName'],
            isGroup: false,
            lastMessage: '',
            lastActivity: DateTime.now(),
            pfpIndex: '💬',
            pfpBg: '#4CAF50',
            themeIndex: 0,
            isDark: true,
          ),
        );

        _selectChat(chat);
        setState(() {
          _messageNotifications.remove(notification);
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 4,
        color: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _accent,
                    child:
                        const Icon(Icons.chat, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['chatName'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _accent,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['message'],
                          style: TextStyle(
                            color: _mutedText,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _messageNotifications.remove(notification);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().slideX(
            begin: -1,
            end: 0,
            curve: Curves.easeOut,
            duration: 300.ms,
          ),
    );
  }

  Widget _buildChatListItem(ChatRoom chat) {
    final isSelected = _selectedChatId == chat.chatId;
    final isHovered = _hoveredChatId == chat.chatId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredChatId = chat.chatId),
      onExit: (_) => setState(() => _hoveredChatId = null),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectChat(chat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? _highlight.withOpacity(0.4)
                : isHovered
                    ? Colors.white.withOpacity(0.8)
                    : _surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (isHovered || isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: _parseColor(chat.pfpBg),
              child: Text(
                chat.pfpIndex,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              chat.chatName,
              style: TextStyle(
                color: _accent,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              chat.lastMessage.isNotEmpty
                  ? chat.lastMessage
                  : 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedText,
                fontSize: 13,
              ),
            ),
            trailing: Text(
              _formatTime(chat.lastActivity),
              style: TextStyle(
                fontSize: 12,
                color: _mutedText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _connectionStatusBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _webSocketService.isConnected
            ? Colors.green[50]
            : Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            _webSocketService.isConnected ? Icons.check_circle : Icons.sync,
            size: 18,
            color: _webSocketService.isConnected ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            _webSocketService.isConnected ? 'Connected' : 'Reconnecting...',
            style: TextStyle(
              color: _webSocketService.isConnected
                  ? Colors.green[700]
                  : Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isLargeScreen ? 360 : double.infinity,
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: _bgLight,
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

            // Improved Tab bar
            _buildTabBar(),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Chats Tab
                  _buildChatsTab(),
                  // Invitations Tab
                  _buildInvitationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsTab() {
    return RefreshIndicator(
      backgroundColor: _beige,
      color: _brown,
      onRefresh: () async {
        _loadChatsFromApi();
      },
      child: _chats.isEmpty
          ? _buildEmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No chats yet',
              subtitle: 'Start a conversation by searching for users',
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return _buildChatListItem(chat);
              },
            ),
    );
  }

  Widget _buildInvitationsTab() {
    if (_isLoadingInvitations) {
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
    }

    return _groupInvitations.isEmpty
        ? _buildEmptyState(
            icon: Icons.group_add_outlined,
            title: 'No invitations',
            subtitle: 'You have no pending group invitations',
          )
        : RefreshIndicator(
            backgroundColor: _beige,
            color: _brown,
            onRefresh: () async {
              _loadGroupInvitations();
            },
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              itemCount: _groupInvitations.length,
              itemBuilder: (context, index) {
                final invitation = _groupInvitations[index];
                return _buildInvitationListItem(invitation);
              },
            ),
          );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: _brown.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: _brown.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _brown.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatView() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgLight, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 100, color: _accent.withOpacity(0.2)),
              const SizedBox(height: 24),
              Text("Welcome to URChat",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _accent)),
              const SizedBox(height: 8),
              Text(
                "Select a chat or start a new one",
                style: TextStyle(color: _mutedText, fontSize: 14),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .moveY(begin: 10, curve: Curves.easeOutQuart),
        ),
      ),
    );
  }

  Widget _buildSelectedChatView() {
    if (_selectedChat == null) return _buildEmptyChatView();

    return Expanded(
      child: URChatApp(
        key: ValueKey(_selectedChat!.chatId),
        chatRoom: _selectedChat!,
        webSocketService: _webSocketService,
        onBack:
            _isMobileScreen ? _deselectChat : null, // Only show back on mobile
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Main content
        _showChatScreen && _selectedChat != null
            ? _buildSelectedChatView()
            : _buildChatsList(),

        // Message notifications
        _buildMessageNotifications(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChatsList(),
            _selectedChatId != null
                ? _buildSelectedChatView()
                : _buildEmptyChatView(),
          ],
        ),

        // Message notifications
        _buildMessageNotifications(),
      ],
    );
  }

  // Check if we're on mobile screen
  // bool get _isMobileScreen {
  //   final mediaQuery = MediaQuery.of(context);
  //   return mediaQuery.size.width < 768;
  // }

  // bool get _isLargeScreen => !_isMobileScreen;

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
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4E342E),
          secondary: Color(0xFF6D4C41),
          background: Color(0xFFFDFBF8),
          surface: Color(0xFFFFFFFF),
          onPrimary: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFBF8),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: Scaffold(
        backgroundColor: _beige,
        appBar: _showChatScreen && _isMobileScreen
            ? null // Hide main app bar when in chat view on mobile
            : AppBar(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                title: const Text(
                  'URChat',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchScreen()),
                      ).then((_) {
                        _loadChatsFromApi();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.group_add_rounded),
                    onPressed: _showCreateGroupDialog,
                  ),
                  PopupMenuButton(
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'profile', child: Text('Profile')),
                      const PopupMenuItem(
                          value: 'logout', child: Text('Logout')),
                    ],
                    onSelected: (value) {
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                      } else if (value == 'logout') {
                        _logout();
                      }
                    },
                  ),
                ],
              ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeInQuart,
          child: _isLoading
              ? _buildLoadingState().animate().fade(duration: 350.ms)
              : _isMobileScreen
                  ? _buildMobileLayout().animate().fadeIn(duration: 400.ms)
                  : _buildDesktopLayout()
                      .animate()
                      .slideY(begin: 0.05, duration: 500.ms),
        ),
        floatingActionButton: _isMobileScreen && !_showChatScreen
            ? FloatingActionButton.extended(
                backgroundColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.add_comment_outlined,
                    color: Colors.black87),
                label: const Text("New Chat",
                    style: TextStyle(color: Colors.black87)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  );
                },
              )
            : null,
      ),
    );
  }

  void _showCreateGroupDialog() async {
    final newGroup = await showDialog<GroupChatRoomDTO>(
      context: context,
      builder: (context) => CreateGroupDialog(
        onGroupCreated: (GroupChatRoomDTO group) {
          _loadChatsFromApi();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
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

    Future.delayed(const Duration(seconds: 3), () {
      if (_webSocketService.isConnected) {
        print('🎉 WebSocket is connected and ready!');
      } else {
        print('❌ WebSocket failed to connect');
      }
    });
  }
}
