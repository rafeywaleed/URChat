import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:urchat/model/message.dart';
import 'package:urchat/service/api_service.dart';
import '../model/chat_room.dart';

class WebSocketService {
  StompClient? _stompClient;

  // Keep all callbacks as they were
  ValueChanged<Message> onMessageReceived;
  ValueChanged<List<ChatRoom>> onChatListUpdated;
  ValueChanged<Map<String, dynamic>> onTyping;
  ValueChanged<Map<String, dynamic>> onReadReceipt;
  ValueChanged<Map<String, dynamic>> onMessageDeleted;
  ValueChanged<String> onChatDeleted;

  // Subscription management - keep as is
  final Map<String, StompUnsubscribe> _messageDeletionSubscriptions = {};
  final Map<String, StompUnsubscribe> _chatSubscriptions = {};
  final Map<String, StompUnsubscribe> _typingSubscriptions = {};
  StompUnsubscribe? _chatListSubscription;

  // Connection state management - NEW: Add these to fix the issues
  String? _currentChatId;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10; // Increased limit
  static const Duration _initialReconnectDelay = Duration(seconds: 3);

  String webSocketURL = "https://urchat-backend.onrender.com/api/v1/ws";

  WebSocketService({
    required this.onMessageReceived,
    required this.onChatListUpdated,
    required this.onTyping,
    required this.onReadReceipt,
    required this.onMessageDeleted,
    required this.onChatDeleted,
  });

  void connect() {
    // NEW: Prevent multiple connection attempts
    if (_isConnecting || _isConnected) {
      //print('ℹ️ WebSocket already connecting or connected, skipping...');
      return;
    }

    final token = ApiService.accessToken;
    if (token == null) {
      //print('❌ No access token available for WebSocket connection');
      return;
    }

    //print('🔌 Connecting to WebSocket...');
    _isConnecting = true;
    _cancelPendingReconnect(); // NEW: Cancel any pending reconnects

    try {
      _stompClient = StompClient(
        config: StompConfig(
          url: webSocketURL,
          onConnect: _onConnect,
          onWebSocketError: (dynamic error) {
            //print('❌ WebSocket error: $error');
            _isConnected = false;
            _isConnecting = false;

            _scheduleReconnect();
          },
          onStompError: (dynamic error) {
            //print('❌ STOMP error: $error');
            _isConnected = false;
            _isConnecting = false;
            _scheduleReconnect();
          },
          onDisconnect: (frame) {
            //print('🔌 WebSocket disconnected');
            _isConnected = false;
            _isConnecting = false;
            _scheduleReconnect();
          },
          stompConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
          connectionTimeout: Duration(seconds: 10),
          useSockJS: true,
          // KEEP: This is fine, but we'll control reconnects manually
          reconnectDelay: Duration(milliseconds: 5000),
          beforeConnect: () async {
            //print('🔄 Preparing to connect to WebSocket...');
          },
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      //print('❌ Error activating WebSocket: $e');
      _isConnecting = false;
      _scheduleReconnect(); // FIXED: Use controlled reconnect
    }
  }

  // NEW: Controlled reconnect method
  void _scheduleReconnect() {
    _cancelPendingReconnect();

    // Don't reconnect if we've exceeded max attempts
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      //print('🚫 Max reconnect attempts ($_maxReconnectAttempts) reached. Giving up.');
      return;
    }

    _reconnectAttempts++;
    final delay = _calculateReconnectDelay();

    //print('🔄 Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && !_isConnecting) {
        connect();
      }
    });
  }

  // NEW: Calculate reconnect delay with exponential backoff
  Duration _calculateReconnectDelay() {
    final baseDelay = _initialReconnectDelay.inSeconds;
    final exponentialDelay = baseDelay * pow(2, _reconnectAttempts - 1).toInt();
    final jitter = Random().nextDouble() * 0.3; // Up to 30% jitter
    final totalDelay = exponentialDelay * (1 + jitter);

    return Duration(
        seconds: totalDelay.clamp(1, 30).toInt()); // Cap at 30 seconds
  }

  // NEW: Cancel pending reconnect
  void _cancelPendingReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _onConnect(StompFrame frame) {
    //print('✅ Connected to WebSocket successfully');
    //print('📦 Connection frame: ${frame.headers}');
    _isConnected = true;
    _isConnecting = false;
    _reconnectAttempts = 0; // NEW: Reset reconnect counter
    _cancelPendingReconnect(); // NEW: Cancel any pending reconnects

    // Subscribe to chat list updates
    subscribeToChatListUpdates();

    // Resubscribe to all previously subscribed chats
    _resubscribeToAllChats();

    //print('📡 Subscribed to chat list updates');
  }

  void _resubscribeToAllChats() {
    final chatIds = _chatSubscriptions.keys.toList();
    //print('🔄 Resubscribing to ${chatIds.length} chats: $chatIds');

    for (final chatId in chatIds) {
      _subscribeToChatRoomInternal(chatId);
    }
  }

  // ALL YOUR EXISTING METHODS STAY EXACTLY THE SAME FROM HERE DOWN
  void subscribeToChatListUpdates() {
    if (!_isConnected || _stompClient == null) {
      //print('❌ Cannot subscribe to chat list: WebSocket not connected');
      return;
    }

    // Unsubscribe from previous subscription if exists
    _chatListSubscription?.call();

    //print('🎯 SUBSCRIBING TO: /user/queue/chats/update');

    _chatListSubscription = _stompClient!.subscribe(
      destination: '/user/queue/chats/update',
      callback: (StompFrame frame) {
        //print('🎯 === CHAT LIST UPDATE CALLBACK TRIGGERED ===');
        //print('📦 Frame headers: ${frame.headers}');
        //print('📦 Frame command: ${frame.command}');

        if (frame.body != null) {
          //print('🔄 Received chat list update: ${frame.body}');
          try {
            final List<dynamic> chatData = jsonDecode(frame.body!);
            //print('📊 Parsed ${chatData.length} chat items');

            final chats =
                chatData.map((json) => ChatRoom.fromJson(json)).toList();

            // Sort chats by last activity (most recent first)
            chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

            //print('✅ Calling onChatListUpdated callback with ${chats.length} chats');
            onChatListUpdated(chats);
          } catch (e) {
            //print('❌ Error parsing chat list: $e');
            //print('Stack trace: ${e.toString()}');
            //print('Raw response that failed: ${frame.body}');
          }
        } else {
          //print('❌ Received empty chat list update frame');
        }
      },
    );

    //print('✅ Successfully subscribed to chat list updates');
  }

  void subscribeToChatRoom(String chatId) {
    if (!_isConnected || _stompClient == null) {
      //print('❌ Cannot subscribe: WebSocket not connected. ChatId: $chatId');
      _currentChatId = chatId;
      return;
    }

    _currentChatId = chatId;

    // Check if already subscribed to this chat
    if (_chatSubscriptions.containsKey(chatId)) {
      //print('ℹ️ Already subscribed to chat: $chatId, skipping duplicate subscription');
      return;
    }

    _subscribeToChatRoomInternal(chatId);
  }

  void _subscribeToChatRoomInternal(String chatId) {
    //print('🎯 SUBSCRIBING TO: /topic/chat/$chatId');

    final messageUnsubscribe = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId',
      callback: (StompFrame frame) {
        //print('💬 === MESSAGE CALLBACK TRIGGERED for chat $chatId ===');
        //print('📦 Frame headers: ${frame.headers}');

        if (frame.body != null) {
          //print('💬 Received message: ${frame.body}');
          try {
            final messageData = jsonDecode(frame.body!);
            final message = Message.fromJson(messageData);
            onMessageReceived(message);
          } catch (e) {
            //print('❌ Error parsing message: $e');
          }
        }
      },
    );

    _chatSubscriptions[chatId] = messageUnsubscribe;

    //print('🎯 SUBSCRIBING TO: /topic/chat/$chatId/typing');

    final typingUnsubscribe = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId/typing',
      callback: (StompFrame frame) {
        //print('⌨️ === TYPING CALLBACK TRIGGERED for chat $chatId ===');

        if (frame.body != null) {
          //print('⌨️ Received typing notification: ${frame.body}');
          try {
            final typingData = jsonDecode(frame.body!);
            // Add chatId to the typing data so we can filter it
            typingData['chatId'] = chatId;
            onTyping(typingData);
          } catch (e) {
            //print('❌ Error parsing typing notification: $e');
          }
        }
      },
    );

    _typingSubscriptions[chatId] = typingUnsubscribe;

    // Subscribe to message deletion events
    //print('🎯 SUBSCRIBING TO: /topic/chat/$chatId/message-deleted');

    final deletionUnsubscribe = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId/message-deleted',
      callback: (StompFrame frame) {
        //print('🗑️ === MESSAGE DELETION CALLBACK TRIGGERED for chat $chatId ===');
        if (frame.body != null) {
          //print('🗑️ Received message deletion: ${frame.body}');
          try {
            final deletionData = jsonDecode(frame.body!);
            onMessageDeleted(deletionData);
          } catch (e) {
            //print('❌ Error parsing message deletion: $e');
          }
        }
      },
    );

    _messageDeletionSubscriptions[chatId] = deletionUnsubscribe;

    //print('✅ Successfully subscribed to chat: $chatId');
    //print('📊 Current subscriptions: ${_chatSubscriptions.keys.toList()}');
  }

  void sendMessage(String chatId, String content) {
    if (!_isConnected || _stompClient == null) {
      //print('❌ Cannot send message: WebSocket not connected');
      return;
    }

    try {
      _stompClient!.send(
        destination: '/app/chat/$chatId/send',
        body: jsonEncode({
          'content': content,
        }),
      );
      //print('📤 Sent message to chat $chatId: $content');
    } catch (e) {
      //print('❌ Error sending message: $e');
    }
  }

  void sendTyping(String chatId, bool isTyping) {
    if (!_isConnected || _stompClient == null) return;

    try {
      _stompClient!.send(
        destination: '/app/chat/$chatId/typing',
        body: jsonEncode({
          'typing': isTyping,
        }),
      );
      //print('⌨️ Sent typing notification: $isTyping');
    } catch (e) {
      //print('❌ Error sending typing notification: $e');
    }
  }

  void deleteMessage(String chatId, int messageId) {
    if (!_isConnected || _stompClient == null) {
      //print('❌ Cannot delete message: WebSocket not connected');
      return;
    }

    try {
      _stompClient!.send(
        destination: '/app/chat/$chatId/delete-message',
        body: jsonEncode({
          'messageId': messageId,
        }),
      );
      //print('🗑️ Sent message deletion for message $messageId in chat $chatId');
    } catch (e) {
      //print('❌ Error sending message deletion: $e');
    }
  }

  void createIndividualChat(String targetUsername) {
    if (!_isConnected || _stompClient == null) return;

    try {
      _stompClient!.send(
        destination: '/app/chat/create-individual',
        body: jsonEncode({
          'targetUsername': targetUsername,
        }),
      );
      //print('👥 Creating individual chat with: $targetUsername');
    } catch (e) {
      //print('❌ Error creating individual chat: $e');
    }
  }

  void disconnect() {
    //print('🔌 Disconnecting WebSocket...');

    // NEW: Cancel any pending reconnects
    _cancelPendingReconnect();
    _isConnecting = false;
    _reconnectAttempts = 0;

    // Unsubscribe from chat list updates
    _chatListSubscription?.call();
    _chatListSubscription = null;

    // Unsubscribe from all chat rooms
    for (var unsubscribe in _chatSubscriptions.values) {
      unsubscribe();
    }
    _chatSubscriptions.clear();

    for (var unsubscribe in _typingSubscriptions.values) {
      unsubscribe();
    }
    _typingSubscriptions.clear();

    for (var unsubscribe in _messageDeletionSubscriptions.values) {
      unsubscribe();
    }
    _messageDeletionSubscriptions.clear();

    _stompClient?.deactivate();
    _isConnected = false;
    //print('✅ WebSocket disconnected');
  }

  bool get isConnected => _isConnected;

  bool isSubscribedToChat(String chatId) {
    return _chatSubscriptions.containsKey(chatId);
  }

  List<String> getSubscribedChats() {
    return _chatSubscriptions.keys.toList();
  }

  void unsubscribeFromChatRoom(String chatId) {
    if (_chatSubscriptions.containsKey(chatId)) {
      _chatSubscriptions[chatId]!();
      _chatSubscriptions.remove(chatId);
      //print('🔕 Unsubscribed from chat messages: $chatId');
    }

    if (_typingSubscriptions.containsKey(chatId)) {
      _typingSubscriptions[chatId]!();
      _typingSubscriptions.remove(chatId);
      //print('🔕 Unsubscribed from chat typing: $chatId');
    }

    if (_messageDeletionSubscriptions.containsKey(chatId)) {
      _messageDeletionSubscriptions[chatId]!();
      _messageDeletionSubscriptions.remove(chatId);
      //print('🔕 Unsubscribed from message deletion: $chatId');
    }
  }

  // Method to manually request chat list update
  void requestChatListUpdate() {
    if (!_isConnected || _stompClient == null) return;

    _stompClient!.send(
      destination: '/app/chats/refresh',
      body: '',
    );
    //print('📋 Requested chat list refresh');
  }

  void reconnectWithNewToken() {
    //print('🔄 Reconnecting WebSocket with refreshed token...');
    disconnect();
    Future.delayed(Duration(milliseconds: 500), () {
      connect();
    });
  }
}
