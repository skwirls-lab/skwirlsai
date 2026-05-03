import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import 'auth_service.dart';

class CalendarService {
  static const _tag = 'CalendarService';

  final AuthService _authService;

  /// Cached events for offline access
  List<Map<String, dynamic>> _cachedEvents = [];

  CalendarService({required AuthService authService})
      : _authService = authService;

  /// Fetch upcoming events from Google Calendar
  Future<List<Map<String, dynamic>>> getUpcomingEvents({
    int daysAhead = 7,
  }) async {
    if (!_authService.isAuthenticated) {
      Log.w(_tag, 'Not authenticated, returning cached events');
      return _cachedEvents;
    }

    try {
      final calApi = await _getCalendarApi();
      if (calApi == null) return _cachedEvents;

      final now = DateTime.now();
      final end = now.add(Duration(days: daysAhead));

      final events = await calApi.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 50,
      );

      _cachedEvents = (events.items ?? []).map((event) {
        final start = event.start?.dateTime ?? event.start?.date;
        final end = event.end?.dateTime ?? event.end?.date;

        return <String, dynamic>{
          'id': event.id,
          'summary': event.summary ?? 'No title',
          'description': event.description,
          'start': start?.toIso8601String(),
          'end': end?.toIso8601String(),
          'location': event.location,
          'status': event.status,
          'htmlLink': event.htmlLink,
        };
      }).toList();

      Log.i(_tag, 'Fetched ${_cachedEvents.length} events');
      return _cachedEvents;
    } catch (e) {
      Log.e(_tag, 'Failed to fetch calendar events', e);
      return _cachedEvents;
    }
  }

  Future<cal.CalendarApi?> _getCalendarApi() async {
    final credentials = _authService.credentials;
    if (credentials == null) return null;

    final client = _AuthClient(
      http.Client(),
      credentials.accessToken.data,
    );

    return cal.CalendarApi(client);
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
