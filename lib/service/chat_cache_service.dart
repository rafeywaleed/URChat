import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:urchat/model/message.dart';

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
