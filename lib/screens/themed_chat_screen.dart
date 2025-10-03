// themed_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:urchat_back_testing/themes/theme_manager.dart';
import 'chat_screen.dart';

class ThemedChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final WebSocketService webSocketService;
  final VoidCallback? onBack;
  final bool isEmbedded;

  const ThemedChatScreen({
    Key? key,
    required this.chatRoom,
    required this.webSocketService,
    required this.onBack,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<ThemedChatScreen> createState() => _ThemedChatScreenState();
}

class _ThemedChatScreenState extends State<ThemedChatScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ThemeManager(),
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            theme: themeManager.currentTheme,
            darkTheme: themeManager.currentTheme,
            themeMode: themeManager.themeMode,
            home: ChatScreen(
              chatRoom: widget.chatRoom,
              webSocketService: widget.webSocketService,
              onBack: widget.onBack,
              isEmbedded: widget.isEmbedded,
            ),
          );
        },
      ),
    );
  }
}
