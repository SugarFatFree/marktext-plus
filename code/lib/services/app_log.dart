/// How bad a line is.
enum LogLevel {
  debug,
  info,
  warning,
  error;

  /// Whether this is at least as bad as [other].
  bool atLeast(LogLevel other) => index >= other.index;
}

/// One thing that happened.
class LogLine {
  const LogLine({
    required this.at,
    required this.level,
    required this.message,
    this.source = '',
  });

  final DateTime at;
  final LogLevel level;
  final String message;

  /// Empty for the editor itself, a plugin id for a plugin.
  ///
  /// "Which of these lines is the plugin's" is the first question anyone
  /// debugging one asks.
  final String source;

  @override
  String toString() {
    final where = source.isEmpty ? '' : ' [$source]';
    return '[${at.toIso8601String()}] '
        '[${level.name.toUpperCase()}]$where $message';
  }
}

/// What the editor remembers about what it has been doing.
///
/// In memory and bounded: something asking "what just happened" wants the last
/// few hundred lines, and an unbounded log inside a text editor is a leak with
/// a tidy name. Nothing is written to disk — plugins keep their own files, and
/// this is for answering a question now.
class AppLog {
  AppLog({this.limit = 500});

  /// The one the application writes to.
  static final AppLog instance = AppLog();

  final int limit;
  final _lines = <LogLine>[];

  void debug(String message, {String source = ''}) =>
      _add(LogLevel.debug, message, source);

  void info(String message, {String source = ''}) =>
      _add(LogLevel.info, message, source);

  void warning(String message, {String source = ''}) =>
      _add(LogLevel.warning, message, source);

  void error(String message, {String source = ''}) =>
      _add(LogLevel.error, message, source);

  void _add(LogLevel level, String message, String source) {
    _lines.add(
      LogLine(
        at: DateTime.now(),
        level: level,
        message: message,
        source: source,
      ),
    );
    if (_lines.length > limit) {
      _lines.removeRange(0, _lines.length - limit);
    }
  }

  /// The most recent lines, oldest first.
  List<LogLine> recent({int? limit, LogLevel? atLeast, String? source}) {
    var lines = _lines.where((line) {
      if (atLeast != null && !line.level.atLeast(atLeast)) return false;
      if (source != null && line.source != source) return false;
      return true;
    }).toList();
    if (limit != null && lines.length > limit) {
      lines = lines.sublist(lines.length - limit);
    }
    return List.unmodifiable(lines);
  }

  String asText({int? limit, LogLevel? atLeast, String? source}) => recent(
    limit: limit,
    atLeast: atLeast,
    source: source,
  ).map((line) => line.toString()).join('\n');

  void clear() => _lines.clear();
}
