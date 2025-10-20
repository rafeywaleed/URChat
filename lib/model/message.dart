import 'package:flutter/foundation.dart';

class Message {
  final int id;
  final String content;
  final String sender;
  final String chatId;
  final DateTime timestamp;
  final bool isOwnMessage;

  Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.chatId,
    required this.timestamp,
    required this.isOwnMessage,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('🔍 Creating Message from JSON: $json');
    }

    // Spring Boot LocalDateTime parser (same as in ChatRoom)
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

    DateTime timestamp = parseSpringBootDateTime(json['timestamp']);

    // Parse ID - handle different field names
    int id;
    try {
      final idData = json['id'] ?? json['messageId'];
      if (idData is int) {
        id = idData;
      } else if (idData is String) {
        id = int.tryParse(idData) ?? 0;
      } else {
        id = 0;
      }
    } catch (e) {
      id = 0;
    }

    // Parse isOwnMessage
    bool isOwnMessage;
    try {
      final isOwnData = json['isOwnMessage'];
      if (isOwnData is bool) {
        isOwnMessage = isOwnData;
      } else if (isOwnData is String) {
        isOwnMessage = isOwnData.toLowerCase() == 'true';
      } else if (isOwnData is int) {
        isOwnMessage = isOwnData == 1;
      } else {
        isOwnMessage = false;
      }
    } catch (e) {
      isOwnMessage = false;
    }

    return Message(
      id: id,
      content: _parseString(json['content'] ?? json['messageContent'], ''),
      sender: _parseString(json['sender'], 'Unknown'),
      chatId: _parseString(json['chatId'], 'unknown'),
      timestamp: timestamp,
      isOwnMessage: isOwnMessage,
    );
  }

  static String _parseString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'chatId': chatId,
      'timestamp': timestamp.toIso8601String(),
      'isOwnMessage': isOwnMessage,
    };
  }

  bool canDelete(String currentUsername) {
    return sender == currentUsername;
  }

  @override
  String toString() {
    return 'Message{id: $id, sender: $sender, content: $content, timestamp: $timestamp}';
  }
}
