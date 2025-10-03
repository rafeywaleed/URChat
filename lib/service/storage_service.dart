import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _currentUsernameKey = 'current_username';
  static const String _isLoggedInKey = 'is_logged_in';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save tokens and user data
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String username,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_currentUsernameKey, username);
    await _prefs.setBool(_isLoggedInKey, true);
  }

  // Clear auth data (logout)
  Future<void> clearAuthData() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_currentUsernameKey);
    await _prefs.setBool(_isLoggedInKey, false);
  }

  // Getters
  String? get accessToken => _prefs.getString(_accessTokenKey);
  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  String? get currentUsername => _prefs.getString(_currentUsernameKey);
  bool get isLoggedIn => _prefs.getBool(_isLoggedInKey) ?? false;

  // Check if user is authenticated
  bool get isAuthenticated {
    return accessToken != null && accessToken!.isNotEmpty && isLoggedIn;
  }
}
