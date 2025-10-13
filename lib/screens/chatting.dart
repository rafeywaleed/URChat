import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:animated_emoji/emoji.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat_back_testing/model/chat_room.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/screens/group_management_screen.dart';
import 'package:urchat_back_testing/screens/user_profile.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/chat_cache_service.dart';
import 'package:urchat_back_testing/service/font_prefrences.dart';
import 'package:urchat_back_testing/service/user_cache_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:urchat_back_testing/themes/butter/bfdemo.dart';
import 'package:urchat_back_testing/themes/grid.dart';
import 'package:urchat_back_testing/themes/meteor.dart';
import 'package:urchat_back_testing/utils/animated_emoji_mapper.dart';
import 'package:urchat_back_testing/utils/font_options.dart';
import 'package:urchat_back_testing/widgets/animated_emoji_picker.dart';
import 'package:urchat_back_testing/widgets/deletion_dialog.dart';

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
  final List<String> _themeNames = ['Simple', 'Modern', 'Elegant', 'Cute'];

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

    // ---------------------
    // Theme 0: SIMPLE (Default)
    // ---------------------
// ---------- MONO MINIMAL THEME ---------- //

    _lightThemes.add(ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: const Color(0xFF2C2C2C),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF2C2C2C),
        secondary: const Color(0xFF555555),
        surface: Colors.white,
        background: const Color(0xFFF8F9FA),
        onSurface: const Color(0xFF2C2C2C),
        onBackground: const Color(0xFF2C2C2C),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: GoogleFonts.pixelifySansTextTheme().apply(
        bodyColor: const Color(0xFF2C2C2C),
        displayColor: const Color(0xFF2C2C2C),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.pixelifySans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        // FIX: Online status text color
        toolbarTextStyle: TextStyle(
          color: Colors.white
              .withOpacity(0.8), // This will make online status visible
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: const Color(0xFFE0E0E0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2C2C2C), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ));

    _darkThemes.add(ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: const Color.fromARGB(255, 102, 102, 102),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: const Color.fromARGB(255, 71, 71, 71),
        secondary: const Color(0xFFB0B0B0),
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        onSurface: const Color(0xFFE0E0E0),
        onBackground: const Color(0xFFE0E0E0),
        onPrimary: const Color(0xFF121212),
        onSecondary: const Color(0xFF121212),
      ),
      textTheme: GoogleFonts.pixelifySansTextTheme().apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: const Color(0xFFE0E0E0),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.pixelifySans(
          color: const Color(0xFFE0E0E0),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        // FIX: Online status text color
        toolbarTextStyle: TextStyle(
          color: const Color(0xFFE0E0E0)
              .withOpacity(0.8), // This will make online status visible
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: const Color(0xFF121212),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: const Color(0xFF333333),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF888888)),
      ),
    ));

    // ---------------------
    // Theme 1: MODERN
    // ---------------------
    _lightThemes.add(ThemeData(
      primaryColor: const Color(0xFF2E4057),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2E4057),
        secondary: Color(0xFF4A6FA5),
        surface: Color(0xFFF8F9FA),
        background: Color(0xFFFFFFFF),
        onSurface: Color(0xFF212529),
      ),
      textTheme: GoogleFonts.pixelifySansTextTheme().apply(
        bodyColor: Color(0xFF212529),
        displayColor: Color(0xFF212529),
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
        titleTextStyle: GoogleFonts.pixelifySans(
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
      textTheme: GoogleFonts.pixelifySansTextTheme().apply(
        bodyColor: Color(0xFFE0E0E0),
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
        titleTextStyle: GoogleFonts.pixelifySans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ));

    // ---------------------
    // Theme 2: ELEGANT
    // ---------------------
    _lightThemes.add(ThemeData(
      primaryColor: const Color(0xFF5D737E),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5D737E),
        secondary: Color(0xFF7A8B99),
        surface: Color(0xFFF8F9FA),
        background: Color(0xFFFFFFFF),
        onSurface: Color(0xFF3A3A3A),
      ),
      textTheme: GoogleFonts.pixelifySansTextTheme().apply(
        bodyColor: Color(0xFF3A3A3A),
        displayColor: Color(0xFF3A3A3A),
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
        titleTextStyle: GoogleFonts.pixelifySans(
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
      textTheme: GoogleFonts.pixelifySansTextTheme().apply(
        bodyColor: Color(0xFFE0E3E7),
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
        titleTextStyle: GoogleFonts.pixelifySans(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ));

    // ---------------------
    // Theme 3: CUTE
    // ---------------------
    _lightThemes.add(ThemeData(
      primaryColor: const Color(0xFFE91E63),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE91E63),
        secondary: Color(0xFFEC407A),
        surface: Color(0xFFFFF5F7),
        background: Color(0xFFFFF9FB),
        onSurface: Color(0xFF333333),
      ),
      textTheme: GoogleFonts.pixelifySansTextTheme().apply(
        bodyColor: Color(0xFF333333),
        displayColor: Color(0xFF333333),
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
        titleTextStyle: GoogleFonts.pixelifySans(
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
      textTheme: GoogleFonts.pixelifySansTextTheme().apply(
        bodyColor: Color(0xFFE0E0E0),
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
        titleTextStyle: GoogleFonts.pixelifySans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
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
  final AnimatedEmojiMapper _emojiMapper = AnimatedEmojiMapper();

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

  bool _showEmojiPicker = false;

  late String _selectedFont;
  String _committedFont = ChatFonts.defaultFont;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _selectedFont = ChatFonts.defaultFont;
    _committedFont = ChatFonts.defaultFont;
    _loadSavedFont();
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

  Future<void> _loadSavedFont() async {
    final savedFont =
        await FontPreferenceService.getChatFont(widget.chatRoom.chatId);
    if (savedFont != null && mounted) {
      setState(() {
        _selectedFont = savedFont;
        _committedFont = savedFont;
      });
    }
  }

  void _changeFont(String fontKey) {
    if (mounted) {
      setState(() {
        _selectedFont = fontKey;
      });
    }
  }

  void _saveFontChanges() async {
    setState(() {
      _committedFont = _selectedFont;
    });
    await FontPreferenceService.saveChatFont(
        widget.chatRoom.chatId, _selectedFont);
  }

  void _revertFontChanges() {
    setState(() {
      _selectedFont = _committedFont;
    });
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

        // Preload user profiles AFTER loading cached messages
        _preloadUserProfiles();

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

          // Preload user profiles AFTER loading fresh messages
          _preloadUserProfiles();

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
    _typingCleanupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _typingUsers.removeWhere((username, data) {
        return now - data['lastSeenTyping'] > 5000;
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

  void _addMessage(Message message) async {
    await _fetchAndCacheUserProfile(message.sender);
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
          _scrollController.position.maxScrollExtent -
              MediaQuery.of(context).size.height / 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
  }

  void _subscribeToChat() {
    widget.webSocketService.onMessageReceived = (Message message) {
      if (message.chatId == widget.chatRoom.chatId) {
        _addMessage(message);
      }

      if (message.sender != ApiService.currentUsername) {
        _cacheUserFromMessage(message);
      }
    };

    // NEW: Add message deletion handler
    widget.webSocketService.onMessageDeleted = _handleMessageDeleted;

    widget.webSocketService.onTyping = (data) {
      final isTyping = data['typing'] as bool;
      final username = data['username'] as String;
      final userProfile = data['userProfile'] as Map<String, dynamic>?;
      final chatId = data['chatId'] as String?;

      // Only process typing events for THIS specific chat
      if (chatId != null && chatId != widget.chatRoom.chatId) {
        print('⌨️ Ignoring typing event for different chat: $chatId');
        return;
      }

      if (mounted) {
        setState(() {
          if (isTyping && username != ApiService.currentUsername) {
            _typingUsers[username] = {
              'username': username,
              'profile': userProfile,
              'lastSeenTyping': DateTime.now().millisecondsSinceEpoch,
            };

            if (userProfile != null) {
              _cacheUserFromProfile(username, userProfile);
            }

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
    String tempFont = _selectedFont;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      barrierDismissible: false,
      fullscreenDialog: true,
      useRootNavigator: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: colorScheme.background,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        border: Border.all(
                          color: colorScheme.onPrimary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'THEME SETTINGS',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.text_fields,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'CHAT FONT',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                ChatFonts.availableFonts.entries.map((font) {
                              final isSelected = tempFont == font.key;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    tempFont = font.key;
                                  });
                                  _changeFont(font.key);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.background,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.onSurface
                                              .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    font.value,
                                    style: ChatFonts.getTextStyle(
                                      font.key,
                                      baseStyle: TextStyle(
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Theme Mode Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.brightness_6,
                              color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(
                            'MODE',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.background,
                              border: Border.all(
                                color: colorScheme.onSurface.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Light Mode Button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      tempDarkMode = false;
                                    });
                                    widget.onThemeModeChanged
                                        ?.call(ThemeMode.light);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    color: !tempDarkMode
                                        ? colorScheme.primary
                                        : colorScheme.surface,
                                    child: Text(
                                      'LIGHT',
                                      style: TextStyle(
                                        color: !tempDarkMode
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                // Dark Mode Button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      tempDarkMode = true;
                                    });
                                    widget.onThemeModeChanged
                                        ?.call(ThemeMode.dark);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    color: tempDarkMode
                                        ? colorScheme.primary
                                        : colorScheme.surface,
                                    child: Text(
                                      'DARK',
                                      style: TextStyle(
                                        color: tempDarkMode
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Theme Style Selection
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.brush,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'THEME STYLE',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Theme Selection Grid
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(widget.themeNames.length,
                                (index) {
                              final isSelected = tempTheme == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    tempTheme = index;
                                  });
                                  widget.onThemeChanged?.call(index);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.background,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.onSurface
                                              .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    widget.themeNames[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // NES Style Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              border: Border.all(
                                color: colorScheme.onSurface.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                widget.onThemeCancel?.call();
                                _revertFontChanges(); // NEW: Revert font changes too
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Save Button
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              border: Border.all(
                                color: colorScheme.onPrimary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                widget.onThemeSave?.call();
                                _saveFontChanges(); // NEW: Save font changes
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text(
                                'SAVE',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      case 3:
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
            style: ChatFonts.getTextStyle(
              _selectedFont,
              baseStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (_typingUsers.isEmpty) return const SizedBox();

    // Auto-scroll when someone starts typing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: _typingUsers.entries.map((entry) {
          final username = entry.key;
          final profile = _userProfiles[username] ??
              {
                'fullName': username,
                'pfpIndex': '😊',
                'pfpBg': '#4CAF50',
              };

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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${profile['fullName'] ?? username} is typing',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
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

  Future<void> _preloadUserProfiles() async {
    if (_messages.isEmpty) {
      print('⏳ No messages yet, skipping user profile preload');
      return;
    }

    print("🚀 Starting preloadUserProfiles");
    print("📊 Total messages: ${_messages.length}");

    // Get unique usernames from messages and typing users
    final usernames = <String>{};

    for (final message in _messages) {
      if (message.sender != ApiService.currentUsername) {
        usernames.add(message.sender);
        print('📨 Found message from: ${message.sender}');
      }
    }

    usernames.addAll(_typingUsers.keys);

    print('📝 Found ${usernames.length} unique users to preload: $usernames');

    if (usernames.isEmpty) {
      print('ℹ️ No users to preload');
      return;
    }

    // Clear the currently fetching set to ensure we can fetch again
    _currentlyFetchingUsers.clear();

    // Use Future.wait to load profiles in parallel but with limited concurrency
    final batches =
        _splitIntoBatches(usernames.toList(), 3); // 3 concurrent requests

    for (final batch in batches) {
      print('🔄 Processing batch: $batch');

      final futures = batch.map((username) async {
        print('🎯 Preloading profile for: $username');
        await _fetchAndCacheUserProfile(username);
      }).toList();

      await Future.wait(futures);

      // Small delay between batches
      await Future.delayed(const Duration(milliseconds: 200));
    }

    print('✅ Finished preloading user profiles');

    if (mounted) {
      setState(() {});
    }
  }

  void _manuallyLoadProfiles() {
    print('🔄 Manually triggering profile load');
    _preloadUserProfiles();
  }

// Helper method to split list into batches
  List<List<String>> _splitIntoBatches(List<String> list, int batchSize) {
    List<List<String>> batches = [];
    for (int i = 0; i < list.length; i += batchSize) {
      int end = (i + batchSize < list.length) ? i + batchSize : list.length;
      batches.add(list.sublist(i, end));
    }
    return batches;
  }

  final Map<String, Map<String, dynamic>> _userProfiles = {};

  Future<void> _fetchAndCacheUserProfile(String username) async {
    // Skip if it's the current user
    if (username == ApiService.currentUsername) {
      return;
    }

    print('🔍 Fetching profile for: $username');

    // Track if we're currently fetching this user to avoid duplicate API calls
    if (_currentlyFetchingUsers.contains(username)) {
      print('⏳ Already fetching profile for $username, skipping...');
      return;
    }

    _currentlyFetchingUsers.add(username);

    try {
      // 1. First try to get from cache for instant display
      var cachedProfile = await UserCacheService.getUserProfile(username);
      if (cachedProfile != null) {
        print('✅ Found in cache: $username');
        _userProfiles[username] = cachedProfile;
        if (mounted) setState(() {});
      } else {
        // Set default profile immediately for instant display
        _userProfiles[username] = {
          'username': username,
          'fullName': username,
          'pfpIndex': '😊',
          'pfpBg': '#4CAF50',
          'bio': '',
        };
        if (mounted) setState(() {});
      }

      // 2. ALWAYS try to fetch from API to get fresh data (even if we have cache)
      print('🌐 Calling API for user: $username');

      // Add a small delay to ensure UI is updated with cached/default data first
      await Future.delayed(const Duration(milliseconds: 100));

      final apiProfile = await ApiService.getUserProfile(username);

      if (apiProfile != null && apiProfile.isNotEmpty) {
        print('✅ API response received for $username: $apiProfile');

        // Convert API response to UserDTO
        final userDTO = UserDTO.fromJson(apiProfile);

        // Save to cache
        await UserCacheService.saveUser(userDTO);
        print('✅ Saved to cache: ${userDTO.username}');

        // Update in-memory profile
        final updatedProfile = {
          'username': userDTO.username,
          'fullName': userDTO.fullName,
          'pfpIndex': userDTO.pfpIndex,
          'pfpBg': userDTO.pfpBg,
          'bio': userDTO.bio,
        };

        // Always update with fresh API data
        _userProfiles[username] = updatedProfile;
        print('🔄 Updated profile for $username with API data');

        if (mounted) {
          setState(() {});
        }
      } else {
        print('❌ No API data received for $username');
      }
    } catch (e) {
      print('❌ Error fetching profile for $username: $e');
      // Keep the cached/default profile if API fails
    } finally {
      _currentlyFetchingUsers.remove(username);
    }
  }

// Add this set to track currently fetching users
  final Set<String> _currentlyFetchingUsers = {};

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
    final profile = _userProfiles[username] ??
        {
          'pfpIndex': '😊',
          'pfpBg': '#4CAF50',
        };
    final pfpIndex = profile['pfpIndex'] ?? '😊';
    final pfpBg = profile['pfpBg'] ?? '#4CAF50';

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
    final profile = _userProfiles[message.sender] ??
        {
          'fullName': message.sender,
          'pfpIndex': '😊',
          'pfpBg': '#4CAF50',
        };
    final colorScheme = Theme.of(context).colorScheme;

    final canDelete = _canDeleteMessage(message);

    final isSingleAnimatedEmoji = _isSingleAnimatedEmoji(message.content);
    final messageTextStyle = ChatFonts.getTextStyle(
      _selectedFont,
      baseStyle: TextStyle(
        color: isOwnMessage ? colorScheme.onSurface : Colors.white,
        fontSize: 14,
      ),
    );

    Widget messageContent;

    if (isSingleAnimatedEmoji) {
      // Display animated emoji without bubble
      messageContent = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment:
              isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showAvatar) ...[
              _buildUserAvatar(message.sender),
              const SizedBox(width: 12),
            ],
            Column(
              crossAxisAlignment: isOwnMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage && widget.chatRoom.isGroup == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      profile['fullName'] ?? message.sender,
                      style: messageTextStyle.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                // Animated emoji - FIXED: Use the actual emoji string
                Container(
                  padding: const EdgeInsets.all(8),
                  child: _buildAnimatedEmojiWidget(message.content),
                ),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: messageTextStyle.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            if (!showAvatar) const SizedBox(width: 12),
          ],
        ),
      );
    } else {
      // Regular message bubble
      messageContent = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment:
              isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar) ...[
              _buildUserAvatar(message.sender),
              const SizedBox(width: 8),
            ] else
              SizedBox(width: 20),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isOwnMessage
                      ? colorScheme.surface.withOpacity(0.9)
                      : colorScheme.primary,
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
                    if (!isOwnMessage && widget.chatRoom.isGroup == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          profile['fullName'] ?? message.sender,
                          style: messageTextStyle.copyWith(
                            color: isOwnMessage
                                ? colorScheme.onSurface
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: messageTextStyle.copyWith(
                        color:
                            isOwnMessage ? colorScheme.onSurface : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: messageTextStyle.copyWith(
                            color: isOwnMessage ? Colors.grey : Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!showAvatar)
              const SizedBox(width: 3)
            else
              SizedBox(
                width: 20,
              )
          ],
        ),
      );
    }

    return GestureDetector(
      onLongPress: canDelete
          ? () {
              // Add haptic feedback
              Feedback.forLongPress(context);
              _showMessageOptions(message);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: messageContent,
      ),
    );
  }

// UPDATED: Show message options menu with theme consistency
  void _showMessageOptions(Message message) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Material(
            color: colorScheme.background,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          color: colorScheme.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'MESSAGE OPTIONS',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Message preview
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        message.content.length > 50
                            ? '${message.content.substring(0, 50)}...'
                            : message.content,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontFamily: 'VT323',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Options
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Delete button
                        _buildThemeMessageOptionButton(
                          icon: Icons.delete_outline,
                          title: 'Delete Message',
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteMessage(message);
                          },
                        ),
                        const SizedBox(height: 8),

                        // Cancel button
                        _buildThemeMessageOptionButton(
                          icon: Icons.cancel_outlined,
                          title: 'Cancel',
                          backgroundColor: colorScheme.surface,
                          textColor: colorScheme.onSurface,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// UPDATED: Helper method for theme-consistent option buttons
  Widget _buildThemeMessageOptionButton({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: backgroundColor == Colors.red
              ? Colors.red.withOpacity(0.3)
              : textColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper to determine button type for message options
  NesButtonType _getMessageButtonType(Color color) {
    if (color == Colors.red) return NesButtonType.error;
    if (color == Colors.orange) return NesButtonType.warning;
    if (color == Colors.green) return NesButtonType.success;
    return NesButtonType.normal;
  }

  bool _isSingleAnimatedEmoji(String content) {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) return false;

    // More comprehensive emoji detection
    bool isSingleEmoji;

    // Handle single character emojis
    if (trimmedContent.runes.length == 1) {
      isSingleEmoji = true;
    }
    // Handle emojis with skin tones, flags, or modifiers
    else {
      // Use a more comprehensive regex for emoji detection
      final emojiRegex = RegExp(
        r'^(\p{Emoji}|\p{Emoji_Presentation}|\p{Emoji_Modifier_Base}|\p{Emoji_Modifier}|\p{Emoji_Component})+$',
        unicode: true,
      );

      isSingleEmoji = emojiRegex.hasMatch(trimmedContent) &&
          trimmedContent.runes.length <= 4; // Allow for modifiers
    }

    final hasAnimatedVersion =
        AnimatedEmojiMapper.hasAnimatedVersion(trimmedContent);

    print('🔍 Emoji Check: "$trimmedContent" - '
        'Single: $isSingleEmoji, '
        'Animated: $hasAnimatedVersion, '
        'Length: ${trimmedContent.runes.length}');

    return isSingleEmoji && hasAnimatedVersion;
  }

  Widget _buildAnimatedEmojiWidget(String emoji) {
    final animatedEmojiData = AnimatedEmojiMapper.getAnimatedEmoji(emoji);

    if (animatedEmojiData != null) {
      return AnimatedEmoji(
        animatedEmojiData,
        size: 48,
      );
    } else {
      // Fallback to regular text if animation fails
      print('⚠️ No animated emoji data found for: $emoji');
      return Text(
        emoji,
        style: const TextStyle(fontSize: 48),
      );
    }
  }

  String _getOtherUserName() {
    // For individual chats, try to get the full name from user profiles
    if (!widget.chatRoom.isGroup) {
      // Get all users in the chat except current user
      final otherUser = widget.chatRoom.chatName;

      final profile = _userProfiles[otherUser];
      if (profile != null && profile['fullName'] != null) {
        return profile['fullName']!;
      }
    }

    // Fallback to chat name if no profile found or it's a group
    return widget.chatRoom.chatName;
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
        title: GestureDetector(
          onTap: () => widget.chatRoom.isGroup
              ? Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GroupManagementScreen(
                      group: widget.chatRoom,
                    ),
                  ),
                )
              : Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => OtherUserProfileScreen(
                            username: widget.chatRoom.chatName,
                            fromChat: true,
                          )),
                ),
          child: Row(
            children: [
              Hero(
                tag: widget.chatRoom.isGroup
                    ? "chat_avatar_${widget.chatRoom.chatId}"
                    : "user_avatar_${widget.chatRoom.chatName}",
                child: CircleAvatar(
                  backgroundColor: _parseColor(widget.chatRoom.pfpBg),
                  child: Text(
                    widget.chatRoom.pfpIndex,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatRoom.chatName,
                    style: ChatFonts.getTextStyle(
                      _selectedFont,
                      baseStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _typingUser.isNotEmpty
                        ? Text(
                            '$_typingUser is typing...',
                            style: ChatFonts.getTextStyle(
                              _selectedFont,
                              baseStyle: const TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          )
                        : Text(
                            widget.chatRoom.isGroup ? 'Group' : 'Online',
                            style: ChatFonts.getTextStyle(
                              _selectedFont,
                              baseStyle: const TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
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
              _buildInlineEmojiPicker(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showInlineEmojiPicker = !_showInlineEmojiPicker;
                        });
                      },
                      icon: Icon(
                        _showInlineEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                      ),
                      tooltip: 'Emojis',
                    ),
                    const SizedBox(width: 4),

                    // Message Text Field
                    Expanded(
                      child: TextField(
                        autofocus: true,
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

                    // Send Button
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

//   void _showAnimatedEmojiPicker() async {
//   final selectedEmoji = await Navigator.of(context).push(
//     MaterialPageRoute(
//       builder: (context) => const AnimatedEmojiPickerScreen(
//         onEmojiSelected: null, // We'll handle this differently
//       ),
//     ),
//   );

//   if (selectedEmoji != null && selectedEmoji is String) {
//     // Send the selected emoji immediately
//     _sendEmojiMessage(selectedEmoji);
//   }
// }

// Alternative approach using callback
  void _showAnimatedEmojiPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnimatedEmojiPickerScreen(
          onEmojiSelected: (emoji) {
            // Send the selected emoji
            _sendEmojiMessage(emoji);
          },
        ),
      ),
    );
  }

  void _sendEmojiMessage(String emoji) {
    // Set the emoji as the text field content
    _messageController.text = emoji;

    // Call the existing send function
    _sendMessage();
  }

  bool _showInlineEmojiPicker = false;

  Widget _buildInlineEmojiPicker() {
    if (!_showInlineEmojiPicker) return const SizedBox.shrink();

    // Quick access to popular emojis
    final popularEmojis = [
      '😀',
      '😂',
      '🥰',
      '❤️',
      '🔥',
      '👍',
      '🎉',
      '🙏',
      '😭',
      '😡',
      '🤔',
      '👏',
      '🎂',
      '🌟',
      '💯',
      '🤣',
      '😎',
      '💕',
      '😊',
      '🎈'
    ];

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Quick Emojis',
                  style: ChatFonts.getTextStyle(
                    _selectedFont,
                    baseStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _showInlineEmojiPicker = false;
                    });
                  },
                ),
              ],
            ),
          ),
          // Emoji grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: popularEmojis.length,
              itemBuilder: (context, index) {
                final emoji = popularEmojis[index];
                return GestureDetector(
                  onTap: () {
                    _sendEmojiMessage(emoji);
                    setState(() {
                      _showInlineEmojiPicker = false;
                    });
                  },
                  child: Center(
                    child: AnimatedEmoji(
                      AnimatedEmojiMapper.getAnimatedEmoji(emoji)!,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
          ),
          // View all button
          TextButton(
            onPressed: _showAnimatedEmojiPicker,
            child: const Text('View All Emojis'),
          ),
        ],
      ),
    );
  }

  // Add to _ChatScreenState class

// NEW: Handle message deletion from WebSocket
  void _handleMessageDeleted(Map<String, dynamic> deletionData) {
    print('🗑️ Message deletion received: $deletionData');

    final deletedMessageId = deletionData['messageId'];
    final chatId = deletionData['chatId'];

    // Only process if it's for the current chat
    if (chatId == widget.chatRoom.chatId) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((message) => message.id == deletedMessageId);
        });
      }

      // Update cache
      ChatCacheService.saveChatMessages(widget.chatRoom.chatId, _messages);

      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A message was deleted'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

// UPDATED: Delete message method with theme-consistent dialog
  Future<void> _deleteMessage(Message message) async {
    final confirmed = await _showDeleteMessageDialog();

    if (confirmed == true) {
      try {
        // Store message ID before deletion
        final messageId = message.id;

        // Immediately remove from local state for instant UI update
        if (mounted) {
          setState(() {
            _messages.removeWhere((msg) => msg.id == messageId);
          });
        }

        // Update cache
        await ChatCacheService.saveChatMessages(
            widget.chatRoom.chatId, _messages);

        // Call API to delete from backend
        await ApiService.deleteMessage(widget.chatRoom.chatId, messageId);

        // Show success message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //       'Message deleted',
        //       style: TextStyle(fontFamily: 'VT323', fontSize: 14),
        //     ),
        //     backgroundColor: Colors.green,
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      } catch (e) {
        // If API call fails, reload messages to restore state
        _loadInitialMessages();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete message: $e',
              style: TextStyle(fontFamily: 'VT323', fontSize: 14),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

// NEW: Check if current user can delete this message
  bool _canDeleteMessage(Message message) {
    return message.sender == ApiService.currentUsername;
  }

  void _cacheUserFromMessage(Message message) async {
    try {
      final hasCachedUser = await UserCacheService.hasUser(message.sender);
      if (!hasCachedUser) {
        final userData = await ApiService.getUserProfile(message.sender);
        if (userData != null) {
          final user = UserDTO.fromJson(userData);
          await UserCacheService.saveUser(user);
          // Update in-memory profile
          final profile = await UserCacheService.getUserProfile(user.username);
          if (profile != null) {
            setState(() {
              _userProfiles[user.username] = profile;
            });
          }
          print('✅ Cached user ${user.username} from message');
        }
      }
    } catch (e) {
      print('❌ Failed to cache user from message: $e');
    }
  }

  /// NEW: Theme-consistent delete message dialog - RESPONSIVE
  Future<bool?> _showDeleteMessageDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        // Get screen dimensions for responsive sizing
        final screenWidth = MediaQuery.of(context).size.width;

        // Responsive breakpoints
        final bool isSmallScreen = screenWidth < 360;
        final bool isLargeScreen = screenWidth > 600;

        // Responsive sizing calculations
        final double dialogPadding = isSmallScreen ? 16 : 20;
        final double elementSpacing = isSmallScreen ? 12 : 16;
        final double smallElementSpacing = isSmallScreen ? 8 : 12;

        // Responsive font sizes
        final double headerFontSize = isSmallScreen ? 10 : 12;
        final double titleFontSize = isSmallScreen ? 14 : 16;
        final double subtitleFontSize = isSmallScreen ? 12 : 14;
        final double buttonFontSize = isSmallScreen ? 10 : 12;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16), // Consistent padding on all sides
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400, // Maximum width to prevent overflow
              minWidth: 280, // Minimum width for content
            ),
            padding: EdgeInsets.all(dialogPadding),
            decoration: BoxDecoration(
              color: colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center everything
              children: [
                // Header - Centered
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Take minimum width
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'DELETE MESSAGE',
                        style: GoogleFonts.pressStart2p(
                          fontSize: headerFontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: elementSpacing),

                // Message content - Centered
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Are you sure you want to delete\nthis message?',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: smallElementSpacing),
                    Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                SizedBox(height: elementSpacing),

                // Warning note - Centered
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          color: Colors.orange[800], size: 16),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'This will remove the message for everyone',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: elementSpacing),

                // Action buttons - Always centered with proper spacing
                if (isSmallScreen)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'DELETE',
                            style: GoogleFonts.pressStart2p(
                              fontSize: buttonFontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            backgroundColor: colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: colorScheme.onSurface.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.pressStart2p(
                              fontSize: buttonFontSize,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          backgroundColor: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: colorScheme.onSurface.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.pressStart2p(
                            fontSize: buttonFontSize,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'DELETE',
                          style: GoogleFonts.pressStart2p(
                            fontSize: buttonFontSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper method to cache user from profile data
  void _cacheUserFromProfile(
      String username, Map<String, dynamic> profile) async {
    try {
      final hasCachedUser = await UserCacheService.hasUser(username);
      if (!hasCachedUser) {
        final user = UserDTO(
          username: username,
          fullName: profile['fullName'] ?? username,
          bio: profile['bio'] ?? '',
          pfpIndex: profile['pfpIndex'] ?? '😊',
          pfpBg: profile['pfpBg'] ?? '#4CAF50',
          joinedAt: profile['joinedAt'] != null
              ? DateTime.parse(profile['joinedAt'])
              : DateTime.now(),
        );
        await UserCacheService.saveUser(user);
        // Update in-memory profile
        final updatedProfile = await UserCacheService.getUserProfile(username);
        if (updatedProfile != null) {
          setState(() {
            _userProfiles[username] = updatedProfile;
          });
        }
        print('✅ Cached user $username from typing profile');
      }
    } catch (e) {
      print('❌ Failed to cache user from profile: $e');
    }
  }
}
