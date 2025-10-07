// controllers/chat_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:urchat_back_testing/service/local_cache_service.dart';

class ChatController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  final WebSocketService webSocketService = Get.find();
  final LocalCacheService localCacheService = Get.find();

  // Reactive variables
  var chats = <ChatRoom>[].obs;
  var groupInvitations = <ChatRoom>[].obs;
  var selectedChat = Rxn<ChatRoom>();
  var isLoading = false.obs;
  var isLoadingInvitations = false.obs;
  var errorMessage = ''.obs;
  var isConnected = false.obs;

  // For mobile layout
  var showChatScreen = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeWebSocket();
    loadInitialData();
  }

  void initializeWebSocket() {
    webSocketService.onMessageReceived = handleNewMessage;
    webSocketService.onChatListUpdated = handleChatListUpdate;
    webSocketService.onTyping = handleTypingStatus;
    webSocketService.onReadReceipt = handleReadReceipt;

    webSocketService.connect();

    Timer.periodic(Duration(seconds: 3), (timer) {
      isConnected.value = webSocketService.isConnected;
    });
  }

  handleTypingStatus(Map<String, dynamic> data) {
    print('⌨️ Typing status: $data');
  }

  handleReadReceipt(Map<String, dynamic> data) {
    print('👀 Read receipt: $data');
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        loadChats(),
        loadGroupInvitations(),
      ]);
    } catch (e) {
      errorMessage.value = 'Failed to load data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadChats() async {
    try {
      // Try cache first
      final cachedChats = await localCacheService.getCachedChats();
      if (cachedChats != null && cachedChats.isNotEmpty) {
        chats.value = cachedChats;
        errorMessage.value = '';
      }

      // Load fresh data in background
      await loadFreshChats();
    } catch (e) {
      errorMessage.value = 'Failed to load chats: $e';
    }
  }

  Future<void> loadFreshChats() async {
    try {
      final freshChats = await apiService.getUserChats();
      freshChats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

      chats.value = freshChats;
      await localCacheService.cacheChats(freshChats);
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = 'Failed to load fresh chats: $e';
    }
  }

  Future<void> loadGroupInvitations() async {
    try {
      isLoadingInvitations.value = true;
      final invitations = await apiService.getGroupInvitations();
      groupInvitations.value = invitations;
    } catch (e) {
      print('❌ Error loading group invitations: $e');
    } finally {
      isLoadingInvitations.value = false;
    }
  }

  void selectChat(ChatRoom chat) {
    selectedChat.value = chat;
    showChatScreen.value = true;
    webSocketService.subscribeToChatRoom(chat.chatId);
  }

  void deselectChat() {
    if (selectedChat.value != null) {
      webSocketService.unsubscribeFromChatRoom(selectedChat.value!.chatId);
    }
    selectedChat.value = null;
    showChatScreen.value = false;
  }

  void handleNewMessage(Message message) {
    print('💬 New message received: ${message.content}');
    // Don't manually update chat order - wait for WebSocket update from backend
  }

  void handleChatListUpdate(List<ChatRoom> updatedChats) {
    print(
        '🔄 Real-time chat list update received: ${updatedChats.length} chats');

    chats.value = updatedChats;
    errorMessage.value = '';

    // Update selected chat reference if it exists
    if (selectedChat.value != null) {
      try {
        final updatedSelectedChat = chats.firstWhere(
          (chat) => chat.chatId == selectedChat.value!.chatId,
        );
        selectedChat.value = updatedSelectedChat;
      } catch (e) {
        print(
            '⚠️ Selected chat no longer exists: ${selectedChat.value!.chatId}');
        deselectChat();
      }
    }
  }

  // Group invitation methods
  Future<void> acceptGroupInvitation(ChatRoom invitation) async {
    try {
      await apiService.acceptGroupInvitation(invitation.chatId);
      groupInvitations.removeWhere((inv) => inv.chatId == invitation.chatId);
      await loadFreshChats();

      Get.snackbar('Success', 'Joined ${invitation.chatName}',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to join group: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> declineGroupInvitation(ChatRoom invitation) async {
    try {
      await apiService.declineGroupInvitation(invitation.chatId);
      groupInvitations.removeWhere((inv) => inv.chatId == invitation.chatId);

      Get.snackbar('Success', 'Declined invitation to ${invitation.chatName}',
          backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline invitation: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void testWebSocketConnection() {
    print('🔍 === MANUAL WEB SOCKET TEST ===');
    print('   Current chats: ${chats.length}');
    print('   WebSocket connected: ${webSocketService.isConnected}');
    print('   Selected chat: ${selectedChat.value?.chatId}');

    loadFreshChats();
    print('   Testing message reception...');
  }

  @override
  void onClose() {
    webSocketService.disconnect();
    super.onClose();
  }
}
