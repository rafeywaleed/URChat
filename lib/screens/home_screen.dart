import 'package:nes_ui/nes_ui.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // --- Colors & constants ---
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

  // Theme colors
  Color _accent = const Color.fromARGB(255, 0, 0, 0);
  final Color _secondaryAccent = const Color.fromARGB(255, 0, 0, 0);
  final Color _bgLight = const Color(0xFFFDFBF8);
  final Color _surface = Colors.white;
  final Color _mutedText = Colors.black87;
  Color _highlight = const Color.fromARGB(255, 0, 0, 0);

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    _initializeWebSocket();

    // Keep the periodic debug from original file
    Timer.periodic(const Duration(seconds: 10), (timer) {
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
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Load chats and invitations sequentially to avoid type errors
      await _loadChats();
      await _loadGroupInvitations();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _debugSubscriptions();
    } catch (e) {
      print('❌ Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: $e';
        });
      }
    }
  }

  Future<void> _loadChats() async {
    try {
      final cachedChats = await LocalCacheService.getCachedChats();

      if (cachedChats != null && cachedChats.isNotEmpty) {
        print('📦 Loading chats from cache');
        if (mounted) {
          setState(() {
            _chats = cachedChats;
            _errorMessage = '';
          });
        }
      }
      await _loadFreshChats();
    } catch (e) {
      print('❌ Error loading initial chats: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load chats: $e';
        });
      }
    }
  }

  Future<void> _loadFreshChats() async {
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
      // Don't show error if we have cached chats
    }
  }

  Future<void> _loadGroupInvitations() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingInvitations = true;
        });
      }

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
    await _loadFreshChats();
  }

  void _handleNewMessage(Message message) {
    print('💬 New message received: ${message.content}');

    final bool shouldShowNotification = _selectedChatId != message.chatId;

    if (shouldShowNotification) {
      _showMessageNotification(message);
    }

    _refreshChatListForMessage(message);
  }

  void _refreshChatListForMessage(Message message) {
    final chatIndex =
        _chats.indexWhere((chat) => chat.chatId == message.chatId);
    if (chatIndex != -1 && mounted) {
      setState(() {
        _chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      });
    }
  }

  void _handleChatListUpdate(List<ChatRoom> updatedChats) {
    print(
        '🔄 Real-time chat list update received: ${updatedChats.length} chats');

    if (mounted) {
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
  }

  void _selectChat(ChatRoom chat) {
    if (_selectedChatId == chat.chatId && _showChatScreen) {
      _deselectChat();
      return;
    }

    print('👆 Selecting chat: ${chat.chatName} (ID: ${chat.chatId})');

    if (_selectedChatId != null) {
      _webSocketService.unsubscribeFromChatRoom(_selectedChatId!);
    }

    _webSocketService.subscribeToChatRoom(chat.chatId);

    if (mounted) {
      setState(() {
        _selectedChatId = chat.chatId;
        _showChatScreen = true;
      });
    }

    _debugSubscriptions();
  }

  void _debugSubscriptions() {
    print(
        '🔍 CURRENT SUBSCRIPTIONS: ${_webSocketService.getSubscribedChats()}');
  }

  void _deselectChat() {
    print('👈 Deselecting chat');
    if (mounted) {
      setState(() {
        _selectedChatId = null;
        _showChatScreen = false;
      });
    }
  }

  // Group invitation methods
  Future<void> _acceptGroupInvitation(ChatRoom invitation) async {
    try {
      await ApiService.acceptGroupInvitation(invitation.chatId);

      if (mounted) {
        setState(() {
          _groupInvitations
              .removeWhere((inv) => inv.chatId == invitation.chatId);
        });
      }

      await _loadFreshChats();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => NesDialog(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Joined ${invitation.chatName}'),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting group invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineGroupInvitation(ChatRoom invitation) async {
    try {
      await ApiService.declineGroupInvitation(invitation.chatId);

      if (mounted) {
        setState(() {
          _groupInvitations
              .removeWhere((inv) => inv.chatId == invitation.chatId);
        });
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => NesWindow(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Declined invitation to ${invitation.chatName}'),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error declining group invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: NesContainer(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: const Color.fromARGB(255, 77, 105, 118),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: GoogleFonts.pressStart2p(
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          unselectedLabelStyle: GoogleFonts.pressStart2p(
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
          tabs: const [
            Tab(text: "Chats"),
            Tab(text: "Invitations"),
          ],
        ),
      ),
    );
  }

  void _showMessageNotification(Message message) {
    if (_selectedChatId == message.chatId && _showChatScreen) {
      print('🔕 Skipping notification - currently viewing this chat');
      return;
    }

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

    if (mounted) {
      setState(() {
        _messageNotifications.add(notification);
      });
    }

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _messageNotifications
              .removeWhere((n) => n['id'] == notification['id']);
        });
      }
    });
  }

  Widget _buildMessageNotifications() {
    if (_messageNotifications.isEmpty) return const SizedBox();

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
        if (mounted) {
          setState(() {
            _messageNotifications.remove(notification);
          });
        }
      },
      child: NesContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            NesContainer(
              width: 36,
              height: 36,
              backgroundColor: _accent,
              child: const Center(
                child: Icon(Icons.chat, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['chatName'],
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: GoogleFonts.vt323(
                      color: _mutedText,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            NesButton(
              type: NesButtonType.normal,
              child: const Icon(Icons.close, size: 16),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _messageNotifications.remove(notification);
                  });
                }
              },
            ),
          ],
        ),
      )
          .animate()
          .slideX(begin: -1, end: 0, curve: Curves.easeOut, duration: 300.ms),
    );
  }

  Widget _buildChatListItem(ChatRoom chat) {
    final isSelected = _selectedChatId == chat.chatId;
    final isHovered = _hoveredChatId == chat.chatId;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _hoveredChatId = chat.chatId);
      },
      onExit: (_) {
        if (mounted) setState(() => _hoveredChatId = null);
      },
      child: GestureDetector(
        onTap: () => _selectChat(chat),
        child: NesContainer(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          backgroundColor: isSelected
              ? Colors.grey.shade800
              : (isHovered ? Colors.grey.shade300 : _surface),
          child: Row(
            children: [
              NesContainer(
                width: 44,
                height: 44,
                backgroundColor: _parseColor(chat.pfpBg),
                child: Center(
                  child: Text(
                    chat.pfpIndex,
                    style: TextStyle(fontSize: 24, fontFamily: null),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.chatName,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 12,
                        color: isSelected ? Colors.white : _accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessage.isNotEmpty
                          ? chat.lastMessage
                          : 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.vt323(
                        fontSize: 12,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatTime(chat.lastActivity),
                  style: GoogleFonts.vt323(fontSize: 12, color: _mutedText))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationListItem(ChatRoom invitation) {
    return NesContainer(
      padding: const EdgeInsets.all(8),
      backgroundColor: Colors.white,
      child: Row(
        children: [
          NesContainer(
            width: 44,
            height: 44,
            backgroundColor: _parseColor(invitation.pfpBg),
            child: Center(
              child: Text(invitation.pfpIndex,
                  style: GoogleFonts.pressStart2p(
                      fontSize: 14, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invitation.chatName,
                    style:
                        GoogleFonts.pressStart2p(fontSize: 12, color: _brown)),
                const SizedBox(height: 4),
                Text('Group Invitation',
                    style: GoogleFonts.vt323(
                        fontSize: 12, color: Colors.orange[700])),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NesButton(
                  type: NesButtonType.success,
                  child: const Text('Accept'),
                  onPressed: () => _acceptGroupInvitation(invitation)),
              const SizedBox(width: 6),
              NesButton(
                  type: NesButtonType.error,
                  child: const Text('Decline'),
                  onPressed: () => _declineGroupInvitation(invitation)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isLargeScreen ? 360 : double.infinity,
      curve: Curves.easeOutCubic,
      child: NesContainer(
        backgroundColor: _bgLight,
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
                      style: GoogleFonts.vt323(
                        color: _webSocketService.isConnected
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  NesButton(
                    type: NesButtonType.normal,
                    child: const Icon(Icons.search),
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

            // Tab bar
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NesHourglassLoadingIndicator(),
            SizedBox(height: 16),
            Text('Loading invitations...'),
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
            style: GoogleFonts.pressStart2p(
              fontSize: 12,
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
              style: GoogleFonts.vt323(
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
      child: NesContainer(
        backgroundColor: _bgLight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 100, color: _accent.withOpacity(0.2)),
              const SizedBox(height: 24),
              Text("Welcome to URChat",
                  style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _accent)),
              const SizedBox(height: 8),
              Text(
                "Select a chat or start a new one",
                style: GoogleFonts.vt323(color: _mutedText, fontSize: 14),
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
        onBack: _isMobileScreen ? _deselectChat : null,
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

  ThemeData _getSafeTheme() {
    // Create a custom theme that doesn't use NesUI to avoid animation issues
    return ThemeData(
      useMaterial3: false, // Disable Material3 to avoid conflicts
      primaryColor: const Color(0xFF4E342E),
      primaryColorDark: const Color(0xFF3E2723),
      primaryColorLight: const Color(0xFF6D4C41),
      scaffoldBackgroundColor: const Color(0xFFFDFBF8),
      // backgroundColor: const Color(0xFFF5F5DC),
      cardColor: Colors.white,
      textTheme: TextTheme(
        titleLarge: GoogleFonts.pressStart2p(
          fontSize: 16,
          color: const Color(0xFF4E342E),
        ),
        bodyMedium: GoogleFonts.vt323(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF4E342E),
        titleTextStyle: GoogleFonts.pressStart2p(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4E342E),
        secondary: Color(0xFF6D4C41),
        background: Color(0xFFFDFBF8),
        surface: Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beige,
      appBar: _showChatScreen && _isMobileScreen
          ? null
          : AppBar(
              title:
                  Text('URChat', style: GoogleFonts.pressStart2p(fontSize: 14)),
              actions: [
                NesButton(
                  type: NesButtonType.normal,
                  child: const Icon(Icons.search_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    ).then((_) {
                      _loadChatsFromApi();
                    });
                  },
                ),
                const SizedBox(width: 8),
                NesButton(
                  type: NesButtonType.primary,
                  child: const Icon(Icons.group_add_rounded),
                  onPressed: _showCreateGroupDialog,
                ),
                const SizedBox(width: 8),
                NesDropdownMenu(
                  entries: const [
                    NesDropdownMenuEntry(value: 'profile', label: 'Profile'),
                    NesDropdownMenuEntry(value: 'logout', label: 'Logout'),
                  ],
                  onChanged: (value) {
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
                const SizedBox(width: 8),
              ],
            ),
      body: _isLoading
          ? _buildLoadingState()
          : (_isMobileScreen ? _buildMobileLayout() : _buildDesktopLayout()),
      floatingActionButton: _isMobileScreen && !_showChatScreen
          ? NesButton(
              type: NesButtonType.primary,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_comment_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text("New Chat",
                      style: GoogleFonts.pressStart2p(fontSize: 10)),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
            )
          : null,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NesHourglassLoadingIndicator(),
          SizedBox(height: 16),
          Text('Loading chats...'),
        ],
      ),
    );
  }

  void _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const NesConfirmDialog(
        cancelLabel: 'Cancel',
        confirmLabel: 'Logout',
        message: 'Are you sure you want to logout?',
      ),
    );

    if (result == true && mounted) {
      _webSocketService.disconnect();
      await ApiService.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
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

    Future.delayed(const Duration(seconds: 3), () {
      if (_webSocketService.isConnected) {
        print('🎉 WebSocket is connected and ready!');
      } else {
        print('❌ WebSocket failed to connect');
      }
    });
  }
}
