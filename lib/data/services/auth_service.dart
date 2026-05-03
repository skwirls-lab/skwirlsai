import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/user.dart';

class AuthService {
  static const _tag = 'AuthService';
  static const _tokenKey = 'oauth_access_token';
  static const _refreshTokenKey = 'oauth_refresh_token';
  static const _expiryKey = 'oauth_token_expiry';
  static const _userKey = 'user_profile';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ApiConstants.googleOAuthScopes,
  );

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  final _authStateController = StreamController<AppUser?>.broadcast();
  Stream<AppUser?> get authStateStream => _authStateController.stream;

  gauth.AccessCredentials? _credentials;
  gauth.AccessCredentials? get credentials => _credentials;

  /// Initialize auth state from stored tokens
  Future<void> initialize() async {
    Log.i(_tag, 'Initializing auth service...');

    try {
      final accessToken = await _secureStorage.read(key: _tokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final expiryStr = await _secureStorage.read(key: _expiryKey);

      if (accessToken != null && expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);

        _credentials = gauth.AccessCredentials(
          gauth.AccessToken('Bearer', accessToken, expiry.toUtc()),
          refreshToken,
          ApiConstants.googleOAuthScopes,
        );

        // Check if token is expired
        if (expiry.isBefore(DateTime.now())) {
          Log.i(_tag, 'Token expired, attempting refresh...');
          await _refreshToken();
        }

        // Try to restore user from stored profile
        await _restoreUser();
        Log.i(_tag, 'Auth restored for: ${_currentUser?.email}');
      } else {
        Log.i(_tag, 'No stored credentials found');
      }
    } catch (e) {
      Log.e(_tag, 'Failed to initialize auth', e);
      _currentUser = null;
    }

    _authStateController.add(_currentUser);
  }

  /// Sign in with Google
  Future<AppUser> signInWithGoogle() async {
    Log.i(_tag, 'Starting Google Sign-In...');

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Sign-in cancelled by user');
      }

      final auth = await account.authentication;

      // Store tokens securely
      if (auth.accessToken != null) {
        await _secureStorage.write(key: _tokenKey, value: auth.accessToken);
      }

      // Create credentials for API access
      _credentials = gauth.AccessCredentials(
        gauth.AccessToken(
          'Bearer',
          auth.accessToken ?? '',
          DateTime.now().add(const Duration(hours: 1)).toUtc(),
        ),
        null, // Refresh token from Google Sign-In plugin
        ApiConstants.googleOAuthScopes,
      );

      await _secureStorage.write(
        key: _expiryKey,
        value: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      );

      _currentUser = AppUser(
        id: account.id,
        email: account.email,
        displayName: account.displayName ?? account.email,
        photoUrl: account.photoUrl,
      );

      // Persist user profile
      await _secureStorage.write(
        key: _userKey,
        value: '${_currentUser!.id}|${_currentUser!.email}|${_currentUser!.displayName}|${_currentUser!.photoUrl ?? ""}',
      );

      _authStateController.add(_currentUser);
      Log.i(_tag, 'Signed in as: ${_currentUser!.email}');
      return _currentUser!;
    } catch (e, st) {
      Log.e(_tag, 'Google Sign-In failed', e, st);
      rethrow;
    }
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

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expiryKey);
    await _secureStorage.delete(key: _userKey);

    _currentUser = null;
    _credentials = null;
    _authStateController.add(null);
    Log.i(_tag, 'Signed out');
  }

  /// Check if user is authenticated (not anonymous)
  bool get isAuthenticated =>
      _currentUser != null && !_currentUser!.isAnonymous;

  Future<void> _refreshToken() async {
    // Google Sign-In plugin handles token refresh automatically
    // This is a fallback for manual refresh if needed
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.accessToken != null) {
          await _secureStorage.write(key: _tokenKey, value: auth.accessToken);
          await _secureStorage.write(
            key: _expiryKey,
            value: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          );
          _credentials = gauth.AccessCredentials(
            gauth.AccessToken(
              'Bearer',
              auth.accessToken!,
              DateTime.now().add(const Duration(hours: 1)).toUtc(),
            ),
            null,
            ApiConstants.googleOAuthScopes,
          );
          Log.i(_tag, 'Token refreshed');
        }
      }
    } catch (e) {
      Log.e(_tag, 'Token refresh failed', e);
    }
  }

  Future<void> _restoreUser() async {
    final stored = await _secureStorage.read(key: _userKey);
    if (stored != null) {
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

  void dispose() {
    _authStateController.close();
  }
}
