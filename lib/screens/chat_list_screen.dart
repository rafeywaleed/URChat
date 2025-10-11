import 'package:flutter/material.dart';
import 'package:urchat_back_testing/model/chat_room.dart';

class ChatListScreen extends StatefulWidget {
  final List<ChatRoom> chats;
  final Function(ChatRoom) onChatSelected;
  final VoidCallback onSearchUser;

  const ChatListScreen({
    required this.chats,
    required this.onChatSelected,
    required this.onSearchUser,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search chats...',
              prefixIcon: Icon(Icons.search),
            ),
            onTap: widget.onSearchUser,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.chats.length,
            itemBuilder: (context, index) {
              final chat = widget.chats[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _parseColor(chat.pfpBg),
                  child: Text(chat.pfpIndex),
                ),
                title: Text(chat.chatName),
                subtitle: Text(
                  chat.lastMessage.isEmpty
                      ? 'No messages yet'
                      : chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: chat.isGroup ? Icon(Icons.group) : null,
                onTap: () => widget.onChatSelected(chat),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(
          int.parse(colorString.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }
}
