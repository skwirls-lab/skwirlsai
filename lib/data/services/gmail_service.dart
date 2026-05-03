import 'dart:convert';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import 'auth_service.dart';

class GmailService {
  static const _tag = 'GmailService';

  final AuthService _authService;

  /// Cached emails for offline access
  List<Map<String, dynamic>> _cachedEmails = [];

  GmailService({required AuthService authService})
      : _authService = authService;

  /// Get recent emails from inbox
  Future<List<Map<String, dynamic>>> getRecentEmails({
    int count = 10,
  }) async {
    if (!_authService.isAuthenticated) {
      Log.w(_tag, 'Not authenticated, returning cached emails');
      return _cachedEmails;
    }

    try {
      final gmailApi = await _getGmailApi();
      if (gmailApi == null) return _cachedEmails;

      final messageList = await gmailApi.users.messages.list(
        'me',
        maxResults: count,
        labelIds: ['INBOX'],
      );

      final emails = <Map<String, dynamic>>[];

      for (final msg in messageList.messages ?? []) {
        final full = await gmailApi.users.messages.get('me', msg.id!);
        emails.add(_parseMessage(full));
      }

      _cachedEmails = emails;
      Log.i(_tag, 'Fetched ${emails.length} emails');
      return emails;
    } catch (e) {
      Log.e(_tag, 'Failed to fetch emails', e);
      return _cachedEmails;
    }
  }

  /// Search emails by query
  Future<List<Map<String, dynamic>>> searchEmails({
    required String query,
    int maxResults = 20,
  }) async {
    if (!_authService.isAuthenticated) {
      Log.w(_tag, 'Not authenticated');
      return [];
    }

    try {
      final gmailApi = await _getGmailApi();
      if (gmailApi == null) return [];

      final messageList = await gmailApi.users.messages.list(
        'me',
        q: query,
        maxResults: maxResults,
      );

      final emails = <Map<String, dynamic>>[];

      for (final msg in messageList.messages ?? []) {
        final full = await gmailApi.users.messages.get('me', msg.id!);
        emails.add(_parseMessage(full));
      }

      Log.i(_tag, 'Search "$query" returned ${emails.length} results');
      return emails;
    } catch (e) {
      Log.e(_tag, 'Gmail search failed', e);
      return [];
    }
  }

  Map<String, dynamic> _parseMessage(gmail.Message message) {
    final headers = message.payload?.headers ?? [];

    String getHeader(String name) {
      return headers
              .where((h) => h.name?.toLowerCase() == name.toLowerCase())
              .map((h) => h.value)
              .firstOrNull ??
          '';
    }

    // Extract plain text body
    String body = '';
    if (message.payload?.body?.data != null) {
      body = utf8.decode(base64Url.decode(message.payload!.body!.data!));
    } else if (message.payload?.parts != null) {
      for (final part in message.payload!.parts!) {
        if (part.mimeType == 'text/plain' && part.body?.data != null) {
          body = utf8.decode(base64Url.decode(part.body!.data!));
          break;
        }
      }
    }

    return {
      'id': message.id,
      'threadId': message.threadId,
      'subject': getHeader('Subject'),
      'from': getHeader('From'),
      'to': getHeader('To'),
      'date': getHeader('Date'),
      'snippet': message.snippet,
      'body': body.length > 500 ? '${body.substring(0, 500)}...' : body,
      'isUnread': message.labelIds?.contains('UNREAD') ?? false,
    };
  }

  Future<gmail.GmailApi?> _getGmailApi() async {
    final credentials = _authService.credentials;
    if (credentials == null) return null;

    final client = _AuthClient(
      http.Client(),
      credentials.accessToken.data,
    );

    return gmail.GmailApi(client);
  }
}

class _AuthClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;

  _AuthClient(this._inner, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}
