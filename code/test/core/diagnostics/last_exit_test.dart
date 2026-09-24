import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/last_exit.dart';

/// What the previous run's exit looked like, from outside Dart.
///
/// Dart starts timing a close at the moment it is told about one, and every
/// close recorded that way runs 17-35 ms from there to the window going —
/// while the reader reports waiting seconds for the window to close. So the
/// wait is outside what Dart can see: either before the message reaches it, or
/// after the window has gone and the process has not.
///
/// The runner writes the whole of it beside the executable on its way out, in
/// four numbers. This reads that line on the next launch and says what it
/// means: figures of milliseconds since the process started are not something
/// anybody should have to subtract in their head, and the reason for having
/// four is that one reading should be able to name the stretch to fix.
void main() {
  test('it says which of the three stretches the wait was in', () {
    // The point of the line. Asking a reader to close their window costs them
    // an interaction, so one of these has to be able to name the half to fix.
    final said = LastExit.describe(
        'queued-ms=4 close-asked-ms=52457926 gone-ms=52457954 '
        'exiting-ms=52457961\n');
    expect(said, isNotNull);
    expect(said, contains('4 ms for the button to be heard'));
    expect(said, contains('28 ms before the window went'),
        reason: '52457954 - 52457926');
    expect(said, contains('7 ms to leave after that'), reason: '52457961 - 52457954');
    // Not the numbers themselves: two figures of milliseconds since the
    // process started are not something anybody should subtract in their head.
    expect(said, isNot(contains('52457')));
  });

  test('a queue wait the runner could not vouch for is left out', () {
    // Not reported as zero. "Nothing waited" and "not known" are different
    // findings, and this is the stretch the line exists to expose.
    final said = LastExit.describe(
        'queued-ms=-1 close-asked-ms=1000 gone-ms=1020 exiting-ms=1023\n');
    expect(said, isNotNull);
    expect(said, isNot(contains('to be heard')));
    expect(said, contains('20 ms before the window went'));
  });

  test('a run whose window never left the screen says exactly that', () {
    // Not a gap to paper over: this is what a reader's machine reported the
    // first time, and it was the finding — the window stood in front of them
    // through everything Windows does to end a process.
    final said = LastExit.describe(
        'queued-ms=2 close-asked-ms=1000 gone-ms=-1 exiting-ms=1500\n');
    expect(said, isNotNull);
    expect(said, contains('500 ms'));
    expect(said, contains('never taken off the screen'));
    expect(said, isNot(contains('before the window went')));
  });

  test('a close that was never asked for is said plainly', () {
    // The process ended without the window being closed — an update replacing
    // it, or something else ending it. Subtracting -1 would report a number
    // longer than the run.
    final said = LastExit.describe('close-asked-ms=-1 exiting-ms=9000\n');
    expect(said, isNotNull);
    expect(said, contains('without the window being closed'));
    // And no duration at all: the only one available would be the length of
    // the whole run, which is not what anybody reading this wants to know.
    expect(said, isNot(contains('ms')));
  });

  test('a line it cannot read is passed over rather than guessed at', () {
    expect(LastExit.describe(''), isNull);
    expect(LastExit.describe('nonsense'), isNull);
    expect(LastExit.describe('close-asked-ms=abc exiting-ms=1'), isNull);
  });

  test('an exit before the close is refused rather than reported backwards',
      () {
    // The clock comes from the process, not the wall, but a number that says
    // the process left before the button was pressed is not one to report.
    expect(LastExit.describe('close-asked-ms=900 exiting-ms=800'), isNull);
  });

  group('reading what the runner left', () {
    late Directory directory;

    setUp(() => directory = Directory.systemTemp.createTempSync('mt-exit'));
    tearDown(() => directory.deleteSync(recursive: true));

    File theFile() =>
        File('${directory.path}${Platform.pathSeparator}${LastExit.fileName}');

    test('it reads the file the runner leaves beside the executable', () {
      // The reader half of a measurement taken in another language. Until now
      // only the sentence was covered, and the sentence is not the part that
      // can look in the wrong place or under the wrong name.
      theFile().writeAsStringSync(
          'queued-ms=3 close-asked-ms=100 gone-ms=130 exiting-ms=134\n');
      expect(LastExit.readAndForget(beside: directory.path),
          contains('30 ms before the window went'));
    });

    test('it takes the account away once it has been read', () {
      // Left in place, every launch from then on reports the same close as
      // though it had just happened — and the one after a genuinely slow close
      // would look identical to the one after a fast one.
      theFile().writeAsStringSync('close-asked-ms=100 exiting-ms=134\n');
      expect(LastExit.readAndForget(beside: directory.path), isNotNull);
      expect(theFile().existsSync(), isFalse);
      expect(LastExit.readAndForget(beside: directory.path), isNull);
    });

    test('an account it cannot make sense of is taken away too', () {
      // Otherwise a file that can never be understood is read and skipped on
      // every launch for the life of the installation.
      theFile().writeAsStringSync('half a line');
      expect(LastExit.readAndForget(beside: directory.path), isNull);
      expect(theFile().existsSync(), isFalse);
    });

    test('nothing left behind is nothing said', () {
      expect(LastExit.readAndForget(beside: directory.path), isNull);
    });
  });
}
