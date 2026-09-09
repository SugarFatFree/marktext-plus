import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A button drawn as an icon alone still has to say what it is.
///
/// Flutter takes an [IconButton]'s `tooltip` and makes it the button's
/// accessible name as well, so the same word both appears on hover and is
/// what a screen reader announces. Without one the button is announced as
/// "button", and for everybody else it is a guess at a glyph.
///
/// Twenty-eight of the thirty-six carried one, so this was already the
/// practice; four had not caught up — the close on the find bar, the send in
/// the plugin drawer, the search in the sidebar, and the × on a tab, which is
/// a `GestureDetector` and so needs a [Tooltip] around it rather than a
/// parameter.
void main() {
  /// Anything the source names on purpose without a tooltip, and why.
  const allowed = <String, String>{};

  test('every IconButton says what it does', () {
    final offenders = <String>[];
    final directory = Directory('lib/ui');
    expect(directory.existsSync(), isTrue, reason: '找不到 lib/ui，取法要跟着改');

    var found = 0;
    for (final file in directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'(?<![\w.])IconButton\(').allMatches(source)) {
        // The call's own argument list, found by balancing brackets: a
        // tooltip belongs to this button and not to one nested inside it.
        var depth = 1;
        var i = match.end;
        while (i < source.length && depth > 0) {
          if (source[i] == '(') depth++;
          if (source[i] == ')') depth--;
          i++;
        }
        found++;
        final arguments = source.substring(match.end, i);
        if (arguments.contains('tooltip:')) continue;
        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        final where = '${file.path}:$line';
        if (allowed.containsKey(where)) continue;
        offenders.add(where);
      }
    }

    expect(found, greaterThan(20), reason: '读出的按钮太少，取法要跟着改');
    expect(offenders, isEmpty,
        reason: '只有图标的按钮读屏软件只会念作「按钮」；'
            '加一个 tooltip，或把它写进 allowed 并说明理由');
  });
}
