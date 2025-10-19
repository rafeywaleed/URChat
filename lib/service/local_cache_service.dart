// local_cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urchat/model/chat_room.dart';

import 'package:urchat/model/message.dart';

class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Chat Rooms Cache
  static const String _chatsKey = 'cached_chats';
  static const String _chatsTimestampKey = 'chats_timestamp';

  // Messages Cache - per chat
  static String _messagesKey(String chatId) => 'cached_messages_$chatId';
  static String _messagesTimestampKey(String chatId) =>
      'messages_timestamp_$chatId';

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Save chats to cache
  static Future<void> cacheChats(List<ChatRoom> chats) async {
    final chatsJson = chats.map((chat) => chat.toJson()).toList();
    await _prefs.setString(_chatsKey, json.encode(chatsJson));
    await _prefs.setInt(
        _chatsTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Get cached chats
  static Future<List<ChatRoom>?> getCachedChats() async {
    final timestamp = _prefs.getInt(_chatsTimestampKey);
    if (timestamp == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - timestamp > _cacheDuration.inMilliseconds) {
      return null; // Cache expired
    }

    final chatsJson = _prefs.getString(_chatsKey);
    if (chatsJson == null) return null;

    try {
      final List<dynamic> data = json.decode(chatsJson);
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    } catch (e) {
      //print('Error parsing cached chats: $e');
      return null;
    }
  }

  // Save messages to cache
  static Future<void> cacheMessages(
      String chatId, List<Message> messages) async {
    final messagesJson = messages.map((msg) => msg.toJson()).toList();
    await _prefs.setString(_messagesKey(chatId), json.encode(messagesJson));
    await _prefs.setInt(
        _messagesTimestampKey(chatId), DateTime.now().millisecondsSinceEpoch);
  }

  // Get cached messages
  static Future<List<Message>?> getCachedMessages(String chatId) async {
    final timestamp = _prefs.getInt(_messagesTimestampKey(chatId));
    if (timestamp == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - timestamp > _cacheDuration.inMilliseconds) {
      return null; // Cache expired
    }

    final messagesJson = _prefs.getString(_messagesKey(chatId));
    if (messagesJson == null) return null;

    try {
      final List<dynamic> data = json.decode(messagesJson);
      return data.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      //print('Error parsing cached messages: $e');
      return null;
    }
  }

  // Clear specific cache
  static Future<void> clearChatCache() async {
    await _prefs.remove(_chatsKey);
    await _prefs.remove(_chatsTimestampKey);
  }

  static Future<void> clearMessagesCache(String chatId) async {
    await _prefs.remove(_messagesKey(chatId));
    await _prefs.remove(_messagesTimestampKey(chatId));
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cached_') || key.contains('timestamp')) {
        await _prefs.remove(key);
      }
    }
  }
}
