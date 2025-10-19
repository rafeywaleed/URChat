import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat/model/chat_room.dart';
import 'package:urchat/screens/home_screen.dart';
import 'package:urchat/widgets/pixle_circle.dart';

class InAppNotifications {
  static final InAppNotifications instance = InAppNotifications._internal();
  InAppNotifications._internal();

  final Color _accent = const Color(0xFF000000);
  final Color _mutedText = Colors.black87;

  final ValueNotifier<List<Map<String, dynamic>>> messageNotifications =
      ValueNotifier([]);

  List<ChatRoom> chats = [];
  String? currentChatId;

  Function(String chatId)? onOpenChat;

  bool get isInChat => currentChatId != null;

  void addNotification(Map<String, dynamic> notification) {
    if (notification['chatId'] == currentChatId) return;

    messageNotifications.value = [
      ...messageNotifications.value,
      notification,
    ];

    Future.delayed(const Duration(seconds: 3), () {
      messageNotifications.value =
          messageNotifications.value.where((n) => n != notification).toList();
    });
  }

  void removeNotification(Map<String, dynamic> notification) {
    messageNotifications.value =
        messageNotifications.value.where((n) => n != notification).toList();
  }

  void updateChats(List<ChatRoom> newChats) {
    chats = newChats;
  }

  void setCurrentChat(String? chatId) {
    currentChatId = chatId;
  }

  void setOnOpenChatCallback(Function(String chatId) callback) {
    onOpenChat = callback;
  }

  Widget buildNotifications(BuildContext context, VoidCallback onSelectChat) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: messageNotifications,
      builder: (context, notifications, _) {
        if (notifications.isEmpty) return const SizedBox.shrink();

        return Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: IgnorePointer(
            ignoring: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: notifications.map((notification) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildNotificationCard(
                      context, notification, onSelectChat),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context,
      Map<String, dynamic> notification, VoidCallback onSelectChat) {
    final bool isDeletion = notification['type'] == 'deletion';

    ChatRoom chat;
    try {
      chat = chats.firstWhere((c) => c.chatId == notification['chatId']);
    } catch (_) {
      chat = ChatRoom(
        chatId: notification['chatId'],
        chatName: notification['chatName'] ?? 'Unknown',
        isGroup: false,
        lastMessage: '',
        lastActivity: DateTime.now(),
        pfpIndex: notification['pfpIndex'] ?? '💬',
        pfpBg: notification['pfpBg'] ?? '#4CAF50',
        themeIndex: 0,
        isDark: true,
      );
    }

    return GestureDetector(
      onTap: isDeletion
          ? null
          : () {
              setCurrentChat(chat.chatId);
              removeNotification(notification);

              // NEW: Use callback if available, otherwise fallback to navigation
              if (onOpenChat != null) {
                print('🎯 Using callback to open chat: ${chat.chatId}');
                onOpenChat!(chat.chatId);
              } else {
                print('🔄 Callback not available, using fallback navigation');
                _fallbackNavigation(context, chat.chatId);
              }
            },
      child: NesContainer(
        padding: const EdgeInsets.all(12),
        backgroundColor: isDeletion ? Colors.orange.withOpacity(0.1) : null,
        child: Row(
          children: [
            PixelCircle(
              color: _parseColor(chat.pfpBg),
              label: chat.pfpIndex,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.chatName,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: isDeletion ? Colors.orange : _accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] ?? '',
                    style: GoogleFonts.vt323(
                      color: isDeletion ? Colors.orange[700] : _mutedText,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            NesButton(
              type: NesButtonType.normal,
              child: const Icon(Icons.close, size: 16),
              onPressed: () => removeNotification(notification),
            ),
          ],
        ),
      )
          .animate()
          .slideX(begin: -1, end: 0, curve: Curves.easeOut, duration: 300.ms),
    );
  }

  void _fallbackNavigation(BuildContext context, String chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Homescreen(
          initialChatId: chatId,
          openChatOnStart: true,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4CAF50);
    }
  }
}
