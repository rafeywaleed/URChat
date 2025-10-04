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
    print('🔍 Creating Message from JSON: $json');

    // Handle timestamp parsing
    DateTime timestamp;
    try {
      if (json['timestamp'] is String) {
        timestamp = DateTime.parse(json['timestamp']);
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parsing timestamp, using current time: $e');
      timestamp = DateTime.now();
    }

    return Message(
      id: (json['id'] ?? json['messageId'])?.toInt() ?? 0,
      content: json['content']?.toString() ??
          json['messageContent']?.toString() ??
          '',
      sender: json['sender']?.toString() ?? 'Unknown',
      chatId: json['chatId']?.toString() ?? 'unknown',
      timestamp: timestamp,
      isOwnMessage: json['isOwnMessage'] ?? false,
    );
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

  @override
  String toString() {
    return 'Message{id: $id, sender: $sender, content: $content}';
  }
}
