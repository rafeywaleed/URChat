import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat/firebase_options.dart';
import 'package:urchat/model/user.dart';
import 'package:urchat/screens/auth/auth_screen.dart';
import 'package:urchat/screens/home_screen.dart';
import 'package:urchat/screens/splash_screen.dart';
import 'package:urchat/service/api_service.dart';
import 'package:urchat/service/local_cache_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:urchat/service/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await LocalCacheService.init();
    await ApiService.init();
    await NotificationService().initialize();
  } catch (e) {
    //print("❌ Error during app initialization: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationService.notificationStream.listen((data) {
      final type = data['type'];
      final chatId = data['chatId'];
      if (type == 'NEW_MESSAGE' && chatId != null) {
        //print('📱 Notification received for chat: $chatId');
      }
    });
  }
  // void _handleNotification(Map<String, dynamic> data) {
  //   final type = data['type'];
  //   final chatId = data['chatId'];

  //   if (type == 'NEW_MESSAGE' && chatId != null) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       final currentRoute = navigatorKey.currentState?.widget.pages.last.name;

  //       if (currentRoute == '/') {
  //         // We're already on home screen, just open the chat
  //         navigatorKey.currentState?.push(
  //           MaterialPageRoute(
  //             builder: (context) => Homescreen(
  //               initialChatId: chatId,
  //               openChatOnStart: true,
  //             ),
  //           ),
  //         );
  //       } else {
  //         // Navigate to home first, then open chat
  //         navigatorKey.currentState?.pushAndRemoveUntil(
  //           MaterialPageRoute(
  //               builder: (context) => Homescreen(
  //                     initialChatId: chatId,
  //                     openChatOnStart: true,
  //                   )),
  //           (route) => false,
  //         );
  //       }
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'URChat',
      theme: _getScaledNesTheme(),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  Future<User> getUserProfile(String username) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/users/$username'),
      headers: ApiService.headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  ThemeData _getScaledNesTheme() {
    final nesTheme = flutterNesTheme();

    return nesTheme.copyWith(
      textTheme: _scaleTextTheme(nesTheme.textTheme),
      primaryTextTheme: _scaleTextTheme(nesTheme.primaryTextTheme),
    );
  }

  TextTheme _scaleTextTheme(TextTheme textTheme) {
    return TextTheme(
      displayLarge: _scaleTextStyle(textTheme.displayLarge),
      displayMedium: _scaleTextStyle(textTheme.displayMedium),
      displaySmall: _scaleTextStyle(textTheme.displaySmall),
      headlineLarge: _scaleTextStyle(textTheme.headlineLarge),
      headlineMedium: _scaleTextStyle(textTheme.headlineMedium),
      headlineSmall: _scaleTextStyle(textTheme.headlineSmall),
      titleLarge: _scaleTextStyle(textTheme.titleLarge),
      titleMedium: _scaleTextStyle(textTheme.titleMedium),
      titleSmall: _scaleTextStyle(textTheme.titleSmall),
      bodyLarge: _scaleTextStyle(textTheme.bodyLarge),
      bodyMedium: _scaleTextStyle(textTheme.bodyMedium),
      bodySmall: _scaleTextStyle(textTheme.bodySmall),
      labelLarge: _scaleTextStyle(textTheme.labelLarge),
      labelMedium: _scaleTextStyle(textTheme.labelMedium),
      labelSmall: _scaleTextStyle(textTheme.labelSmall),
    );
  }

  TextStyle? _scaleTextStyle(TextStyle? textStyle) {
    if (textStyle == null) return null;

    if (textStyle.fontSize == null) {
      return textStyle.copyWith(fontSize: 12.0);
    }
    return textStyle.copyWith(
      fontSize: textStyle.fontSize! - 4.0,
    );
  }
}
