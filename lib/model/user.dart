class User {
  final String username;
  final String email;
  final String fullName;
  final String bio;
  final String pfpIndex;
  final String pfpBg;
  final String joinedAt;
  final String refreshToken;
  final DateTime refreshTokenExpiry;

  User({
    required this.username,
    required this.email,
    required this.fullName,
    required this.bio,
    required this.pfpIndex,
    required this.pfpBg,
    required this.joinedAt,
    required this.refreshToken,
    required this.refreshTokenExpiry,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      bio: (json['bio'] == null || json['bio'].toString().isEmpty)
          ? ''
          : json['bio'],
      pfpIndex:
          (json['pfpIndex'] == null || json['pfpIndex'].toString().isEmpty)
              ? '😊'
              : json['pfpIndex'],
      pfpBg: (json['pfpBg'] == null || json['pfpBg'].toString().isEmpty)
          ? '#4CAF50'
          : json['pfpBg'],
      joinedAt: json['joinedAt'] ?? '',
      refreshToken: (json['refreshToken'] == null ||
              json['refreshToken'].toString().isEmpty)
          ? ''
          : json['refreshToken'],
      refreshTokenExpiry: json['refreshTokenExpiry'] != null &&
              json['refreshTokenExpiry'].toString().isNotEmpty
          ? DateTime.tryParse(json['refreshTokenExpiry']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
