import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nothing this program writes is sitting in a buffer of its own.
///
/// The editor ends its process outright rather than letting Windows wind it
/// down, because winding down runs the detach handler of every DLL a 51 MB
/// install loaded and a reader waited seconds for it with the window still on
/// screen. What makes that safe is that nothing here holds data back: every
/// writer hands its bytes to the operating system before it returns, and the
/// file system outlives the process that wrote them.
///
/// That was a claim in a comment until it was checked, and comments do not
/// notice the day somebody reaches for a stream because a file got large.
/// An IOSink keeps its own buffer and flushes when it feels like it, which on
/// this exit path means the last writes never happen.
void main() {
  test('no writer keeps a buffer the exit would not wait for', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final (line, index) in source.split('\n').indexed.map((e) =>
          (e.$2, e.$1))) {
        final code = line.split('//').first;
        if (code.contains('.openWrite(') || code.contains('IOSink')) {
          offenders.add('${entity.path}:${index + 1}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'these hold bytes in a buffer of their own, and the process '
            'now ends without waiting for anyone: $offenders');
  });
}
