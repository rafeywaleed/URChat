import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:urchat_back_testing/themes/butter/bfdemo.dart';
import 'package:urchat_back_testing/themes/grid.dart';
import 'package:urchat_back_testing/themes/meteor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatCacheService {
  static const String _themePrefix = 'chat_theme_';
  static const String _messagesPrefix = 'chat_messages_';
  static const int _maxCachedMessages = 20;

  // Save theme for a specific chat
  static Future<void> saveChatTheme(
      String chatId, int themeIndex, bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeData = {
        'themeIndex': themeIndex,
        'isDark': isDark,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('$_themePrefix$chatId', json.encode(themeData));
    } catch (e) {
      print('❌ Failed to save theme to cache: $e');
    }
  }

  // Load theme for a specific chat
  static Future<Map<String, dynamic>?> loadChatTheme(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeJson = prefs.getString('$_themePrefix$chatId');
      if (themeJson != null) {
        return json.decode(themeJson);
      }
    } catch (e) {
      print('❌ Failed to load theme from cache: $e');
    }
    return null;
  }

  // Save initial messages for a specific chat
  static Future<void> saveChatMessages(
      String chatId, List<Message> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Take only the last _maxCachedMessages messages
      final messagesToSave = messages.length > _maxCachedMessages
          ? messages.sublist(messages.length - _maxCachedMessages)
          : messages;

      final messagesData = {
        'messages': messagesToSave.map((msg) => msg.toJson()).toList(),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'count': messagesToSave.length,
      };

      await prefs.setString(
          '$_messagesPrefix$chatId', json.encode(messagesData));
    } catch (e) {
      print('❌ Failed to save messages to cache: $e');
    }
  }

  // Load messages for a specific chat
  static Future<List<Message>?> loadChatMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('$_messagesPrefix$chatId');
      if (messagesJson != null) {
        final messagesData = json.decode(messagesJson);
        final List<dynamic> messagesList = messagesData['messages'];
        return messagesList
            .map((msgJson) => Message.fromJson(msgJson))
            .toList();
      }
    } catch (e) {
      print('❌ Failed to load messages from cache: $e');
    }
    return null;
  }

  // Clear cache for a specific chat
  static Future<void> clearChatCache(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_themePrefix$chatId');
      await prefs.remove('$_messagesPrefix$chatId');
    } catch (e) {
      print('❌ Failed to clear chat cache: $e');
    }
  }

  // Get cache info for a specific chat
  static Future<Map<String, dynamic>> getCacheInfo(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeJson = prefs.getString('$_themePrefix$chatId');
      final messagesJson = prefs.getString('$_messagesPrefix$chatId');

      return {
        'hasTheme': themeJson != null,
        'hasMessages': messagesJson != null,
        'themeLastUpdated':
            themeJson != null ? json.decode(themeJson)['lastUpdated'] : null,
        'messagesLastUpdated': messagesJson != null
            ? json.decode(messagesJson)['lastUpdated']
            : null,
        'cachedMessagesCount':
            messagesJson != null ? json.decode(messagesJson)['count'] : 0,
      };
    } catch (e) {
      print('❌ Failed to get cache info: $e');
      return {};
    }
  }
}

class URChatApp extends StatefulWidget {
  final ChatRoom chatRoom;
  final WebSocketService webSocketService;
  final VoidCallback? onBack;

  const URChatApp({
    required this.chatRoom,
    required this.webSocketService,
    this.onBack,
    super.key,
  });

  @override
  State<URChatApp> createState() => _URChatAppState();
}

class _URChatAppState extends State<URChatApp> {
  late ThemeMode _themeMode;
  late int _selectedTheme;
  late bool _isDarkMode;

  // Add these to remember the last committed theme/mode
  late int _committedTheme;
  late ThemeMode _committedThemeMode;

  final List<ThemeData> _lightThemes = [];
  final List<ThemeData> _darkThemes = [];
  final List<String> _themeNames = ['Cute', 'Modern', 'Elegant'];

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.chatRoom.themeIndex ?? 0;
    _isDarkMode = widget.chatRoom.isDark ?? true;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;

    // Save committed values
    _committedTheme = _selectedTheme;
    _committedThemeMode = _themeMode;

    _initializeThemes();

    // Load theme from cache first, then API
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      // First try to load from cache
      final cachedTheme =
          await ChatCacheService.loadChatTheme(widget.chatRoom.chatId);

      if (cachedTheme != null) {
        setState(() {
          _selectedTheme = cachedTheme['themeIndex'] ?? 0;
          _isDarkMode = cachedTheme['isDark'] ?? true;
          _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
          _committedTheme = _selectedTheme;
          _committedThemeMode = _themeMode;
        });
      }

      // Then load from API to check for updates
      final themeData = await ApiService.getChatTheme(widget.chatRoom.chatId);
      if (themeData.containsKey('themeIndex') &&
          themeData.containsKey('isDark')) {
        final apiThemeIndex = themeData['themeIndex'] ?? 0;
        final apiIsDark = themeData['isDark'] ?? true;

        // Only update if different from cache
        if (apiThemeIndex != _selectedTheme || apiIsDark != _isDarkMode) {
          setState(() {
            _selectedTheme = apiThemeIndex;
            _isDarkMode = apiIsDark;
            _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
            _committedTheme = _selectedTheme;
            _committedThemeMode = _themeMode;
          });

          // Update cache with fresh data
          await ChatCacheService.saveChatTheme(
              widget.chatRoom.chatId, _selectedTheme, _isDarkMode);
        }
      }
    } catch (e) {
      print('❌ Failed to load chat theme: $e');
      // Fallback to defaults already set in initState
    }
  }

  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
      _isDarkMode = mode == ThemeMode.dark;
    });
  }

  void _changeTheme(int index) {
    setState(() {
      _selectedTheme = index;
    });
  }

  // Call this to commit the previewed theme/mode
  Future<void> _commitThemeChanges() async {
    setState(() {
      _committedTheme = _selectedTheme;
      _committedThemeMode = _themeMode;
    });

    try {
      // Save to API first
      await ApiService.updateChatTheme(
        {
          "themeIndex": _selectedTheme,
          "isDark": _isDarkMode,
        },
        widget.chatRoom.chatId,
      );

      // Only save to cache if API call was successful
      await ChatCacheService.saveChatTheme(
          widget.chatRoom.chatId, _selectedTheme, _isDarkMode);

      print('✅ Chat theme updated on server and cache');
    } catch (e) {
      print('❌ Failed to update chat theme: $e');
      // Revert changes if API call fails
      _revertThemeChanges();
      rethrow;
    }
  }

  // Call this to revert to the last committed theme/mode
  void _revertThemeChanges() {
    setState(() {
      _selectedTheme = _committedTheme;
      _themeMode = _committedThemeMode;
      _isDarkMode = _themeMode == ThemeMode.dark;
    });
  }

  void _initializeThemes() {
    _lightThemes.clear();
    _darkThemes.clear();

    // Theme 0: Cute
    _lightThemes.add(ThemeData(
      primaryColor: const Color(0xFFE91E63),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE91E63),
        secondary: Color(0xFFEC407A),
        surface: Color(0xFFFFF5F7),
        background: Color(0xFFFFF9FB),
        onSurface: Color(0xFF333333),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFF333333),
        displayColor: const Color(0xFF333333),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE91E63),
        elevation: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ));

    _darkThemes.add(ThemeData(
      primaryColor: const Color(0xFFEC407A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFEC407A),
        secondary: Color(0xFFF06292),
        surface: Color(0xFF1E1E2E),
        background: Color(0xFF121212),
        onSurface: Color(0xFFE0E0E0),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E2E),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFEC407A),
        elevation: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFEC407A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ));

    // Theme 1: Modern
    _lightThemes.add(ThemeData(
      primaryColor: const Color(0xFF2E4057),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2E4057),
        secondary: Color(0xFF4A6FA5),
        surface: Color(0xFFF8F9FA),
        background: Color(0xFFFFFFFF),
        onSurface: Color(0xFF212529),
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFF212529),
        displayColor: const Color(0xFF212529),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2E4057),
        elevation: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2E4057),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ));

    _darkThemes.add(ThemeData(
      primaryColor: const Color(0xFF4A6FA5),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4A6FA5),
        secondary: Color(0xFF6B8CBC),
        surface: Color(0xFF1A1A2E),
        background: Color(0xFF121212),
        onSurface: Color(0xFFE0E0E0),
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1A1A2E),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4A6FA5),
        elevation: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF4A6FA5),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ));

    // Theme 2: Elegant
    _lightThemes.add(ThemeData(
      primaryColor: const Color(0xFF5D737E),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5D737E),
        secondary: Color(0xFF7A8B99),
        surface: Color(0xFFF8F9FA),
        background: Color(0xFFFFFFFF),
        onSurface: Color(0xFF3A3A3A),
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFF3A3A3A),
        displayColor: const Color(0xFF3A3A3A),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF5D737E),
        elevation: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF5D737E),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ));

    _darkThemes.add(ThemeData(
      primaryColor: const Color(0xFF7A8B99),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7A8B99),
        secondary: Color(0xFF5D737E),
        surface: Color(0xFF1E2A32),
        background: Color(0xFF121A21),
        onSurface: Color(0xFFE0E3E7),
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFFE0E3E7),
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E2A32),
        margin: const EdgeInsets.all(8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7A8B99),
        elevation: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF7A8B99),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URChat',
      debugShowCheckedModeBanner: false,
      theme: _lightThemes[_selectedTheme],
      darkTheme: _darkThemes[_selectedTheme],
      themeMode: _themeMode,
      home: ChatScreen(
        chatRoom: widget.chatRoom,
        webSocketService: widget.webSocketService,
        onBack: widget.onBack,
        onThemeModeChanged: _changeThemeMode,
        onThemeChanged: _changeTheme,
        onThemeSave: _commitThemeChanges,
        onThemeCancel: _revertThemeChanges,
        isDarkMode: _isDarkMode,
        selectedTheme: _selectedTheme,
        themeNames: _themeNames,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final WebSocketService webSocketService;
  final VoidCallback? onBack;
  final void Function(ThemeMode)? onThemeModeChanged;
  final void Function(int)? onThemeChanged;
  final VoidCallback? onThemeSave;
  final VoidCallback? onThemeCancel;
  final bool isDarkMode;
  final int selectedTheme;
  final List<String> themeNames;

  const ChatScreen({
    required this.chatRoom,
    required this.webSocketService,
    this.onBack,
    this.onThemeModeChanged,
    this.onThemeChanged,
    this.onThemeSave,
    this.onThemeCancel,
    this.isDarkMode = false,
    this.selectedTheme = 0,
    required this.themeNames,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  String _typingUser = '';
  Timer? _typingTimer;
  bool _showScrollToBottom = false;

  final Map<String, Map<String, dynamic>> _typingUsers = {};
  Timer? _typingCleanupTimer;

  late AnimationController _typingAnimationController;
  late AnimationController _scrollButtonAnimationController;
  late Animation<double> _scrollButtonAnimation;

  @override
  void initState() {
    super.initState();

    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

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

    _subscribeToChat();
    _setupScrollListener();
    _startTypingCleanupTimer();
    _loadInitialMessages();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _scrollButtonAnimationController.dispose();
    _typingTimer?.cancel();
    _typingCleanupTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadInitialMessages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First try to load from cache
      final cachedMessages =
          await ChatCacheService.loadChatMessages(widget.chatRoom.chatId);

      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(cachedMessages);
          _isLoading = false;
        });

        // Scroll to bottom after loading cached messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      // Then load fresh data from API
      final int _pageSize = 20;
      final freshMessages = await ApiService.getPaginatedMessages(
          widget.chatRoom.chatId, 0, _pageSize);

      if (freshMessages.isNotEmpty) {
        freshMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Merge fresh messages with cached messages
        final Set<int> existingMessageIds =
            _messages.map((msg) => msg.id).toSet();
        final List<Message> newMessages = [];

        for (final message in freshMessages) {
          if (!existingMessageIds.contains(message.id)) {
            newMessages.add(message);
          }
        }

        if (mounted) {
          setState(() {
            _messages.addAll(newMessages);
            _isLoading = false;
          });

          // Save updated messages to cache
          if (_messages.isNotEmpty) {
            await ChatCacheService.saveChatMessages(
                widget.chatRoom.chatId, _messages);
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      } else if (cachedMessages == null) {
        // No cached messages and no fresh messages
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startTypingCleanupTimer() {
    _typingCleanupTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _typingUsers.removeWhere((username, data) {
        return now - data['lastSeenTyping'] > 3000;
      });
      if (_typingUsers.isEmpty && _typingUser.isNotEmpty) {
        if (mounted) {
          setState(() {
            _typingUser = '';
          });
        }
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50;

      if (_showScrollToBottom != !isAtBottom) {
        if (mounted) {
          setState(() {
            _showScrollToBottom = !isAtBottom;
          });
        }

        if (_showScrollToBottom) {
          _scrollButtonAnimationController.forward();
        } else {
          _scrollButtonAnimationController.reverse();
        }
      }
    });
  }

  void _addMessage(Message message) {
    if (mounted) {
      setState(() {
        _messages.add(message);
      });

      // Update cache when new message is added
      if (_messages.length <= 20) {
        // Only cache if we have reasonable number of messages
        ChatCacheService.saveChatMessages(widget.chatRoom.chatId, _messages);
      }

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _scrollToBottom();
      }
    }
  }

  void _subscribeToChat() {
    widget.webSocketService.onMessageReceived = (Message message) {
      if (message.chatId == widget.chatRoom.chatId) {
        _addMessage(message);
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showThemeMenu() async {
    int tempTheme = widget.selectedTheme;
    bool tempDarkMode = widget.isDarkMode;

    await showDialog(
      barrierDismissible: false,
      fullscreenDialog: true,
      useRootNavigator: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Theme Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      tempDarkMode ? Iconsax.sun_1 : Iconsax.moon,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(tempDarkMode ? 'Light Mode' : 'Dark Mode'),
                    onTap: () {
                      setState(() {
                        tempDarkMode = !tempDarkMode;
                      });
                      widget.onThemeModeChanged?.call(
                          tempDarkMode ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Theme Style',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(widget.themeNames.length, (index) {
                      return ChoiceChip(
                        label: Text(widget.themeNames[index]),
                        selected: tempTheme == index,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              tempTheme = index;
                            });
                            widget.onThemeChanged?.call(index);
                          }
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    widget.onThemeCancel?.call(); // revert preview
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onThemeSave?.call(); // commit preview
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _background(int themeIndex) {
    switch (themeIndex) {
      case 2:
        return MeteorShower(
          isDark: Theme.of(context).brightness == Brightness.dark,
          numberOfMeteors: 10,
          duration: const Duration(seconds: 5),
          child: Container(
            height: MediaQuery.of(context).size.height,
          ),
        );
      case 1:
        return AnimatedGridPattern(
          squares: List.generate(20, (index) => [index % 5, index ~/ 5]),
          gridSize: 40,
          skewAngle: 12,
        );
      case 0:
        return const ButterflyDemo();
      default:
        return const SizedBox.shrink();
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      widget.webSocketService.sendMessage(widget.chatRoom.chatId, message);
      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      _stopTyping();
    } catch (e) {
      print('Error sending message: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _startTyping() {
    if (!_isTyping) {
      _isTyping = true;
      widget.webSocketService.sendTyping(widget.chatRoom.chatId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      widget.webSocketService.sendTyping(widget.chatRoom.chatId, false);
    }
    _typingTimer?.cancel();
  }

  bool _isLoadingMore = false;

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

    if (_isLoadingMore) {
      messageWidgets.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: messageWidgets.length,
      itemBuilder: (context, index) {
        return messageWidgets[index];
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    if (_typingUsers.isEmpty) return const SizedBox();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: _typingUsers.entries.map((entry) {
          final username = entry.key;
          final userData = entry.value;
          final profile = userData['profile'] as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Row(
              children: [
                _buildUserAvatar(username),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 8),
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

  Widget _buildUserAvatar(String username) {
    final userData = _typingUsers[username];
    final pfpIndex = userData?['profile']?['pfpIndex'] ?? '😊';
    final pfpBg = userData?['profile']?['pfpBg'] ?? '#4CAF50';

    return CircleAvatar(
      backgroundColor: _parseColor(pfpBg),
      radius: 16,
      child: Text(
        pfpIndex,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
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
                      decoration: const BoxDecoration(
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

  Widget _buildMessageBubble(Message message, int index) {
    final isOwnMessage = message.sender == ApiService.currentUsername;
    final showAvatar = !isOwnMessage;
    final String? text = message.content.isNotEmpty ? message.content : null;
    final DateTime? timestamp =
        message.timestamp != DateTime.fromMillisecondsSinceEpoch(0)
            ? message.timestamp
            : null;

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            _buildUserAvatar(message.sender),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? colorScheme.primary
                    : colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isOwnMessage
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isOwnMessage
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: const [
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
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender,
                        style: TextStyle(
                          color: isOwnMessage
                              ? Colors.white
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color:
                          isOwnMessage ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
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
          if (!showAvatar) const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _parseColor(widget.chatRoom.pfpBg),
              child: Text(
                widget.chatRoom.pfpIndex,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.chatName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _typingUser.isNotEmpty
                      ? Text(
                          '$_typingUser is typing...',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        )
                      : Text(
                          widget.chatRoom.isGroup ? 'Group' : 'Online',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.paintbucket),
            onPressed: _showThemeMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          _background(widget.selectedTheme),
          Column(
            children: [
              Expanded(
                child: _buildMessageList(),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixIcon: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            _startTyping();
                          } else {
                            _stopTyping();
                          }
                        },
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _isSending ? null : _sendMessage,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showScrollToBottom)
            Positioned(
              bottom: 80,
              right: 16,
              child: ScaleTransition(
                scale: _scrollButtonAnimation,
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.arrow_downward),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
