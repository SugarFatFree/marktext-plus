import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No sentence the reader sees is written in the source.
///
/// The editor speaks twelve languages and its 402 strings live in `.arb` files.
/// One sentence did not: a plugin with no settings was told so in English,
/// whatever language the rest of the window was in. It is the kind of leak that
/// happens once per feature and is never noticed by whoever reads only English.
///
/// This looks at the places a sentence reaches the reader — `Text`,
/// `SelectableText`, a tooltip's `message`, a field's `hintText`, a snack bar —
/// and fails on a literal holding two or more English words. Interpolations are
/// removed first: `'${plugin.name}: ${entry.title}'` is two translated pieces
/// joined, and the join is not a sentence.
///
/// What it cannot catch: a single English word (`OK`, `Save`), which is both the
/// commonest false positive and the least costly leak, and text built up in a
/// variable before it reaches a widget. Both are readings; this is a scan.
void main() {
  /// The argument positions a sentence can arrive at the reader through.
  const positions = r'(?:message|hintText|labelText|helperText|tooltip|'
      r'semanticLabel|label|title|content|text)';

  final literal = RegExp(
    '(?:Text|SelectableText|Tooltip|SnackBar|$positions:)'
    r"""\s*\(?\s*(['"])((?:[^'"\\]|\\.){4,160})\1""",
  );
  final interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');
  final englishPhrase = RegExp(r'\b[A-Za-z]{2,}\b(?:[ ,.]+\b[A-Za-z]{2,}\b)+');

  test('every sentence the reader sees comes from the .arb files', () {
    final offenders = <String>[];
    var scanned = 0;

    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        // The generated localisations are where the English lives.
        .where((f) => !f.path.contains('l10n'))) {
      scanned++;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        for (final match in literal.allMatches(lines[i])) {
          final raw = match.group(2)!;
          // A literal the line break cut in half — `'\${a.b ?? '` — leaves an
          // interpolation with no closing brace, so nothing strips it and its
          // identifier reads as two words. The fragment is not what the reader
          // sees; the whole expression is, and that is on the next line too.
          final opens = raw.split('{').length;
          final closes = raw.split('}').length;
          if (opens != closes) continue;
          final rest = raw.replaceAll(interpolation, ' ').trim();
          final phrase = englishPhrase.firstMatch(rest);
          // Eight characters of running words: shorter than that is a label
          // or an identifier caught by the pattern, not a sentence.
          if (phrase == null || phrase.group(0)!.length < 8) continue;
          offenders.add('${file.path}:${i + 1}  "${match.group(2)}"');
        }
      }
    }

    // A scan that reads nothing passes. The tree could move and this would go
    // quiet while reporting that it had looked.
    expect(scanned, greaterThan(100),
        reason: '只扫到 $scanned 个 dart 文件，取法要跟着改');

    expect(offenders, isEmpty,
        reason: '这些句子写死在源码里，读者无论用哪种语言都会看到英文：\n'
            '${offenders.join('\n')}');
  });
}
