// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urchat_back_testing/controllers/auth_controller.dart';
import 'package:urchat_back_testing/controllers/chat_controller.dart';
import 'package:urchat_back_testing/model/user.dart';
import 'package:urchat_back_testing/screens/auth_screen.dart';
import 'package:urchat_back_testing/screens/home_screen.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/local_cache_service.dart';
import 'package:urchat_back_testing/service/storage_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting app initialization...');

  try {
    // Initialize services in correct order
    await Get.putAsync(() => StorageService().init());
    print('✅ StorageService initialized');

    await Get.putAsync(() => ApiService().onInit());
    print('✅ ApiService initialized');

    await Get.putAsync(() => LocalCacheService().init());

    Get.put(LocalCacheService());
    print('✅ LocalCacheService initialized');

    // Initialize WebSocketService with proper callbacks
    Get.put(WebSocketService(
      onMessageReceived: (message) {
        print('💬 Message received: ${message.content}');
      },
      onChatListUpdated: (chats) {
        print('🔄 Chat list updated: ${chats.length} chats');
      },
      onTyping: (data) {
        print('⌨️ Typing: $data');
      },
      onReadReceipt: (data) {
        print('👀 Read receipt: $data');
      },
    ));
    print('✅ WebSocketService initialized');

    // Initialize controllers
    Get.put(ChatController());
    print('✅ ChatController initialized');

    Get.put(AuthController());
    print('✅ AuthController initialized');

    print('🎉 All services and controllers initialized successfully!');
  } catch (e) {
    print('❌ Error during initialization: $e');
    rethrow;
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'URChat',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 500)),
        builder: (context, snapshot) {
          try {
            final apiService = Get.find<ApiService>();
            if (apiService.hasStoredAuth && apiService.isAuthenticated) {
              print('🔐 User is authenticated, going to Homescreen');
              return Homescreen();
            } else {
              print('🔓 User not authenticated, going to AuthScreen');
              return AuthScreen();
            }
          } catch (e) {
            print('❌ Error checking auth status: $e');
            return AuthScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<User> getUserProfile(String username) async {
  final apiService = Get.find<ApiService>();
  final response = await http.get(
    Uri.parse('${ApiService.baseUrl}/users/$username'),
    headers: apiService.headers,
  );

  if (response.statusCode == 200) {
    return User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load user profile');
  }
}
