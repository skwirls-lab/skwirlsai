import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../domain/entities/user.dart';
import 'desktop_oauth_service.dart';

class AuthService {
  static const _tag = 'AuthService';
  static const _userKey = 'user_profile';
  static const _userInfoEndpoint = 'https://www.googleapis.com/oauth2/v2/userinfo';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final DesktopOAuthService _desktopOAuth;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  final _authStateController = StreamController<AppUser?>.broadcast();
  Stream<AppUser?> get authStateStream => _authStateController.stream;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  AuthService() {
    _desktopOAuth = DesktopOAuthService(secureStorage: _secureStorage);
  }

  /// Initialize auth state from stored tokens
  Future<void> initialize() async {
    Log.i(_tag, 'Initializing auth service...');

    try {
      if (_isDesktop) {
        final restored = await _desktopOAuth.restoreTokens();
        if (restored) {
          await _restoreUser();
          if (_currentUser != null) {
            Log.i(_tag, 'Auth restored for: ${_currentUser?.email}');
          } else {
            // Tokens restored but no user profile — fetch it
            await _fetchAndStoreUserProfile();
          }
        } else {
          Log.i(_tag, 'No stored credentials found');
        }
      }
    } catch (e) {
      Log.e(_tag, 'Failed to initialize auth', e);
      _currentUser = null;
    }

    _authStateController.add(_currentUser);
  }

  /// Get a valid access token for API calls
  Future<String?> getAccessToken() async {
    if (_isDesktop) {
      return _desktopOAuth.getValidAccessToken();
    }
    return null;
  }

  /// Check if user is authenticated (not anonymous)
  bool get isAuthenticated =>
      _currentUser != null && !_currentUser!.isAnonymous;

  /// Sign in with Google
  Future<AppUser> signInWithGoogle() async {
    Log.i(_tag, 'Starting Google Sign-In...');

    if (_isDesktop) {
      final success = await _desktopOAuth.signIn();
      if (!success) {
        throw Exception('Sign-in failed or was cancelled');
      }

      // Fetch user profile from Google
      await _fetchAndStoreUserProfile();

      _authStateController.add(_currentUser);
      Log.i(_tag, 'Signed in as: ${_currentUser!.email}');
      return _currentUser!;
    }

    throw UnsupportedError('Mobile sign-in not yet implemented');
  }

  /// Continue without account (anonymous/offline mode)
  AppUser continueAnonymously() {
    _currentUser = AppUser.anonymous();
    _authStateController.add(_currentUser);
    Log.i(_tag, 'Continuing in anonymous mode');
    return _currentUser!;
  }

  /// Sign out
  Future<void> signOut() async {
    Log.i(_tag, 'Signing out...');

    if (_isDesktop) {
      await _desktopOAuth.signOut();
    }

    await _secureStorage.delete(key: _userKey);

    _currentUser = null;
    _authStateController.add(null);
    Log.i(_tag, 'Signed out');
  }

  /// Fetch user profile from Google's userinfo endpoint
  Future<void> _fetchAndStoreUserProfile() async {
    final token = await getAccessToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(_userInfoEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = AppUser(
          id: data['id'] as String? ?? '',
          email: data['email'] as String? ?? '',
          displayName: data['name'] as String? ?? data['email'] as String? ?? '',
          photoUrl: data['picture'] as String?,
        );

        // Persist user profile
        await _secureStorage.write(
          key: _userKey,
          value: jsonEncode(_currentUser!.toJson()),
        );

        Log.i(_tag, 'User profile fetched: ${_currentUser!.email}');
      } else {
        Log.e(_tag, 'Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      Log.e(_tag, 'Error fetching user profile', e);
    }
  }

  Future<void> _restoreUser() async {
    final stored = await _secureStorage.read(key: _userKey);
    if (stored != null) {
      try {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        _currentUser = AppUser.fromJson(json);
      } catch (_) {
        // Legacy format: pipe-delimited
        final parts = stored.split('|');
        if (parts.length >= 3) {
          _currentUser = AppUser(
            id: parts[0],
            email: parts[1],
            displayName: parts[2],
            photoUrl: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
          );
        }
      }
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
