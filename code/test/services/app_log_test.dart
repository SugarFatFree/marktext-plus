import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/app_log.dart';

/// What the editor remembers about what it has been doing.
///
/// Kept in memory and bounded: an agent asking "what just happened" wants the
/// last few hundred lines, and a log that grows without limit in a text editor
/// is a leak with a nice name.
void main() {
  setUp(AppLog.instance.clear);

  test('nothing has happened until something does', () {
    expect(AppLog.instance.recent(), isEmpty);
  });

  test('what was written comes back, newest last', () {
    AppLog.instance.info('opened a file');
    AppLog.instance.warning('the file changed on disk');
    final lines = AppLog.instance.recent();
    expect(lines, hasLength(2));
    expect(lines.first.message, 'opened a file');
    expect(lines.last.level, LogLevel.warning);
  });

  test('it keeps a bound, dropping the oldest', () {
    final log = AppLog(limit: 3);
    for (var i = 0; i < 10; i++) {
      log.info('line $i');
    }
    final lines = log.recent();
    expect(lines, hasLength(3));
    expect(lines.first.message, 'line 7', reason: '最旧的先丢');
    expect(lines.last.message, 'line 9');
  });

  test('only the last n, when that is all that was asked for', () {
    final log = AppLog(limit: 100);
    for (var i = 0; i < 10; i++) {
      log.info('line $i');
    }
    expect(log.recent(limit: 3).map((l) => l.message), [
      'line 7',
      'line 8',
      'line 9',
    ]);
  });

  test('lines can be filtered by how bad they are', () {
    final log = AppLog(limit: 100);
    log.info('fine');
    log.error('not fine');
    log.warning('a bit off');
    expect(log.recent(atLeast: LogLevel.warning).map((l) => l.message), [
      'not fine',
      'a bit off',
    ]);
  });

  test('a source is recorded, so a plugin can be told apart', () {
    // "Which of these lines is the plugin's" is the first question anyone
    // debugging one asks.
    final log = AppLog(limit: 100);
    log.info('editor did a thing');
    log.info('plugin did a thing', source: 'com.example.demo');
    expect(log.recent(source: 'com.example.demo').map((l) => l.message), [
      'plugin did a thing',
    ]);
  });

  test('a line knows when it happened', () {
    final log = AppLog(limit: 10);
    log.info('now');
    expect(log.recent().single.at, isA<DateTime>());
  });

  test('it can be read as text, one line each', () {
    final log = AppLog(limit: 10);
    log.info('first');
    log.error('second', source: 'plugin');
    final text = log.asText();
    expect(text.split('\n'), hasLength(2));
    expect(text, contains('first'));
    expect(text, contains('ERROR'));
    expect(text, contains('plugin'));
  });
}
