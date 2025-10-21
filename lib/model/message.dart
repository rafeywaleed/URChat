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
    // Handle timestamp parsing - explicitly treat as UTC
    DateTime timestamp;
    try {
      if (json['timestamp'] is String) {
        String timestampString = json['timestamp'];

        if (!timestampString.endsWith('Z') && !timestampString.contains('+')) {
          timestampString += 'Z';
        }
        timestamp = DateTime.parse(timestampString);
      } else {
        timestamp = DateTime.now().toUtc();
      }
    } catch (e) {
      timestamp = DateTime.now().toUtc();
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
      'timestamp': timestamp.toUtc().toIso8601String(),
      'isOwnMessage': isOwnMessage,
    };
  }

  DateTime get localTime => timestamp.toLocal();

  bool canDelete(String currentUsername) {
    return sender == currentUsername;
  }

  @override
  String toString() {
    return 'Message{id: $id, sender: $sender, content: $content}';
  }
}
