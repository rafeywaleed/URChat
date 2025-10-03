import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:urchat_back_testing/themes/butter/bfdemo.dart';
import 'package:urchat_back_testing/themes/grid.dart';
import 'package:urchat_back_testing/themes/meteor.dart';
import 'package:urchat_back_testing/themes/theme_manager.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final WebSocketService webSocketService;
  final VoidCallback? onBack;
  final bool isEmbedded;

  const ChatScreen({
    Key? key,
    required this.chatRoom,
    required this.webSocketService,
    required this.onBack,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<Message> _messages = [];

  late ThemeManager _themeManager;

  bool _isLoading = true;
  bool _isTyping = false;
  String _typingUser = '';
  Timer? _typingTimer;
  bool _showScrollToBottom = false;

  late AnimationController _typingAnimationController;
  late AnimationController _messageSendAnimationController;
  late AnimationController _scrollButtonAnimationController;
  late Animation<double> _scrollButtonAnimation;

  final Map<String, Map<String, dynamic>> _typingUsers = {};
  Timer? _typingCleanupTimer;

  @override
  void initState() {
    super.initState();
    // _themeManager = Provider.of<ThemeManager>(context, listen: false);
    // _loadThemePreferences
    _themeManager = Provider.of<ThemeManager>(context, listen: false);
    _loadChatTheme();

    // Initialize animations
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _messageSendAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scrollButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scrollButtonAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadMessages();
    _subscribeToChat();
    _setupScrollListener();
    _startTypingCleanupTimer();
  }

  void _startTypingCleanupTimer() {
    _typingCleanupTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _typingUsers.removeWhere((username, data) {
        return now - data['lastSeenTyping'] >
            3000; // Remove after 3 seconds of inactivity
      });
      if (_typingUsers.isEmpty && _typingUser.isNotEmpty) {
        setState(() {
          _typingUser = '';
        });
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50;

      if (_showScrollToBottom != !isAtBottom) {
        setState(() {
          _showScrollToBottom = !isAtBottom;
        });

        if (_showScrollToBottom) {
          _scrollButtonAnimationController.forward();
        } else {
          _scrollButtonAnimationController.reverse();
        }
      }
    });
  }

  void _loadMessages() async {
    try {
      final messages = await ApiService.getChatMessages(widget.chatRoom.chatId);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _messages.addAll(messages);
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(instant: true);
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeToChat() {
    widget.webSocketService.onMessageReceived = (Message message) {
      if (message.chatId == widget.chatRoom.chatId) {
        _addMessageWithAnimation(message);
      }
    };

    widget.webSocketService.onTyping = (data) {
      final isTyping = data['typing'] as bool;
      final username = data['username'] as String;
      final userProfile = data['userProfile'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          if (isTyping && username != ApiService.currentUsername) {
            _typingUsers[username] = {
              'username': username,
              'profile': userProfile ??
                  {
                    'pfpIndex': '😊',
                    'pfpBg': '#4CAF50',
                    'fullName': username,
                  },
              'lastSeenTyping': DateTime.now().millisecondsSinceEpoch,
            };
            // Update main typing user for display
            if (_typingUsers.length == 1) {
              _typingUser = username;
            } else {
              _typingUser = '${_typingUsers.length} people';
            }
          } else {
            _typingUsers.remove(username);
            if (_typingUsers.isEmpty) {
              _typingUser = '';
            } else if (_typingUsers.length == 1) {
              _typingUser = _typingUsers.keys.first;
            } else {
              _typingUser = '${_typingUsers.length} people';
            }
          }
        });
      }
    };

    widget.webSocketService.subscribeToChatRoom(widget.chatRoom.chatId);
  }

  void _addMessageWithAnimation(Message message) {
    setState(() {
      _messages.add(message);
    });

    // Animate the new message
    _messageSendAnimationController.forward(from: 0.0);
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    widget.webSocketService.sendMessage(widget.chatRoom.chatId, message);
    _messageController.clear();
    _stopTyping();
    _focusNode.unfocus();
  }

  void _startTyping() {
    if (!_isTyping) {
      _isTyping = true;
      widget.webSocketService.sendTyping(widget.chatRoom.chatId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      widget.webSocketService.sendTyping(widget.chatRoom.chatId, false);
    }
    _typingTimer?.cancel();
  }

  void _scrollToBottom({bool instant = false}) {
    if (_scrollController.hasClients && _messages.isNotEmpty) {
      if (instant) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Widget _buildMessageBubble(Message message, int index) {
    final isOwnMessage = message.sender == ApiService.currentUsername;
    final showAvatar = !isOwnMessage;
    final isNewMessage = index == _messages.length - 1;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: isNewMessage
          ? _messageSendAnimationController
          : AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        final scale = isNewMessage
            ? Tween<double>(begin: 0.5, end: 1.0)
                .animate(
                  CurvedAnimation(
                    parent: _messageSendAnimationController,
                    curve: Curves.elasticOut,
                  ),
                )
                .value
            : 1.0;

        final opacity = isNewMessage
            ? Tween<double>(begin: 0.0, end: 1.0)
                .animate(
                  CurvedAnimation(
                    parent: _messageSendAnimationController,
                    curve: Curves.easeIn,
                  ),
                )
                .value
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment:
              isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar) ...[
              _buildUserAvatar(message.sender),
              SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isOwnMessage
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft:
                        isOwnMessage ? Radius.circular(18) : Radius.circular(4),
                    bottomRight:
                        isOwnMessage ? Radius.circular(4) : Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isOwnMessage)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.sender,
                          style: TextStyle(
                            color: isOwnMessage
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isOwnMessage
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            color: isOwnMessage ? Colors.white70 : Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!showAvatar) SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String username) {
    final userData = _typingUsers[username];
    final pfpIndex = userData?['profile']?['pfpIndex'] ?? '😊';
    final pfpBg = userData?['profile']?['pfpBg'] ?? '#4CAF50';

    return CircleAvatar(
      backgroundColor: _parseColor(pfpBg),
      radius: 16,
      child: Text(
        pfpIndex,
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (_typingUsers.isEmpty) return SizedBox();

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Column(
        children: _typingUsers.entries.map((entry) {
          final username = entry.key;
          final userData = entry.value;
          final profile = userData['profile'] as Map<String, dynamic>;

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Row(
              children: [
                _buildUserAvatar(username),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${profile['fullName'] ?? username} is typing',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildAnimatedDots(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        return SizedBox(
          width: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final animation = Tween<double>(
                begin: 0.3,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: _typingAnimationController,
                  curve: Interval(
                    index * 0.2,
                    index * 0.2 + 0.6,
                    curve: Curves.easeInOut,
                  ),
                ),
              );

              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: animation.value,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildScrollToBottomButton() {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _scrollButtonAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 80,
          right: 16,
          child: Transform.translate(
            offset: Offset(0, (1 - _scrollButtonAnimation.value) * 20),
            child: Opacity(
              opacity: _scrollButtonAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: FloatingActionButton.small(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: _scrollToBottom,
        child: Icon(Icons.arrow_downward),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarIconsColor =
        Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: widget.isEmbedded
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Hero(
              tag: 'chat-avatar-${widget.chatRoom.chatId}',
              child: CircleAvatar(
                backgroundColor: _parseColor(widget.chatRoom.pfpBg),
                child: Text(
                  widget.chatRoom.pfpIndex,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.chatName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _typingUser.isNotEmpty
                      ? Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              _typingUsers.length == 1
                                  ? '$_typingUser is typing...'
                                  : '$_typingUser are typing...',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        )
                      : Text(
                          widget.chatRoom.isGroup ? 'Group' : 'Online',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: _showThemeMenu,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  break;
                case 'mute':
                  break;
                case 'clear':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info, color: Color(0xFF5C4033)),
                    SizedBox(width: 8),
                    Text('Chat Info'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off, color: Color(0xFF5C4033)),
                    SizedBox(width: 8),
                    Text('Mute Notifications'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          _background(_selectedTheme),
          Column(
            children: [
              _buildConnectionStatus(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF5C4033)),
                        ),
                      )
                    : _buildMessageList(),
              ),
              _buildMessageInput(),
            ],
          ),
          if (_showScrollToBottom) _buildScrollToBottomButton(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final Map<DateTime, List<Message>> messagesByDate = {};
    for (final message in _messages) {
      final messageDate = DateTime(message.timestamp.year,
          message.timestamp.month, message.timestamp.day);
      if (!messagesByDate.containsKey(messageDate)) {
        messagesByDate[messageDate] = [];
      }
      messagesByDate[messageDate]!.add(message);
    }

    final sortedDates = messagesByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final List<Widget> messageWidgets = [];

    for (final date in sortedDates) {
      final messages = messagesByDate[date]!;

      if (messages.isNotEmpty) {
        messageWidgets.add(_buildDateSeparator(date));
      }

      for (int i = 0; i < messages.length; i++) {
        messageWidgets.add(
            _buildMessageBubble(messages[i], _messages.indexOf(messages[i])));
      }
    }

    messageWidgets.add(_buildTypingIndicator());

    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: EdgeInsets.only(top: 8, bottom: 8),
      itemCount: messageWidgets.length,
      itemBuilder: (context, index) {
        return messageWidgets[index];
      },
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16),
      color: isDark ? theme.cardTheme.color : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.primaryColor),
            onPressed: _onAttachmentPressed,
          ),
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Color(0xFFF5F5DC),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (text) {
                  if (text.isNotEmpty) {
                    _startTyping();
                  } else {
                    _stopTyping();
                  }
                },
                onSubmitted: (text) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            child: CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onAttachmentPressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Photo & Video Library'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('Document'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Location'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat'),
        content:
            Text('Are you sure you want to clear all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Color(0xFF4CAF50);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildConnectionStatus() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(4),
      color: widget.webSocketService.isConnected
          ? Colors.green.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: widget.webSocketService.isConnected
                ? Colors.green
                : Colors.orange,
          ),
          SizedBox(width: 8),
          Text(
            widget.webSocketService.isConnected ? 'Connected' : 'Connecting...',
            style: TextStyle(
              fontSize: 12,
              color: widget.webSocketService.isConnected
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.webSocketService.unsubscribeFromChatRoom(widget.chatRoom.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _typingCleanupTimer?.cancel();
    _typingAnimationController.dispose();
    _messageSendAnimationController.dispose();
    _scrollButtonAnimationController.dispose();
    _stopTyping();
    super.dispose();
  }

  //Theming

  late int _selectedTheme = widget.chatRoom.themeIndex;
  bool _isDarkMode = false;
  final List<String> _themeNames = ['Cute', 'Modern', 'Elegant'];
  late ThemeMode _themeMode =
      widget.chatRoom.isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIdx = prefs.getInt('selectedTheme') ?? 0;
    final modeIndex = prefs.getInt('themeMode') ?? 0;
    final isDark = prefs.getBool('isDarkMode') ?? false;

    if (mounted) {
      setState(() {
        _selectedTheme = themeIdx;
        _themeMode = ThemeMode.values[modeIndex];
        _isDarkMode = isDark;
      });
    }
  }

  Future<void> _changeTheme(int themeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedTheme', themeIndex);
    if (mounted) {
      setState(() {
        _selectedTheme = themeIndex;
      });

      final appState = context.findAncestorStateOfType<_ChatScreenState>();
      appState?._changeTheme(themeIndex);
    }
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    await prefs.setBool('isDarkMode', mode == ThemeMode.dark);

    if (mounted) {
      setState(() {
        _themeMode = mode;
        _isDarkMode = mode == ThemeMode.dark;
      });

      final appState = context.findAncestorStateOfType<_ChatScreenState>();
      appState?._changeThemeMode(mode);
    }
  }

  void _showThemeMenu() {
    final RenderBox appBarBox = context.findRenderObject() as RenderBox;
    final Offset appBarPosition = appBarBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    int tempSelectedTheme = _selectedTheme;
    bool tempIsDarkMode = _isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat Theme Settings'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Mode Toggle
                  ListTile(
                    leading: Icon(
                      tempIsDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text('Dark Mode'),
                    trailing: Switch(
                      value: tempIsDarkMode,
                      onChanged: (value) {
                        setDialogState(() {
                          tempIsDarkMode = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 16),

                  // Theme Style Selection
                  Text(
                    'Theme Style',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_themeNames.length, (index) {
                      return ChoiceChip(
                        label: Text(_themeNames[index]),
                        selected: tempSelectedTheme == index,
                        onSelected: (selected) {
                          setDialogState(() {
                            tempSelectedTheme = index;
                          });
                        },
                      );
                    }),
                  ),

                  SizedBox(height: 20),

                  // Preview Section
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: tempSelectedTheme == 0
                                      ? (tempIsDarkMode
                                          ? Color(0xFFD81B60)
                                          : Color(0xFFFFB6C1))
                                      : tempSelectedTheme == 1
                                          ? (tempIsDarkMode
                                              ? Color(0xFF1976D2)
                                              : Color(0xFF2196F3))
                                          : (tempIsDarkMode
                                              ? Color(0xFF5D4037)
                                              : Color(0xFF795548)),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveThemeSettings(tempSelectedTheme, tempIsDarkMode);
              Navigator.pop(context);
            },
            child: Text('Save Theme'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveThemeSettings(int themeIndex, bool isDarkMode) async {
    try {
      // Update local state
      setState(() {
        _selectedTheme = themeIndex;
        _isDarkMode = isDarkMode;
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      });

      // Update ThemeManager
      _themeManager.changeTheme(themeIndex);
      _themeManager.changeThemeMode(_themeMode);

      // Save to backend
      final chatTheme = {
        'themeIndex': themeIndex,
        'isDark': isDarkMode,
      };

      await ApiService.updateChatTheme(chatTheme, widget.chatRoom.chatId);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving theme: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save theme. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _background(int themeIndex) {
    switch (themeIndex) {
      case 2:
        return Center(
          child: MeteorShower(
              isDark: Theme.of(context).brightness == Brightness.dark,
              numberOfMeteors: 10,
              duration: Duration(seconds: 5),
              child: Container(
                height: MediaQuery.of(context).size.height,
              )),
        );

      case 1:
        return AnimatedGridPattern(
          squares: List.generate(20, (index) => [index % 5, index ~/ 5]),
          gridSize: 40,
          skewAngle: 12,
        );
      case 0:
        return ButterflyDemo();

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _loadChatTheme() async {
    try {
      final chatTheme = await ApiService.getChatTheme(widget.chatRoom.chatId);
      if (chatTheme.containsKey('themeIndex')) {
        final themeIndex = chatTheme['themeIndex'] as int;
        final isDark = chatTheme['isDark'] as bool? ?? false;

        if (mounted) {
          setState(() {
            _selectedTheme = themeIndex;
            _isDarkMode = isDark;
            _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
          });

          // Update ThemeManager
          _themeManager.changeTheme(themeIndex);
          _themeManager.changeThemeMode(_themeMode);
        }
      }
    } catch (e) {
      print('Error loading chat theme: $e');
    }
  }
}
