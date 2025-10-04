import 'package:flutter/material.dart';

class ChatTheme {
  final bool isDark;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final LinearGradient? gradient;

  const ChatTheme({
    required this.isDark,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    this.gradient,
  });

  static ChatTheme defaultLight() => ChatTheme(
        isDark: false,
        backgroundColor: Colors.white,
        textColor: Colors.black,
        accentColor: Colors.blue,
      );

  static ChatTheme defaultDark() => ChatTheme(
        isDark: true,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        accentColor: Colors.purpleAccent,
      );
}

class ChatThemeManager extends ChangeNotifier {
  final Map<String, ChatTheme> _themes = {};
  ChatTheme _currentTheme = ChatTheme.defaultLight();
  String? _currentChatId;

  ChatTheme get currentTheme => _currentTheme;

  void setCurrentChat(String chatId) {
    _currentChatId = chatId;
    _currentTheme = _themes[chatId] ?? ChatTheme.defaultLight();
    notifyListeners();
  }

  void updateChatTheme(String chatId, ChatTheme newTheme) {
    _themes[chatId] = newTheme;
    if (_currentChatId == chatId) {
      _currentTheme = newTheme;
      notifyListeners();
    }
  }

  ChatTheme getChatTheme(String chatId) {
    return _themes[chatId] ?? ChatTheme.defaultLight();
  }
}
