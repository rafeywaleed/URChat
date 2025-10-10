import 'package:animated_emoji/animated_emoji.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class AnimatedEmojiUtils {
  static final Set<String> _supportedEmojis = {
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
    '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
    '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🥸',
    '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️',
    '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡',
    '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓',
    '🤗', '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄',
    '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵',
    '🤐', '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠',
    // Add more emojis as needed from the animated_emoji package
  };

  static bool isSingleEmoji(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // Check if the text contains only one emoji
    final characters = trimmed.characters;
    if (characters.length == 1) {
      return _supportedEmojis.contains(trimmed);
    }

    // Some emojis might be multiple characters (like ☹️)
    if (characters.length <= 3) {
      return _supportedEmojis.contains(trimmed);
    }

    return false;
  }

  static Future<bool> hasGoodConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // You could add additional network quality checks here
      return true;
    } catch (e) {
      return false;
    }
  }
}
