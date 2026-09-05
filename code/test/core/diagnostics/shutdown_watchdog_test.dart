import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/startup_trace.dart';

/// The watchdog that keeps a hung close from stranding the reader, and the
/// call that stands it down when the close was not hung after all.
///
/// `armShutdownWatchdog` goes on before `destroy()`, because that call may
/// never return; if six hundred milliseconds pass it writes the trace and
/// leaves rather than making anyone wait. `shutdownFinished` exists to cancel
/// it — and nothing called it. Both close paths armed the watchdog, awaited
/// `destroy()`, marked the line after it, and walked away leaving it running.
///
/// So on every ordinary exit where `destroy()` did return, the timer kept
/// writing "still running Nms after close began" into the trace, and at six
/// hundred milliseconds it would `exit(0)` — cutting in front of the shutdown
/// that was already happening.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('watchdog_');
    StartupTrace.useDirectory(root.path);
  });

  tearDown(() {
    StartupTrace.shutdownFinished();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  String traceText() {
    final path = StartupTrace.logPath;
    if (path == null) return '';
    final file = File(path);
    return file.existsSync() ? file.readAsStringSync() : '';
  }

  int stillRunningLines() => 'still running'.allMatches(traceText()).length;

  test('while a close drags on, the watchdog says so', () async {
    // giveUpAfter far beyond the test: reaching it calls exit(0), which would
    // take the test runner with it.
    StartupTrace.armShutdownWatchdog(
      interval: const Duration(milliseconds: 10),
      giveUpAfter: const Duration(seconds: 30),
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));
    StartupTrace.flush();

    expect(
      stillRunningLines(),
      greaterThan(0),
      reason: '关闭卡住时看门狗要留下记录，这是它存在的理由',
    );
    StartupTrace.shutdownFinished();
  });

  test('a close that finishes stands the watchdog down', () async {
    StartupTrace.armShutdownWatchdog(
      interval: const Duration(milliseconds: 10),
      giveUpAfter: const Duration(seconds: 30),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));

    StartupTrace.shutdownFinished();
    StartupTrace.flush();
    final atStandDown = stillRunningLines();

    await Future<void>.delayed(const Duration(milliseconds: 60));
    StartupTrace.flush();

    expect(
      stillRunningLines(),
      atStandDown,
      reason:
          '取消之后不该再多一行——多出来的每一行都是噪音，'
          '而且说明 600ms 后的 exit(0) 仍然会抢在正常退出前面',
    );
  });

  test('every close path stands it down after destroy returns', () {
    // The watchdog works; nothing called it off. That is wiring, and the
    // close handler is behind a window event a widget test cannot raise —
    // so this reads the source.
    //
    // Both paths are checked, not one: they are two arms of the same handler
    // with the same four lines in them, and the last time a fix touched one
    // arm of a pair it left the other exactly as it was.
    final source = File('lib/ui/screens/home_screen.dart').readAsStringSync();

    final armed = 'armShutdownWatchdog('.allMatches(source).length;
    expect(armed, 2, reason: '两条关闭路径都要装看门狗；数量变了就该重看这条测试');

    final destroys = 'windowManager.destroy()'.allMatches(source).toList();
    expect(destroys, hasLength(2));

    for (final destroy in destroys) {
      // The lines of code after it, comments dropped. Taking a fixed number
      // of characters instead made the check depend on how long a comment
      // was — the first version failed on the very explanation of the fix.
      final after = source
          .substring(destroy.end)
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('//'))
          .take(4)
          .join('\n');
      expect(
        after,
        contains('shutdownFinished'),
        reason:
            'destroy 返回了就说明关闭没卡住，看门狗该撤下——'
            '否则它继续写噪音，600ms 后 exit(0) 抢在正常退出前面',
      );
    }
  });

  test('standing it down twice is not an error', () {
    StartupTrace.shutdownFinished();
    StartupTrace.shutdownFinished();
  });
}
