// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:urchat/model/message.dart';
// import 'package:urchat/service/api_service.dart';
// import 'package:urchat/service/websocket_service.dart';
// import 'package:urchat/themes/butter/bfdemo.dart';
// import 'package:urchat/themes/grid.dart';
// import 'package:urchat/themes/meteor.dart';

// import '../model/chat_room.dart';

// class ChatScreen extends StatefulWidget {
//   final ChatRoom chatRoom;
//   final WebSocketService webSocketService;
//   final VoidCallback? onBack;
//   final bool isEmbedded;

//   const ChatScreen({
//     Key? key,
//     required this.chatRoom,
//     required this.webSocketService,
//     required this.onBack,
//     this.isEmbedded = false,
//   }) : super(key: key);

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final FocusNode _focusNode = FocusNode();
//   final List<Message> _messages = [];

//   bool _isLoading = true;
//   bool _isTyping = false;
//   String _typingUser = '';
//   Timer? _typingTimer;
//   bool _showScrollToBottom = false;

//   late AnimationController _typingAnimationController;
//   late AnimationController _messageSendAnimationController;
//   late AnimationController _scrollButtonAnimationController;
//   late Animation<double> _scrollButtonAnimation;

//   final Map<String, Map<String, dynamic>> _typingUsers = {};
//   Timer? _typingCleanupTimer;

//   int _currentPage = 0;
//   int _pageSize = 20;
//   bool _hasMoreMessages = true;
//   bool _isLoadingMore = false;
//   final List<String> _themeNames = ['Simple' 'Modern', 'Cute', 'Elegant'];
//   late final Widget _backgroundWidget;

//   late int _selectedTheme;
//   late bool _isDarkMode;

//   @override
//   void initState() {
//     super.initState();

//     _backgroundWidget = _getBackgroundByTheme(
//         widget.chatRoom.themeIndex, widget.chatRoom.isDark);

//     // Initialize chat-specific theme from chatRoom
//     _selectedTheme = widget.chatRoom.themeIndex;
//     _isDarkMode = widget.chatRoom.isDark;

//     // _loadChatTheme();

//     _typingAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     )..repeat(reverse: true);

//     _messageSendAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     _scrollButtonAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );

//     _scrollButtonAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _scrollButtonAnimationController,
//       curve: Curves.easeInOut,
//     ));

//     _subscribeToChat();
//     _setupScrollListener();
//     _startTypingCleanupTimer();
//     _loadInitialMessages();
//   }

//   @override
//   void didUpdateWidget(ChatScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (oldWidget.chatRoom.themeIndex != widget.chatRoom.themeIndex ||
//         oldWidget.chatRoom.isDark != widget.chatRoom.isDark) {
//       setState(() {
//         _backgroundWidget = _getBackgroundByTheme(
//             widget.chatRoom.themeIndex, widget.chatRoom.isDark);
//       });
//     }
//   }

//   void _loadInitialMessages() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _currentPage = 0;
//         _hasMoreMessages = true;
//       });

//       final messages = await ApiService.getPaginatedMessages(
//           widget.chatRoom.chatId, 0, _pageSize);

//       messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

//       setState(() {
//         _messages.clear();
//         _messages.addAll(messages);
//         _isLoading = false;
//         _hasMoreMessages = messages.length == _pageSize;
//       });

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _scrollToBottom(instant: true);
//       });
//     } catch (e) {
//       print('Error loading messages: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _loadMoreMessages() async {
//     if (_isLoadingMore || !_hasMoreMessages) return;

//     try {
//       setState(() {
//         _isLoadingMore = true;
//       });

//       final nextPage = _currentPage + 1;
//       final messages = await ApiService.getPaginatedMessages(
//           widget.chatRoom.chatId, nextPage, _pageSize);

//       if (messages.isNotEmpty) {
//         messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

//         setState(() {
//           _messages.insertAll(0, messages);
//           _currentPage = nextPage;
//           _hasMoreMessages = messages.length == _pageSize;
//         });
//       } else {
//         setState(() {
//           _hasMoreMessages = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading more messages: $e');
//     } finally {
//       setState(() {
//         _isLoadingMore = false;
//       });
//     }
//   }

//   void _startTypingCleanupTimer() {
//     _typingCleanupTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       final now = DateTime.now().millisecondsSinceEpoch;
//       _typingUsers.removeWhere((username, data) {
//         return now - data['lastSeenTyping'] > 3000;
//       });
//       if (_typingUsers.isEmpty && _typingUser.isNotEmpty) {
//         setState(() {
//           _typingUser = '';
//         });
//       }
//     });
//   }

//   void _setupScrollListener() {
//     _scrollController.addListener(() {
//       final isAtBottom = _scrollController.position.pixels >=
//           _scrollController.position.maxScrollExtent - 50;

//       if (_showScrollToBottom != !isAtBottom) {
//         setState(() {
//           _showScrollToBottom = !isAtBottom;
//         });

//         if (_showScrollToBottom) {
//           _scrollButtonAnimationController.forward();
//         } else {
//           _scrollButtonAnimationController.reverse();
//         }
//       }

//       if (_scrollController.position.pixels <= 100 &&
//           !_isLoadingMore &&
//           _hasMoreMessages) {
//         _loadMoreMessages();
//       }
//     });
//   }

//   void _subscribeToChat() {
//     widget.webSocketService.onMessageReceived = (Message message) {
//       if (message.chatId == widget.chatRoom.chatId) {
//         _addMessageWithAnimation(message);
//       }
//     };

//     widget.webSocketService.onTyping = (data) {
//       final isTyping = data['typing'] as bool;
//       final username = data['username'] as String;
//       final userProfile = data['userProfile'] as Map<String, dynamic>?;

//       if (mounted) {
//         setState(() {
//           if (isTyping && username != ApiService.currentUsername) {
//             _typingUsers[username] = {
//               'username': username,
//               'profile': userProfile ??
//                   {
//                     'pfpIndex': '😊',
//                     'pfpBg': '#4CAF50',
//                     'fullName': username,
//                   },
//               'lastSeenTyping': DateTime.now().millisecondsSinceEpoch,
//             };
//             if (_typingUsers.length == 1) {
//               _typingUser = username;
//             } else {
//               _typingUser = '${_typingUsers.length} people';
//             }
//           } else {
//             _typingUsers.remove(username);
//             if (_typingUsers.isEmpty) {
//               _typingUser = '';
//             } else if (_typingUsers.length == 1) {
//               _typingUser = _typingUsers.keys.first;
//             } else {
//               _typingUser = '${_typingUsers.length} people';
//             }
//           }
//         });
//       }
//     };

//     widget.webSocketService.subscribeToChatRoom(widget.chatRoom.chatId);
//   }

//   void _addMessageWithAnimation(Message message) {
//     setState(() {
//       _messages.add(message);
//     });

//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 100) {
//       _scrollToBottom();
//     }
//   }

//   void _sendMessage() {
//     final message = _messageController.text.trim();
//     if (message.isEmpty) return;

//     widget.webSocketService.sendMessage(widget.chatRoom.chatId, message);
//     _messageController.clear();
//     _stopTyping();
//   }

//   void _startTyping() {
//     if (!_isTyping) {
//       _isTyping = true;
//       widget.webSocketService.sendTyping(widget.chatRoom.chatId, true);
//     }

//     _typingTimer?.cancel();
//     _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
//   }

//   void _stopTyping() {
//     if (_isTyping) {
//       _isTyping = false;
//       widget.webSocketService.sendTyping(widget.chatRoom.chatId, false);
//     }
//     _typingTimer?.cancel();
//   }

//   void _scrollToBottom({bool instant = false}) {
//     if (_scrollController.hasClients && _messages.isNotEmpty) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (instant) {
//           _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//         } else {
//           _scrollController.animateTo(
//             _scrollController.position.maxScrollExtent,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//         }
//       });
//     }
//   }

//   Widget _buildMessageBubble(Message message, int index) {
//     final isOwnMessage = message.sender == ApiService.currentUsername;
//     final showAvatar = !isOwnMessage;
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
//       child: Row(
//         mainAxisAlignment:
//             isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (showAvatar) ...[
//             _buildUserAvatar(message.sender),
//             const SizedBox(width: 8),
//           ],
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//               decoration: BoxDecoration(
//                 color: isOwnMessage
//                     ? theme.colorScheme.primary
//                     : theme.colorScheme.surface.withOpacity(0.9),
//                 borderRadius: BorderRadius.only(
//                   topLeft: const Radius.circular(18),
//                   topRight: const Radius.circular(18),
//                   bottomLeft: isOwnMessage
//                       ? const Radius.circular(18)
//                       : const Radius.circular(4),
//                   bottomRight: isOwnMessage
//                       ? const Radius.circular(4)
//                       : const Radius.circular(18),
//                 ),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 2,
//                     offset: Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (!isOwnMessage)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 4),
//                       child: Text(
//                         message.sender,
//                         style: TextStyle(
//                           color: isOwnMessage
//                               ? Colors.white
//                               : theme.colorScheme.onSurface,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   Text(
//                     message.content,
//                     style: TextStyle(
//                       color: isOwnMessage
//                           ? Colors.white
//                           : (isDark ? Colors.white : Colors.black87),
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         _formatMessageTime(message.timestamp),
//                         style: TextStyle(
//                           color: isOwnMessage ? Colors.white70 : Colors.grey,
//                           fontSize: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (!showAvatar) const SizedBox(width: 8),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserAvatar(String username) {
//     final userData = _typingUsers[username];
//     final pfpIndex = userData?['profile']?['pfpIndex'] ?? '😊';
//     final pfpBg = userData?['profile']?['pfpBg'] ?? '#4CAF50';

//     return CircleAvatar(
//       backgroundColor: _parseColor(pfpBg),
//       radius: 16,
//       child: Text(
//         pfpIndex,
//         style: const TextStyle(fontSize: 12, color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildDateSeparator(DateTime date) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Center(
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade300,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Text(
//             _formatDate(date),
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade700,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTypingIndicator() {
//     if (_typingUsers.isEmpty) return const SizedBox();

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       child: Column(
//         children: _typingUsers.entries.map((entry) {
//           final username = entry.key;
//           final userData = entry.value;
//           final profile = userData['profile'] as Map<String, dynamic>;

//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
//             child: Row(
//               children: [
//                 _buildUserAvatar(username),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 2,
//                         offset: Offset(0, 1),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         '${profile['fullName'] ?? username} is typing',
//                         style: const TextStyle(
//                           color: Colors.grey,
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       _buildAnimatedDots(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildAnimatedDots() {
//     return AnimatedBuilder(
//       animation: _typingAnimationController,
//       builder: (context, child) {
//         return SizedBox(
//           width: 24,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: List.generate(3, (index) {
//               final animation = Tween<double>(
//                 begin: 0.3,
//                 end: 1.0,
//               ).animate(
//                 CurvedAnimation(
//                   parent: _typingAnimationController,
//                   curve: Interval(
//                     index * 0.2,
//                     index * 0.2 + 0.6,
//                     curve: Curves.easeInOut,
//                   ),
//                 ),
//               );

//               return AnimatedBuilder(
//                 animation: animation,
//                 builder: (context, child) {
//                   return Transform.scale(
//                     scale: animation.value,
//                     child: Container(
//                       width: 6,
//                       height: 6,
//                       decoration: const BoxDecoration(
//                         color: Colors.grey,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             }),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildScrollToBottomButton() {
//     final theme = Theme.of(context);

//     return AnimatedBuilder(
//       animation: _scrollButtonAnimation,
//       builder: (context, child) {
//         return Positioned(
//           bottom: 80,
//           right: 16,
//           child: Transform.translate(
//             offset: Offset(0, (1 - _scrollButtonAnimation.value) * 20),
//             child: Opacity(
//               opacity: _scrollButtonAnimation.value,
//               child: child,
//             ),
//           ),
//         );
//       },
//       child: FloatingActionButton.small(
//         backgroundColor: theme.primaryColor,
//         foregroundColor: Colors.white,
//         onPressed: _scrollToBottom,
//         child: const Icon(Icons.arrow_downward),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: Colors.black87,
//       appBar: AppBar(
//         leading: widget.isEmbedded
//             ? IconButton(
//                 icon: const Icon(Icons.arrow_back),
//                 onPressed: widget.onBack,
//               )
//             : null,
//         backgroundColor: theme.primaryColor,
//         foregroundColor: Colors.white,
//         title: Row(
//           children: [
//             Hero(
//               tag: 'chat-avatar-${widget.chatRoom.chatId}',
//               child: CircleAvatar(
//                 backgroundColor: _parseColor(widget.chatRoom.pfpBg),
//                 child: Text(
//                   widget.chatRoom.pfpIndex,
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.chatRoom.chatName,
//                   style: const TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   child: _typingUser.isNotEmpty
//                       ? Row(
//                           children: [
//                             const SizedBox(width: 4),
//                             Text(
//                               _typingUsers.length == 1
//                                   ? '$_typingUser is typing...'
//                                   : '$_typingUser are typing...',
//                               style: const TextStyle(
//                                   fontSize: 12, color: Colors.white70),
//                             ),
//                           ],
//                         )
//                       : Text(
//                           widget.chatRoom.isGroup ? 'Group' : 'Online',
//                           style: const TextStyle(
//                               fontSize: 12, color: Colors.white70),
//                         ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.palette),
//             onPressed: _showThemeMenu,
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           _backgroundWidget,
//           Column(
//             children: [
//               _buildConnectionStatus(),
//               Expanded(
//                 child: _isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : _buildMessageList(),
//               ),
//               _buildMessageInput(),
//             ],
//           ),
//           if (_showScrollToBottom) _buildScrollToBottomButton(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageList() {
//     final Map<DateTime, List<Message>> messagesByDate = {};
//     for (final message in _messages) {
//       final messageDate = DateTime(message.timestamp.year,
//           message.timestamp.month, message.timestamp.day);
//       if (!messagesByDate.containsKey(messageDate)) {
//         messagesByDate[messageDate] = [];
//       }
//       messagesByDate[messageDate]!.add(message);
//     }

//     final sortedDates = messagesByDate.keys.toList()
//       ..sort((a, b) => a.compareTo(b));

//     final List<Widget> messageWidgets = [];

//     if (_isLoadingMore) {
//       messageWidgets.add(
//         const Padding(
//           padding: EdgeInsets.all(16),
//           child: Center(
//             child: CircularProgressIndicator(),
//           ),
//         ),
//       );
//     }

//     for (final date in sortedDates) {
//       final messages = messagesByDate[date]!;

//       if (messages.isNotEmpty) {
//         messageWidgets.add(_buildDateSeparator(date));
//       }

//       for (int i = 0; i < messages.length; i++) {
//         messageWidgets.add(
//             _buildMessageBubble(messages[i], _messages.indexOf(messages[i])));
//       }
//     }

//     messageWidgets.add(_buildTypingIndicator());

//     return ListView.builder(
//       controller: _scrollController,
//       reverse: false,
//       padding: const EdgeInsets.only(top: 8, bottom: 8),
//       itemCount: messageWidgets.length,
//       itemBuilder: (context, index) {
//         return messageWidgets[index];
//       },
//     );
//   }

//   Widget _buildMessageInput() {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: isDark ? theme.cardTheme.color : Colors.white,
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               child: TextField(
//                 controller: _messageController,
//                 focusNode: _focusNode,
//                 maxLines: 5,
//                 minLines: 1,
//                 decoration: InputDecoration(
//                   hintText: 'Type a message...',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(24),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                   fillColor:
//                       isDark ? Colors.grey.shade800 : const Color(0xFFF5F5DC),
//                   contentPadding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 ),
//                 onChanged: (text) {
//                   if (text.isNotEmpty) {
//                     _startTyping();
//                   } else {
//                     _stopTyping();
//                   }
//                 },
//                 onSubmitted: (text) => _sendMessage(),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             child: CircleAvatar(
//               backgroundColor: theme.primaryColor,
//               child: IconButton(
//                 icon: const Icon(Icons.send, color: Colors.white),
//                 onPressed: _sendMessage,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _parseColor(String colorString) {
//     try {
//       return Color(int.parse(colorString.replaceAll('#', '0xFF')));
//     } catch (e) {
//       return const Color(0xFF4CAF50);
//     }
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = DateTime(now.year, now.month, now.day - 1);
//     final messageDate = DateTime(date.year, date.month, date.day);

//     if (messageDate == today) {
//       return 'Today';
//     } else if (messageDate == yesterday) {
//       return 'Yesterday';
//     } else {
//       return '${date.day}/${date.month}/${date.year}';
//     }
//   }

//   String _formatMessageTime(DateTime timestamp) {
//     return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
//   }

//   Widget _buildConnectionStatus() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       padding: const EdgeInsets.all(4),
//       color: widget.webSocketService.isConnected
//           ? Colors.green.withOpacity(0.1)
//           : Colors.orange.withOpacity(0.1),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.circle,
//             size: 8,
//             color: widget.webSocketService.isConnected
//                 ? Colors.green
//                 : Colors.orange,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             widget.webSocketService.isConnected ? 'Connected' : 'Connecting...',
//             style: TextStyle(
//               fontSize: 12,
//               color: widget.webSocketService.isConnected
//                   ? Colors.green
//                   : Colors.orange,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     widget.webSocketService.unsubscribeFromChatRoom(widget.chatRoom.chatId);
//     _messageController.dispose();
//     _scrollController.dispose();
//     _focusNode.dispose();
//     _typingTimer?.cancel();
//     _typingCleanupTimer?.cancel();
//     _typingAnimationController.dispose();
//     _messageSendAnimationController.dispose();
//     _scrollButtonAnimationController.dispose();
//     _stopTyping();
//     super.dispose();
//   }

//   // THEMING METHODS
//   Future<void> _changeTheme(int themeIndex) async {
//     try {
//       await ApiService.updateChatTheme({
//         'themeIndex': themeIndex,
//         'isDark': widget.chatRoom.isDark,
//       }, widget.chatRoom.chatId);

//       // Force Homescreen to reload chat data to reflect theme changes
//       // This will trigger a rebuild of ChatThemeWrapper

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Theme changed to ${_themeNames[themeIndex]}'),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       print('Error updating chat theme: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to change theme'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _toggleDarkMode() async {
//     try {
//       final newDarkMode = !widget.chatRoom.isDark;

//       await ApiService.updateChatTheme({
//         'themeIndex': widget.chatRoom.themeIndex,
//         'isDark': newDarkMode,
//       }, widget.chatRoom.chatId);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Switched to ${newDarkMode ? 'Dark' : 'Light'} mode'),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       print('Error toggling dark mode: $e');
//     }
//   }

//   void _showThemeMenu() {
//     final RenderBox appBarBox = context.findRenderObject() as RenderBox;
//     final Offset appBarPosition = appBarBox.localToGlobal(Offset.zero);
//     final screenWidth = MediaQuery.of(context).size.width;

//     showMenu(
//       context: context,
//       position: RelativeRect.fromLTRB(
//         screenWidth - 220,
//         appBarPosition.dy + appBarBox.size.height,
//         16,
//         0,
//       ),
//       items: [
//         // Dark/Light mode toggle
//         PopupMenuItem(
//           onTap: _toggleDarkMode,
//           child: ListTile(
//             leading: Icon(
//               widget.chatRoom.isDark ? Icons.light_mode : Icons.dark_mode,
//               color: Theme.of(context).iconTheme.color,
//             ),
//             title: Text(
//                 widget.chatRoom.isDark ? 'Switch to Light' : 'Switch to Dark'),
//           ),
//         ),
//         // Theme style selector
//         PopupMenuItem(
//           enabled: false,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Theme Style',
//                 style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//               ),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 8,
//                 children: List.generate(_themeNames.length, (index) {
//                   return ChoiceChip(
//                     label: Text(_themeNames[index]),
//                     selected: widget.chatRoom.themeIndex == index,
//                     onSelected: (selected) {
//                       if (selected) {
//                         Navigator.pop(context);
//                         _changeTheme(index);
//                       }
//                     },
//                   );
//                 }),
//               ),
//             ],
//           ),
//         ),
//         // Current theme info
//         PopupMenuItem(
//           enabled: false,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 8),
//               Text(
//                 'Current: ${_themeNames[widget.chatRoom.themeIndex]} • ${widget.chatRoom.isDark ? 'Dark' : 'Light'}',
//                 style: TextStyle(
//                   color: Theme.of(context).primaryColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       elevation: 8,
//     );
//   }

//   // Widget _background() {
//   //   return _getBackgroundByTheme(_selectedTheme);
//   // }

//   Widget _getBackgroundByTheme(int themeIndex, bool isDark) {
//     switch (themeIndex) {
//       case 2: // Elegant
//         return MeteorShower(
//           key: ValueKey('elegant-$isDark'), // Important: key prevents reset
//           isDark: isDark,
//           numberOfMeteors: 10,
//           duration: const Duration(seconds: 5),
//           child: Container(),
//         );
//       case 1: // Modern
//         return AnimatedGridPattern(
//           key: ValueKey('modern-$isDark'),
//           squares: List.generate(20, (index) => [index % 5, index ~/ 5]),
//           gridSize: 40,
//           skewAngle: 12,
//         );
//       case 3: // Cute
//         return ButterflyDemo(
//           key: ValueKey('cute-$isDark'),
//         );
//       case 0: // Simple (new)
//       default:
//         return Container(
//             key: ValueKey('simple-$isDark'),
//             color: Theme.of(context).scaffoldBackgroundColor);
//     }
//   }

//   // Future<void> _loadChatTheme() async {
//   //   try {
//   //     final chatTheme = await ApiService.getChatTheme(widget.chatRoom.chatId);
//   //     if (chatTheme.containsKey('themeIndex')) {
//   //       final themeIndex = chatTheme['themeIndex'] as int;
//   //       final isDark = chatTheme['isDark'] as bool? ?? false;

//   //       if (mounted) {
//   //         setState(() {
//   //           _selectedTheme = themeIndex;
//   //           _isDarkMode = isDark;
//   //         });
//   //       }
//   //     }
//   //   } catch (e) {
//   //     print('Error loading chat theme: $e');
//   //   }
//   // }
// }
