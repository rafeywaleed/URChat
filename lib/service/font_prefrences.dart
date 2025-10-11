import 'package:shared_preferences/shared_preferences.dart';

class FontPreferenceService {
  static const String _fontPrefix = 'chat_font_';

  static Future<void> saveChatFont(String chatId, String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_fontPrefix$chatId', fontFamily);
  }

  static Future<String?> getChatFont(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_fontPrefix$chatId');
  }

  static Future<void> clearChatFont(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_fontPrefix$chatId');
  }
}
