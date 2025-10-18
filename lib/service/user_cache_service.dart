import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urchat/model/dto.dart';

class UserCacheService {
  static const String _userPrefix = 'cached_user_';
  static const String _allUsersKey = 'cached_users_list';
  static const String _cacheTimestampPrefix = 'user_cache_timestamp_';
  static const Duration _cacheExpiryDuration = Duration(hours: 24);

  // Save a single user to cache
  static Future<void> saveUser(UserDTO user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save user data
      await prefs.setString(
          '$_userPrefix${user.username}', json.encode(user.toJson()));

      // Save cache timestamp
      await prefs.setString(
        '$_cacheTimestampPrefix${user.username}',
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Update the list of all cached usernames
      await _updateCachedUsersList(user.username, prefs);

      print('✅ User ${user.username} saved to cache');
    } catch (e) {
      print('❌ Failed to save user ${user.username} to cache: $e');
    }
  }

  // Save multiple users to cache
  static Future<void> saveUsers(List<UserDTO> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final user in users) {
        await prefs.setString(
            '$_userPrefix${user.username}', json.encode(user.toJson()));

        await prefs.setString(
          '$_cacheTimestampPrefix${user.username}',
          DateTime.now().millisecondsSinceEpoch.toString(),
        );

        await _updateCachedUsersList(user.username, prefs);
      }

      print('✅ ${users.length} users saved to cache');
    } catch (e) {
      print('❌ Failed to save users to cache: $e');
    }
  }

  // Get a user by username
  static Future<UserDTO?> getUser(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('$_userPrefix$username');

      if (userJson != null) {
        final userData = json.decode(userJson);
        return UserDTO.fromJson(userData);
      }
    } catch (e) {
      print('❌ Failed to get user $username from cache: $e');
    }
    return null;
  }

  // Get user profile (simplified version for message bubbles)
  static Future<Map<String, dynamic>?> getUserProfile(String username) async {
    try {
      final user = await getUser(username);
      if (user != null) {
        return {
          'username': user.username,
          'fullName': user.fullName,
          'pfpIndex': user.pfpIndex,
          'pfpBg': user.pfpBg,
          'bio': user.bio,
        };
      }
    } catch (e) {
      print('❌ Failed to get user profile for $username: $e');
    }
    return null;
  }

  // Get multiple users by usernames
  static Future<List<UserDTO>> getUsers(List<String> usernames) async {
    final List<UserDTO> users = [];

    for (final username in usernames) {
      final user = await getUser(username);
      if (user != null) {
        users.add(user);
      }
    }

    return users;
  }

  // Update specific fields of a user
  static Future<void> updateUserFields({
    required String username,
    String? fullName,
    String? bio,
    String? pfpIndex,
    String? pfpBg,
  }) async {
    try {
      final user = await getUser(username);
      if (user != null) {
        final updatedUser = UserDTO(
          username: user.username,
          fullName: fullName ?? user.fullName,
          bio: bio ?? user.bio,
          pfpIndex: pfpIndex ?? user.pfpIndex,
          pfpBg: pfpBg ?? user.pfpBg,
          joinedAt: user.joinedAt,
        );

        await saveUser(updatedUser);
        print('✅ User $username updated in cache');
      }
    } catch (e) {
      print('❌ Failed to update user $username in cache: $e');
    }
  }

  // Check if user exists in cache and is not expired
  static Future<bool> hasUser(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('$_userPrefix$username');
      final timestampStr = prefs.getString('$_cacheTimestampPrefix$username');

      if (userJson != null && timestampStr != null) {
        final timestamp = int.tryParse(timestampStr);
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();

          // Check if cache is still valid
          if (now.difference(cacheTime) < _cacheExpiryDuration) {
            return true;
          } else {
            // Cache expired, remove it
            await removeUser(username);
            return false;
          }
        }
      }
    } catch (e) {
      print('❌ Failed to check if user $username exists in cache: $e');
    }
    return false;
  }

  // Remove a user from cache
  static Future<void> removeUser(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_userPrefix$username');
      await prefs.remove('$_cacheTimestampPrefix$username');
      await _removeFromCachedUsersList(username, prefs);

      print('✅ User $username removed from cache');
    } catch (e) {
      print('❌ Failed to remove user $username from cache: $e');
    }
  }

  // Clear all cached users
  static Future<void> clearAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUsernames = await getAllCachedUsernames();

      for (final username in allUsernames) {
        await prefs.remove('$_userPrefix$username');
        await prefs.remove('$_cacheTimestampPrefix$username');
      }

      await prefs.remove(_allUsersKey);
      print('✅ All users cleared from cache');
    } catch (e) {
      print('❌ Failed to clear all users from cache: $e');
    }
  }

  // Get all cached usernames
  static Future<List<String>> getAllCachedUsernames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usernamesJson = prefs.getString(_allUsersKey);

      if (usernamesJson != null) {
        final List<dynamic> usernamesList = json.decode(usernamesJson);
        return usernamesList.cast<String>();
      }
    } catch (e) {
      print('❌ Failed to get all cached usernames: $e');
    }
    return [];
  }

  // Get cache info for a specific user
  static Future<Map<String, dynamic>> getCacheInfo(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString('$_cacheTimestampPrefix$username');

      if (timestampStr != null) {
        final timestamp = int.tryParse(timestampStr);
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();
          final age = now.difference(cacheTime);

          return {
            'exists': true,
            'cachedAt': cacheTime,
            'age': age,
            'isExpired': age > _cacheExpiryDuration,
          };
        }
      }
    } catch (e) {
      print('❌ Failed to get cache info for user $username: $e');
    }

    return {'exists': false};
  }

  // Get overall cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final allUsernames = await getAllCachedUsernames();
      int expiredCount = 0;
      int validCount = 0;

      for (final username in allUsernames) {
        final cacheInfo = await getCacheInfo(username);
        if (cacheInfo['exists'] == true) {
          if (cacheInfo['isExpired'] == true) {
            expiredCount++;
          } else {
            validCount++;
          }
        }
      }

      return {
        'totalUsers': allUsernames.length,
        'validUsers': validCount,
        'expiredUsers': expiredCount,
        'cacheSize': allUsernames.length,
      };
    } catch (e) {
      print('❌ Failed to get cache stats: $e');
      return {};
    }
  }

  // Helper method to update the list of cached users
  static Future<void> _updateCachedUsersList(
      String username, SharedPreferences prefs) async {
    try {
      final currentList = await getAllCachedUsernames();
      if (!currentList.contains(username)) {
        currentList.add(username);
        await prefs.setString(_allUsersKey, json.encode(currentList));
      }
    } catch (e) {
      print('❌ Failed to update cached users list: $e');
    }
  }

  // Helper method to remove from cached users list
  static Future<void> _removeFromCachedUsersList(
      String username, SharedPreferences prefs) async {
    try {
      final currentList = await getAllCachedUsernames();
      currentList.remove(username);
      await prefs.setString(_allUsersKey, json.encode(currentList));
    } catch (e) {
      print('❌ Failed to remove from cached users list: $e');
    }
  }

  // Clean up expired cache entries
  static Future<void> cleanupExpiredCache() async {
    try {
      final allUsernames = await getAllCachedUsernames();
      int removedCount = 0;

      for (final username in allUsernames) {
        final cacheInfo = await getCacheInfo(username);
        if (cacheInfo['exists'] == true && cacheInfo['isExpired'] == true) {
          await removeUser(username);
          removedCount++;
        }
      }

      print('✅ Cleaned up $removedCount expired user cache entries');
    } catch (e) {
      print('❌ Failed to cleanup expired cache: $e');
    }
  }
}
