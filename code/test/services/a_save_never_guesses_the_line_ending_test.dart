import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every place that saves a document says which line ending and which encoding.
///
/// `FileService.saveDocument` defaults to LF and UTF-8, and both defaults are
/// right for a document being created. For a document being *saved* they are a
/// guess, and a wrong one rewrites the file: a CRLF file comes back with every
/// line changed, so one edit becomes a whole-file diff; a GBK file comes back as
/// UTF-8, which is not the file the reader had.
///
/// That the write path honours them is tested elsewhere — `saveDocument writes
/// back the line ending the file had`. What nothing held is that the callers
/// hand them over. Six places save, all six do; a seventh that forgot would
/// pass every test in the suite, and the reader would find out from their
/// version control.
///
/// This reads the three files that save rather than the whole tree, the same
/// three the conflict guard beside it reads, because a save from anywhere else
/// would be the larger surprise.
///
/// What it cannot catch: a caller that passes the wrong tab's ending, or a
/// literal instead of the document's. Those are a reading, and this is a scan.
void main() {
  const savers = [
    'lib/providers/tab_provider.dart',
    'lib/ui/widgets/app_menu_bar.dart',
    'lib/ui/widgets/editor_tab_bar.dart',
  ];

  /// Every save call in [path], as (line number, the call's own lines).
  List<(int, String)> savesIn(String path) {
    final lines = File(path).readAsLinesSync();
    final calls = <(int, String)>[];
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].contains('FileService.saveDocument')) continue;
      // The call, not the line: these are written over several lines, and the
      // arguments that matter are usually not on the first one.
      final end = (i + 10 < lines.length) ? i + 10 : lines.length;
      calls.add((i + 1, lines.sublist(i, end).join('\n')));
    }
    return calls;
  }

  test('every save names the line ending and the encoding', () {
    final silent = <String>[];
    var found = 0;
    for (final path in savers) {
      for (final (line, body) in savesIn(path)) {
        found++;
        final says = body.contains('lineEnding:') && body.contains('encoding:');
        if (!says) silent.add('$path:$line');
      }
    }

    // A guard that finds nothing passes. The call could be renamed, the files
    // could move, and this would go quiet while saying it had checked.
    expect(found, greaterThanOrEqualTo(6),
        reason: 'only $found save calls were found in ${savers.length} files — '
            'the scan has stopped matching, so fix the scan before trusting it');

    expect(silent, isEmpty,
        reason: '这些保存没有说明行尾与编码，会按 LF / UTF-8 猜：'
            'CRLF 文件每一行都会被改写，非 UTF-8 文件会被转码。'
            '${silent.join(', ')}');
  });

  test('the defaults are still what a new document wants', () {
    final source = File('lib/services/file_service.dart').readAsStringSync();
    expect(source, contains('LineEnding lineEnding = LineEnding.lf'),
        reason: 'the default changed; this file explains why callers must be '
            'explicit and the reason has moved');
    expect(source, contains('FileEncoding encoding = FileEncoding.utf8Encoding'),
        reason: 'the default changed; see above');
  });
}
