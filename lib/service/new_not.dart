// import 'dart:async';
// import 'dart:convert';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:urchat/firebase_options.dart';
// import 'package:urchat/main.dart';
// import 'package:urchat/screens/home_screen.dart';
// import 'package:urchat/service/api_service.dart';

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   // Use the singleton instance directly
//   await NotificationService.instance._handleBackgroundMessage(message);
// }

// class NotificationService {
//   // Proper singleton pattern
//   static final NotificationService _instance = NotificationService._internal();
//   static NotificationService get instance => _instance;
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   final StreamController<Map<String, dynamic>> _notificationStreamController =
//       StreamController<Map<String, dynamic>>.broadcast();
//   Stream<Map<String, dynamic>> get notificationStream =>
//       _notificationStreamController.stream;

//   // SharedPreferences keys
//   static const String _notifyMessageKey = 'urchat_messages';
//   static const String _notifyChatNamesKey = 'urchat_chat_names';
//   static const String _collapsedChatsKey = 'urchat_collapsed_chats';

//   bool _isInitialized = false;

//   // Use a simple lock
//   bool _isProcessing = false;

//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     try {
//       await Firebase.initializeApp(
//           options: DefaultFirebaseOptions.currentPlatform);

//       await _setupLocalNotificationsWithActions();

//       _setupMessageHandling();

//       if (!kIsWeb) {
//         await requestPermissions();
//         await _getTokenAndSendToServer();
//         FirebaseMessaging.onBackgroundMessage(
//             firebaseMessagingBackgroundHandler);
//       }

//       _isInitialized = true;
//       print('✅ NotificationService initialized');

//       // Debug initial state
//       final prefs = await SharedPreferences.getInstance();
//       final messagesJson = prefs.getString(_notifyMessageKey);
//       print('🔍 Initial storage: ${messagesJson ?? "empty"}');
//     } catch (e) {
//       print('❌ NotificationService init error: $e');
//     }
//   }

//   // ========== COLLAPSIBLE NOTIFICATIONS METHODS ==========

//   Future<Set<String>> _getCollapsedChats() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final collapsedJson = prefs.getString(_collapsedChatsKey);
//       if (collapsedJson != null) {
//         final collapsedList = jsonDecode(collapsedJson) as List<dynamic>;
//         return collapsedList.map((e) => e.toString()).toSet();
//       }
//     } catch (e) {
//       print('❌ Error loading collapsed chats: $e');
//     }
//     return <String>{};
//   }

//   Future<void> _saveCollapsedChats(Set<String> collapsedChats) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(
//           _collapsedChatsKey, jsonEncode(collapsedChats.toList()));
//     } catch (e) {
//       print('❌ Error saving collapsed chats: $e');
//     }
//   }

//   Future<void> toggleChatCollapse(String chatId) async {
//     try {
//       final collapsedChats = await _getCollapsedChats();
//       if (collapsedChats.contains(chatId)) {
//         collapsedChats.remove(chatId);
//         print('📂 Expanded chat: $chatId');
//       } else {
//         collapsedChats.add(chatId);
//         print('📁 Collapsed chat: $chatId');
//       }
//       await _saveCollapsedChats(collapsedChats);

//       // Refresh the notification to show updated state
//       await _refreshNotificationForChat(chatId);
//     } catch (e) {
//       print('❌ Error toggling chat collapse: $e');
//     }
//   }

//   Future<bool> isChatCollapsed(String chatId) async {
//     final collapsedChats = await _getCollapsedChats();
//     return collapsedChats.contains(chatId);
//   }

//   // ========== DIRECT SHAREDPREFERENCES OPERATIONS ==========

//   Future<Map<String, List<Map<String, String>>>> _loadMessagesDirect() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final messagesJson = prefs.getString(_notifyMessageKey);
//       if (messagesJson != null && messagesJson.isNotEmpty) {
//         final messagesMap = jsonDecode(messagesJson) as Map<String, dynamic>;
//         final result = <String, List<Map<String, String>>>{};

//         messagesMap.forEach((chatId, messagesList) {
//           result[chatId] = (messagesList as List)
//               .map((message) => Map<String, String>.from(message))
//               .toList();
//         });

//         print('📥 Direct load: ${result.length} chats');
//         return result;
//       }
//     } catch (e) {
//       print('❌ Error in direct load: $e');
//     }
//     return {};
//   }

//   Future<void> _saveMessagesDirect(
//       Map<String, List<Map<String, String>>> messages) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_notifyMessageKey, jsonEncode(messages));
//       print('💾 Direct save: ${messages.length} chats');
//     } catch (e) {
//       print('❌ Error in direct save: $e');
//     }
//   }

//   Future<Map<String, String>> _loadChatNamesDirect() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final namesJson = prefs.getString(_notifyChatNamesKey);
//       if (namesJson != null) {
//         final namesMap = jsonDecode(namesJson) as Map<String, dynamic>;
//         return namesMap.map((key, value) => MapEntry(key, value.toString()));
//       }
//     } catch (e) {
//       print('❌ Error loading chat names: $e');
//     }
//     return {};
//   }

//   Future<void> _saveChatNamesDirect(Map<String, String> chatNames) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_notifyChatNamesKey, jsonEncode(chatNames));
//     } catch (e) {
//       print('❌ Error saving chat names: $e');
//     }
//   }

//   // ========== SIMPLE MUTEX LOCK ==========

//   Future<void> _waitForLock() async {
//     while (_isProcessing) {
//       await Future.delayed(Duration(milliseconds: 50));
//     }
//   }

//   Future<T> _withLock<T>(Future<T> Function() operation) async {
//     await _waitForLock();
//     _isProcessing = true;
//     try {
//       return await operation();
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   // ========== MESSAGE HANDLING ==========

//   Future<void> _handleBackgroundMessage(RemoteMessage message) async {
//     print('🌐 Background message handler called');
//     await _handleIncomingMessage(message, fromBackground: true);
//   }

//   void _setupMessageHandling() {
//     FirebaseMessaging.onMessage.listen((message) {
//       print('📨 Foreground message received');
//       _handleIncomingMessage(message, fromBackground: false);
//     });

//     FirebaseMessaging.onMessageOpenedApp.listen((message) {
//       print('🔔 Notification tapped');
//       _handleNotificationData(message.data);
//     });

//     FirebaseMessaging.instance
//         .getInitialMessage()
//         .then((RemoteMessage? message) {
//       if (message != null) {
//         Future.delayed(Duration(seconds: 3), () {
//           _handleNotificationData(message.data);
//         });
//       }
//     });
//   }

//   Future<void> _handleIncomingMessage(RemoteMessage message,
//       {bool fromBackground = false}) async {
//     final chatId = message.data['chatId'] ?? 'default_chat';
//     final chatName = message.data['chatName'] ?? 'URChat';
//     final sender = message.data['sender'] ?? 'Someone';
//     final text =
//         message.data['message'] ?? message.notification?.body ?? 'New message';
//     final isGroup = message.data['isGroup'] == 'true';

//     print(
//         '💬 Processing message for: $chatName ($chatId) from ${fromBackground ? 'background' : 'foreground'}');

//     await _withLock(() async {
//       try {
//         // Step 1: Cancel existing notification for this chat
//         await _flutterLocalNotificationsPlugin.cancel(chatId.hashCode.abs());
//         print('🗑️ Cancelled notification for: $chatId');

//         // Step 2: Load current state DIRECTLY from SharedPreferences
//         final messages = await _loadMessagesDirect();
//         final chatNames = await _loadChatNamesDirect();

//         print('🔍 Current state: ${messages.length} chats in storage');

//         // Step 3: Add new message
//         if (!messages.containsKey(chatId)) {
//           print('🆕 New chat, creating entry');
//           messages[chatId] = [];
//         }

//         chatNames[chatId] = chatName;

//         messages[chatId]!.add({
//           'sender': sender,
//           'message': text,
//           'isGroup': isGroup.toString(),
//           'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
//           'chatId': chatId,
//         });

//         // Keep only last 5 messages
//         if (messages[chatId]!.length > 5) {
//           messages[chatId] =
//               messages[chatId]!.sublist(messages[chatId]!.length - 5);
//         }

//         // Step 4: Save DIRECTLY to SharedPreferences
//         await _saveMessagesDirect(messages);
//         await _saveChatNamesDirect(chatNames);

//         // Verify save worked
//         final verifyMessages = await _loadMessagesDirect();
//         print(
//             '✅ Saved ${messages[chatId]!.length} messages for $chatName. Storage now has: ${verifyMessages.length} chats');

//         // Step 5: Show notification
//         await _showMergedNotification(chatId);
//       } catch (e) {
//         print('❌ Error in message processing: $e');
//       }
//     });
//   }

//   // ========== NOTIFICATION METHODS ==========

//   Future<void> _setupLocalNotificationsWithActions() async {
//     if (kIsWeb) return;

//     const androidChannel = AndroidNotificationChannel(
//       'urchat_channel',
//       'URChat Messages',
//       description: 'Notifications for chat messages',
//       importance: Importance.max,
//       playSound: true,
//     );

//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(androidChannel);

//     final initSettings = InitializationSettings(
//       android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
//       iOS: DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//         notificationCategories: [
//           DarwinNotificationCategory(
//             'urchat_category',
//             actions: <DarwinNotificationAction>[
//               // DarwinNotificationAction.plain(
//               //   'remove_notification',
//               //   'Remove',
//               // ),
//               DarwinNotificationAction.plain(
//                 'view_chat',
//                 'View Chat',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );

//     await _flutterLocalNotificationsPlugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         _handleNotificationAction(response);
//       },
//     );
//   }

//   Future<void> _refreshNotificationForChat(String chatId) async {
//     await _showMergedNotification(chatId);
//   }

//   Future<void> _showMergedNotification(String chatId) async {
//     if (kIsWeb) return;

//     try {
//       final messages = await _loadMessagesDirect();
//       final chatNames = await _loadChatNamesDirect();
//       final isCollapsed = await isChatCollapsed(chatId);

//       final chatMessages = messages[chatId];
//       if (chatMessages == null || chatMessages.isEmpty) {
//         print('🚫 No messages for: $chatId');
//         return;
//       }

//       final chatName = chatNames[chatId] ?? 'URChat';
//       final count = chatMessages.length;
//       final isGroup = chatMessages.first['isGroup'] == 'true';

//       String body;
//       StyleInformation? style;

//       if (isCollapsed) {
//         // Collapsed state - show summary only
//         body = '$count new message${count > 1 ? 's' : ''}';
//         style = BigTextStyleInformation(
//           body,
//           contentTitle: '$chatName 📁',
//           htmlFormatBigText: true,
//         );
//       } else if (count == 1) {
//         // Expanded state - single message
//         final msg = chatMessages.first;
//         body =
//             isGroup ? '${msg['sender']}: ${msg['message']}' : msg['message']!;
//         style = BigTextStyleInformation(
//           body,
//           contentTitle: chatName,
//           htmlFormatBigText: true,
//         );
//       } else {
//         // Expanded state - multiple messages
//         final lines = chatMessages
//             .map((m) =>
//                 isGroup ? '${m['sender']}: ${m['message']}' : m['message']!)
//             .toList();
//         style = InboxStyleInformation(
//           lines,
//           contentTitle: chatName,
//           summaryText: '$count new messages',
//           htmlFormatLines: true,
//         );
//         body = lines.last;
//       }

//       // Create actions - "Remove" and "View Chat"
//       final actions = <AndroidNotificationAction>[
//         // AndroidNotificationAction(
//         //   'remove_notification',
//         //   'Remove',
//         //   titleColor: Colors.red,
//         //   showsUserInterface: false, // FIXED: Don't show UI when removing
//         // ),
//         AndroidNotificationAction(
//           'view_chat',
//           'View Chat',
//           titleColor: Colors.green,
//           showsUserInterface: true,
//         ),
//       ];

//       final androidDetails = AndroidNotificationDetails(
//         'urchat_channel',
//         'URChat Messages',
//         channelDescription: 'Notifications for chat messages',
//         importance: Importance.max,
//         priority: Priority.high,
//         styleInformation: style,
//         autoCancel: true,
//         number: count,
//         showWhen: true,
//         actions: actions,
//         // Grouping settings
//         setAsGroupSummary: false,
//         groupKey: chatId, // Group by chat ID
//       );

//       final platformDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: DarwinNotificationDetails(
//           threadIdentifier: chatId,
//           badgeNumber: count,
//           subtitle: isCollapsed ? '$count new messages' : null,
//           categoryIdentifier:
//               'urchat_category', // FIXED: Add category identifier
//         ),
//       );

//       await _flutterLocalNotificationsPlugin.show(
//         chatId.hashCode.abs(),
//         isCollapsed ? '$chatName 📁' : chatName,
//         body,
//         platformDetails,
//         payload: jsonEncode({
//           'chatId': chatId,
//           'chatName': chatName,
//           'type': 'NEW_MESSAGE',
//           'isCollapsed': isCollapsed,
//         }),
//       );

//       print(
//           '🔔 Notification shown: $chatName ($count messages) - ${isCollapsed ? 'Collapsed' : 'Expanded'}');
//     } catch (e) {
//       print('❌ Error showing notification: $e');
//     }
//   }

//   // ========== NOTIFICATION ACTION HANDLING ==========

//   void _handleNotificationAction(NotificationResponse response) {
//     try {
//       final payload = response.payload;
//       final actionId = response.actionId;

//       print('🔔 Notification action: $actionId, payload: $payload');

//       if (payload != null) {
//         final data = jsonDecode(payload) as Map<String, dynamic>;

//         if (actionId != null && actionId.isNotEmpty) {
//           // Handle button action
//           data['action'] = actionId;
//         }

//         _handleNotificationTap(jsonEncode(data));
//       }
//     } catch (e) {
//       print('❌ Error handling notification action: $e');
//     }
//   }

//   void _handleNotificationTap(String? payload) {
//     if (payload == null) return;
//     try {
//       final data = jsonDecode(payload) as Map<String, dynamic>;
//       final action = data['action'];

//       print('🔔 Handling notification tap with action: $action');

//       // if (action == 'remove_notification') {
//       //   final chatId = data['chatId'];
//       //   if (chatId != null) {
//       //     print('🗑️ Removing notifications for chat: $chatId');
//       //     clearChatNotifications(chatId);
//       //     // Don't navigate to chat - just remove notifications
//       //     return;
//       //   }
//       // } else
//       if (action == 'view_chat') {
//         final chatId = data['chatId'];
//         if (chatId != null) {
//           print('💬 Navigating to chat: $chatId');
//           _handleNotificationData({'type': 'NEW_MESSAGE', 'chatId': chatId});
//         }
//       } else {
//         // Default tap behavior - navigate to chat
//         final chatId = data['chatId'];
//         if (chatId != null) {
//           print('💬 Default tap - navigating to chat: $chatId');
//           _handleNotificationData({'type': 'NEW_MESSAGE', 'chatId': chatId});
//         }
//       }
//     } catch (e) {
//       print('❌ Error handling notification tap: $e');
//     }
//   }

//   // ========== NUCLEAR CLEARING METHOD ==========

//   Future<void> clearAllNotifications() async {
//     print('💥💥 NUCLEAR CLEAR ALL');
//     final prefs = await SharedPreferences.getInstance();
//     final messagesJson = prefs.getString(_notifyMessageKey);
//     print('🔍 Clear All storage: ${messagesJson ?? "empty"}');

//     await _withLock(() async {
//       try {
//         // Cancel all notifications
//         await _flutterLocalNotificationsPlugin.cancelAll();

//         // Clear SharedPreferences COMPLETELY
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.remove(_notifyMessageKey);
//         await prefs.remove(_notifyChatNamesKey);
//         await prefs.remove(_collapsedChatsKey);

//         // Verify
//         final messages = await _loadMessagesDirect();
//         if (messages.isEmpty) {
//           print('✅ SUCCESS: All notifications cleared');
//         } else {
//           print(
//               '❌ FAILED: Still have ${messages.length} chats after clear all');
//         }

//         print('🔍 after clearing all storage: ${messagesJson ?? "empty"}');
//       } catch (e) {
//         print('❌ Error in clear all: $e');
//       }
//     });
//   }

//   Future<void> clearChatNotifications(String chatId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final messagesJson = prefs.getString(_notifyMessageKey);
//     print('🔍 Before clearing Chat: ${messagesJson ?? "empty"}');
//     print('💥 NUCLEAR CLEAR for chat: $chatId');

//     await _withLock(() async {
//       try {
//         // Step 1: Cancel notification
//         await _flutterLocalNotificationsPlugin.cancel(chatId.hashCode.abs());
//         print('✅ Cancelled notification');

//         // Step 2: Get current state
//         final messages = await _loadMessagesDirect();
//         final chatNames = await _loadChatNamesDirect();

//         print('🔍 Before clear: ${messages.length} chats');

//         // Step 3: Remove the chat COMPLETELY
//         messages.remove(chatId);
//         chatNames.remove(chatId);

//         // Step 4: Save the UPDATED state
//         await _saveMessagesDirect(messages);
//         await _saveChatNamesDirect(chatNames);

//         // Step 5: Remove from collapsed chats
//         final collapsedChats = await _getCollapsedChats();
//         collapsedChats.remove(chatId);
//         await _saveCollapsedChats(collapsedChats);

//         // Step 6: VERIFY it's gone by reading again
//         final verifyMessages = await _loadMessagesDirect();
//         final stillExists = verifyMessages.containsKey(chatId);

//         if (stillExists) {
//           print('❌ FAILED: Chat still exists after clearing!');
//         } else {
//           print('✅ SUCCESS: Chat completely removed from storage');
//           print('🔍 After clear: ${verifyMessages.length} chats remaining');
//         }

//         print('🔍 After Clearing Chat: ${messagesJson ?? "empty"}');
//       } catch (e) {
//         print('❌ Error in nuclear clear: $e');
//       }
//     });
//   }

//   Future<bool> enableWebNotifications() async {
//     try {
//       final settings = await _firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//       final granted =
//           settings.authorizationStatus == AuthorizationStatus.authorized;
//       if (granted) {
//         await _getTokenAndSendToServer();
//         print('✅ Web notifications enabled');
//       }
//       return granted;
//     } catch (e) {
//       print('❌ Error enabling web notifications: $e');
//       return false;
//     }
//   }

//   Future<void> requestPermissions() async {
//     try {
//       final settings = await _firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//         await _getTokenAndSendToServer();
//         print('✅ Notification permissions granted');
//       } else {
//         print('⚠️ Notification permissions denied');
//       }
//     } catch (e) {
//       print('❌ Error requesting permissions: $e');
//     }
//   }

//   Future<bool> hasNotificationPermission() async {
//     try {
//       final settings = await _firebaseMessaging.getNotificationSettings();
//       return settings.authorizationStatus == AuthorizationStatus.authorized;
//     } catch (e) {
//       print('❌ Error checking permissions: $e');
//       return false;
//     }
//   }

//   Future<void> _getTokenAndSendToServer() async {
//     try {
//       final token = await _firebaseMessaging.getToken();
//       if (token != null && ApiService.isAuthenticated) {
//         await ApiService.saveFcmToken(token);
//         print('✅ FCM token sent to server');
//       }

//       _firebaseMessaging.onTokenRefresh.listen((newToken) {
//         if (ApiService.isAuthenticated) {
//           ApiService.saveFcmToken(newToken);
//           print('🔄 FCM token refreshed and sent to server');
//         }
//       });
//     } catch (e) {
//       print('❌ Error getting/sending FCM token: $e');
//     }
//   }

//   void _handleNotificationData(Map<String, dynamic> data) {
//     final type = data['type'];
//     final chatId = data['chatId'];

//     if (type == 'NEW_MESSAGE' && chatId != null) {
//       _navigateToChat(chatId);
//     }
//   }

//   void _navigateToChat(String chatId) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final navigator = navigatorKey.currentState;
//       if (navigator != null) {
//         navigator.pushAndRemoveUntil(
//           MaterialPageRoute(
//             builder: (context) =>
//                 Homescreen(initialChatId: chatId, openChatOnStart: true),
//           ),
//           (route) => false,
//         );
//       }
//     });
//   }

//   void dispose() {
//     if (!_notificationStreamController.isClosed) {
//       _notificationStreamController.close();
//     }
//   }
// }
