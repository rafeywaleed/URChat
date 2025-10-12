import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nes_ui/nes_ui.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/screens/auth_screen.dart';
import 'package:urchat_back_testing/screens/chatting.dart';
import 'package:urchat_back_testing/screens/group_management_screen.dart';
import 'package:urchat_back_testing/screens/group_pfp_dialog.dart';
import 'package:urchat_back_testing/screens/new_group.dart';
import 'package:urchat_back_testing/screens/profile_screen.dart';
import 'package:urchat_back_testing/screens/search_delegate.dart';
import 'package:urchat_back_testing/screens/user_profile.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/local_cache_service.dart';
import 'package:urchat_back_testing/service/notification_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:urchat_back_testing/widgets/deletion_dialog.dart';
import 'package:urchat_back_testing/widgets/pixle_circle.dart';

import '../model/chat_room.dart';

class Homescreen extends StatefulWidget {
  final String? initialChatId;
  final bool? openChatOnStart;

  const Homescreen({Key? key, this.initialChatId, this.openChatOnStart = false})
      : super(key: key);

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

  bool _isDarkMode = false;

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

  int _currentTextIndex = 0;
  late Timer _timer;
  bool _showRunningText = true;

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
    _loadInitialData().then((_) {
      if (widget.openChatOnStart == true && widget.initialChatId != null) {
        _openInitialChat();
      }
    });

    _initializeWebSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyNotificationSystem();
    });

    Timer.periodic(const Duration(seconds: 10), (timer) {
      _debugSubscriptions();
    });

    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    NotificationService().notificationStream.listen((data) {
      _handleNotification(data);
    });
  }

  void _handleNotification(Map<String, dynamic> data) {
    final type = data['type'];
    final chatId = data['chatId'];
    final sender = data['sender'];
    final message = data['message'];

    if (type == 'NEW_MESSAGE' && chatId != null) {
      // Refresh chat list to show updated last message
      _loadFreshChats();

      // Show in-app notification if not viewing that chat
      if (_selectedChatId != chatId || !_showChatScreen) {
        final notification = {
          'chatName': data['chatName'] ?? 'New Message',
          'message': '$sender: $message',
          'chatId': chatId,
        };

        if (mounted) {
          setState(() {
            _messageNotifications.add(notification);
          });
        }
      }
    }
  }

  void _verifyNotificationAdded() {
    print('=== NOTIFICATION STATE CHECK ===');
    print('📊 Total notifications: ${_messageNotifications.length}');
    print('📱 Widget mounted: $mounted');
    print('🔄 Last rebuild: ${DateTime.now()}');
    _messageNotifications.forEach((n) {
      print('  - ${n['chatName']}: ${n['message']}');
    });
    print('================================');
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
      onMessageDeleted: _handleMessageDeleted,
      onChatDeleted: _handleChatDeleted,
    );

    // Add connection listener
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (!_webSocketService.isConnected) {
        print('🔄 WebSocket not connected, reconnecting...');
        _webSocketService.connect();
      }
    });

    _webSocketService.connect();
    _testWebSocketConnection();
  }

  // NEW: Handle message deletion from WebSocket
  void _handleMessageDeleted(Map<String, dynamic> deletionData) {
    print('🗑️ Message deletion received: $deletionData');

    final deletedMessageId = deletionData['messageId'];
    final chatId = deletionData['chatId'];

    // If we're currently viewing the chat where message was deleted, update UI
    if (_selectedChatId == chatId) {
      // This will be handled by the ChatScreen via its own listener
      print('🗑️ Message $deletedMessageId deleted from current chat');
    }

    // Show notification for message deletion
    _showDeletionNotification(deletionData);
  }

  // NEW: Handle chat deletion from WebSocket
  void _handleChatDeleted(String chatId) {
    print('🗑️ Chat deletion received for: $chatId');

    if (mounted) {
      setState(() {
        _chats.removeWhere((chat) => chat.chatId == chatId);

        // If deleted chat was selected, clear selection
        if (_selectedChatId == chatId) {
          _selectedChatId = null;
          _showChatScreen = false;
        }
      });
    }

    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat was deleted'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // NEW: Show deletion notification
  void _showDeletionNotification(Map<String, dynamic> deletionData) {
    final chat = _chats.firstWhere(
      (chat) => chat.chatId == deletionData['chatId'],
      orElse: () => ChatRoom(
        chatId: deletionData['chatId'],
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
      'chatName': chat.chatName,
      'type': 'deletion',
      'message': 'A message was deleted',
      'timestamp': DateTime.now(),
    };

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

  Future<void> _loadInitialData() async {
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

  void _openInitialChat() {
    // Only open initial chat if explicitly requested AND we have a valid chatId
    if (widget.openChatOnStart == true &&
        widget.initialChatId != null &&
        mounted) {
      print('🚀 Opening initial chat: ${widget.initialChatId}');

      // Add a small delay to ensure the UI is built
      Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) return;

        try {
          // Try to find the chat in existing chats
          final existingChat = _chats.firstWhere(
            (chat) => chat.chatId == widget.initialChatId,
          );

          // Chat found, select it
          _selectChat(existingChat);
        } catch (e) {
          // If chat not found, refresh and try again
          print(
              '⚠️ Chat not found, refreshing and retrying: ${widget.initialChatId}');
          _loadFreshChats().then((_) {
            if (!mounted) return;
            try {
              final refreshedChat = _chats.firstWhere(
                (chat) => chat.chatId == widget.initialChatId,
              );
              _selectChat(refreshedChat);
            } catch (e) {
              print(
                  '❌ Chat not found even after refresh: ${widget.initialChatId}');
            }
          });
        }
      });
    }
  }

  void _openChatWithUser(String username) async {
    try {
      // First check if chat already exists
      final existingChat = _chats.firstWhere(
        (chat) => !chat.isGroup && chat.chatName == username,
      );

      // Chat exists, select it
      _selectChat(existingChat);
    } catch (e) {
      // Chat doesn't exist, create new one
      try {
        final newChat = await ApiService.createIndividualChat(username);
        _selectChat(ChatRoom.convertChatDTOToChatRoom(newChat));
        // Refresh chat list to include the new chat
        _loadFreshChats();
      } catch (createError) {
        print('❌ Error creating chat with user: $createError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create chat: $createError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(Homescreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.openChatOnStart == true &&
        widget.initialChatId != oldWidget.initialChatId &&
        widget.initialChatId != null) {
      _openInitialChat();
    }
  }

  Future<void> _loadChats() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final cachedChats = await LocalCacheService.getCachedChats();

      if (cachedChats != null && cachedChats.isNotEmpty) {
        print('📦 Loading chats from cache');
        // FIX: Use the helper method for proper type conversion
        List<ChatRoom> convertedChats = _convertToChatRoomList(cachedChats);

        if (mounted) {
          setState(() {
            _chats = convertedChats;
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFreshChats() async {
    print('🔄 Fetching fresh chats from API...');
    try {
      final chats = await ApiService.getUserChats();

      // FIX: Safe type conversion for API response
      List<ChatRoom> convertedChats = _convertToChatRoomList(chats);
      convertedChats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

      await LocalCacheService.cacheChats(convertedChats);

      if (mounted) {
        setState(() {
          _chats = convertedChats;
          _errorMessage = '';
        });
      }
    } catch (e) {
      print('❌ Error loading fresh chats: $e');
      // Don't show error if we have cached chats
      if (_chats.isEmpty && mounted) {
        setState(() {
          _errorMessage = 'Failed to load fresh chats: $e';
        });
      }
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

      // FIX: Use the helper method for proper type conversion
      List<ChatRoom> convertedInvitations = _convertToChatRoomList(invitations);

      if (mounted) {
        setState(() {
          _groupInvitations = convertedInvitations;
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

// Helper method for safe type conversion
  List<ChatRoom> _convertToChatRoomList(dynamic data) {
    if (data == null) return [];

    if (data is List<ChatRoom>) {
      return data;
    }

    if (data is List<dynamic>) {
      return data
          .map<ChatRoom>((item) {
            if (item is ChatRoom) {
              return item;
            } else if (item is Map<String, dynamic>) {
              try {
                return ChatRoom.fromJson(item);
              } catch (e) {
                print('⚠️ Error converting map to ChatRoom: $e');
                return _createFallbackChatRoom();
              }
            } else if (item is ChatRoomDTO) {
              return ChatRoom.convertChatDTOToChatRoom(item);
            } else {
              print('⚠️ Unknown chat data type: ${item.runtimeType}');
              return _createFallbackChatRoom();
            }
          })
          .where((chat) => chat != null)
          .cast<ChatRoom>()
          .toList();
    }

    print('⚠️ Unexpected data type for chat list: ${data.runtimeType}');
    return [];
  }

  ChatRoom _createFallbackChatRoom() {
    return ChatRoom(
      chatId: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
      chatName: 'Unknown Chat',
      isGroup: false,
      lastMessage: 'Error loading chat',
      lastActivity: DateTime.now(),
      pfpIndex: '❓',
      pfpBg: '#FF0000',
      themeIndex: 0,
      isDark: true,
    );
  }

  void _loadChatsFromApi() async {
    print('🔄 Reloading chats from API...');
    await _loadFreshChats();
  }

  void _handleNewMessage(Message message) {
    _debugNotificationState(message);

    // Check if we should show notification
    final bool shouldShowNotification =
        _selectedChatId != message.chatId || !_showChatScreen;

    print('🔔 Should show notification: $shouldShowNotification');

    if (shouldShowNotification) {
      _showMessageNotification(message);
    } else {
      print('🔕 Skipping notification - currently viewing this chat');
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
      var chat = _chats.first;
      final notify = InAppNotification(
          chatId: chat.chatId,
          chatName: chat.chatName,
          lastMessage: chat.lastMessage,
          pfpBg: chat.pfpBg,
          pfpIndex: chat.pfpIndex);

      _showInAppNotification(notify);
    }
  }

  void _showInAppNotification(InAppNotification notify) {
    // Double-check we're not currently viewing this chat
    if (_selectedChatId == notify.chatId && _showChatScreen) {
      print('🔕 Skipping notification - currently viewing this chat');
      return;
    }

    try {
      // final chatRoom = _chats.firstWhere(
      //   (chat) => chat.chatId == message.chatId,
      //   orElse: () => ChatRoom(
      //     chatId: message.chatId,
      //     chatName: 'Unknown Chat',
      //     isGroup: false,
      //     lastMessage: '',
      //     lastActivity: DateTime.now(),
      //     pfpIndex: '💬',
      //     pfpBg: '#4CAF50',
      //     themeIndex: 0,
      //     isDark: true,
      //   ),
      // );

      final notification = {
        'chatName': notify.chatName,
        'message': notify.lastMessage,
        'chatId': notify.chatId,
      };

      print(
          '🔔 Creating notification: ${notify.chatId} - ${notify.lastMessage}');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _messageNotifications.add(notification);
            print(
                '✅ Notification added! Total count: ${_messageNotifications.length}');
          });
        }
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _messageNotifications
                .removeWhere((n) => n['id'] == notification['id']);
            print(
                '🗑️ Removed notification, count: ${_messageNotifications.length}');
          });
        }
      });
    } catch (e) {
      print('❌ Error showing notification: $e');
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

  // UPDATED: Delete chat method with immediate UI refresh
  Future<void> _deleteChat(ChatRoom chat) async {
    final confirmed = await DeletionDialogs.showDeleteChatDialog(
        context, chat.chatName, chat.isGroup);

    if (confirmed == true) {
      try {
        // Store the chat ID before deletion for cleanup
        final deletedChatId = chat.chatId;
        final wasSelected = _selectedChatId == deletedChatId;

        // Immediately remove from local state for instant UI update
        if (mounted) {
          setState(() {
            _chats.removeWhere((c) => c.chatId == deletedChatId);

            // Clear selection if this was the selected chat
            if (wasSelected) {
              _selectedChatId = null;
              _showChatScreen = false;
            }
          });
        }

        // Unsubscribe from WebSocket for this chat
        _webSocketService.unsubscribeFromChatRoom(deletedChatId);

        // Call API to delete from backend
        await ApiService.deleteChat(deletedChatId);

        // Show success message using NesUI dialog
        await DeletionDialogs.showSuccessDialog(
            context,
            'Success',
            chat.isGroup
                ? 'Group deleted successfully'
                : 'Chat deleted successfully');

        // Force refresh the chat list to ensure consistency
        await _loadFreshChats();
      } catch (e) {
        // If API call fails, reload chats to restore the deleted chat
        await _loadFreshChats();

        await DeletionDialogs.showErrorDialog(
            context, 'Error', 'Failed to delete: $e');
      }
    }
  }

// UPDATED: Leave group method with immediate UI refresh
  Future<void> _leaveGroup(ChatRoom chat) async {
    final confirmed =
        await DeletionDialogs.showLeaveGroupDialog(context, chat.chatName);

    if (confirmed == true) {
      try {
        // Store the chat ID before leaving for cleanup
        final leftChatId = chat.chatId;
        final wasSelected = _selectedChatId == leftChatId;

        // Immediately remove from local state for instant UI update
        if (mounted) {
          setState(() {
            _chats.removeWhere((c) => c.chatId == leftChatId);

            // Clear selection if this was the selected chat
            if (wasSelected) {
              _selectedChatId = null;
              _showChatScreen = false;
            }
          });
        }

        // Unsubscribe from WebSocket for this chat
        _webSocketService.unsubscribeFromChatRoom(leftChatId);

        // Call API to leave from backend
        await ApiService.leaveChat(leftChatId);

        // Show success message using NesUI dialog
        await DeletionDialogs.showSuccessDialog(
            context, 'Success', 'Left group successfully');

        // Force refresh the chat list to ensure consistency
        await _loadFreshChats();
      } catch (e) {
        // If API call fails, reload chats to restore the left chat
        await _loadFreshChats();

        await DeletionDialogs.showErrorDialog(
            context, 'Error', 'Failed to leave group: $e');
      }
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
    // Double-check we're not currently viewing this chat
    if (_selectedChatId == message.chatId && _showChatScreen) {
      print('🔕 Skipping notification - currently viewing this chat');
      return;
    }

    try {
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
        'type': 'message',
      };

      print(
          '🔔 Creating notification: ${notification['chatName']} - ${notification['message']}');

      // CRITICAL FIX: Use post frame callback to ensure setState happens after current build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _messageNotifications.add(notification);
            print(
                '✅ Notification added! Total count: ${_messageNotifications.length}');
          });
        }
      });

      // Auto-remove notification after delay
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _messageNotifications
                .removeWhere((n) => n['id'] == notification['id']);
            print(
                '🗑️ Removed notification, count: ${_messageNotifications.length}');
          });
        }
      });
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  void _debugNotificationState(Message message) {
    print('=== NOTIFICATION DEBUG ===');
    print('📱 Mounted: $mounted');
    print('💬 Message received: ${message.content}');
    print('🏠 Selected chat ID: $_selectedChatId');
    print('💻 Show chat screen: $_showChatScreen');
    print('🔔 Current notifications: ${_messageNotifications.length}');
    print('📡 WebSocket connected: ${_webSocketService.isConnected}');
    print('==========================');
  }

  Widget _buildMessageNotifications() {
    print(
        '🎨 Building notifications widget. Count: ${_messageNotifications.length}');

    if (_messageNotifications.isEmpty) {
      print('⚠️ No notifications to display');
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _messageNotifications.map((notification) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildGlassNotification(notification),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGlassNotification(Map<String, dynamic> notification) {
    final isDeletion = notification['type'] == 'deletion';

    return GestureDetector(
      onTap: isDeletion
          ? null
          : () {
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
        backgroundColor: isDeletion ? Colors.orange.withOpacity(0.1) : null,
        child: Row(
          children: [
            NesContainer(
              width: 36,
              height: 36,
              backgroundColor: isDeletion ? Colors.orange : _accent,
              child: Center(
                child: Icon(isDeletion ? Icons.delete_outline : Icons.chat,
                    color: Colors.white, size: 16),
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
                      color: isDeletion ? Colors.orange : _accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: GoogleFonts.vt323(
                      color: isDeletion ? Colors.orange[700] : _mutedText,
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
        onLongPress: () => {
          Feedback.forLongPress(context),
          _showChatOptions(chat),
        },
        // onLongPress: () => !_isMobileScreen
        //     ? chat.isGroup
        //         ? GroupManagementScreen(group: chat)
        //         : OtherUserProfileScreen(username: chat.chatName)
        //     : null,
        // onDoubleTap: () => _isMobileScreen
        //     ? chat.isGroup
        //         ? GroupManagementScreen(group: chat)
        //         : OtherUserProfileScreen(username: chat.chatName)
        //     : null,
        child: NesContainer(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          backgroundColor: isSelected
              ? Colors.grey.shade500
              : (isHovered ? Colors.grey.shade300 : _surface),
          child: Row(
            children: [
              PixelCircle(
                color: _parseColor(chat.pfpBg),
                label: chat.pfpIndex,
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
                        fontSize: 13,
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

  void _showChatOptions(ChatRoom chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Important for responsiveness
      builder: (context) {
        // Get screen dimensions for responsive sizing
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Responsive sizing calculations
        final bool isSmallScreen = screenWidth < 360;
        final bool isLargeScreen = screenWidth > 600;
        final double horizontalPadding = isSmallScreen ? 12 : 16;
        final double containerMargin = isSmallScreen ? 8 : 16;
        final double buttonSpacing = isSmallScreen ? 6 : 8;

        // Responsive font sizes
        final double titleFontSize =
            isSmallScreen ? 10 : (isLargeScreen ? 14 : 12);
        final double subtitleFontSize =
            isSmallScreen ? 12 : (isLargeScreen ? 16 : 14);
        final double buttonFontSize =
            isSmallScreen ? 8 : (isLargeScreen ? 12 : 10);

        // Responsive icon size
        final double iconSize = isSmallScreen ? 14 : 16;

        // Responsive spacing
        final double elementSpacing = isSmallScreen ? 8 : 12;
        final double pixelCircleSize = isSmallScreen ? 32 : 40;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NesContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => chat.isGroup
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  GroupManagementScreen(group: chat)),
                        )
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OtherUserProfileScreen(
                                  username: chat.chatName, fromChat: false)),
                        ),
                  child: NesContainer(
                    child: Row(
                      children: [
                        PixelCircle(
                          color: _parseColor(chat.pfpBg),
                          label: chat.pfpIndex,
                        ),
                        SizedBox(width: elementSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat.chatName,
                                style: GoogleFonts.pressStart2p(
                                  fontSize: titleFontSize,
                                  color: _accent,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              SizedBox(height: isSmallScreen ? 2 : 4),
                              Text(
                                chat.isGroup ? 'Group Chat' : 'Direct Message',
                                style: GoogleFonts.vt323(
                                  fontSize: subtitleFontSize,
                                  color: _mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),

                // Options
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chat.isGroup) ...[
                        _buildOptionButton(
                          icon: Icons.exit_to_app,
                          title: 'Leave Group',
                          color: Colors.orange,
                          onPressed: () {
                            Navigator.pop(context);
                            _leaveGroup(chat);
                          },
                          fontSize: buttonFontSize,
                          iconSize: iconSize,
                        ),
                        SizedBox(height: buttonSpacing),
                        _buildOptionButton(
                          icon: Icons.delete,
                          title: 'Delete Group',
                          color: Colors.red,
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteChat(chat);
                          },
                          fontSize: buttonFontSize,
                          iconSize: iconSize,
                        ),
                      ] else
                        _buildOptionButton(
                          icon: Icons.delete,
                          title: 'Delete Chat',
                          color: Colors.red,
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteChat(chat);
                          },
                          fontSize: buttonFontSize,
                          iconSize: iconSize,
                        ),
                      SizedBox(height: buttonSpacing),
                      _buildOptionButton(
                        icon: Icons.cancel,
                        title: 'Cancel',
                        color: Colors.grey,
                        onPressed: () => Navigator.pop(context),
                        fontSize: buttonFontSize,
                        iconSize: iconSize,
                      ),
                      SizedBox(height: buttonSpacing),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Updated helper method for option buttons with responsive parameters
  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
    required double fontSize,
    required double iconSize,
  }) {
    return NesButton(
      type: _getButtonType(color),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.pressStart2p(
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

// Helper to determine button type based on color (unchanged)
  NesButtonType _getButtonType(Color color) {
    if (color == Colors.red) return NesButtonType.error;
    if (color == Colors.orange) return NesButtonType.warning;
    if (color == Colors.green) return NesButtonType.success;
    return NesButtonType.normal;
  }

  Widget _buildInvitationListItem(ChatRoom invitation) {
    return NesContainer(
      padding: const EdgeInsets.all(8),
      backgroundColor: Colors.white,
      child: Row(
        children: [
          PixelCircle(
            color: _parseColor(invitation.pfpBg),
            label: invitation.pfpIndex,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NesButton(
                  type: NesButtonType.success,
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontSize: 8),
                  ),
                  onPressed: () => _acceptGroupInvitation(invitation)),
              const SizedBox(width: 3),
              NesButton(
                  type: NesButtonType.error,
                  child: const Text(
                    'Decline',
                    style: TextStyle(fontSize: 8),
                  ),
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
            _isMobileScreen ? _buildRunningTextBanner() : SizedBox.shrink(),
            // Connection status bar
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Connection: ",
                    style: TextStyle(fontSize: 8),
                  ),
                  NesBlinker(
                    child: Icon(
                      _webSocketService.isConnected
                          ? Icons.circle
                          : Icons.circle_outlined,
                      size: 8,
                      color: _webSocketService.isConnected
                          ? Colors.green
                          : Colors.orange,
                    ),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: NesIcon(iconData: NesIcons.musicNote),
      ),
      title: Text('URChat', style: GoogleFonts.pressStart2p(fontSize: 14)),
      actions: [
        // In your Homescreen build method, replace the web notification section with:

        if (kIsWeb)
          FutureBuilder<bool>(
            future: NotificationService().hasNotificationPermission(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return NesTerminalLoadingIndicator();
              }

              if (snapshot.hasData && !snapshot.data!) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: NesIconButton(
                    icon: NesIcons.bell,
                    onPress: () async {
                      await NotificationService().enableWebNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notifications enabled!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        PopupMenuButton(
          child: NesIcon(iconData: NesIcons.threeVerticalDots),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'profile', child: Text('Profile')),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
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
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _testNotification() {
    print('🧪 Testing notification system...');

    final testMessage = Message(
        id: 999,
        content: 'Message',
        sender: 'test_user',
        chatId: _chats.isNotEmpty ? _chats.first.chatId : 'test_chat',
        timestamp: DateTime.now(),
        isOwnMessage: false);

    _showMessageNotification(testMessage);
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
            Text(
              'Loading invitations...',
            ),
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
              _buildRunningTextBanner(),
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
    return _showChatScreen && _selectedChat != null
        ? _buildSelectedChatView()
        : _buildChatsList();
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

  void _verifyNotificationSystem() {
    print('=== NOTIFICATION SYSTEM VERIFICATION ===');
    print('📱 App mounted: $mounted');
    print('🔔 Notifications in list: ${_messageNotifications.length}');
    print('💬 Chats loaded: ${_chats.length}');
    print('📡 WebSocket connected: ${_webSocketService.isConnected}');
    print('🎯 Subscribed chats: ${_webSocketService.getSubscribedChats()}');
    print('🔄 Build method called at: ${DateTime.now()}');
    print('========================================');
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
    return WillPopScope(
      onWillPop: () => _exitAppDialog(),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _deselectChat();
          }
        },
        child: Scaffold(
            backgroundColor: _beige,
            appBar: _showChatScreen && _isMobileScreen ? null : _buildAppBar(),
            body: Stack(
              children: [
                // Main content
                _isLoading
                    ? _buildLoadingState()
                    : (_isMobileScreen
                        ? _buildMobileLayout()
                        : _buildDesktopLayout()),

                // Notifications overlay - TOP LEVEL
                if (_messageNotifications.isNotEmpty)
                  _buildMessageNotifications(),
              ],
            ),
            floatingActionButton: !_showChatScreen
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
                      _showFloatingActionMenu();
                    },
                  )
                : null),
      ),
    );
  }

  Future<bool> _exitAppDialog() async {
    final result = await NesDialog.show<bool>(
      context: context,
      builder: (context) => const NesConfirmDialog(
        cancelLabel: "Cancel",
        confirmLabel: "Exit",
        message: "Are you sure you want to quit the app?",
      ),
    );

    return result ?? false;
  }

  void _showFloatingActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // New Chat Option
                NesButton(
                  type: NesButtonType.primary,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_outlined, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        "New Chat",
                        style: GoogleFonts.pressStart2p(fontSize: 10),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close the menu
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    ).then((_) {
                      _loadChatsFromApi();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Create Group Option
                NesButton(
                  type: NesButtonType.warning,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_add_outlined, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        "Create Group",
                        style: GoogleFonts.pressStart2p(fontSize: 10),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close the menu
                    _showCreateGroupDialog();
                  },
                ),
                const SizedBox(height: 8),

                // Close button
                NesButton(
                  type: NesButtonType.normal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        "Close",
                        style: GoogleFonts.pressStart2p(fontSize: 10),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildRunningTextBanner() {
    return SizedBox(
      height: 40,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _showRunningText ? 1.0 : 0.0,
        child: _currentTextIndex == 0
            ? Center(
                child: NesRunningText(
                  onEnd: () {
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          _showRunningText = false;
                        });

                        // After fade out, switch text and fade in
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() {
                              _currentTextIndex = 1;
                              _showRunningText = true;
                            });
                          }
                        });
                      }
                    });
                  },
                  text: "Welcome to URChat",
                  textStyle: TextStyle(fontSize: _isLargeScreen ? 14 : 12),
                ),
              )
            : Center(
                child: NesRunningText(
                  onEnd: () {
                    // Wait a bit after text completes, then fade out and switch
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          _showRunningText = false;
                        });

                        // After fade out, switch text and fade in
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() {
                              _currentTextIndex = 0;
                              _showRunningText = true;
                            });
                          }
                        });
                      }
                    });
                  },
                  text: "Messages will be automatically\ndeleted after 30 days",
                  textStyle: TextStyle(fontSize: _isLargeScreen ? 12 : 10),
                ),
              ),
      ),
    );
  }

  void _logout() async {
    final result = await NesDialog.show<bool>(
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
