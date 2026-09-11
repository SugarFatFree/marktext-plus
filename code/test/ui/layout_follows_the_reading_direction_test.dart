import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nothing in the window is pinned to a side the reader does not read from.
///
/// `app.dart` wraps everything in a right-to-left [Directionality] for Arabic,
/// and for anyone who chooses that direction in Settings whatever their
/// language. Flutter turns `EdgeInsetsDirectional` and `AlignmentDirectional`
/// around for them and leaves `EdgeInsets.only(left:)` and
/// `Alignment.centerLeft` exactly where they were — so a file tree indented
/// with `left:` indents away from the names it is nesting, and a button
/// aligned `centerRight` sits at the far side of its row from every other
/// button.
///
/// Thirteen of these were in place and nothing tested any of them: there was
/// not one `TextDirection.rtl` anywhere under `test/`. The measurement that
/// started this found a code block's line numbers at x=740 with its code at
/// x=40, the gutter across the block from what it was numbering.
///
/// This is a reading of the source, and a source guard only proves that the
/// wrong constructor is not named. `rtl_keeps_code_readable_test` is the other
/// half: it turns a window around and measures where things land.
void main() {
  /// A layout that names a side rather than an edge.
  final sided = RegExp(
    r'Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)'
    r"|EdgeInsets\.only\([^)]*\b(left|right)\s*:"
    r'|TextAlign\.(left|right)'
    r'|Positioned\(\s*(left|right)\s*:'
    // A border on a named side. `BorderDirectional` is the one that turns
    // around, and both of these were written the fixed way: the quote's
    // accent bar sat across the quote from where Arabic text begins, and the
    // line-number gutter's edge stayed on the same side while the gutter
    // itself moved. Neither was named by the pattern above, which is how they
    // lasted.
    r'|Border\(\s*(left|right)\s*:'
    // And a corner. `BorderRadius.only(topLeft:)` does not turn around
    // either; nothing writes one today, which is when a pattern is cheapest
    // to widen.
    r'|BorderRadius\.only\([^)]*\b(topLeft|topRight|bottomLeft|bottomRight)\s*:',
  );

  /// A side named on purpose, and why.
  ///
  /// Keyed by the file it is in and the line's own text, because these are
  /// decisions about particular places rather than about a construct.
  const allowed = <String, String>{
    "if (index >= alignments.length) return TextAlign.left;":
        'A markdown table column with no alignment given. GFM writes '
            '`:---` and `---:` for left and right, meaning the sides '
            'themselves, and every renderer treats them literally',
    "'right' => TextAlign.right,": 'The `---:` a table column was written with',
    '_ => TextAlign.left,': 'The `:---` a table column was written with',
    'textAlign: TextAlign.right,':
        'Line numbers, right-aligned so the digits sit against the code. '
            'The block around them is held left-to-right, so this side is '
            'the same side in every language',
  };

  test('no widget under lib/ui is pinned to a physical side', () {
    final offenders = <String>[];
    final directory = Directory('lib/ui');
    expect(directory.existsSync(), isTrue, reason: '找不到 lib/ui，取法要跟着改');

    for (final file in directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      // Mermaid draws on a canvas rather than laying out widgets, and its
      // `TextDirection.ltr` is how a `TextPainter` is asked to measure.
      if (file.path.contains('mermaid')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        if (!sided.hasMatch(line)) continue;
        if (allowed.containsKey(line)) continue;
        offenders.add('${file.path}:${i + 1}  $line');
      }
    }

    expect(offenders, isEmpty,
        reason: '右起阅读时这些不会跟着翻；'
            '改用 EdgeInsetsDirectional / AlignmentDirectional，'
            '或把这一行写进 allowed 并说明理由');
  });

  test('the list of exceptions is still describing something real', () {
    // Guards the guard: an allowance for a line that no longer exists reads as
    // a decision and is only a leftover, and it goes on excusing any other
    // line that happens to be written the same way.
    final source = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('mermaid'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    for (final entry in allowed.entries) {
      expect(source, contains(entry.key),
          reason: '${entry.key} 已经不在 lib/ui 里了，这条例外可以删掉');
      expect(entry.value, isNotEmpty);
    }
  });
}
