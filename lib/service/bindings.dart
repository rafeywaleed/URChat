// service/bindings.dart
import 'package:get/get.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/local_cache_service.dart';
import 'package:urchat_back_testing/service/storage_service.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'package:urchat_back_testing/service/chat_cache_service.dart';
import 'package:urchat_back_testing/service/user_cache_service.dart';
import 'package:urchat_back_testing/controllers/auth_controller.dart';
import 'package:urchat_back_testing/controllers/chat_controller.dart';
import 'package:urchat_back_testing/controllers/chat_screen_controller.dart';
import 'package:urchat_back_testing/controllers/theme_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut(() => StorageService(), fenix: true);
    Get.lazyPut(() => ApiService(), fenix: true);
    Get.lazyPut(() => LocalCacheService(), fenix: true);
    // Get.lazyPut(() => ChatCacheService(), fenix: true);
    // Get.lazyPut(() => UserCacheService(), fenix: true);

    // Controllers
    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => ThemeController(), fenix: true);

    // WebSocket service needs ChatController for callbacks
    Get.lazyPut(
      () => WebSocketService(
        onMessageReceived: Get.find<ChatController>().handleNewMessage,
        onChatListUpdated: Get.find<ChatController>().handleChatListUpdate,
        onTyping: Get.find<ChatController>().handleTypingStatus,
        onReadReceipt: Get.find<ChatController>().handleReadReceipt,
      ),
      fenix: true,
    );

    // ChatScreenController is created per chat, so we don't make it permanent
  }
}
