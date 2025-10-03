import 'package:flutter/material.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/screens/auth_screen.dart';
import 'package:urchat_back_testing/screens/chat_screen.dart';
import 'package:urchat_back_testing/screens/profile_screen.dart';
import 'package:urchat_back_testing/screens/search_delegate.dart';
import 'package:urchat_back_testing/screens/themed_chat_screen.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';

class Homescreen extends StatefulWidget {
  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final Color _beige = const Color(0xFFF5F5DC);
  final Color _brown = const Color(0xFF5C4033);

  List<ChatRoom> _chats = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late WebSocketService _webSocketService;
  String? _selectedChatId;

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
    _initializeWebSocket();
    _loadChats();
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

  void _loadChats() async {
    try {
      final chats = await ApiService.getUserChats();
      // Sort by last activity DESCENDING (newest first)
      chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

      setState(() {
        _chats = chats;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      print('❌ Error loading initial chats: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load chats: $e';
      });
    }
  }

  void _handleNewMessage(Message message) {
    print('💬 New message received: ${message.content}');
    // Don't manually update chat order - wait for WebSocket update from backend
  }

  void _handleChatListUpdate(List<ChatRoom> updatedChats) {
    print(
        '🔄 Real-time chat list update received: ${updatedChats.length} chats');

    print(
        "======================================== Chats================================");
    for (var chat in _chats) {
      print("Chat: ${chat.chatName}, Last Activity: ${chat.lastActivity}");
    }

    print(
        "======================================== Updated Chats================================");
    for (var chat in updatedChats) {
      print("Chat: ${chat.chatName}, Last Activity: ${chat.lastActivity}");
    }

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
        }
      }
    });
  }

  void _loadChatsFromApi() async {
    print('🔄 Reloading chats from API...');
    try {
      final chats = await ApiService.getUserChats();
      setState(() {
        _chats = chats;
        _errorMessage = '';
      });
      print('✅ Reloaded ${chats.length} chats');
    } catch (e) {
      print('❌ Error reloading chats: $e');
      setState(() {
        _errorMessage = 'Failed to reload chats: $e';
      });
    }
  }

  void _selectChat(ChatRoom chat) {
    print('👆 Selecting chat: ${chat.chatName} (ID: ${chat.chatId})');
    setState(() {
      _selectedChatId = chat.chatId;
    });

    _webSocketService.subscribeToChatRoom(chat.chatId);
  }

  void _deselectChat() {
    print('👈 Deselecting chat');
    if (_selectedChatId != null) {
      _webSocketService.unsubscribeFromChatRoom(_selectedChatId!);
    }
    setState(() {
      _selectedChatId = null;
    });
  }

  Widget _buildChatListItem(ChatRoom chat) {
    final isSelected = _selectedChatId == chat.chatId;

    return Hero(
      tag: chat.chatId,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                offset: Offset(0, 1),
              ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _parseColor(chat.pfpBg),
            child: Text(
              chat.pfpIndex,
              style: TextStyle(
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

  Widget _buildChatsList() {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: _beige,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Connection status bar
          Container(
            padding: EdgeInsets.all(12),
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
                SizedBox(width: 8),
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

          // Chats list
          Expanded(
            child: RefreshIndicator(
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
                          SizedBox(height: 16),
                          Text(
                            'No chats yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: _brown.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
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
              SizedBox(height: 24),
              Text(
                'Welcome to URChat',
                style: TextStyle(
                  fontSize: 24,
                  color: _brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Select a chat from the list to start messaging',
                style: TextStyle(
                  fontSize: 16,
                  color: _brown.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 8),
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

  Widget _buildSelectedChatView() {
    if (_selectedChat == null) return _buildEmptyChatView();

    return Expanded(
      child: ThemedChatScreen(
        key: Key(_selectedChatId!),
        chatRoom: _selectedChat!,
        webSocketService: _webSocketService,
        onBack: _deselectChat,
        isEmbedded: true,
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      print('⚠️ Error parsing color: $colorString, using default');
      return Color(0xFF4CAF50);
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
        actions: [
          IconButton(
            icon: Icon(Icons.wifi_find),
            onPressed: () {
              print('🔍 === MANUAL WEB SOCKET TEST ===');
              print('   Current chats: ${_chats.length}');
              print('   WebSocket connected: ${_webSocketService.isConnected}');
              print('   Selected chat: $_selectedChatId');

              // Force a chat list reload to test
              _loadChatsFromApi();

              // Test if we can receive messages
              print('   Testing message reception...');
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
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
                    SizedBox(width: 8),
                    Text('Profile'),
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
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_brown),
                  ),
                  SizedBox(height: 16),
                  Text('Loading chats...'),
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
                      SizedBox(height: 16),
                      const Text(
                        'Error loading chats',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChatsFromApi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brown,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildChatsList(),
                    _selectedChatId != null
                        ? _buildSelectedChatView()
                        : _buildEmptyChatView(),
                  ],
                ),
      floatingActionButton: _selectedChatId == null
          ? FloatingActionButton(
              backgroundColor: _brown,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                ).then((_) {
                  _loadChatsFromApi();
                });
              },
              child: Icon(Icons.search),
            )
          : null,
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
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
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
    Future.delayed(Duration(seconds: 3), () {
      if (_webSocketService.isConnected) {
        print('🎉 WebSocket is connected and ready!');
        print('   📡 Should receive updates on: /user/queue/chats/update');
      } else {
        print('❌ WebSocket failed to connect');
      }
    });
  }
}
