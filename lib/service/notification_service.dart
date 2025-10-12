// lib/service/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:urchat_back_testing/firebase_options.dart';
import 'package:urchat_back_testing/main.dart';
import 'package:urchat_back_testing/screens/home_screen.dart';
// import 'package:urchat_back_testing/old-firebase-options.dart';
import 'package:urchat_back_testing/service/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    print('🔄 Starting notification service initialization...');

    try {
      // Step 1: Initialize Firebase with error handling
      await _setupFirebase();

      // Step 2: Setup local notifications
      await _setupLocalNotifications();

      // Step 3: Request permissions (non-blocking)
      _requestPermissions();

      // Step 4: Get token and setup message handling
      await _getTokenAndSendToServer();
      _setupForegroundMessageHandling();

      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing notification service: $e');
      print('Stack trace: $stackTrace');
      // Don't rethrow - we don't want to crash the app
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setupFirebase() async {
    try {
      print('🔥 Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _setupLocalNotifications() async {
    try {
      print('🔔 Setting up local notifications...');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // For iOS (even if not used, keep for compatibility)
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('👆 Local notification tapped: ${response.payload}');
          _handleNotificationTap(response.payload);
        },
      );

      print('✅ Local notifications setup complete');
    } catch (e) {
      print('❌ Local notifications setup failed: $e');
      // Don't rethrow - local notifications are optional
    }
  }

  Future<void> _requestPermissions() async {
    try {
      print('📝 Requesting notification permissions...');

      if (kIsWeb) {
        // Web permissions
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        print(
            '🌐 Web notification permission: ${settings.authorizationStatus}');
      } else {
        // Mobile permissions
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        print(
            '📱 Mobile notification permission: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('⚠️ Permission request failed: $e');
      // Continue without permissions
    }
  }

  Future<void> _getTokenAndSendToServer() async {
    try {
      print('🔑 Getting FCM token...');
      String? token = await _firebaseMessaging.getToken();
      print('📱 FCM Token: ${token ?? "NULL"}');

      if (token != null && ApiService.isAuthenticated) {
        await _sendTokenToServer(token);
      } else if (token == null) {
        print('⚠️ FCM token is null - notifications may not work');
      } else {
        print('⚠️ User not authenticated, skipping token save');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM token refreshed: $newToken');
        if (ApiService.isAuthenticated) {
          _sendTokenToServer(newToken);
        }
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      print('📤 Sending FCM token to server...');
      await ApiService.saveFcmToken(token);
      print('✅ FCM token sent to server successfully');
    } catch (e) {
      print('❌ Error sending FCM token to server: $e');
    }
  }

  void _setupForegroundMessageHandling() {
    print('🎯 Setting up message handlers...');

    // Handle messages when app is in foreground - JUST SHOW NOTIFICATION, DON'T NAVIGATE
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground message received:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');

      _showLocalNotification(message);
      // DON'T call _handleNotificationData here - just show the notification
    });

    // Handle notification tap when app is in background/terminated - NAVIGATE ONLY ON TAP
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Background notification TAPPED - Navigating to chat:');
      print('   Data: ${message.data}');
      _handleNotificationData(message.data); // This should navigate
    });

    // For web specific handling
    if (kIsWeb) {
      _setupWebNotificationHandling();
    }

    print('✅ Message handlers setup complete');
  }

  void _setupWebNotificationHandling() {
    print('🌐 Setting up web notification handling...');

    // Handle initial message (app was terminated)
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print('🌐 Initial message from terminated app: ${message.data}');
        _handleNotificationData(
            message.data); // Navigate if app was opened from notification
      }
    });
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(payload);
        print('👆 Local notification TAPPED - Navigating to chat: $data');
        _handleNotificationData(data); // Navigate on tap
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    print('🎯 Handling notification data: $data');

    final type = data['type'];
    final chatId = data['chatId'];
    final isGroup = data['isGroup'] == 'true';

    if (type == 'NEW_MESSAGE' && chatId != null) {
      print('💬 Notification tapped for chat: $chatId - Navigating...');
      // Navigate to chat when notification is clicked
      _navigateToChat(chatId);
    } else if (type == 'GROUP_INVITATION') {
      final groupName = data['groupName'];
      print('👥 Group invitation notification for: $groupName');
      _handleGroupInvitation(groupName);
    }
  }

  void _navigateToChat(String chatId) {
    // Use the global navigator key to navigate safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check current route to avoid rebuilding HomeScreen
      NavigatorState? navigator = navigatorKey.currentState;

      if (navigator != null) {
        // Check if we're already on a HomeScreen
        bool isAlreadyOnHomeScreen = false;
        navigator.popUntil((route) {
          if (route.settings.name == '/' || route is MaterialPageRoute) {
            isAlreadyOnHomeScreen = true;
          }
          return true;
        });

        if (isAlreadyOnHomeScreen) {
          // We're already on home screen, push the chat screen on top
          navigator.push(
            MaterialPageRoute(
              builder: (context) => Homescreen(
                initialChatId: chatId,
                openChatOnStart: true,
              ),
            ),
          );
        } else {
          // Navigate to home first, then open chat
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => Homescreen(
                initialChatId: chatId,
                openChatOnStart: true,
              ),
            ),
            (route) => false,
          );
        }
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'urchat_channel',
        'URChat Messages',
        channelDescription: 'Notifications for new messages and invitations',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        message.notification?.title ?? 'URChat',
        message.notification?.body ?? 'New message',
        platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );

      print('📨 Local notification shown');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  Future<void> removeFcmToken() async {
    try {
      await ApiService.removeFcmToken();
      print('✅ FCM token removed from server');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  void _handleGroupInvitation(String groupName) {
    // Show a local notification or dialog about the invitation
    // You can also automatically refresh the invitations list
    print('🎯 Group invitation received: $groupName');

    // Optionally show a local dialog or snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // You can show a dialog or update the UI to reflect new invitation
      // For now, just log it - you can implement UI updates later
      print('📬 New group invitation: $groupName');
    });
  }

  void dispose() {
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.close();
    }
  }
}
