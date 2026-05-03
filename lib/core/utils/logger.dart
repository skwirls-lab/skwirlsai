import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class Log {
  Log._();

  static LogLevel _minLevel = LogLevel.debug;

  static void setMinLevel(LogLevel level) => _minLevel = level;

  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void w(String tag, String message) =>
      _log(LogLevel.warning, tag, message);

  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message);
    if (error != null) {
      developer.log(
        'ERROR: $error',
        name: tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void _log(LogLevel level, String tag, String message) {
    if (level.index < _minLevel.index) return;

    final prefix = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => 'ℹ️',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
    };

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    developer.log(
      '$prefix [$timestamp] $message',
      name: tag,
    );
  }
}
