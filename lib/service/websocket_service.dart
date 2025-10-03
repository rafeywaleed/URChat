import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/service/api_service.dart';

class WebSocketService {
  StompClient? _stompClient;
  ValueChanged<Message> onMessageReceived;
  ValueChanged<List<ChatRoom>> onChatListUpdated;
  ValueChanged<Map<String, dynamic>> onTyping;
  ValueChanged<Map<String, dynamic>> onReadReceipt;

  final Map<String, StompUnsubscribe> _chatSubscriptions = {};
  StompUnsubscribe? _chatListSubscription;

  String? _currentChatId;
  bool _isConnected = false;

  WebSocketService({
    required this.onMessageReceived,
    required this.onChatListUpdated,
    required this.onTyping,
    required this.onReadReceipt,
  });

  void connect() {
    final token = ApiService.accessToken;
    if (token == null) {
      print('❌ No access token available for WebSocket connection');
      return;
    }

    print('🔌 Connecting to WebSocket...');

    try {
      _stompClient = StompClient(
        config: StompConfig(
          url: 'http://localhost:8080/ws',
          onConnect: _onConnect,
          onWebSocketError: (dynamic error) {
            print('❌ WebSocket error: $error');
            _isConnected = false;
            Future.delayed(Duration(seconds: 3), () {
              if (!_isConnected) {
                print('🔄 Attempting to reconnect...');
                connect();
              }
            });
          },
          onStompError: (dynamic error) {
            print('❌ STOMP error: $error');
            _isConnected = false;
          },
          onDisconnect: (frame) {
            print('🔌 WebSocket disconnected');
            _isConnected = false;
          },
          stompConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
          connectionTimeout: Duration(seconds: 10),
          useSockJS: true,
          reconnectDelay: Duration(milliseconds: 5000),
          // Add this for better debugging
          beforeConnect: () async {
            print('🔄 Preparing to connect to WebSocket...');
          },
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      print('❌ Error activating WebSocket: $e');
      Future.delayed(Duration(seconds: 3), () {
        connect();
      });
    }
  }

  void _onConnect(StompFrame frame) {
    print('✅ Connected to WebSocket successfully');
    print('📦 Connection frame: ${frame.headers}');
    _isConnected = true;

    // Subscribe to chat list updates
    subscribeToChatListUpdates();

    // If we have a current chat, resubscribe to it
    if (_currentChatId != null &&
        !_chatSubscriptions.containsKey(_currentChatId)) {
      subscribeToChatRoom(_currentChatId!);
    }

    print('📡 Subscribed to chat list updates');
  }

  void subscribeToChatListUpdates() {
    if (!_isConnected || _stompClient == null) {
      print('❌ Cannot subscribe to chat list: WebSocket not connected');
      return;
    }

    // Unsubscribe from previous subscription if exists
    _chatListSubscription?.call();

    print('🎯 SUBSCRIBING TO: /user/queue/chats/update');

    _chatListSubscription = _stompClient!.subscribe(
      destination: '/user/queue/chats/update',
      callback: (StompFrame frame) {
        print('🎯 === CHAT LIST UPDATE CALLBACK TRIGGERED ===');
        print('📦 Frame headers: ${frame.headers}');
        print('📦 Frame command: ${frame.command}');

        if (frame.body != null) {
          print('🔄 Received chat list update: ${frame.body}');
          try {
            final List<dynamic> chatData = jsonDecode(frame.body!);
            print('📊 Parsed ${chatData.length} chat items');

            // Debug: Print raw data
            for (var i = 0; i < chatData.length; i++) {
              print('   📋 Raw chat $i: ${chatData[i]}');
            }

            final chats =
                chatData.map((json) => ChatRoom.fromJson(json)).toList();

            // Debug: Print each parsed chat
            for (var i = 0; i < chats.length; i++) {
              final chat = chats[i];
              print(
                  '   💬 Chat ${i + 1}: ${chat.chatName} | Last: "${chat.lastMessage}" | Time: ${chat.lastActivity}');
            }

            // Sort chats by last activity (most recent first)
            chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

            print(
                '✅ Calling onChatListUpdated callback with ${chats.length} chats');
            onChatListUpdated(chats);
          } catch (e) {
            print('❌ Error parsing chat list: $e');
            print('Stack trace: ${e.toString()}');
            print('Raw response that failed: ${frame.body}');
          }
        } else {
          print('❌ Received empty chat list update frame');
        }
      },
    );

    print('✅ Successfully subscribed to chat list updates');
  }

  void subscribeToChatRoom(String chatId) {
    if (!_isConnected || _stompClient == null) {
      print('❌ Cannot subscribe: WebSocket not connected. ChatId: $chatId');
      _currentChatId = chatId;
      return;
    }

    _currentChatId = chatId;

    if (_chatSubscriptions.containsKey(chatId)) {
      print('🔁 Already subscribed to $chatId, unsubscribing old subscription');
      _chatSubscriptions[chatId]!();
    }

    print('🎯 SUBSCRIBING TO: /topic/chat/$chatId');

    final unsubscribe = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId',
      callback: (StompFrame frame) {
        print('💬 === MESSAGE CALLBACK TRIGGERED ===');
        print('📦 Frame headers: ${frame.headers}');

        if (frame.body != null) {
          print('💬 Received message: ${frame.body}');
          try {
            final messageData = jsonDecode(frame.body!);
            final message = Message.fromJson(messageData);
            onMessageReceived(message);
          } catch (e) {
            print('❌ Error parsing message: $e');
          }
        }
      },
    );

    _chatSubscriptions[chatId] = unsubscribe;

    print('🎯 SUBSCRIBING TO: /topic/chat/$chatId/typing');

    final typingUnsubscribe = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId/typing',
      callback: (StompFrame frame) {
        print('⌨️ === TYPING CALLBACK TRIGGERED ===');

        if (frame.body != null) {
          print('⌨️ Received typing notification: ${frame.body}');
          try {
            final typingData = jsonDecode(frame.body!);
            onTyping(typingData);
          } catch (e) {
            print('❌ Error parsing typing notification: $e');
          }
        }
      },
    );

    print('✅ Subscribed to chat: $chatId');
  }

  void sendMessage(String chatId, String content) {
    if (!_isConnected || _stompClient == null) {
      print('❌ Cannot send message: WebSocket not connected');
      return;
    }

    try {
      _stompClient!.send(
        destination: '/app/chat/$chatId/send',
        body: jsonEncode({
          'content': content,
        }),
      );
      print('📤 Sent message to chat $chatId: $content');
    } catch (e) {
      print('❌ Error sending message: $e');
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
      print('⌨️ Sent typing notification: $isTyping');
    } catch (e) {
      print('❌ Error sending typing notification: $e');
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
      print('👥 Creating individual chat with: $targetUsername');
    } catch (e) {
      print('❌ Error creating individual chat: $e');
    }
  }

  void disconnect() {
    print('🔌 Disconnecting WebSocket...');

    // Unsubscribe from chat list updates
    _chatListSubscription?.call();
    _chatListSubscription = null;

    // Unsubscribe from all chat rooms
    for (var unsubscribe in _chatSubscriptions.values) {
      unsubscribe();
    }
    _chatSubscriptions.clear();

    _stompClient?.deactivate();
    _isConnected = false;
    print('✅ WebSocket disconnected');
  }

  bool get isConnected => _isConnected;

  void unsubscribeFromChatRoom(String chatId) {
    if (_chatSubscriptions.containsKey(chatId)) {
      _chatSubscriptions[chatId]!();
      _chatSubscriptions.remove(chatId);
      print('🔕 Unsubscribed from chat: $chatId');
    }
  }

  // Method to manually request chat list update
  void requestChatListUpdate() {
    if (!_isConnected || _stompClient == null) return;

    // You can send a request to get the latest chat list
    // This depends on your backend implementation
    _stompClient!.send(
      destination: '/app/chats/refresh',
      body: '',
    );
    print('📋 Requested chat list refresh');
  }
}
