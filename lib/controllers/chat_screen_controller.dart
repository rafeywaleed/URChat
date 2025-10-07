// controllers/chat_screen_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/model/user.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:urchat_back_testing/service/chat_cache_service.dart';
import 'package:urchat_back_testing/service/user_cache_service.dart';

class ChatScreenController extends GetxController
    with SingleGetTickerProviderMixin {
  final ChatRoom chatRoom;
  ChatScreenController({required this.chatRoom});

  final WebSocketService webSocketService = Get.find();
  final ApiService apiService = Get.find<ApiService>();
  // final ChatCacheService chatCacheService = Get.find();
  // final UserCacheService userCacheService = Get.find();

  // Reactive state
  var messages = <Message>[].obs;
  var isLoading = true.obs;
  var isSending = false.obs;
  var showScrollToBottom = false.obs;
  var typingUsers = <String, Map<String, dynamic>>{}.obs;
  var userProfiles = <String, Map<String, dynamic>>{}.obs;

  // Controllers
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // Timers and animations
  Timer? _typingTimer;
  Timer? _typingCleanupTimer;
  var isTyping = false.obs;
  var typingUser = ''.obs;

  // Current chat info
  // late ChatRoom chatRoom;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    // if (arguments != null && arguments['chatRoom'] != null) {
    //   chatRoom = arguments['chatRoom'];
    // }
    _initializeChat();
  }

  void _initializeChat() {
    _loadInitialMessages();
    _subscribeToChat();
    _setupScrollListener();
    _startTypingCleanupTimer();
  }

  Future<void> _loadInitialMessages() async {
    try {
      isLoading.value = true;

      // Try cache first
      final cachedMessages =
          await ChatCacheService.loadChatMessages(chatRoom.chatId);
      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        messages.value = cachedMessages;
        isLoading.value = false;
        _preloadUserProfiles();
        scrollToBottom();
      }

      // Load fresh data
      final freshMessages =
          await apiService.getPaginatedMessages(chatRoom.chatId, 0, 20);
      if (freshMessages.isNotEmpty) {
        freshMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        final Set<int> existingMessageIds =
            messages.map((msg) => msg.id).toSet();
        final List<Message> newMessages = [];

        for (final message in freshMessages) {
          if (!existingMessageIds.contains(message.id)) {
            newMessages.add(message);
          }
        }

        messages.addAll(newMessages);
        _preloadUserProfiles();

        // Save to cache
        if (messages.isNotEmpty) {
          await ChatCacheService.saveChatMessages(chatRoom.chatId, messages);
        }

        scrollToBottom();
      }

      isLoading.value = false;
    } catch (e) {
      print('Error loading messages: $e');
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to load messages: $e');
    }
  }

  void _subscribeToChat() {
    webSocketService.onMessageReceived = (Message message) {
      if (message.chatId == chatRoom.chatId) {
        _addMessage(message);
      }
      if (message.sender != apiService.currentUsername) {
        _cacheUserFromMessage(message);
      }
    };

    webSocketService.onTyping = (data) {
      final isUserTyping = data['typing'] as bool;
      final username = data['username'] as String;
      final userProfile = data['userProfile'] as Map<String, dynamic>?;

      if (isUserTyping && username != apiService.currentUsername) {
        typingUsers[username] = {
          'username': username,
          'profile': userProfile,
          'lastSeenTyping': DateTime.now().millisecondsSinceEpoch,
        };

        if (userProfile != null) {
          _cacheUserFromProfile(username, userProfile);
        }

        if (typingUsers.length == 1) {
          typingUser.value = username;
        } else {
          typingUser.value = '${typingUsers.length} people';
        }
      } else {
        typingUsers.remove(username);
        if (typingUsers.isEmpty) {
          typingUser.value = '';
        } else if (typingUsers.length == 1) {
          typingUser.value = typingUsers.keys.first;
        } else {
          typingUser.value = '${typingUsers.length} people';
        }
      }
    };

    webSocketService.subscribeToChatRoom(chatRoom.chatId);
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      final isAtBottom = scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 50;

      showScrollToBottom.value = !isAtBottom;
    });
  }

  void _startTypingCleanupTimer() {
    _typingCleanupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      typingUsers.removeWhere((username, data) {
        return now - data['lastSeenTyping'] > 5000;
      });
      if (typingUsers.isEmpty && typingUser.isNotEmpty) {
        typingUser.value = '';
      }
    });
  }

  void _addMessage(Message message) async {
    await _fetchAndCacheUserProfile(message.sender);
    messages.add(message);

    // Update cache
    if (messages.length <= 20) {
      ChatCacheService.saveChatMessages(chatRoom.chatId, messages);
    }

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - (Get.height / 2)) {
      scrollToBottom();
    }
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty || isSending.value) return;

    isSending.value = true;
    try {
      webSocketService.sendMessage(chatRoom.chatId, message);
      messageController.clear();
      scrollToBottom();
      stopTyping();
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e');
    } finally {
      isSending.value = false;
    }
  }

  void startTyping() {
    if (!isTyping.value) {
      isTyping.value = true;
      webSocketService.sendTyping(chatRoom.chatId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), stopTyping);
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void stopTyping() {
    if (isTyping.value) {
      isTyping.value = false;
      webSocketService.sendTyping(chatRoom.chatId, false);
    }
    _typingTimer?.cancel();
  }

  // User profile management
  Future<void> _preloadUserProfiles() async {
    if (messages.isEmpty) return;

    final usernames = <String>{};
    for (final message in messages) {
      if (message.sender != apiService.currentUsername) {
        usernames.add(message.sender);
      }
    }

    for (final username in usernames) {
      await _fetchAndCacheUserProfile(username);
    }
  }

  Future<void> _fetchAndCacheUserProfile(String username) async {
    if (username == apiService.currentUsername) return;

    try {
      // Try cache first
      var cachedProfile = await UserCacheService.getUserProfile(username);
      if (cachedProfile != null) {
        userProfiles[username] = cachedProfile;
      } else {
        // Set default
        userProfiles[username] = {
          'username': username,
          'fullName': username,
          'pfpIndex': '😊',
          'pfpBg': '#4CAF50',
          'bio': '',
        };
      }

      // Always try API for fresh data
      final apiProfile = await apiService.getUserProfile(username);
      if (apiProfile != null && apiProfile.isNotEmpty) {
        final userDTO = UserDTO.fromJson(apiProfile);
        await UserCacheService.saveUser(userDTO);

        userProfiles[username] = {
          'username': userDTO.username,
          'fullName': userDTO.fullName,
          'pfpIndex': userDTO.pfpIndex,
          'pfpBg': userDTO.pfpBg,
          'bio': userDTO.bio,
        };
      }
    } catch (e) {
      print('Error fetching profile for $username: $e');
    }
  }

  void _cacheUserFromMessage(Message message) async {
    try {
      final hasCachedUser = await UserCacheService.hasUser(message.sender);
      if (!hasCachedUser) {
        final userData = await apiService.getUserProfile(message.sender);
        if (userData != null) {
          final user = UserDTO.fromJson(userData);
          await UserCacheService.saveUser(user);
          final profile = await UserCacheService.getUserProfile(user.username);
          if (profile != null) {
            userProfiles[user.username] = profile;
          }
        }
      }
    } catch (e) {
      print('Failed to cache user from message: $e');
    }
  }

  void _cacheUserFromProfile(
      String username, Map<String, dynamic> profile) async {
    try {
      final hasCachedUser = await UserCacheService.hasUser(username);
      if (!hasCachedUser) {
        final user = UserDTO(
          username: username,
          fullName: profile['fullName'] ?? username,
          bio: profile['bio'] ?? '',
          pfpIndex: profile['pfpIndex'] ?? '😊',
          pfpBg: profile['pfpBg'] ?? '#4CAF50',
          joinedAt: profile['joinedAt'] != null
              ? DateTime.parse(profile['joinedAt'])
              : DateTime.now(),
        );
        await UserCacheService.saveUser(user);
        final updatedProfile = await UserCacheService.getUserProfile(username);
        if (updatedProfile != null) {
          userProfiles[username] = updatedProfile;
        }
      }
    } catch (e) {
      print('Failed to cache user from profile: $e');
    }
  }

  Map<String, dynamic>? getUserProfile(String username) {
    return userProfiles[username];
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    _typingCleanupTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    webSocketService.unsubscribeFromChatRoom(chatRoom.chatId);
    super.onClose();
  }
}
