// DTO Classes and Converters for Flutter App
// Generated from Java Spring Boot DTOs

class ApiResponse {
  final bool success;
  final String message;

  ApiResponse({required this.success, required this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String username;
  final String email;
  final String fullName;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.username,
    required this.email,
    required this.fullName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'username': username,
      'email': email,
      'fullName': fullName,
    };
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String bio;
  final String pfpIndex;
  final String pfpBg;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.bio,
    required this.pfpIndex,
    required this.pfpBg,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      'bio': bio,
      'pfpIndex': pfpIndex,
      'pfpBg': pfpBg,
    };
  }
}

class TokenRefreshResponse {
  final String refreshToken;
  final String accessToken;

  TokenRefreshResponse({
    required this.refreshToken,
    required this.accessToken,
  });

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponse(
      refreshToken: json['refreshToken'] ?? '',
      accessToken: json['accessToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
      'accessToken': accessToken,
    };
  }
}

class ChatRoomDTO {
  final String chatId;
  final String chatName;
  final bool isGroup;
  final String lastMessage;
  final String pfpIndex;
  final String pfpBg;

  ChatRoomDTO({
    required this.chatId,
    required this.chatName,
    required this.isGroup,
    required this.lastMessage,
    required this.pfpIndex,
    required this.pfpBg,
  });

  factory ChatRoomDTO.fromJson(Map<String, dynamic> json) {
    return ChatRoomDTO(
      chatId: json['chatId'] ?? '',
      chatName: json['chatName'] ?? '',
      isGroup: json['isGroup'] ?? false,
      lastMessage: json['lastMessage'] ?? '',
      pfpIndex: json['pfpIndex'] ?? '',
      pfpBg: json['pfpBg'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'chatName': chatName,
      'isGroup': isGroup,
      'lastMessage': lastMessage,
      'pfpIndex': pfpIndex,
      'pfpBg': pfpBg,
    };
  }
}

class CreateGroupRequest {
  final String name;
  final List<String> participants;

  CreateGroupRequest({
    required this.name,
    required this.participants,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'participants': participants,
    };
  }
}

class GroupMembersDTO {
  final String username;
  final String fullName;
  final String pfpIndex;
  final String pfpBg;
  final bool isAdmin;
  final bool isMember;

  GroupMembersDTO({
    required this.username,
    required this.fullName,
    required this.pfpIndex,
    required this.pfpBg,
    required this.isAdmin,
    required this.isMember,
  });

  factory GroupMembersDTO.fromJson(Map<String, dynamic> json) {
    return GroupMembersDTO(
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      pfpIndex: json['pfpIndex'] ?? '',
      pfpBg: json['pfpBg'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      isMember: json['isMember'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'pfpIndex': pfpIndex,
      'pfpBg': pfpBg,
      'isAdmin': isAdmin,
      'isMember': isMember,
    };
  }
}

class GroupChatRoomDTO {
  final String chatName;
  final String chatId;
  final bool isGroup;
  final String adminUsername;
  final List<GroupMembersDTO> groupMembers;
  final List<GroupMembersDTO> memberRequests;
  final String pfpIndex;
  final String pfpBg;

  GroupChatRoomDTO({
    required this.chatName,
    required this.chatId,
    required this.isGroup,
    required this.adminUsername,
    required this.groupMembers,
    required this.memberRequests,
    required this.pfpIndex,
    required this.pfpBg,
  });

  factory GroupChatRoomDTO.fromJson(Map<String, dynamic> json) {
    return GroupChatRoomDTO(
      chatName: json['chatName'] ?? '',
      chatId: json['chatId'] ?? '',
      isGroup: json['isGroup'] ?? false,
      adminUsername: json['adminUsername'] ?? '',
      groupMembers: (json['groupMembers'] as List<dynamic>?)
              ?.map((e) => GroupMembersDTO.fromJson(e))
              .toList() ??
          [],
      memberRequests: (json['memberRequests'] as List<dynamic>?)
              ?.map((e) => GroupMembersDTO.fromJson(e))
              .toList() ??
          [],
      pfpIndex: json['pfpIndex'] ?? '',
      pfpBg: json['pfpBg'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatName': chatName,
      'chatId': chatId,
      'isGroup': isGroup,
      'adminUsername': adminUsername,
      'groupMembers': groupMembers.map((e) => e.toJson()).toList(),
      'memberRequests': memberRequests.map((e) => e.toJson()).toList(),
      'pfpIndex': pfpIndex,
      'pfpBg': pfpBg,
    };
  }
}

class UserChatRoomDTO {
  final String chatName;
  final String userFullName;
  final String chatId;
  final bool isGroup;
  final String userBio;
  final String pfpIndex;
  final String pfpBg;

  UserChatRoomDTO({
    required this.chatName,
    required this.userFullName,
    required this.chatId,
    required this.isGroup,
    required this.userBio,
    required this.pfpIndex,
    required this.pfpBg,
  });

  factory UserChatRoomDTO.fromJson(Map<String, dynamic> json) {
    return UserChatRoomDTO(
      chatName: json['chatName'] ?? '',
      userFullName: json['userFullName'] ?? '',
      chatId: json['chatId'] ?? '',
      isGroup: json['isGroup'] ?? false,
      userBio: json['UserBio'] ?? '',
      pfpIndex: json['pfpIndex'] ?? '',
      pfpBg: json['pfpBg'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatName': chatName,
      'userFullName': userFullName,
      'chatId': chatId,
      'isGroup': isGroup,
      'UserBio': userBio,
      'pfpIndex': pfpIndex,
      'pfpBg': pfpBg,
    };
  }
}

class MessageDTO {
  final int id;
  final String content;
  final String sender;
  final String chatId;
  final DateTime timestamp;
  final bool isOwnMessage;

  MessageDTO({
    required this.id,
    required this.content,
    required this.sender,
    required this.chatId,
    required this.timestamp,
    required this.isOwnMessage,
  });

  factory MessageDTO.fromJson(Map<String, dynamic> json) {
    return MessageDTO(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      sender: json['sender'] ?? '',
      chatId: json['chatId'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isOwnMessage: json['isOwnMessage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'chatId': chatId,
      'timestamp': timestamp.toIso8601String(),
      'isOwnMessage': isOwnMessage,
    };
  }
}

class UserDTO {
  final String username;
  final String fullName;
  final String bio;
  final String pfpIndex;
  final String pfpBg;
  final DateTime joinedAt;

  UserDTO({
    required this.username,
    required this.fullName,
    required this.bio,
    required this.pfpIndex,
    required this.pfpBg,
    required this.joinedAt,
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      bio: json['bio'] ?? '',
      pfpIndex: json['pfpIndex'] ?? '',
      pfpBg: json['pfpBg'] ?? '',
      joinedAt:
          DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'bio': bio,
      'pfpIndex': pfpIndex,
      'pfpBg': pfpBg,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

class UserSearchDTO {
  final String username;
  final String fullName;
  final String pfpIndex;
  final String pfpBg;

  UserSearchDTO({
    required this.username,
    required this.fullName,
    required this.pfpIndex,
    required this.pfpBg,
  });

  factory UserSearchDTO.fromJson(Map<String, dynamic> json) {
    return UserSearchDTO(
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      pfpIndex: json['pfpIndex'] ?? '',
      pfpBg: json['pfpBg'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'pfpIndex': pfpIndex,
      'pfpBg': pfpBg,
    };
  }
}

class ChatHistoryResponse {
  final String chatId;
  final dynamic messages;
  final bool success;
  final String error;

  ChatHistoryResponse({
    required this.chatId,
    required this.messages,
    required this.success,
    this.error = '',
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ChatHistoryResponse(
      chatId: json['chatId'] ?? '',
      messages: json['messages'],
      success: json['success'] ?? false,
      error: json['error'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'messages': messages,
      'success': success,
      'error': error,
    };
  }
}

class ChatMessageRequest {
  final String content;

  ChatMessageRequest({required this.content});

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}

// Converter Classes
class ChatDTOConvertor {
  ChatRoomDTO convertToChatRoomDTO(Map<String, dynamic> chatRoomData) {
    return ChatRoomDTO(
      chatId: chatRoomData['chatId'] ?? '',
      chatName: chatRoomData['chatName'] ?? '',
      isGroup: chatRoomData['isGroup'] ?? false,
      lastMessage: chatRoomData['lastMessage'] ?? '',
      pfpIndex: chatRoomData['pfpIndex'] ?? '',
      pfpBg: chatRoomData['pfpBg'] ?? '',
    );
  }

  UserChatRoomDTO convertToUserChatRoomDTO(
      Map<String, dynamic> chatRoomData, Map<String, dynamic> otherUserData) {
    return UserChatRoomDTO(
      chatName: chatRoomData['chatName'] ?? '',
      userFullName: otherUserData['fullName'] ?? '',
      chatId: chatRoomData['chatId'] ?? '',
      isGroup: chatRoomData['isGroup'] ?? false,
      userBio: otherUserData['bio'] ?? '',
      pfpIndex: otherUserData['pfpIndex'] ?? '',
      pfpBg: otherUserData['pfpBg'] ?? '',
    );
  }

  GroupMembersDTO convertToGroupMembersDTO(
      Map<String, dynamic> userData, bool isAdmin, bool isMember) {
    return GroupMembersDTO(
      username: userData['username'] ?? '',
      fullName: userData['fullName'] ?? '',
      pfpIndex: userData['pfpIndex'] ?? '',
      pfpBg: userData['pfpBg'] ?? '',
      isAdmin: isAdmin,
      isMember: isMember,
    );
  }

  GroupChatRoomDTO convertToGroupChatRoomDTO(
      Map<String, dynamic> chatRoomData,
      String adminUsername,
      List<GroupMembersDTO> groupMembers,
      List<GroupMembersDTO> memberRequests) {
    return GroupChatRoomDTO(
      chatName: chatRoomData['chatName'] ?? '',
      chatId: chatRoomData['chatId'] ?? '',
      isGroup: chatRoomData['isGroup'] ?? false,
      adminUsername: adminUsername,
      groupMembers: groupMembers,
      memberRequests: memberRequests,
      pfpIndex: chatRoomData['pfpIndex'] ?? '',
      pfpBg: chatRoomData['pfpBg'] ?? '',
    );
  }

  List<GroupMembersDTO> mapUsersToGroupMembersDTO(
      List<Map<String, dynamic>> users, String adminUsername) {
    return users.map((user) {
      return convertToGroupMembersDTO(
        user,
        adminUsername == user['username'],
        true, // they're members
      );
    }).toList();
  }
}

class MessageDTOConvertor {
  MessageDTO convertToMessageDTO(
      Map<String, dynamic> messageData, String currentUsername) {
    return MessageDTO(
      id: messageData['messageId'] ?? messageData['id'] ?? 0,
      content: messageData['messageContent'] ?? messageData['content'] ?? '',
      sender: messageData['sender']?['username'] ?? messageData['sender'] ?? '',
      chatId: messageData['chatRoom']?['chatId'] ?? messageData['chatId'] ?? '',
      timestamp: DateTime.parse(
          messageData['timestamp'] ?? DateTime.now().toIso8601String()),
      isOwnMessage:
          (messageData['sender']?['username'] ?? messageData['sender'] ?? '') ==
              currentUsername,
    );
  }
}

class UserDTOConvertor {
  UserSearchDTO convertToSearchDTO(Map<String, dynamic> userData) {
    return UserSearchDTO(
      username: userData['username'] ?? '',
      fullName: userData['fullName'] ?? '',
      pfpIndex: userData['pfpIndex'] ?? '',
      pfpBg: userData['pfpBg'] ?? '',
    );
  }

  UserDTO convertToUserDTO(Map<String, dynamic> userData) {
    return UserDTO(
      username: userData['username'] ?? '',
      fullName: userData['fullName'] ?? '',
      bio: userData['bio'] ?? '',
      pfpIndex: userData['pfpIndex'] ?? '',
      pfpBg: userData['pfpBg'] ?? '',
      joinedAt: DateTime.parse(
          userData['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
