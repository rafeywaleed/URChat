import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/model/user.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.102:8081';
  static final StorageService _storage = StorageService();

  static Future<void> init() async {
    await _storage.init();
    accessToken = _storage.accessToken;
    refreshToken = _storage.refreshToken;
    currentUsername = _storage.currentUsername;
  }

  static String? accessToken;
  static String? refreshToken;
  static String? currentUsername;

  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  // Auth endpoints
  static Future<AuthResponse> register(
      String username, String email, String password, String fullName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
        'bio': 'Hello! I am using URChat',
        'pfpIndex': '😊',
        'pfpBg': '#4CAF50',
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _storage.saveAuthData(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        username: authResponse.username,
      );
      accessToken = authResponse.accessToken;
      refreshToken = authResponse.refreshToken;
      currentUsername = authResponse.username;
      return authResponse;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  static Future<AuthResponse> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _storage.saveAuthData(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        username: authResponse.username,
      );
      accessToken = authResponse.accessToken;
      refreshToken = authResponse.refreshToken;
      currentUsername = authResponse.username;
      return authResponse;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        await _storage.clearAuthData();
        accessToken = null;
        refreshToken = null;
        currentUsername = null;
      }
    } catch (e) {
      await _storage.clearAuthData();
      accessToken = null;
      refreshToken = null;
      currentUsername = null;
    }
  }

  static bool get isAuthenticated {
    return accessToken != null && accessToken!.isNotEmpty;
  }

  static bool get hasStoredAuth {
    return _storage.isLoggedIn;
  }

  static Future<List<ChatRoom>> getUserChats() async {
    print('🔍 Fetching user chats...');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/chats'),
        headers: headers,
      );
    });

    print('📡 Response status: ${response.statusCode}');
    print('📡 Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        print('📦 Parsed ${data.length} chats');

        final chats = data.map((json) {
          print('🔍 Parsing chat: $json');
          return ChatRoom.fromJson(json);
        }).toList();

        for (var chat in chats) {
          print(
              '✅ Loaded chat: ${chat.chatName} (ID: ${chat.chatId}), Last Msg: ${chat.lastMessage}');
        }

        print('✅ Successfully loaded ${chats.length} chats');
        return chats;
      } catch (e) {
        print('❌ Error parsing chats: $e');
        throw Exception('Failed to parse chat data: $e');
      }
    } else {
      throw Exception(
          'Failed to load chats: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<ChatRoom> createIndividualChat(String withUser) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/individual?withUser=$withUser'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return ChatRoom.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create chat: ${response.body}');
    }
  }

  static Future<List<Message>> getChatMessages(String chatId) async {
    print('🔍 Fetching messages for chat: $chatId');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/$chatId/messages'),
        headers: headers,
      );
    });

    print('📡 Messages response status: ${response.statusCode}');
    print('📡 Messages response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        print('📦 Parsed ${data.length} messages');
        return data.map((json) => Message.fromJson(json)).toList();
      } catch (e) {
        print('❌ Error parsing messages: $e');
        throw Exception('Failed to parse messages: $e');
      }
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  static Future<List<User>> searchUsers(String query) async {
    try {
      if (query.length < 2) {
        return [];
      }

      final response = await _makeAuthenticatedRequest(() async {
        return await http
            .get(
              Uri.parse(
                  '$baseUrl/users/search?q=${Uri.encodeQueryComponent(query)}'),
              headers: headers,
            )
            .timeout(Duration(seconds: 10));
      });

      print('🔍 Search API Response - Status: ${response.statusCode}');
      print('🔍 Search API Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Search found ${data.length} users');

        // Debug: Print each user data
        for (var userData in data) {
          print('👤 User data: $userData');
        }

        final users = data.map((json) {
          try {
            return User.fromJson(json);
          } catch (e) {
            print('❌ Error parsing user: $e');
            print('❌ Problematic JSON: $json');
            rethrow;
          }
        }).toList();

        print('✅ Successfully parsed ${users.length} users');
        return users;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error during search: $e');
      throw Exception('Network error. Please check your connection.');
    } on TimeoutException catch (e) {
      print('❌ Search timeout: $e');
      throw Exception('Search timeout. Please try again.');
    } catch (e) {
      print('❌ Unexpected search error: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final response = await _makeAuthenticatedRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/users/self/profile'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String username) async {
    print("🔍 Fetching profile for user: $username");
    try {
      final response = await _makeAuthenticatedRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/users/$username/profile'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _makeAuthenticatedRequest(() async {
        return await http.put(
          Uri.parse('$baseUrl/users/profile'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(profileData),
        );
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  static Future<List<Message>> getPaginatedMessages(
      String chatId, int page, int size) async {
    print('🔍 Fetching paginated messages for chat: $chatId, page: $page');

    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse(
            '$baseUrl/chat/$chatId/messages/paginated?page=$page&size=$size'),
        headers: headers,
      );
    });

    print('📡 Paginated messages response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        print('📦 Parsed ${data.length} messages for page $page');
        return data.map((json) => Message.fromJson(json)).toList();
      } catch (e) {
        print('❌ Error parsing paginated messages: $e');
        throw Exception('Failed to parse paginated messages: $e');
      }
    } else {
      throw Exception(
          'Failed to load paginated messages: ${response.statusCode}');
    }
  }

  static Future<GroupChatRoomDTO> createGroup(
      String name, List<String> participants) async {
    print('👥 Creating group: $name with ${participants.length} participants');

    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/group'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'participants': participants,
        }),
      );
    });

    print('📡 Create group response status: ${response.statusCode}');
    print('📡 Create group response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('✅ Successfully created group: $name');
      return GroupChatRoomDTO.fromJson(data);
    } else {
      throw Exception(
          'Failed to create group: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<GroupChatRoomDTO> updateGroupPfp(
      String chatId, String pfpIndex, String pfpBg) async {
    print('🎨 Updating group pfp for: $chatId');

    final response = await _makeAuthenticatedRequest(() async {
      return await http.put(
        Uri.parse('$baseUrl/chat/group/$chatId'),
        headers: headers,
        body: jsonEncode({
          'pfpIndex': pfpIndex,
          'pfpBg': pfpBg,
        }),
      );
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('✅ Successfully updated group pfp');
      return GroupChatRoomDTO.fromJson(data);
    } else {
      throw Exception(
          'Failed to update group pfp: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<GroupChatRoomDTO> getGroupDetails(String chatId) async {
    print('🔍 Fetching group details for: $chatId');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/group/$chatId/details'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('✅ Successfully loaded group details');
      return GroupChatRoomDTO.fromJson(data);
    } else {
      throw Exception(
          'Failed to load group details: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> inviteToGroup(
      String chatId, String inviteeUsername) async {
    print('📨 Inviting $inviteeUsername to group: $chatId');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse(
            '$baseUrl/chat/group/$chatId/invite?inviteeUsername=${Uri.encodeQueryComponent(inviteeUsername)}'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      print('✅ Successfully invited user to group');
    } else {
      throw Exception(
          'Failed to invite user to group: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> removeFromGroup(
      String chatId, String removeUsername) async {
    print('🗑️ Removing $removeUsername from group: $chatId');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse(
            '$baseUrl/chat/group/$chatId/remove?removeUsername=${Uri.encodeQueryComponent(removeUsername)}'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      print('✅ Successfully removed user from group');
    } else {
      throw Exception(
          'Failed to remove user from group: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> leaveGroup(String chatId) async {
    print('🚪 Leaving group: $chatId');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/group/$chatId/leave'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      print('✅ Successfully left group');
    } else {
      throw Exception(
          'Failed to leave group: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<ChatRoom>> searchGroups(String name) async {
    print('🔍 Searching groups with name: $name');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse(
            '$baseUrl/chat/groups/search?name=${Uri.encodeQueryComponent(name)}'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('✅ Found ${data.length} groups');
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to search groups: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<ChatRoom>> getGroupInvitations() async {
    print('🔍 Fetching group invitations...');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/group/invitations'),
        headers: headers,
      );
    });

    print('📡 Group invitations response status: ${response.statusCode}');
    print('📡 Group invitations response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        print('📦 Parsed ${data.length} group invitations');

        final invitations = data.map((json) {
          print('🔍 Parsing invitation: $json');
          return ChatRoom.fromJson(json);
        }).toList();

        for (var invitation in invitations) {
          print(
              '✅ Loaded invitation: ${invitation.chatName} (ID: ${invitation.chatId})');
        }

        print('✅ Successfully loaded ${invitations.length} group invitations');
        return invitations;
      } catch (e) {
        print('❌ Error parsing group invitations: $e');
        throw Exception('Failed to parse group invitation data: $e');
      }
    } else {
      throw Exception(
          'Failed to load group invitations: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> acceptGroupInvitation(String chatId) async {
    print('✅ Accepting group invitation for chat: $chatId');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/group/$chatId/accept'),
        headers: headers,
      );
    });

    print('📡 Accept invitation response status: ${response.statusCode}');
    print('📡 Accept invitation response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Successfully accepted group invitation');
    } else {
      throw Exception(
          'Failed to accept group invitation: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> declineGroupInvitation(String chatId) async {
    print('❌ Declining group invitation for chat: $chatId');
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/group/$chatId/decline'),
        headers: headers,
      );
    });

    print('📡 Decline invitation response status: ${response.statusCode}');
    print('📡 Decline invitation response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Successfully declined group invitation');
    } else {
      throw Exception(
          'Failed to decline group invitation: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateChatTheme(
      Map<String, dynamic> chatTheme, String chatId) async {
    try {
      final response = await _makeAuthenticatedRequest(() async {
        return await http.put(
          Uri.parse('$baseUrl/chat/theme/$chatId/change'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(chatTheme),
        );
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  static Future<Map<String, dynamic>> getChatTheme(String chatId) async {
    try {
      final response = await _makeAuthenticatedRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/chat/theme/$chatId'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  static Future<bool> refreshAccessToken() async {
    try {
      print('🔄 Attempting to refresh access token...');

      if (refreshToken == null || refreshToken!.isEmpty) {
        print('❌ No refresh token available');
        return false;
      }
      print("🔄 Using refresh token: $refreshToken");

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      print('📡 Refresh token response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final tokenResponse =
            TokenRefreshResponse.fromJson(jsonDecode(response.body));
        await _storage.saveAuthData(
          accessToken: tokenResponse.accessToken,
          refreshToken: refreshToken ?? '',
          username: currentUsername!,
        );
        accessToken = tokenResponse.accessToken;
        print('✅ Access token refreshed successfully');
        return true;
      } else {
        print('❌ Token refresh failed: ${response.body}');
        // If refresh fails, clear auth data
        await _storage.clearAuthData();
        accessToken = null;
        refreshToken = null;
        currentUsername = null;
        return false;
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
      return false;
    }
  }

  static Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    var response = await requestFn();

    if (response.statusCode == 401 || response.statusCode == 403) {
      print('🔐 Token expired, attempting refresh...');
      final refreshSuccess = await refreshAccessToken();

      if (refreshSuccess) {
        response = await requestFn();
      } else {
        throw Exception('Authentication failed. Please login again.');
      }
    }

    return response;
  }
}
