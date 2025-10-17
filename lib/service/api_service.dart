import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:urchat_back_testing/model/chat_room.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/model/message.dart';
import 'package:urchat_back_testing/model/user.dart';
import 'package:urchat_back_testing/service/websocket_service.dart';
import 'storage_service.dart';

class ApiService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? "";
  static final StorageService _storage = StorageService();

  static String? accessToken;
  static String? refreshToken;
  static String? currentUsername;

  static WebSocketService? _webSocketService;

  static Future<void> init() async {
    await _storage.init();
    accessToken = _storage.accessToken;
    refreshToken = _storage.refreshToken;
    currentUsername = _storage.currentUsername;
  }

  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  static bool get isAuthenticated {
    return accessToken != null &&
        refreshToken != null &&
        !_storage.isRefreshTokenExpired;
  }

  static bool get hasStoredAuth => _storage.isLoggedIn;

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
      await _saveAuthData(authResponse);
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
      await _saveAuthData(authResponse);
      return authResponse;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      );
    } catch (e) {
      print('Logout API error: $e');
    } finally {
      await _storage.clearAuthData();
      accessToken = null;
      refreshToken = null;
      currentUsername = null;
    }
  }

  static Future<void> initiateRegistration(RegisterRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/initiate-registration'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Registration initiation failed: ${response.body}');
    }
  }

  static Future<AuthResponse> completeRegistration(
      RegisterRequest request, String otp) async {
    final completeRequest = {
      'registerRequest': request.toJson(),
      'otp': otp,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/auth/complete-registration'),
      headers: headers,
      body: jsonEncode(completeRequest),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _saveAuthData(authResponse);
      return authResponse;
    } else {
      throw Exception('Registration completion failed: ${response.body}');
    }
  }

  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: headers,
      body: jsonEncode({'email': email, 'purpose': 'PASSWORD_RESET'}),
    );

    if (response.statusCode != 200) {
      throw Exception('Password reset request failed: ${response.body}');
    }
  }

  static Future<void> resetPassword(
      String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Password reset failed: ${response.body}');
    }
  }

  static Future<void> resendOtp(String email, String purpose) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-otp'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'purpose': purpose,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resend OTP: ${response.body}');
    }
  }

  // ============ CHAT METHODS ============
  static Future<List<ChatRoom>> getUserChats() async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/chats'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chats: ${response.statusCode}');
    }
  }

  static Future<ChatRoomDTO> createIndividualChat(String withUser) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/individual?withUser=$withUser'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return ChatRoomDTO.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create chat: ${response.body}');
    }
  }

  static Future<List<Message>> getChatMessages(String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/$chatId/messages'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  static Future<List<Message>> getPaginatedMessages(
      String chatId, int page, int size) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse(
            '$baseUrl/chat/$chatId/messages/paginated?page=$page&size=$size'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load paginated messages: ${response.statusCode}');
    }
  }

  static Future<void> deleteMessage(String chatId, int messageId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.delete(
        Uri.parse('$baseUrl/chat/message/$messageId'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message: ${response.body}');
    }
  }

// ============ CHAT DELETION METHODS ============
  static Future<void> deleteChat(String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.delete(
        Uri.parse('$baseUrl/chat/$chatId'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to delete chat: ${response.body}');
    }
  }

  static Future<void> leaveChat(String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/$chatId/leave'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to leave chat: ${response.body}');
    }
  }

  // ============ USER METHODS ============
  static Future<List<User>> searchUsers(String query) async {
    if (query.length < 2) return [];

    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/users/search?q=${Uri.encodeQueryComponent(query)}'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Search failed: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/users/self/profile'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String username) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/users/$username/profile'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: json.encode(profileData),
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  // ============ GROUP METHODS ============
  static Future<GroupChatRoomDTO> createGroup(
      String name, List<String> participants) async {
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

    if (response.statusCode == 200) {
      return GroupChatRoomDTO.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create group: ${response.body}');
    }
  }

  static Future<GroupChatRoomDTO> updateGroupPfp(
      String chatId, String pfpIndex, String pfpBg) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.put(
        Uri.parse('$baseUrl/chat/group/$chatId/updatePfp'),
        headers: headers,
        body: jsonEncode({
          'pfpIndex': pfpIndex,
          'pfpBg': pfpBg,
        }),
      );
    });

    if (response.statusCode == 200) {
      return GroupChatRoomDTO.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update group pfp: ${response.body}');
    }
  }

  static Future<GroupChatRoomDTO> getGroupDetails(String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/group/$chatId/details'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return GroupChatRoomDTO.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load group details: ${response.body}');
    }
  }

  static Future<void> inviteToGroup(
      String chatId, String inviteeUsername) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse(
            '$baseUrl/chat/group/$chatId/invite?inviteeUsername=${Uri.encodeQueryComponent(inviteeUsername)}'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to invite user to group: ${response.body}');
    }
  }

  static Future<void> removeFromGroup(
      String chatId, String removeUsername) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse(
            '$baseUrl/chat/group/$chatId/remove?removeUsername=${Uri.encodeQueryComponent(removeUsername)}'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to remove user from group: ${response.body}');
    }
  }

  static Future<void> leaveGroup(String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/group/$chatId/leave'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to leave group: ${response.body}');
    }
  }

  static Future<List<ChatRoom>> searchGroups(String name) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse(
            '$baseUrl/chat/groups/search?name=${Uri.encodeQueryComponent(name)}'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search groups: ${response.body}');
    }
  }

  static Future<bool> changeAdmin(
      String chatId, String candidateUsername) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.put(
        Uri.parse('$baseUrl/chat/group/changeAdmin'),
        headers: headers,
        body: jsonEncode({
          'adminUsername': currentUsername,
          'candidateUsername': candidateUsername,
          'chatId': chatId,
        }),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to change admin: ${response.body}');
    }
  }

  static Future<List<ChatRoom>> getGroupInvitations() async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/group/invitations'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load group invitations: ${response.body}');
    }
  }

  static Future<void> acceptGroupInvitation(String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/group/$chatId/accept'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to accept group invitation: ${response.body}');
    }
  }

  static Future<void> declineGroupInvitation(String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/chat/group/$chatId/decline'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to decline group invitation: ${response.body}');
    }
  }

  //============= FCMMETHODS ===============

  static Future<void> saveFcmToken(String fcmToken) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/notifications/token'),
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to save FCM token');
    }
  }

  static Future<void> removeFcmToken() async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.delete(
        Uri.parse('$baseUrl/notifications/token'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to remove FCM token');
    }
  }

  // ============ THEME METHODS ============
  static Future<void> updateChatTheme(
      Map<String, dynamic> chatTheme, String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.put(
        Uri.parse('$baseUrl/chat/theme/$chatId/change'),
        headers: headers,
        body: json.encode(chatTheme),
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to update chat theme');
    }
  }

  static Future<Map<String, dynamic>> getChatTheme(String chatId) async {
    final response = await _makeAuthenticatedRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/chat/theme/$chatId'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load chat theme');
    }
  }

  // ============ CORE AUTH LOGIC ============
  static Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    if (_storage.shouldRefreshAccessToken) {
      print('🔄 Access token needs refresh');
      final success = await _refreshAccessToken();
      if (!success) {
        throw Exception('Authentication failed. Please login again.');
      }
    }

    var response = await requestFn();

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount <= maxRetries) {
      if (response.statusCode == 401) {
        print('🔄 Token rejected (401), attempting refresh...');
        final success = await _refreshAccessToken();
        if (success) {
          response = await requestFn();
        } else {
          throw Exception('Authentication failed. Please login again.');
        }
      }

      if (response.statusCode == 401 && retryCount < maxRetries) {
        retryCount++;
        continue;
      }

      return response;
    }

    throw Exception('Max retry attempts exceeded');
  }

  static Future<bool> _refreshAccessToken() async {
    try {
      print('🔄 Refreshing access token...');

      if (refreshToken == null || _storage.isRefreshTokenExpired) {
        print('❌ Refresh token expired or missing');
        await logout();
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final tokenResponse =
            TokenRefreshResponse.fromJson(jsonDecode(response.body));
        await _saveTokenData(tokenResponse);
        _webSocketService?.reconnectWithNewToken();
        print('✅ Access token refreshed successfully');
        return true;
      } else {
        print('❌ Token refresh failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
      return false;
    }
  }

  // ============ HELPER METHODS ============
  static Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _storage.saveAuthData(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      username: authResponse.username,
      accessTokenExpiry: authResponse.accessTokenExpiry.toIso8601String(),
      refreshTokenExpiry: authResponse.refreshTokenExpiry.toIso8601String(),
    );
    accessToken = authResponse.accessToken;
    refreshToken = authResponse.refreshToken;
    currentUsername = authResponse.username;
  }

  static Future<void> _saveTokenData(TokenRefreshResponse tokenResponse) async {
    await _storage.saveAuthData(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
      username: currentUsername!,
      accessTokenExpiry: tokenResponse.accessTokenExpiry.toIso8601String(),
      refreshTokenExpiry: tokenResponse.refreshTokenExpiry.toIso8601String(),
    );
    accessToken = tokenResponse.accessToken;
    refreshToken = tokenResponse.refreshToken;
  }

  static void setWebSocketService(WebSocketService webSocketService) {
    _webSocketService = webSocketService;
  }
}
