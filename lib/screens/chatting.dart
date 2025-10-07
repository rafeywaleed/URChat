// screens/chatting.dart (Updated URChatApp)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urchat_back_testing/controllers/chat_screen_controller.dart';
import 'package:urchat_back_testing/controllers/theme_controller.dart';

import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/screens/group_management_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:urchat_back_testing/themes/butter/bfdemo.dart';
import 'package:urchat_back_testing/themes/grid.dart';
import 'package:urchat_back_testing/themes/meteor.dart';

class URChatApp extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback? onBack;

  URChatApp({
    required this.chatRoom,
    this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      init: ThemeController(),
      builder: (themeController) {
        return MaterialApp(
          title: 'URChat',
          debugShowCheckedModeBanner: false,
          theme: _lightThemes[themeController.themeIndex.value],
          darkTheme: _darkThemes[themeController.themeIndex.value],
          themeMode: themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light,
          home: ChatScreenWrapper(chatRoom: chatRoom, onBack: onBack),
        );
      },
    );
  }

  final List<ThemeData> _lightThemes = [
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: const Color(0xFF2C2C2C),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2C2C2C),
        secondary: Color(0xFF555555),
        surface: Colors.white,
        background: Color(0xFFF8F9FA),
        onSurface: Color(0xFF2C2C2C),
        onBackground: Color(0xFF2C2C2C),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: const Color(0xFF2C2C2C),
        displayColor: const Color(0xFF2C2C2C),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        toolbarTextStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: const Color(0xFFE0E0E0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2C2C2C), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    ThemeData(
      primaryColor: const Color(0xFF2E4057),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2E4057),
        secondary: Color(0xFF4A6FA5),
        surface: Color(0xFFF8F9FA),
        background: Color(0xFFFFFFFF),
        onSurface: Color(0xFF212529),
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFF212529),
        displayColor: const Color(0xFF212529),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2E4057),
        elevation: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2E4057),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ),
    ThemeData(
      primaryColor: const Color(0xFF5D737E),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5D737E),
        secondary: Color(0xFF7A8B99),
        surface: Color(0xFFF8F9FA),
        background: Color(0xFFFFFFFF),
        onSurface: Color(0xFF3A3A3A),
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFF3A3A3A),
        displayColor: const Color(0xFF3A3A3A),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF5D737E),
        elevation: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF5D737E),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ),
    ThemeData(
      primaryColor: const Color(0xFFE91E63),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE91E63),
        secondary: Color(0xFFEC407A),
        surface: Color(0xFFFFF5F7),
        background: Color(0xFFFFF9FB),
        onSurface: Color(0xFF333333),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFF333333),
        displayColor: const Color(0xFF333333),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE91E63),
        elevation: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ),
  ];

  final List<ThemeData> _darkThemes = [
    ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: const Color.fromARGB(255, 102, 102, 102),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 71, 71, 71),
        secondary: Color(0xFFB0B0B0),
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        onSurface: Color(0xFFE0E0E0),
        onBackground: Color(0xFFE0E0E0),
        onPrimary: Color(0xFF121212),
        onSecondary: Color(0xFF121212),
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: const Color(0xFFE0E0E0),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFFE0E0E0),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        toolbarTextStyle: TextStyle(
          color: const Color(0xFFE0E0E0).withOpacity(0.8),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: const Color(0xFF121212),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: const Color(0xFF333333),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF888888)),
      ),
    ),
    ThemeData(
      primaryColor: const Color(0xFF4A6FA5),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4A6FA5),
        secondary: Color(0xFF6B8CBC),
        surface: Color(0xFF1A1A2E),
        background: Color(0xFF121212),
        onSurface: Color(0xFFE0E0E0),
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1A1A2E),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4A6FA5),
        elevation: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF4A6FA5),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ),
    ThemeData(
      primaryColor: const Color(0xFF7A8B99),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7A8B99),
        secondary: Color(0xFF5D737E),
        surface: Color(0xFF1E2A32),
        background: Color(0xFF121A21),
        onSurface: Color(0xFFE0E3E7),
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFFE0E3E7),
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E2A32),
        margin: const EdgeInsets.all(8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7A8B99),
        elevation: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF7A8B99),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ),
    ThemeData(
      primaryColor: const Color(0xFFEC407A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFEC407A),
        secondary: Color(0xFFF06292),
        surface: Color(0xFF1E1E2E),
        background: Color(0xFF121212),
        onSurface: Color(0xFFE0E0E0),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E2E),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFEC407A),
        elevation: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFEC407A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    ),
  ];
}

class ChatScreenWrapper extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback? onBack;

  const ChatScreenWrapper({required this.chatRoom, this.onBack});

  @override
  Widget build(BuildContext context) {
    return GetX<ChatScreenController>(
      init: ChatScreenController(chatRoom: chatRoom),
      builder: (controller) {
        return Scaffold(
          appBar: _buildAppBar(controller),
          body: _buildBody(controller),
        );
      },
    );
  }

  AppBar _buildAppBar(ChatScreenController controller) {
    return AppBar(
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          : null,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: _parseColor(chatRoom.pfpBg),
            child: Text(
              chatRoom.pfpIndex,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatRoom.chatName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Obx(() {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: controller.typingUser.isNotEmpty
                      ? Text(
                          '${controller.typingUser.value} is typing...',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        )
                      : Text(
                          chatRoom.isGroup ? 'Group' : 'Online',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                );
              }),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.paintbucket),
          onPressed: _showThemeMenu,
        ),
        if (chatRoom.isGroup)
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Get.to(() => GroupManagementScreen(group: chatRoom));
            },
            tooltip: 'Group Info',
          ),
      ],
    );
  }

  Widget _buildBody(ChatScreenController controller) {
    return Stack(
      children: [
        _buildBackground(Get.find<ThemeController>().themeIndex.value),
        Column(
          children: [
            Expanded(
              child: _buildMessageList(controller),
            ),
            _buildMessageInput(controller),
          ],
        ),
        Obx(() {
          return controller.showScrollToBottom.value
              ? Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: controller.scrollToBottom,
                    child: const Icon(Icons.arrow_downward),
                  ),
                )
              : const SizedBox();
        }),
      ],
    );
  }

  Widget _buildMessageList(ChatScreenController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.messages.isEmpty) {
        return const Center(child: Text('No messages yet'));
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: controller.messages.length +
            (controller.typingUsers.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < controller.messages.length) {
            return _buildMessageBubble(controller.messages[index], controller);
          } else {
            return _buildTypingIndicator(controller);
          }
        },
      );
    });
  }

  Widget _buildMessageBubble(Message message, ChatScreenController controller) {
    final isOwnMessage =
        message.sender == Get.find<ApiService>().currentUsername;
    final showAvatar = !isOwnMessage;
    final profile = controller.getUserProfile(message.sender) ??
        {
          'fullName': message.sender,
          'pfpIndex': '😊',
          'pfpBg': '#4CAF50',
        };
    final colorScheme = Theme.of(Get.context!).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            _buildUserAvatar(profile),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? colorScheme.surface.withOpacity(0.9)
                    : colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isOwnMessage
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isOwnMessage
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwnMessage && chatRoom.isGroup)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        profile['fullName'] ?? message.sender,
                        style: TextStyle(
                          color: isOwnMessage
                              ? colorScheme.onSurface
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color:
                          isOwnMessage ? colorScheme.onSurface : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isOwnMessage ? Colors.grey : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!showAvatar) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ChatScreenController controller) {
    return Column(
      children: controller.typingUsers.entries.map((entry) {
        final username = entry.key;
        final profile = controller.getUserProfile(username) ??
            {
              'fullName': username,
              'pfpIndex': '😊',
              'pfpBg': '#4CAF50',
            };

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              _buildUserAvatar(profile),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${profile['fullName'] ?? username} is typing',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAnimatedDots(),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageInput(ChatScreenController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: controller.isSending.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (text) {
                if (text.isNotEmpty) {
                  controller.startTyping();
                } else {
                  controller.stopTyping();
                }
              },
              onSubmitted: (_) => controller.sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            return FloatingActionButton(
              onPressed: controller.isSending.value
                  ? null
                  : () => controller.sendMessage(),
              child: controller.isSending.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> profile) {
    return CircleAvatar(
      backgroundColor: _parseColor(profile['pfpBg'] ?? '#4CAF50'),
      radius: 16,
      child: Text(
        profile['pfpIndex'] ?? '😊',
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildAnimatedDots() {
    // Your existing animated dots implementation
    return SizedBox(
      width: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBackground(int themeIndex) {
    switch (themeIndex) {
      case 2:
        return MeteorShower(
          isDark: Get.isDarkMode,
          numberOfMeteors: 10,
          duration: const Duration(seconds: 5),
          child: Container(height: Get.height),
        );
      case 1:
        return AnimatedGridPattern(
          squares: List.generate(20, (index) => [index % 5, index ~/ 5]),
          gridSize: 40,
          skewAngle: 12,
        );
      case 3:
        return const ButterflyDemo();
      default:
        return const SizedBox.shrink();
    }
  }

  void _showThemeMenu() {
    final themeController = Get.find<ThemeController>();
    themeController.loadChatTheme(chatRoom.chatId);

    Get.dialog(
      ThemeDialog(themeController: themeController, chatId: chatRoom.chatId),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ThemeDialog extends StatelessWidget {
  final ThemeController themeController;
  final String chatId;

  const ThemeDialog({required this.themeController, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Theme Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              themeController.previewIsDarkMode.value
                  ? Iconsax.sun_1
                  : Iconsax.moon,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(themeController.previewIsDarkMode.value
                ? 'Light Mode'
                : 'Dark Mode'),
            onTap: themeController.togglePreviewDarkMode,
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Theme Style',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(themeController.themeNames.length, (index) {
              return ChoiceChip(
                label: Text(themeController.themeNames[index]),
                selected: themeController.previewThemeIndex.value == index,
                onSelected: (selected) {
                  if (selected) {
                    themeController.changePreviewTheme(index);
                  }
                },
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            themeController.cancelPreview();
            Get.back();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            themeController.updateChatTheme(chatId);
            Get.back();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
