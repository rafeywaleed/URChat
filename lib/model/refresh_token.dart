class TokenRefreshResponse {
  final String accessToken;
  final String tokenType;

  TokenRefreshResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponse(
      accessToken: json['accessToken'],
      tokenType: json['tokenType'],
    );
  }
}
