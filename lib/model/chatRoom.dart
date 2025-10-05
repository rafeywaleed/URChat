import 'package:flutter/foundation.dart';
import 'package:urchat_back_testing/model/dto.dart';

class ChatRoom {
  final String chatId;
  final String chatName;
  final bool isGroup;
  String lastMessage;
  final DateTime lastActivity;
  final String pfpIndex;
  final String pfpBg;
  final int themeIndex;
  final bool isDark;

  ChatRoom({
    required this.chatId,
    required this.chatName,
    required this.isGroup,
    required this.lastMessage,
    required this.lastActivity,
    required this.pfpIndex,
    required this.pfpBg,
    required this.themeIndex,
    required this.isDark,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    print('🔍 Creating ChatRoom from JSON: $json');

    // Handle lastActivity - it might be a string or already a DateTime
    DateTime lastActivity;
    try {
      if (json['lastActivity'] is String) {
        lastActivity = DateTime.parse(json['lastActivity']);
      } else {
        // If it's already a DateTime or other format, use current time as fallback
        lastActivity = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parsing lastActivity, using current time: $e');
      lastActivity = DateTime.now();
    }

    return ChatRoom(
        chatId: json['chatId']?.toString() ?? 'unknown',
        chatName: json['chatName']?.toString() ?? 'Unknown Chat',
        isGroup: json['isGroup'] ?? false,
        lastActivity: lastActivity,
        lastMessage: json['lastMessage']?.toString() ?? 'No messages yet',
        pfpIndex: json['pfpIndex']?.toString() ?? '😊',
        pfpBg: json['pfpBg']?.toString() ?? '#4CAF50',
        themeIndex: json['themeIndex'] ?? 0,
        isDark: json['isDark'] ?? true);
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'chatName': chatName,
      'isGroup': isGroup,
      'lastMessage': lastMessage,
      'lastActivity': lastActivity.toIso8601String(),
      'pfpIndex': pfpIndex,
      'pfpBg': pfpBg,
      'themeIndex': themeIndex,
      'isDark': isDark,
    };
  }

  ChatRoom convertToChatRoom(GroupChatRoomDTO groupDTO) {
    return ChatRoom(
      chatId: groupDTO.chatId,
      chatName: groupDTO.chatName,
      isGroup: groupDTO.isGroup ?? true,
      lastMessage: '', // or appropriate initial value
      lastActivity: DateTime.now(),
      pfpIndex: groupDTO.pfpIndex,
      pfpBg: groupDTO.pfpBg,
      themeIndex: 0, // default theme
      isDark: true, // default dark mode
    );
  }

  @override
  String toString() {
    return 'ChatRoom{chatId: $chatId, chatName: $chatName, isGroup: $isGroup, lastMessage: $lastMessage}';
  }
}
