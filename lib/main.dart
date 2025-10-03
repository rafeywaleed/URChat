// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'auth_screen.dart';
// import 'chat_list_screen.dart';
// import 'chat_screen.dart';
// import 'group_management_screen.dart';
// import 'profile_screen.dart';
// import 'auth_service.dart';
// import 'chat_service.dart';
// import 'websocket_service.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthService()),
//         ChangeNotifierProvider(create: (_) => ChatService()),
//         ChangeNotifierProvider(create: (_) => WebSocketService()),
//       ],
//       child: MaterialApp(
//         title: 'URChat',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           visualDensity: VisualDensity.adaptivePlatformDensity,
//         ),
//         home: AuthWrapper(),
//         routes: {
//           '/chat_list': (context) => ChatListScreen(),
//           '/profile': (context) => ProfileScreen(),
//           '/group_management': (context) => GroupManagementScreen(),
//         },
//       ),
//     );
//   }
// }

// class AuthWrapper extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);

//     if (authService.isAuthenticated) {
//       return ChatListScreen();
//     } else {
//       return AuthScreen();
//     }
//   }
// }

// import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:urchat_back_testing/main.dart';
import 'package:urchat_back_testing/model/user.dart';
import 'package:urchat_back_testing/screens/auth_screen.dart';
import 'package:urchat_back_testing/screens/home_screen.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/themes/theme_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ThemeManager().initializeThemes();
  await ApiService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URChat',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 500)),
        builder: (context, snapshot) {
          if (ApiService.hasStoredAuth && ApiService.isAuthenticated) {
            return Homescreen();
          } else {
            return AuthScreen();
          }
        },
      ),
    );
  }
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

// Extension for API service
