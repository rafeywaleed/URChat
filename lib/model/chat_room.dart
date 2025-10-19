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
    if (kDebugMode) {
      print('🔍 Creating ChatRoom from JSON: $json');
    }

    // Handle lastActivity - Spring Boot LocalDateTime format
    DateTime parseSpringBootDateTime(dynamic dateData) {
      if (dateData == null) return DateTime.now();

      try {
        if (dateData is DateTime) {
          return dateData;
        }

        if (dateData is String) {
          String dateString = dateData.trim();

          // Spring Boot LocalDateTime formats:
          // - "2025-10-19T06:37:14.950387"
          // - "2025-10-19T06:37:14"
          // - "2025-10-19T06:37:14.950387Z" (if already UTC)

          // Handle the case where it's already UTC
          if (dateString.endsWith('Z')) {
            return DateTime.parse(dateString).toLocal();
          }

          // Handle LocalDateTime (no timezone) - assume UTC and convert to local
          // First, ensure proper fractional seconds format
          if (dateString.contains('.')) {
            final parts = dateString.split('.');
            if (parts.length == 2) {
              String fractional = parts[1];
              // Ensure fractional seconds are properly formatted (max 6 digits)
              if (fractional.length > 6) {
                fractional = fractional.substring(0, 6);
              }
              dateString = '${parts[0]}.${fractional}Z'; // Add Z for UTC
            }
          } else {
            // No fractional seconds, just add Z
            dateString = '${dateString}Z';
          }

          return DateTime.parse(dateString).toLocal();
        }

        // If it's a number (milliseconds since epoch)
        if (dateData is int) {
          return DateTime.fromMillisecondsSinceEpoch(dateData);
        }

        return DateTime.now();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error parsing date "$dateData": $e');
        }
        return DateTime.now();
      }
    }

    DateTime lastActivity = parseSpringBootDateTime(json['lastActivity']);

    int themeIndex;
    try {
      final themeIndexData = json['themeIndex'];
      if (themeIndexData is int) {
        themeIndex = themeIndexData;
      } else if (themeIndexData is String) {
        themeIndex = int.tryParse(themeIndexData) ?? 0;
      } else {
        themeIndex = 0;
      }
    } catch (e) {
      themeIndex = 0;
    }

    bool isDark;
    try {
      final isDarkData = json['isDark'];
      if (isDarkData is bool) {
        isDark = isDarkData;
      } else if (isDarkData is String) {
        isDark = isDarkData.toLowerCase() == 'true';
      } else if (isDarkData is int) {
        isDark = isDarkData == 1;
      } else {
        isDark = true;
      }
    } catch (e) {
      isDark = true;
    }

    return ChatRoom(
      chatId: _parseString(json['chatId'], 'unknown'),
      chatName: _parseString(json['chatName'], 'Unknown Chat'),
      isGroup: json['isGroup'] == true,
      lastActivity: lastActivity,
      lastMessage: _parseString(json['lastMessage'], 'No messages yet'),
      pfpIndex: _parseString(json['pfpIndex'], '😊'),
      pfpBg: _parseString(json['pfpBg'], '#4CAF50'),
      themeIndex: themeIndex,
      isDark: isDark,
    );
  }

  static String _parseString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
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
