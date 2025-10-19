import 'package:flutter/material.dart';
import 'package:urchat/screens/home_screen.dart';
import 'package:urchat/service/api_service.dart';

class NavigationHelper {
  static void navigateToChat(BuildContext context, String username) async {
    try {
      final chat = await ApiService.createIndividualChat(username);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => Homescreen(
            initialChatId: chat.chatId,
            openChatOnStart: true,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      //print('❌ Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
