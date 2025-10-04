// chat_theme_wrapper.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'chat_screen.dart';

class ChatThemeWrapper extends StatefulWidget {
  final ChatRoom chatRoom;
  final WebSocketService webSocketService;
  final VoidCallback? onBack;
  final bool isEmbedded;

  const ChatThemeWrapper({
    Key? key,
    required this.chatRoom,
    required this.webSocketService,
    required this.onBack,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<ChatThemeWrapper> createState() => _ChatThemeWrapperState();
}

class _ChatThemeWrapperState extends State<ChatThemeWrapper> {
  late ChatRoom _currentChatRoom;

  @override
  void initState() {
    super.initState();
    _currentChatRoom = widget.chatRoom;
  }

  @override
  void didUpdateWidget(ChatThemeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatRoom.chatId != widget.chatRoom.chatId ||
        oldWidget.chatRoom.themeIndex != widget.chatRoom.themeIndex ||
        oldWidget.chatRoom.isDark != widget.chatRoom.isDark) {
      setState(() {
        _currentChatRoom = widget.chatRoom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _getChatTheme(_currentChatRoom.themeIndex, _currentChatRoom.isDark),
      child: ChatScreen(
        key: Key(
            '${_currentChatRoom.chatId}-${_currentChatRoom.themeIndex}-${_currentChatRoom.isDark}'),
        chatRoom: _currentChatRoom,
        webSocketService: widget.webSocketService,
        onBack: widget.onBack,
        isEmbedded: widget.isEmbedded,
      ),
    );
  }

  ThemeData _getChatTheme(int themeIndex, bool isDark) {
    switch (themeIndex) {
      case 1: // Cute
        return isDark ? _cuteDarkTheme : _cuteLightTheme;
      case 2: // Elegant
        return isDark ? _elegantDarkTheme : _elegantLightTheme;
      case 0: // Modern (default)
      default:
        return isDark ? _modernDarkTheme : _modernLightTheme;
    }
  }

  ThemeData get _modernLightTheme => ThemeData.light().copyWith(
        useMaterial3: true,
        primaryColor: const Color(0xFF2E4057),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E4057),
          secondary: Color(0xFF4A6FA5),
          surface: Color(0xFFF8F9FA),
          background: Color(0xFFFFFFFF),
          onSurface: Color(0xFF212529),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      );

  ThemeData get _modernDarkTheme => ThemeData.dark().copyWith(
        useMaterial3: true,
        primaryColor: const Color(0xFF4A6FA5),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A6FA5),
          secondary: Color(0xFF6B8CBC),
          surface: Color(0xFF1A1A2E),
          background: Color(0xFF121212),
          onSurface: Color(0xFFE0E0E0),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      );

  ThemeData get _cuteLightTheme => ThemeData.light().copyWith(
        useMaterial3: true,
        primaryColor: const Color(0xFFE91E63),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFE91E63),
          secondary: Color(0xFFEC407A),
          surface: Color(0xFFFFF5F7),
          background: Color(0xFFFFF9FB),
          onSurface: Color(0xFF333333),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF9FB),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      );

  ThemeData get _cuteDarkTheme => ThemeData.dark().copyWith(
        useMaterial3: true,
        primaryColor: const Color(0xFFEC407A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEC407A),
          secondary: Color(0xFFF06292),
          surface: Color(0xFF1E1E2E),
          background: Color(0xFF121212),
          onSurface: Color(0xFFE0E0E0),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      );

  ThemeData get _elegantLightTheme => ThemeData.light().copyWith(
        useMaterial3: true,
        primaryColor: const Color(0xFF5D737E),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5D737E),
          secondary: Color(0xFF7A8B99),
          surface: Color(0xFFF8F9FA),
          background: Color(0xFFFFFFFF),
          onSurface: Color(0xFF3A3A3A),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
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
      );

  ThemeData get _elegantDarkTheme => ThemeData.dark().copyWith(
        useMaterial3: true,
        primaryColor: const Color(0xFF7A8B99),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7A8B99),
          secondary: Color(0xFF5D737E),
          surface: Color(0xFF1E2A32),
          background: Color(0xFF121A21),
          onSurface: Color(0xFFE0E3E7),
        ),
        scaffoldBackgroundColor: const Color(0xFF121A21),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: const Color(0xFF1E2A32),
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
      );
}
