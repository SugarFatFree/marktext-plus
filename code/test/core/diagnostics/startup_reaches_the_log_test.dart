import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/startup_trace.dart';
import 'package:marktext_plus/services/app_log.dart';

/// How long the editor took to start is answerable from a distance.
///
/// The trace goes to `debugPrint` and to `startup-trace.log`. Neither reaches
/// a remote session: a Windows release build is a GUI binary with no stdout,
/// and the file is on the reader's machine. `read_logs` over MCP is the only
/// window there is, and it introduces itself as "use this to find out what
/// just happened" — while the log on a running editor held one line, the MCP
/// server saying it had started.
///
/// The milestones go to the log; the forty detail marks do not. Forty lines
/// would push a plugin's output off the end of a log that keeps a few hundred.
void main() {
  setUp(AppLog.instance.clear);

  List<String> startupLines() => AppLog.instance
      .recent(source: 'startup')
      .map((line) => line.message)
      .toList();

  test('a milestone reaches the log, with a time on it', () {
    StartupTrace.markOnce('a milestone for the test');

    expect(startupLines(), hasLength(1));
    expect(startupLines().single, contains('a milestone for the test'));
    expect(
      startupLines().single,
      matches(RegExp(r'at \d+ ms')),
      reason: '没有数字的里程碑回答不了「启动多久」',
    );
    // And what it cost to get there, where the platform will say.
    expect(startupLines().single, matches(RegExp(r'\d+ MB resident')));
  });

  test('the same milestone twice is still one line', () {
    StartupTrace.markOnce('a repeated milestone');
    StartupTrace.markOnce('a repeated milestone');

    expect(startupLines(), hasLength(1));
  });

  test('a detail mark stays out of the log', () {
    StartupTrace.mark('one of the forty');

    expect(
      startupLines(),
      isEmpty,
      reason: '四十条细节会把插件的输出挤出日志',
    );
  });

  test('the milestone says what came before Dart, or that it could not', () {
    // The number on the line is the stopwatch inside `main`, and the person
    // waited through everything before that too: the shell starting the
    // process, the executable and its libraries being mapped, the engine
    // coming up. The class measures that gap on purpose — the comment beside
    // it says the gap "is the whole question when a launch feels slow" — and
    // puts it in the trace file, which is on the reader's machine.
    //
    // The log is the only window a remote session has, and read from there
    // "home screen first build at 109 ms" reads as the whole start. It is a
    // part of it.
    StartupTrace.markOnce('a milestone that should carry the gap');
    final line = startupLines().single;

    expect(
      line,
      anyOf(
        matches(RegExp(r'\+\d+ ms before Dart')),
        contains('before Dart not measured'),
      ),
      reason: '这条是远程会话唯一能读到的启动数字，它得说清自己只是其中一段：$line',
    );
  });
}
