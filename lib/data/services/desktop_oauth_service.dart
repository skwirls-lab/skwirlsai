import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/google_oauth_config.dart';
import '../../core/utils/logger.dart';

/// Handles OAuth 2.0 Authorization Code flow with PKCE for desktop platforms.
/// Opens the system browser for sign-in, receives the auth code via a
/// temporary localhost HTTP server, then exchanges it for access + refresh tokens.
class DesktopOAuthService {
  static const _tag = 'DesktopOAuth';

  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _revokeEndpoint = 'https://oauth2.googleapis.com/revoke';

  static const _accessTokenKey = 'google_access_token';
  static const _refreshTokenKey = 'google_refresh_token';
  static const _expiryKey = 'google_token_expiry';

  final FlutterSecureStorage _secureStorage;
  HttpServer? _callbackServer;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

  DesktopOAuthService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Try to restore tokens from secure storage
  Future<bool> restoreTokens() async {
    try {
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final expiryStr = await _secureStorage.read(key: _expiryKey);

      if (_accessToken == null || _refreshToken == null) {
        Log.i(_tag, 'No stored tokens found');
        return false;
      }

      if (expiryStr != null) {
        _tokenExpiry = DateTime.parse(expiryStr);
      }

      // If expired, try refreshing
      if (_tokenExpiry != null && _tokenExpiry!.isBefore(DateTime.now())) {
        Log.i(_tag, 'Stored token expired, refreshing...');
        return await refreshAccessToken();
      }

      Log.i(_tag, 'Tokens restored successfully');
      return true;
    } catch (e) {
      Log.e(_tag, 'Failed to restore tokens', e);
      return false;
    }
  }

  /// Launch the full OAuth sign-in flow.
  /// Opens browser → user signs in → we receive auth code → exchange for tokens.
  Future<bool> signIn() async {
    try {
      // Generate PKCE code verifier + challenge
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // Start localhost callback server (completes when auth code arrives)
      final authCodeFuture = await _startCallbackServer();

      // Build authorization URL
      final authUrl = Uri.parse(_authEndpoint).replace(queryParameters: {
        'client_id': GoogleOAuthConfig.clientId,
        'redirect_uri': GoogleOAuthConfig.redirectUri,
        'response_type': 'code',
        'scope': ApiConstants.googleOAuthScopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
      });

      Log.i(_tag, 'Opening browser for Google sign-in...');
      final launched = await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        Log.e(_tag, 'Could not open browser');
        _callbackServer?.close();
        return false;
      }

      // Wait for the auth code from the callback server
      final code = await authCodeFuture;
      if (code == null) {
        Log.e(_tag, 'No authorization code received');
        return false;
      }

      Log.i(_tag, 'Authorization code received, exchanging for tokens...');

      // Exchange auth code for tokens
      final success = await _exchangeCodeForTokens(code, codeVerifier);
      return success;
    } catch (e, st) {
      Log.e(_tag, 'Sign-in failed', e, st);
      _callbackServer?.close();
      return false;
    }
  }

  /// Refresh the access token using the stored refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': GoogleOAuthConfig.clientId,
          'client_secret': GoogleOAuthConfig.clientSecret,
          'refresh_token': _refreshToken!,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode != 200) {
        Log.e(_tag, 'Token refresh failed: ${response.statusCode} ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String;
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      // Persist
      await _secureStorage.write(key: _accessTokenKey, value: _accessToken);
      await _secureStorage.write(key: _expiryKey, value: _tokenExpiry!.toIso8601String());

      Log.i(_tag, 'Token refreshed, expires in ${expiresIn}s');
      return true;
    } catch (e) {
      Log.e(_tag, 'Token refresh error', e);
      return false;
    }
  }

  /// Get a valid access token, refreshing if necessary
  Future<String?> getValidAccessToken() async {
    if (_accessToken == null) return null;

    // Refresh if expiring within 60 seconds
    if (_tokenExpiry != null &&
        _tokenExpiry!.isBefore(DateTime.now().add(const Duration(seconds: 60)))) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) return null;
    }

    return _accessToken;
  }

  /// Sign out — revoke token and clear storage
  Future<void> signOut() async {
    if (_accessToken != null) {
      try {
        await http.post(
          Uri.parse('$_revokeEndpoint?token=$_accessToken'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        );
      } catch (_) {
        // Best-effort revocation
      }
    }

    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;

    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expiryKey);

    Log.i(_tag, 'Signed out and tokens cleared');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Bind a temporary HTTP server on localhost to receive the OAuth callback.
  /// Returns a Future<String?> that completes when the auth code arrives.
  Future<Future<String?>> _startCallbackServer() async {
    final completer = Completer<String?>();

    _callbackServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      GoogleOAuthConfig.callbackPort,
    );

    Log.i(_tag, 'Callback server listening on port ${GoogleOAuthConfig.callbackPort}');

    _callbackServer!.listen((request) async {
      if (request.uri.path == '/callback') {
        final code = request.uri.queryParameters['code'];
        final error = request.uri.queryParameters['error'];

        if (error != null) {
          // Show error page
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(_buildHtmlPage(
              'Sign-In Failed',
              'Error: $error. You can close this tab and try again.',
              isError: true,
            ));
          await request.response.close();
          if (!completer.isCompleted) completer.complete(null);
        } else if (code != null) {
          // Show success page
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(_buildHtmlPage(
              'Sign-In Successful!',
              'You can close this tab and return to SkwirlsAI.',
            ));
          await request.response.close();
          if (!completer.isCompleted) completer.complete(code);
        } else {
          request.response
            ..statusCode = 400
            ..write('Missing code parameter');
          await request.response.close();
        }
      } else {
        request.response
          ..statusCode = 404
          ..write('Not found');
        await request.response.close();
      }
    });

    // Timeout after 2 minutes
    Future.delayed(const Duration(minutes: 2), () {
      if (!completer.isCompleted) {
        Log.w(_tag, 'OAuth callback timed out');
        completer.complete(null);
        _callbackServer?.close();
      }
    });

    return completer.future;
  }

  /// Exchange authorization code for access + refresh tokens
  Future<bool> _exchangeCodeForTokens(String code, String codeVerifier) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': GoogleOAuthConfig.clientId,
          'client_secret': GoogleOAuthConfig.clientSecret,
          'code': code,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': GoogleOAuthConfig.redirectUri,
        },
      );

      if (response.statusCode != 200) {
        Log.e(_tag, 'Token exchange failed: ${response.statusCode} ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String;
      _refreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      // Persist tokens
      await _secureStorage.write(key: _accessTokenKey, value: _accessToken);
      if (_refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken);
      }
      await _secureStorage.write(key: _expiryKey, value: _tokenExpiry!.toIso8601String());

      Log.i(_tag, 'Tokens obtained, expires in ${expiresIn}s');
      await _callbackServer?.close();
      _callbackServer = null;
      return true;
    } catch (e) {
      Log.e(_tag, 'Token exchange error', e);
      return false;
    }
  }

  /// Generate a random PKCE code verifier (43-128 chars, unreserved chars)
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(64, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Generate PKCE code challenge from verifier (S256)
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _buildHtmlPage(String title, String message, {bool isError = false}) {
    final color = isError ? '#ff5252' : '#E3AB59';
    return '''
<!DOCTYPE html>
<html>
<head><title>SkwirlsAI - $title</title></head>
<body style="
  background: #111111;
  color: #e0e0e0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  margin: 0;
">
  <div style="text-align: center;">
    <h1 style="color: $color; font-size: 28px;">$title</h1>
    <p style="font-size: 16px; opacity: 0.8;">$message</p>
  </div>
</body>
</html>
''';
  }
}
