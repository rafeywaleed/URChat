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

      if (!kIsWeb) {
        await requestPermissions();
        await getTokenAndSendToServer();
      } else {
        print('🌐 Web: Wait for user gesture to request notifications');
      }

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

  Future<void> requestPermissions() async {
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

  Future<void> getTokenAndSendToServer() async {
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

  Future<void> _setupWebNotificationHandling() async {
    print('🌐 Setting up web notification handling...');

    try {
      // Request permission for web
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

      print('🌐 Web notification permission: ${settings.authorizationStatus}');

      // Handle initial message (app was terminated and opened via notification)
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('🌐 Initial message from terminated app: ${initialMessage.data}');
        // Wait a bit for app to initialize, then navigate
        Future.delayed(Duration(seconds: 2), () {
          _handleNotificationData(initialMessage.data);
        });
      }

      // Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('👆 Web notification tapped (background): ${message.data}');
        _handleNotificationData(message.data);
      });

      // Handle foreground messages for web
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 Web foreground message: ${message.data}');

        // For web, we rely on the service worker to show notifications
        // The service worker (firebase-messaging-sw.js) will handle this
        print('🌐 Notification should be handled by service worker');

        // You can also show a custom in-app notification for web
        _showWebInAppNotification(message);
      });

      print('✅ Web notification handling setup complete');
    } catch (e) {
      print('❌ Web notification setup failed: $e');
    }
  }

  void _showWebInAppNotification(RemoteMessage message) {
    // For web, show a custom in-app notification instead of browser notifications
    if (kIsWeb) {
      final notificationData = {
        'chatName': message.data['chatName'] ?? 'New Message',
        'message':
            '${message.data['sender'] ?? 'Someone'}: ${message.data['message'] ?? 'New message'}',
        'chatId': message.data['chatId'],
        'type': 'message'
      };

      // Broadcast to stream for in-app notification display
      if (!_notificationStreamController.isClosed) {
        _notificationStreamController.add(notificationData);
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // For web, don't use flutter_local_notifications as it doesn't work well on web
      if (kIsWeb) {
        print(
            '🌐 Skipping local notification for web - using service worker instead');
        return;
      }

      // Only show local notifications for mobile
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

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(payload);
        print('👆 Local notification TAPPED - Navigating to chat: $data');
        _handleNotificationData(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    print('🎯 Handling notification data: $data');

    final type = data['type'];
    final chatId = data['chatId'];

    if (type == 'NEW_MESSAGE' && chatId != null) {
      print('💬 Notification tapped for chat: $chatId - Navigating...');
      _navigateToChat(chatId);
    } else if (type == 'GROUP_INVITATION') {
      final groupName = data['groupName'];
      print('👥 Group invitation notification for: $groupName');
      _handleGroupInvitation(groupName);
    }
  }

  void _navigateToChat(String chatId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          navigator.push(
            MaterialPageRoute(
              builder: (context) => Homescreen(
                initialChatId: chatId,
                openChatOnStart: true,
              ),
            ),
          );
        } else {
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

  void _handleGroupInvitation(String groupName) {
    print('🎯 Group invitation received: $groupName');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📬 New group invitation: $groupName');
    });
  }

  Future<void> removeFcmToken() async {
    try {
      await ApiService.removeFcmToken();
      print('✅ FCM token removed from server');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  void dispose() {
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.close();
    }
  }
}
