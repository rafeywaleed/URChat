// lib/service/notification_service.dart
import 'dart:js' as js;
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
      await _setupFirebase();
      await _setupLocalNotifications();
      _setupMessageHandling();

      // For web, we'll request permissions when user interacts
      if (!kIsWeb) {
        await _requestPermissions();
        await _getTokenAndSendToServer();
      }

      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing notification service: $e');
      print('Stack trace: $stackTrace');
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
    if (kIsWeb) {
      print('🌐 Skipping local notifications setup for web');
      return;
    }

    try {
      print('🔔 Setting up local notifications...');
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

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
    }
  }

  Future<void> _requestPermissions() async {
    try {
      print('📝 Requesting notification permissions...');

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

      print('📱 Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('⚠️ Permission request failed: $e');
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

  void _setupMessageHandling() {
    print('🎯 Setting up message handlers...');

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground message received:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');

      if (kIsWeb) {
        // For web, show custom in-app notification
        _showWebInAppNotification(message);
      } else {
        // For mobile, show local notification
        _showLocalNotification(message);
      }
    });

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Notification TAPPED - Navigating to chat:');
      print('   Data: ${message.data}');
      _handleNotificationData(message.data);
    });

    // Handle initial message when app is opened from terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 Initial message from terminated state: ${message.data}');
        Future.delayed(Duration(seconds: 3), () {
          _handleNotificationData(message.data);
        });
      }
    });

    print('✅ Message handlers setup complete');
  }

  Future<bool> hasNotificationPermission() async {
    if (kIsWeb) {
      try {
        // Use JavaScript interop to check permission status
        if (js.context.hasProperty('Notification')) {
          final permission = js.context['Notification']['permission'];
          return permission == 'granted';
        }
      } catch (e) {
        print('❌ Error checking notification permission: $e');
      }
      return false;
    } else {
      // For mobile, check Firebase messaging permission
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
  }

  void _showWebInAppNotification(RemoteMessage message) {
    final notificationData = {
      'chatName': message.data['chatName'] ??
          message.notification?.title ??
          'New Message',
      'message': message.notification?.body ??
          '${message.data['sender'] ?? 'Someone'}: ${message.data['message'] ?? 'New message'}',
      'chatId': message.data['chatId'],
      'type': 'message',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Broadcast to stream for in-app notification display
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.add(notificationData);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return; // Skip for web

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
    });
  }

  void _handleGroupInvitation(String groupName) {
    print('🎯 Group invitation received: $groupName');
  }

  // Public methods for web
  Future<void> enableWebNotifications() async {
    if (!kIsWeb) return;

    try {
      print('🌐 Enabling web notifications...');
      await _requestPermissions();
      await _getTokenAndSendToServer();
      print('✅ Web notifications enabled');
    } catch (e) {
      print('❌ Error enabling web notifications: $e');
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

  void dispose() {
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.close();
    }
  }
}
