// controllers/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/chat_cache_service.dart';

class ThemeController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  // final ChatCacheService chatCacheService = Get.find();

  var themeIndex = 0.obs;
  var isDarkMode = true.obs;
  var themeNames = ['Simple', 'Modern', 'Elegant', 'Cute'].obs;

  // For theme preview before saving
  var previewThemeIndex = 0.obs;
  var previewIsDarkMode = true.obs;

  Future<void> loadChatTheme(String chatId) async {
    try {
      // Try cache first
      final cachedTheme = await ChatCacheService.loadChatTheme(chatId);
      if (cachedTheme != null) {
        themeIndex.value = cachedTheme['themeIndex'] ?? 0;
        isDarkMode.value = cachedTheme['isDark'] ?? true;
        _resetPreview();
      }

      // Load from API
      final themeData = await apiService.getChatTheme(chatId);
      if (themeData.containsKey('themeIndex') &&
          themeData.containsKey('isDark')) {
        themeIndex.value = themeData['themeIndex'] ?? 0;
        isDarkMode.value = themeData['isDark'] ?? true;
        _resetPreview();

        // Update cache
        await ChatCacheService.saveChatTheme(
            chatId, themeIndex.value, isDarkMode.value);
      }
    } catch (e) {
      print('Error loading chat theme: $e');
    }
  }

  Future<void> updateChatTheme(String chatId) async {
    try {
      // Update locally
      themeIndex.value = previewThemeIndex.value;
      isDarkMode.value = previewIsDarkMode.value;

      // Save to API
      await apiService.updateChatTheme(
        {
          "themeIndex": themeIndex.value,
          "isDark": isDarkMode.value,
        },
        chatId,
      );

      // Update cache
      await ChatCacheService.saveChatTheme(
          chatId, themeIndex.value, isDarkMode.value);

      Get.snackbar('Success', 'Theme updated successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      // Revert on error
      _resetPreview();
      Get.snackbar('Error', 'Failed to update theme: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void changePreviewTheme(int index) {
    previewThemeIndex.value = index;
  }

  void togglePreviewDarkMode() {
    previewIsDarkMode.value = !previewIsDarkMode.value;
  }

  void _resetPreview() {
    previewThemeIndex.value = themeIndex.value;
    previewIsDarkMode.value = isDarkMode.value;
  }

  void cancelPreview() {
    _resetPreview();
  }
}
