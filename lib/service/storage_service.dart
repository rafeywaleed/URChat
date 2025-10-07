// service/storage_service.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _currentUsernameKey = 'current_username';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';

  late SharedPreferences _prefs;

  @override
  Future<StorageService> init() async {
    print('🔄 Initializing StorageService...');
    try {
      _prefs = await SharedPreferences.getInstance();
      print('✅ StorageService initialized successfully');
      return this;
    } catch (e) {
      print('❌ Error initializing StorageService: $e');
      rethrow;
    }
  }

  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String username,
    required String accessTokenExpiry,
    required String refreshTokenExpiry,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_currentUsernameKey, username);
    await _prefs.setString(_accessTokenExpiryKey, accessTokenExpiry);
    await _prefs.setString(_refreshTokenExpiryKey, refreshTokenExpiry);
  }

  Future<void> clearAuthData() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_currentUsernameKey);
    await _prefs.remove(_accessTokenExpiryKey);
    await _prefs.remove(_refreshTokenExpiryKey);
  }

  // Getters
  String? get accessToken => _prefs.getString(_accessTokenKey);
  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  String? get currentUsername => _prefs.getString(_currentUsernameKey);

  DateTime? get accessTokenExpiry {
    final expiry = _prefs.getString(_accessTokenExpiryKey);
    return expiry != null ? DateTime.parse(expiry) : null;
  }

  DateTime? get refreshTokenExpiry {
    final expiry = _prefs.getString(_refreshTokenExpiryKey);
    return expiry != null ? DateTime.parse(expiry) : null;
  }

  bool get isAccessTokenExpired {
    return accessTokenExpiry == null ||
        DateTime.now().isAfter(accessTokenExpiry!);
  }

  bool get isRefreshTokenExpired {
    return refreshTokenExpiry == null ||
        DateTime.now().isAfter(refreshTokenExpiry!);
  }

  bool get shouldRefreshAccessToken {
    if (accessTokenExpiry == null) return true;

    // Refresh if expired or expires in less than 5 minutes
    final timeUntilExpiry = accessTokenExpiry!.difference(DateTime.now());
    return timeUntilExpiry.inMinutes < 5;
  }

  bool get isLoggedIn {
    return accessToken != null &&
        refreshToken != null &&
        !isRefreshTokenExpired;
  }
}
