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
import 'package:urchat_back_testing/screens/group_management_screen.dart';
import 'package:urchat_back_testing/screens/group_pfp_dialog.dart';
import 'package:urchat_back_testing/screens/new_group.dart';
import 'package:urchat_back_testing/screens/profile_screen.dart';
import 'package:urchat_back_testing/screens/search_delegate.dart';
import 'package:urchat_back_testing/screens/user_profile,dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/local_cache_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:urchat_back_testing/widgets/deletion_dialog.dart';
import 'package:urchat_back_testing/widgets/pixle_circle.dart';

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
      onMessageDeleted:
          _handleMessageDeleted, // NEW: Add message deletion handler
      onChatDeleted: _handleChatDeleted, // NEW: Add chat deletion handler
    );

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
      'type':
          'message', // NEW: Add type to distinguish from deletion notifications
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
        onLongPress: () => _showChatOptions(chat),
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

  // // NEW: Show chat options menu
  void _showChatOptions(ChatRoom chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NesContainer(
          // margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with chat info
              NesContainer(
                child: Row(
                  children: [
                    PixelCircle(
                      color: _parseColor(chat.pfpBg),
                      label: chat.pfpIndex,
                      // size: 40,
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
                              color: _accent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chat.isGroup ? 'Group Chat' : 'Direct Message',
                            style: GoogleFonts.vt323(
                              fontSize: 14,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 6,
              ),

              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      ),
                      const SizedBox(height: 8),
                      _buildOptionButton(
                        icon: Icons.delete,
                        title: 'Delete Group',
                        color: Colors.red,
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteChat(chat);
                        },
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
                      ),
                    const SizedBox(height: 8),
                    _buildOptionButton(
                      icon: Icons.cancel,
                      title: 'Cancel',
                      color: Colors.grey,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Helper method for option buttons
  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return NesButton(
      type: _getButtonType(color),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.pressStart2p(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

// Helper to determine button type based on color
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
              NesRunningText(
                text: "Welcome to URChat",
              ),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _exitAppDialog(),
      child: Scaffold(
          backgroundColor: _beige,
          appBar: _showChatScreen && _isMobileScreen ? null : _buildAppBar(),
          body: _isLoading
              ? _buildLoadingState()
              : (_isMobileScreen
                  ? _buildMobileLayout()
                  : _buildDesktopLayout()),
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
