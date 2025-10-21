import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nes_ui/nes_ui.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:urchat/model/dto.dart';
import 'package:urchat/model/message.dart';
import 'package:urchat/screens/auth/auth_screen.dart';
import 'package:urchat/screens/chatting.dart';
import 'package:urchat/screens/group_management_screen.dart';
import 'package:urchat/screens/group_pfp_dialog.dart';
import 'package:urchat/screens/inapp_notifications.dart';
import 'package:urchat/screens/new_group.dart';
import 'package:urchat/screens/offline_screen.dart';
import 'package:urchat/screens/profile_screen.dart';
import 'package:urchat/screens/search_delegate.dart';
import 'package:urchat/screens/splash_screen.dart';
import 'package:urchat/screens/user_profile.dart';
import 'package:urchat/service/api_service.dart';
import 'package:urchat/service/local_cache_service.dart';
import 'package:urchat/service/notification_service.dart';
import 'package:urchat/service/websocket_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:urchat/widgets/deletion_dialog.dart';
import 'package:urchat/widgets/pixle_circle.dart';
import 'package:urchat/widgets/scrolled_text.dart';

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
  // final List<Map<String, dynamic>> _messageNotifications = [];
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

  bool _isInternetConnected = true;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  late Timer _connectionTimer;
  late Timer _debugTimer;
  late final FocusNode _focusNode;

  final inApp = InAppNotifications.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.openChatOnStart == true && widget.initialChatId != null) {
      _openInitialChat();
    }

    _loadInitialData();
    // .then((_) {
    //   if (widget.openChatOnStart == true && widget.initialChatId != null) {
    //     _openInitialChat();
    //   }
    // });

    // _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
    //   _switchRunningText();
    // });

    _focusNode = FocusNode();
    _connectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_webSocketService.isConnected) {
        _webSocketService.connect();
      }
    });

    _debugTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _debugSubscriptions();
    });

    _initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _initializeWebSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyNotificationSystem();
    });

    // Timer.periodic(const Duration(seconds: 10), (timer) {
    //   _debugSubscriptions();
    // });

    _setupNotificationListener();

    _setupNotificationCallback();
  }

  void _setupNotificationCallback() {
    //print('🔗 Setting up notification callback');
    InAppNotifications.instance.setOnOpenChatCallback((String chatId) {
      //print('🎯 Notification callback received for chat: $chatId');
      _openChatFromNotification(chatId);
    });
  }

  void _openChatFromNotification(String chatId) {
    //print('🚀 Opening chat from notification callback: $chatId');

    // Try to find the chat in existing chats
    try {
      final chat = _chats.firstWhere((chat) => chat.chatId == chatId);
      //print('✅ Chat found: ${chat.chatName}');

      // NEW: Check if we're currently in mobile view with a chat open
      if (_isMobileScreen && _selectedChatId != null) {
        //print('📱 Mobile: Replacing current chat with notification chat');

        // First deselect the current chat (this will pop the chat screen)
        _deselectChat();

        // Wait a tiny bit for the navigation to complete, then select the new chat
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _selectChat(chat);
          }
        });
      } else {
        // For desktop or when no chat is selected, just select normally
        _selectChat(chat);
      }
    } catch (e) {
      //print('❌ Chat not found in current list, refreshing...');
      // Chat might not be loaded yet, refresh and try again
      _loadFreshChats().then((_) {
        if (!mounted) return;
        try {
          final refreshedChat =
              _chats.firstWhere((chat) => chat.chatId == chatId);
          //print('✅ Chat found after refresh: ${refreshedChat.chatName}');

          // Apply the same mobile navigation logic
          if (_isMobileScreen && _selectedChatId != null) {
            _deselectChat();
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _selectChat(refreshedChat);
              }
            });
          } else {
            _selectChat(refreshedChat);
          }
        } catch (e) {
          //print('❌ Chat not found even after refresh: $chatId');
          _showChatNotFoundError(chatId);
        }
      });
    }
  }

  void _showChatNotFoundError(String chatId) {
    NesSnackbar.show(
      context,
      text: 'Chat not found or you no longer have access',
      type: NesSnackbarType.error,
    );
  }

  void _setupNotificationListener() {
    NotificationService().notificationStream.listen((data) {
      // Use the global InAppNotifications instance
      if (data['type'] == 'NEW_MESSAGE') {
        InAppNotifications.instance.addNotification(data);
      }
    });
  }

  // void _handleNotification(Map<String, dynamic> data) {
  //   final type = data['type'];
  //   final chatId = data['chatId'];
  //   final sender = data['sender'];
  //   final message = data['message'];

  //   if (type == 'NEW_MESSAGE' && chatId != null) {
  //     // Refresh chat list to show updated last message
  //     _loadFreshChats();

  //     // Show in-app notification if not viewing that chat
  //     if (_selectedChatId != chatId || !_showChatScreen) {
  //       final notification = {
  //         'chatName': data['chatName'] ?? 'New Message',
  //         'message': '$sender: $message',
  //         'chatId': chatId,
  //       };

  //       if (mounted) {
  //         setState(() {
  //           _messageNotifications.add(notification);
  //         });
  //       }
  //     }
  //   }
  // }

  // void _verifyNotificationAdded() {
  //   //print('=== NOTIFICATION STATE CHECK ===');
  //   //print('📊 Total notifications: ${_messageNotifications.length}');
  //   //print('📱 Widget mounted: $mounted');
  //   //print('🔄 Last rebuild: ${DateTime.now()}');
  //   _messageNotifications.forEach((n) {
  //     //print('  - ${n['chatName']}: ${n['message']}');
  //   });
  //   //print('================================');
  // }

  void _initializeWebSocket() {
    //print('🔌 Initializing WebSocket...');

    _webSocketService = WebSocketService(
      onMessageReceived: _handleNewMessage,
      onChatListUpdated: _handleChatListUpdate,
      onTyping: (data) {
        //print('⌨️ Typing: $data');
      },
      onReadReceipt: (data) {
        //print('👀 Read receipt: $data');
      },
      onMessageDeleted: _handleMessageDeleted,
      onChatDeleted: _handleChatDeleted,
    );

    Timer.periodic(Duration(seconds: 2), (timer) {
      if (!_webSocketService.isConnected) {
        //print('🔄 WebSocket not connected, reconnecting...');
        _webSocketService.connect();
      }
    });

    _webSocketService.connect();
    _testWebSocketConnection();
  }

  // NEW: Handle message deletion from WebSocket
  void _handleMessageDeleted(Map<String, dynamic> deletionData) {
    //print('🗑️ Message deletion received: $deletionData');

    final deletedMessageId = deletionData['messageId'];
    final chatId = deletionData['chatId'];

    // If we're currently viewing the chat where message was deleted, update UI
    if (_selectedChatId == chatId) {
      // This will be handled by the ChatScreen via its own listener
      //print('🗑️ Message $deletedMessageId deleted from current chat');
    }

    // Show notification for message deletion
    // _showDeletionNotification(deletionData);
  }

  // NEW: Handle chat deletion from WebSocket
  void _handleChatDeleted(String chatId) {
    //print('🗑️ Chat deletion received for: $chatId');

    if (mounted) {
      setState(() {
        _chats.removeWhere((chat) => chat.chatId == chatId);

        inApp.updateChats(_chats);

        // If deleted chat was selected, clear selection
        if (_selectedChatId == chatId) {
          _selectedChatId = null;
          _showChatScreen = false;
        }
      });
    }

    // Show notification
    NesSnackbar.show(context,
        text: 'Chat was deleted', type: NesSnackbarType.warning);
  }

  Future<void> _loadInitialData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      await _loadChats();
      await _loadGroupInvitations();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _debugSubscriptions();
    } catch (e) {
      //print('❌ Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: $e';
          _isInternetConnected = false;
        });
      }
    }
  }

  void _openInitialChat() {
    if (widget.openChatOnStart == true &&
        widget.initialChatId != null &&
        mounted) {
      //print('🚀 Opening initial chat: ${widget.initialChatId}');

      // Add a small delay to ensure the UI is built
      Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) return;

        try {
          final existingChat = _chats.firstWhere(
            (chat) => chat.chatId == widget.initialChatId,
          );

          // Chat found, select it
          _selectChat(existingChat);
        } catch (e) {
          // If chat not found, refresh and try again
          //print('⚠️ Chat not found, refreshing and retrying: ${widget.initialChatId}');
          _loadFreshChats().then((_) {
            if (!mounted) return;
            try {
              final refreshedChat = _chats.firstWhere(
                (chat) => chat.chatId == widget.initialChatId,
              );
              _selectChat(refreshedChat);
            } catch (e) {
              //print( '❌ Chat not found even after refresh: ${widget.initialChatId}');
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
        //print('❌ Error creating chat with user: $createError');
        NesSnackbar.show(context,
            text: 'Failed to create chat: $createError',
            type: NesSnackbarType.error);
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
        //print('📦 Loading chats from cache');
        // FIX: Use the helper method for proper type conversion
        List<ChatRoom> convertedChats = _convertToChatRoomList(cachedChats);

        if (mounted) {
          setState(() {
            _chats = convertedChats;
            inApp.updateChats(_chats);
            _errorMessage = '';
          });
        }
      }
      await _loadFreshChats();
    } catch (e) {
      //print('❌ Error loading initial chats: $e');
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
    //print('🔄 Fetching fresh chats from API...');
    try {
      final chats = await ApiService.getUserChats();

      // FIX: Safe type conversion for API response
      List<ChatRoom> convertedChats = _convertToChatRoomList(chats);
      convertedChats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

      await LocalCacheService.cacheChats(convertedChats);

      if (mounted) {
        setState(() {
          _chats = convertedChats;
          inApp.updateChats(_chats);
          _errorMessage = '';
        });
      }
    } catch (e) {
      //print('❌ Error loading fresh chats: $e');
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
      //print('❌ Error loading group invitations: $e');
      if (mounted) {
        setState(() {
          _isLoadingInvitations = false;
        });
      }
    }
  }

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
    //print('🔄 Reloading chats from API...');
    await _loadFreshChats();
  }

  void _handleNewMessage(Message message) {
    // Check if we should show notification
    final bool shouldShowNotification =
        _selectedChatId != message.chatId || !_showChatScreen;

    //print('🔔 Should show notification: $shouldShowNotification');

    if (shouldShowNotification) {
      // Find the chat for this message
      try {
        final chat = _chats.firstWhere((chat) => chat.chatId == message.chatId);
        final notification = {
          'chatId': chat.chatId,
          'chatName': chat.chatName,
          'message': '${message.sender}: ${message.content}',
          'type': 'NEW_MESSAGE',
        };

        InAppNotifications.instance.addNotification(notification);
      } catch (e) {
        //print('❌ Chat not found for notification: ${message.chatId}');
      }
    } else {
      //print('🔕 Skipping notification - currently viewing this chat');
    }

    _refreshChatListForMessage(message);
  }

  void _refreshChatListForMessage(Message message) {
    final chatIndex =
        _chats.indexWhere((chat) => chat.chatId == message.chatId);
    if (chatIndex != -1 && mounted) {
      setState(() {
        _chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
        inApp.updateChats(_chats);
      });
    }
  }

  void _handleChatListUpdate(List<ChatRoom> updatedChats) {
    //print('🔄 Real-time chat list update received: ${updatedChats.length} chats');

    if (mounted) {
      setState(() {
        _chats = updatedChats;
        inApp.updateChats(_chats);
        _errorMessage = '';

        if (_selectedChatId != null) {
          try {
            _chats.firstWhere((chat) => chat.chatId == _selectedChatId);
          } catch (e) {
            //print('⚠️ Selected chat no longer exists: $_selectedChatId');
            _selectedChatId = null;
            _showChatScreen = false;
          }
        }
      });

      // Create proper notification map
      if (_chats.isNotEmpty) {
        var chat = _chats.first;
        final notification = {
          'chatId': chat.chatId,
          'chatName': chat.chatName,
          'message': chat.lastMessage,
          'pfpBg': chat.pfpBg,
          'pfpIndex': chat.pfpIndex,
        };

        InAppNotifications.instance.addNotification(notification);
      }
    }
  }

  void _selectChat(ChatRoom chat) {
    if (_selectedChatId == chat.chatId && _showChatScreen) {
      _deselectChat();
      return;
    }

    if (_selectedChatId != null) {
      _webSocketService.unsubscribeFromChatRoom(_selectedChatId!);
    }

    _webSocketService.subscribeToChatRoom(chat.chatId);

    if (mounted) {
      setState(() {
        _selectedChatId = chat.chatId;
        _showChatScreen = _isLargeScreen; // Only show inline for desktop
      });
    }

    // For mobile, navigate to chat screen
    if (_isMobileScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => URChatApp(
              chatRoom: chat,
              webSocketService: _webSocketService,
              onBack: _deselectChat,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOut;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        )
            .then((_) {
          _deselectChat();
        });
      });
    }

    _debugSubscriptions();
  }

  void _debugSubscriptions() {
    //print( '🔍 CURRENT SUBSCRIPTIONS: ${_webSocketService.getSubscribedChats()}');
  }

  void _deselectChat() {
    //print('👈 Deselecting chat and navigating back');
    if (mounted) {
      setState(() {
        _selectedChatId = null;
        _showChatScreen = false;
      });
    }

    if (_isMobileScreen && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
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
            inApp.updateChats(_chats);

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
            inApp.updateChats(_chats);

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
      //print('❌ Error accepting group invitation: $e');
      if (mounted) {
        NesSnackbar.show(context,
            text: 'Failed to join group: $e', type: NesSnackbarType.error);
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
      //print('❌ Error declining group invitation: $e');
      if (mounted) {
        NesSnackbar.show(
          text: 'Failed to decline invitation: $e',
          type: NesSnackbarType.error,
          context,
        );
      }
    }
  }

  void _handleNotificationSettings() async {
    if (kIsWeb) {
      // For web - enable notifications
      final success = await NotificationService().enableWebNotifications();

      if (success && mounted) {
        NesSnackbar.show(
            text: 'Web notifications enabled!',
            type: NesSnackbarType.success,
            context);
        setState(() {}); // Refresh to hide the icon
      } else if (mounted) {
        NesSnackbar.show(
            text: 'Failed to enable notifications',
            type: NesSnackbarType.error,
            context);
      }
    } else {
      // For mobile - request permission
      final hasPermission =
          await NotificationService().hasNotificationPermission();

      if (!hasPermission) {
        await NotificationService().requestPermissions();

        // Check again after requesting
        final newPermission =
            await NotificationService().hasNotificationPermission();

        if (mounted) {
          NesSnackbar.show(
              text: newPermission
                  ? 'Notification permission granted!'
                  : 'Notification permission denied',
              type: newPermission
                  ? NesSnackbarType.success
                  : NesSnackbarType.warning,
              context);

          // Refresh UI to hide icon if permission was granted
          if (newPermission) {
            setState(() {});
          }
        }
      } else {
        // Already have permission - show status
        if (mounted) {
          NesSnackbar.show(
              text: 'Notifications are already enabled',
              type: NesSnackbarType.success,
              context);
        }
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
              Hero(
                tag: chat.isGroup
                    ? "chat_avatar_${chat.chatId}"
                    : "user_avatar_${chat.chatName}",
                child: PixelCircle(
                  color: _parseColor(chat.pfpBg),
                  label: chat.pfpIndex,
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
                        Hero(
                          tag: chat.isGroup
                              ? "chat_avatar_${chat.chatId}"
                              : "user_avatar_${chat.chatName}",
                          child: PixelCircle(
                            color: _parseColor(chat.pfpBg),
                            label: chat.pfpIndex,
                          ),
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
            if (_isMobileScreen) _buildRunningTextBanner(),
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
        child: Hero(
          tag: "app_logo",
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset("assets/urchat_logo.png"),
          ),
        ),
      ),
      title: Text('URChat', style: GoogleFonts.pressStart2p(fontSize: 14)),
      actions: [
        // ElevatedButton(
        //     onPressed: () => Navigator.push(context,
        //         MaterialPageRoute(builder: (context) => SplashScreen())),
        //     child: Text("Splash")),
        if (kIsWeb)
          FutureBuilder<bool>(
            future: NotificationService().hasNotificationPermission(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink(); // Hide while loading
              }
              final hasPermission = snapshot.data ?? false;
              // Only show notification icon if permissions are NOT granted
              return hasPermission
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: NesIconButton(
                        icon: NesIcons.bell,
                        onPress: () async {
                          final success = await NotificationService()
                              .enableWebNotifications();
                          if (success && mounted) {
                            NesSnackbar.show(
                              context,
                              text: 'Web notifications enabled!',
                              type: NesSnackbarType.success,
                            );
                            setState(() {});
                          } else if (mounted) {
                            NesSnackbar.show(
                                text: 'Failed to enable notifications',
                                type: NesSnackbarType.error,
                                context);
                          }
                        },
                      ),
                    );
            },
          ),
        if (!kIsWeb)
          FutureBuilder<bool>(
            future: NotificationService().hasNotificationPermission(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink(); // Hide while loading
              }
              final hasPermission = snapshot.data ?? false;
              // Only show notification icon if permissions are NOT granted
              return hasPermission
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: NesIconButton(
                        icon: NesIcons.bell,
                        onPress: _handleNotificationSettings,
                      ),
                    );
            },
          ),
        PopupMenuButton(
          child: NesIcon(iconData: NesIcons.threeVerticalDots),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'profile', child: Text('Profile')),
            const PopupMenuItem(value: 'game', child: Text('Maze')),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          onSelected: (value) {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            } else if (value == 'game') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MazeGamePage()),
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

  // void _testNotification() {
  //   //print('🧪 Testing notification system...');

  //   final testMessage = Message(
  //       id: 999,
  //       content: 'Message',
  //       sender: 'test_user',
  //       chatId: _chats.isNotEmpty ? _chats.first.chatId : 'test_chat',
  //       timestamp: DateTime.now(),
  //       isOwnMessage: false);

  //   _showMessageNotification(testMessage);
  // }

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
        child: _isInternetConnected
            ? Center(
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
                    .moveY(begin: 10, curve: Curves.easeOutQuart))
            : _buildOfflineState(),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Connection status indicator
          NesContainer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NesBlinker(
                //   child: Icon(
                //     Icons.signal_wifi_off,
                //     size: 16,
                //     color: Colors.orange,
                //   ),
                // ),
                const SizedBox(width: 8),
                NesRunningText(
                  text: "No Internet Connection",
                  textStyle: GoogleFonts.pressStart2p(
                      fontSize: 10, color: Colors.orange),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Offline icon
          Icon(
            Icons.cloud_off,
            size: 80,
            color: _accent.withOpacity(0.3),
          ),

          const SizedBox(height: 24),

          // Offline message
          Text(
            "You're offline",
            style: GoogleFonts.pressStart2p(
              fontSize: 14,
              color: _mutedText,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Try escaping Phantom meanwhile",
            style: GoogleFonts.vt323(
              fontSize: 12,
              color: _mutedText,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          NesButton(
            type: NesButtonType.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MazeGamePage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NesIcon(iconData: NesIcons.gamepad),
                  const SizedBox(width: 12),
                  Text(
                    "PLAY GAME",
                    style: GoogleFonts.pressStart2p(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Retry connection button
          NesButton(
            type: NesButtonType.normal,
            onPressed: () {
              _initConnectivity();
              _loadInitialData();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 16),
                const SizedBox(width: 8),
                Text(
                  "RETRY CONNECTION",
                  style: GoogleFonts.pressStart2p(fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 800.ms)
          .moveY(begin: 10, curve: Curves.easeOutQuart),
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
    if (!_isInternetConnected) {
      return _buildOfflineState();
    }

    return _buildChatsList();
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
    //print('=== NOTIFICATION SYSTEM VERIFICATION ===');
    //print('📱 App mounted: $mounted');
    // //print('🔔 Notifications in list: ${inApp.messageNotifications.length}');
    //print('💬 Chats loaded: ${_chats.length}');
    //print('📡 WebSocket connected: ${_webSocketService.isConnected}');
    //print('🎯 Subscribed chats: ${_webSocketService.getSubscribedChats()}');
    //print('🔄 Build method called at: ${DateTime.now()}');
    //print('========================================');
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      //print('⚠️ Error parsing color: $colorString, using default');
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
      onWillPop: () async {
        if (_isMobileScreen && _selectedChat != null) {
          _deselectChat();
          return false;
        }
        final result = await NesDialog.show<bool>(
          context: context,
          builder: (context) => const NesConfirmDialog(
            cancelLabel: "Cancel",
            confirmLabel: "Exit",
            message: "Are you sure you want to quit the app?",
          ),
        );

        return result ?? false;
      },
      child: RawKeyboardListener(
        focusNode: _focusNode,
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

                // Global notifications overlay
                InAppNotifications.instance.buildNotifications(context, () {
                  //print('ℹ️ Legacy notification callback - not used');
                }),
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
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    ).then((_) {
                      _loadChatsFromApi();
                    });
                  },
                ),
                const SizedBox(height: 12),

                Hero(
                  tag: "create_group",
                  child: NesButton(
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

  Widget _buildRunningTextBanner() => const RunningTextBanner();

  // Widget _buildRunningTextBanner() {
  //   return Container(
  //     height: 40,
  //     width: double.infinity,
  //     child: Center(
  //       child: AnimatedSwitcher(
  //         duration: const Duration(milliseconds: 500),
  //         child: _buildCurrentTextItem(),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildCurrentTextItem() {
  //   final texts = [
  //     "Welcome to URChat",
  //     "Messages will be automatically deleted after 7 days"
  //   ];

  //   return Container(
  //     key: ValueKey(_currentTextIndex),
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: NesRunningText(
  //       text: texts[_currentTextIndex],
  //       textStyle: GoogleFonts.pressStart2p(
  //         fontSize: _isLargeScreen ? 12 : 10,
  //         color: _brown,
  //       ),
  //     ),
  //   );
  // }

  // void _switchRunningText() {
  //   if (!mounted) return;

  //   setState(() {
  //     _currentTextIndex = (_currentTextIndex + 1) % 2;
  //   });
  // }

  void _logout() async {
    if (!_isInternetConnected) {
      if (mounted) {
        NesSnackbar.show(
          context,
          text:
              'Cannot logout while offline. Please check your internet connection.',
          type: NesSnackbarType.error,
        );
      }
      return;
    }

    bool serverReachable = await ApiService.isServerReachable();
    if (!serverReachable) {
      if (mounted) {
        NesSnackbar.show(
          context,
          text: 'Cannot connect to server. Please try again when connected.',
          type: NesSnackbarType.error,
        );
      }
      return;
    }

    final result = await NesDialog.show<bool>(
      context: context,
      builder: (context) => const NesConfirmDialog(
        cancelLabel: 'Cancel',
        confirmLabel: 'Logout',
        message:
            'Are you sure you want to logout? This will remove your device from receiving notifications.',
      ),
    );

    if (result == true && mounted) {
      await _performSecureLogout();
    }
  }

  Future<void> _performSecureLogout() async {
    try {
      // Show loading indicator
      if (mounted) {
        NesSnackbar.show(
          context,
          text: 'Securely logging out...',
          type: NesSnackbarType.warning,
        );
      }

      _webSocketService.disconnect();

      bool serverLogoutSuccess = await ApiService.logout();

      await _clearAllLocalData();

      _cancelAllTimers();

      if (mounted) {
        if (serverLogoutSuccess) {
          NesSnackbar.show(
            context,
            text: 'Logged out successfully. Notifications disabled.',
            type: NesSnackbarType.success,
          );
        } else {
          NesSnackbar.show(
            context,
            text:
                'Local logout complete. Notifications may still work until next login.',
            type: NesSnackbarType.warning,
          );
        }

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AuthScreen()),
            );
          }
        });
      }
    } catch (e) {
      //print('❌ Secure logout failed: $e');
      if (mounted) {
        NesSnackbar.show(
          context,
          text: 'Logout failed. Please try again.',
          type: NesSnackbarType.error,
        );
      }
    }
  }

  Future<void> _clearAllLocalData() async {
    try {
      await LocalCacheService.clearAllCache();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      //print('✅ All local data cleared securely');
    } catch (e) {
      //print('❌ Error clearing local data: $e');
    }
  }

  void _cancelAllTimers() {
    _connectionTimer.cancel();
    _debugTimer.cancel();
    _timer.cancel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectivitySubscription.cancel();
    _connectionTimer.cancel();
    _debugTimer.cancel();
    _timer.cancel();
    _webSocketService.disconnect();
    _focusNode.dispose();
    InAppNotifications.instance.setOnOpenChatCallback((_) {});
    super.dispose();
  }

  void _testWebSocketConnection() {
    //print('🔍 === WEB SOCKET CONNECTION TEST ===');
    //print('   ✅ WebSocketService created: ${_webSocketService != null}');
    //print('   ✅ Connected: ${_webSocketService.isConnected}');

    Future.delayed(const Duration(seconds: 3), () {
      if (_webSocketService.isConnected) {
        //print('🎉 WebSocket is connected and ready!');
      } else {
        //print('❌ WebSocket failed to connect');
      }
    });
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      //print('❌ Error checking connectivity: $e');
      if (mounted) {
        setState(() {
          _isInternetConnected = false;
        });
      }
    }
  }

// FIXED: Parameter type changed to List<ConnectivityResult>
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Consider connected if any connectivity method is available
    final isConnected =
        results.any((result) => result != ConnectivityResult.none);

    if (mounted) {
      setState(() {
        _isInternetConnected = isConnected;

        // Auto-reconnect WebSocket when connection is restored
        if (_isInternetConnected && !_webSocketService.isConnected) {
          _webSocketService.connect();
        } else if (!_isInternetConnected) {
          _webSocketService.disconnect();
        }
      });
    }

    //print('🌐 Connectivity changed: $results → Connected: $isConnected');
  }
}
