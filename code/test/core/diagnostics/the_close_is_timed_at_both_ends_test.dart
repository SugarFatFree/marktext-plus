import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The close is measured from the click to the last instruction, in the runner.
///
/// A reader reports that closing the window is slow. Everything that was
/// measured says it is fast: 17-35 ms from Dart being told about the close to
/// the window going, in every recorded run, and a watchdog armed around the
/// destroy that has never written a line. So the wait is in one of the two
/// stretches nobody was watching — before the message reaches Dart, or after
/// the window has gone and the process has not — and both of those are only
/// visible from the runner.
///
/// Guarded here because the runner cannot be compiled on the machine it is
/// written on, and CI only proves it compiles. The first version of this change
/// compiled perfectly and recorded nothing: the call had gone into the branch a
/// second launch takes when it forwards a path to the running editor, which
/// never had a window and was never asked to close one. That is this project's
/// most frequent defect — written, and never wired up — and the compiler cannot
/// see it, so these assertions are what stands in for it.
void main() {
  /// The source with comments taken out, so prose about a call is not mistaken
  /// for the call. The first version of a guard in this project matched its own
  /// explanation and passed while the code was broken.
  String codeOf(String path) {
    final source = File(path).readAsStringSync();
    return source
        .split('\n')
        .map((line) {
          final comment = line.indexOf('//');
          return comment == -1 ? line : line.substring(0, comment);
        })
        .join('\n');
  }

  test('the click is recorded before Flutter is given the message', () {
    final code = codeOf('windows/runner/flutter_window.cpp');
    expect(code, contains('RecordCloseAsked()'),
        reason: 'nothing records when the close was asked for');
    expect(code.indexOf('RecordCloseAsked()'),
        lessThan(code.indexOf('HandleTopLevelWindowProc')),
        reason: 'window_manager answers WM_CLOSE by telling Dart and refusing '
            'the close, so recording after that hand-off measures nothing');
  });

  test('the last instruction the process runs is recorded', () {
    final code = codeOf('windows/runner/main.cpp');
    final lastExit = code.lastIndexOf('::TerminateProcess');
    expect(lastExit, greaterThan(-1));
    final before = code.substring(0, lastExit);
    expect(before, contains('WriteLastExit('),
        reason: 'the far end of what a reader waits through is not recorded '
            'anywhere, and nothing after this point can be measured at all');
    // Immediately before, not merely somewhere earlier: the whole value of the
    // number is that nothing it fails to include can still be waited through.
    expect(before.substring(before.lastIndexOf('WriteLastExit(')).trim(),
        matches(RegExp(r'^WriteLastExit\([^;]*\);\s*$')),
        reason: 'something runs between the measurement and the exit');
  });

  test('a launch that only forwarded a path leaves no exit behind', () {
    final code = codeOf('windows/runner/main.cpp');
    final messageLoop = code.indexOf('GetMessage');
    expect(messageLoop, greaterThan(-1));
    for (var at = code.indexOf('WriteLastExit(');
        at != -1;
        at = code.indexOf('WriteLastExit(', at + 1)) {
      // The definition is above the message loop; calls must not be.
      if (code.substring(0, at).trimRight().endsWith('void')) continue;
      expect(at, greaterThan(messageLoop),
          reason: 'this process never had a window and was never asked to '
              'close one, so what it would write is a close that never '
              'happened — over the top of the real one');
    }
  });

  test('both ends are read off the same clock', () {
    // Defined in utils, used by main.cpp and by the window procedure. A second
    // copy is the shape this project keeps finding defects in: one of them gets
    // changed and the two numbers stop being comparable.
    expect(codeOf('windows/runner/utils.cpp'),
        contains('long long MillisecondsSinceProcessStart()'));
    expect(codeOf('windows/runner/main.cpp'),
        isNot(contains('long long MillisecondsSinceProcessStart()')),
        reason: 'main.cpp defines a second copy of the clock');
  });

  test('the runner and Dart agree on what the file is called', () {
    // One name, written in C++ and read in Dart, with nothing between them
    // that can notice they have drifted apart. Renaming one alone is a line
    // that simply never appears again — the quietest way this could fail, and
    // indistinguishable from a close that was fast.
    final written = RegExp(r'L"([\w.-]+\.log)"')
        .firstMatch(codeOf('windows/runner/main.cpp'))
        ?.group(1);
    final read = RegExp(r"fileName = '([\w.-]+\.log)'")
        .firstMatch(codeOf('lib/core/diagnostics/last_exit.dart'))
        ?.group(1);
    expect(written, isNotNull, reason: 'the runner writes no file at all');
    expect(read, isNotNull, reason: 'Dart names no file to read');
    expect(read, written);
  });

  test('what the runner writes is what Dart reads', () {
    // The two ends of one line, in two languages, with nothing between them
    // that can check they agree — a runner label nobody parses is a
    // measurement taken and thrown away, and a label Dart looks for that the
    // runner never writes is a stretch of the close silently left out of the
    // sentence. This project keeps finding defects in exactly that shape.
    RegExp labels(String pattern) => RegExp(pattern);
    Set<String> found(String code, String pattern, int group) => labels(pattern)
        .allMatches(code)
        .map((m) => m.group(group)!.trim())
        .toSet();

    final written = found(codeOf('windows/runner/main.cpp'),
        r'FormatTraceArgument\("([^"]*-ms=)"', 1);
    final read = found(codeOf('lib/core/diagnostics/last_exit.dart'),
        r"_numberAfter\(contents, '([^']*)'\)", 1);

    expect(written, isNotEmpty);
    expect(read, isNotEmpty);
    expect(written, equals(read),
        reason: 'the runner writes ${written.difference(read)} that nothing '
            'reads, and Dart looks for ${read.difference(written)} that '
            'nothing writes');
  });

  test('the window is taken off the screen before the process winds down', () {
    // Closing does not destroy this window — window_manager's destroy() is a
    // bare PostQuitMessage — so it stands in front of the reader until the
    // process dies. Hiding it is what makes the close look like a close.
    final code = codeOf('windows/runner/main.cpp');
    final hide = code.indexOf('SW_HIDE');
    expect(hide, greaterThan(-1),
        reason: 'the window is left on screen for the whole of the teardown');
    expect(hide, lessThan(code.lastIndexOf('::TerminateProcess')),
        reason: 'hiding it after the process has gone helps nobody');
    // And the moment is recorded, because it is the moment the reader waits
    // for and the one that was reported as never happening.
    expect(code, contains('RecordWindowGone()'));
  });

  test('nothing runs on after asking to be terminated', () {
    // TerminateProcess is not ExitProcess. ExitProcess is declared
    // DECLSPEC_NORETURN; this returns BOOL and is documented as asynchronous,
    // so without something stopping it the following statements run in the
    // moments before the process dies. On the hand-off path that means booting
    // the engine for a launch whose only job was to pass a path along, and at
    // the end of wWinMain it means returning into the C runtime — the exact
    // thing this exit path exists to avoid.
    //
    // CI found this as a compiler error the first time (C4715 under /W4 /WX),
    // which is luck: the same mistake on a path the compiler could prove ends
    // would have shipped.
    final code = codeOf('windows/runner/main.cpp');
    for (var at = code.indexOf('::TerminateProcess');
        at != -1;
        at = code.indexOf('::TerminateProcess', at + 1)) {
      final after = code.substring(at).split('\n').skip(1).join('\n').trimLeft();
      expect(after, startsWith('return'),
          reason: 'something follows a request to terminate, and it runs');
    }
  });

  test('the run ends at once rather than being wound down', () {
    // Looking closed is not being closed, and the difference is not cosmetic.
    // ExitProcess runs DLL_PROCESS_DETACH for everything this 51 MB install
    // loaded, which is the seconds a reader was waiting through; and while it
    // does, the process still holds the single-instance mutex and its named
    // pipe with nothing alive to read them — so a document opened in that
    // window is handed to a dead listener and silently never appears.
    final code = codeOf('windows/runner/main.cpp');
    expect(code, isNot(contains('::ExitProcess')),
        reason: 'an exit that winds the process down leaves the reader '
            'waiting and leaves a listener that cannot listen');
    expect(code, contains('::TerminateProcess(::GetCurrentProcess()'));
  });

  test('the queue wait is taken inside what the window procedure calls', () {
    // GetMessageTime answers about the message being handled right now. Worked
    // out anywhere else it still returns a number, and the number is about some
    // other message entirely — so the capture has to sit inside the one
    // function the window procedure calls while WM_CLOSE is in hand.
    final utils = codeOf('windows/runner/utils.cpp');
    final opens = utils.indexOf('void RecordCloseAsked()');
    expect(opens, greaterThan(-1));
    final body = utils.substring(opens, utils.indexOf('\n}', opens));
    expect(body, contains('close_queued_for_ms ='),
        reason: 'the queue wait is recorded somewhere the message asking for '
            'the close is no longer the message being handled');
    // And only there. A second assignment elsewhere is a second answer to the
    // same question, and the two would not be about the same message.
    // And only there: the declaration, and the one line above. A second
    // assignment elsewhere is a second answer to the same question, and the two
    // would not be about the same message.
    final settings = RegExp(r'close_queued_for_ms\s*=').allMatches(utils).length;
    expect(settings, 2,
        reason: 'expected the declaration and one assignment, found $settings');
  });

  test('the close reported is the one that ended the process', () {
    // Not the first close asked for. A close can be refused — unsaved work, a
    // prompt, the reader says cancel — and if they close again five minutes
    // later, measuring from the first click files those five minutes of
    // somebody thinking under "inside the editor". Whoever reads that goes
    // looking for five minutes of work in a handler that does none.
    final utils = codeOf('windows/runner/utils.cpp');
    final opens = utils.indexOf('void RecordCloseAsked()');
    final body = utils.substring(opens, utils.indexOf('\n}', opens));
    expect(body, isNot(contains('close_asked_at_ms <')),
        reason: 'the recording is skipped once something has been recorded, '
            'so a refused close is what gets reported');
  });
}
