import 'package:flutter/foundation.dart';
import 'package:urchat/model/dto.dart';

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

  static ChatRoom convertGroupDTOToChatRoom(GroupChatRoomDTO groupDTO) {
    return ChatRoom(
      chatId: groupDTO.chatId,
      chatName: groupDTO.chatName,
      isGroup: groupDTO.isGroup ?? true,
      lastMessage: '',
      lastActivity: DateTime.now(),
      pfpIndex: groupDTO.pfpIndex,
      pfpBg: groupDTO.pfpBg,
      themeIndex: 0,
      isDark: true,
    );
  }

  static ChatRoom convertChatDTOToChatRoom(ChatRoomDTO chatDTO) {
    return ChatRoom(
      chatId: chatDTO.chatId,
      chatName: chatDTO.chatName,
      isGroup: chatDTO.isGroup ?? true,
      lastMessage: chatDTO.lastMessage,
      lastActivity: DateTime.now(),
      pfpIndex: chatDTO.pfpIndex,
      pfpBg: chatDTO.pfpBg,
      themeIndex: 0,
      isDark: true,
    );
  }

  factory ChatRoom.fromDynamic(dynamic data) {
    if (data is ChatRoom) {
      return data;
    } else if (data is Map<String, dynamic>) {
      return ChatRoom.fromJson(data);
    } else if (data is ChatRoomDTO) {
      return ChatRoom.convertChatDTOToChatRoom(data);
    } else {
      throw FormatException('Cannot convert ${data.runtimeType} to ChatRoom');
    }
  }

  static List<ChatRoom> fromList(dynamic listData) {
    if (listData == null) return [];

    if (listData is List<ChatRoom>) {
      return listData;
    }

    if (listData is List<dynamic>) {
      return listData
          .map<ChatRoom>((item) => ChatRoom.fromDynamic(item))
          .toList();
    }

    throw FormatException(
        'Cannot convert ${listData.runtimeType} to List<ChatRoom>');
  }

  @override
  String toString() {
    return 'ChatRoom{chatId: $chatId, chatName: $chatName, isGroup: $isGroup, lastMessage: $lastMessage}';
  }
}
