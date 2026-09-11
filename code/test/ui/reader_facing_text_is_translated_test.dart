import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nothing the reader is shown is written in English in the source.
///
/// The editor is translated into twelve languages and says so on its front
/// page. The plugin pages were not: "Permissions", "This plugin asks for
/// nothing.", "Open repository", "Save settings", the tooltip on the button
/// that opens the SDK, and the message when a search finds nothing were all
/// English whatever language the reader had chosen. So was the dialog that
/// reports a failed AI configuration test — while the line above it, the one
/// that reports success, was translated. The reader got their own language
/// when it worked and English when it did not, which is the moment they most
/// need to understand what happened.
///
/// Thirteen in all, and nothing would have said so: `l10n_coverage_test`
/// holds the twelve files to each other, and every one of them agreed,
/// because a string that never became a key is missing from all twelve
/// equally.
///
/// Mermaid is left out: the words in a diagram are the diagram language's
/// own, and every tool that draws one spells them the same way.
void main() {
  /// A string literal that reads like something written for a person: it
  /// starts with a capital letter and either runs to several words or is one
  /// of the short labels a button carries.
  final sentence = RegExp(r"'([A-Z][A-Za-z][A-Za-z0-9 ,.'’\-?!:]*)'");

  /// Not identifiers, not filenames, not `true`/`false`/`null`.
  final notProse = RegExp(r'^(true|false|null)$|^[A-Z][a-z]+[A-Z]|\.(dart|png|json|md|lua|js)$');

  const shortLabels = {
    'Close', 'Cancel', 'Save', 'Open', 'Settings',
    'Permissions', 'Retry', 'Copy',
  };

  /// English in the source on purpose, and why.
  ///
  /// Every entry here is a decision. A new one is welcome; it just has to be
  /// written down rather than arrived at by nobody noticing.
  const allowed = <String, String>{
    'Authorization': 'An HTTP header name, sent to a server rather than shown',
    'Courier New': 'The name of a font, which is the same in every language',
    'Control Left': 'A key name as the operating system reports it',
    'Control Right': 'A key name as the operating system reports it',
    'Shift Left': 'A key name as the operating system reports it',
    'Shift Right': 'A key name as the operating system reports it',
    'Alt Left': 'A key name as the operating system reports it',
    'Alt Right': 'A key name as the operating system reports it',
    'Meta Left': 'A key name as the operating system reports it',
    'Meta Right': 'A key name as the operating system reports it',
    'Save As':
        'The fallback for a file dialog opened with no context to read a '
            'translation from — the branch beside it uses l10n',
    'Either textController or rawContent must be provided':
        'An assertion, read by whoever is writing the code',
    'Dark Graphite': 'A theme is named, not described; all eight keep their names',
    'Red Graphite': 'A theme is named, not described; all eight keep their names',
  };

  test('no reader-facing string is written in English in lib/ui', () {
    final offenders = <String>[];
    // And `lib/providers`, which holds what the widgets show. The sentence a
    // failed plugin search put on the screen was built in a service, carried
    // through a provider as a `String`, and printed — so it never appeared in
    // `lib/ui` at all and this test said nothing while every reader who was
    // not reading English got English at the one moment they most needed to
    // understand what happened. Nothing in `lib/providers` is flagged today,
    // which is the point: it costs nothing and closes the way round.
    final directories = [Directory('lib/ui'), Directory('lib/providers')];
    for (final directory in directories) {
      expect(directory.existsSync(), isTrue,
          reason: '找不到 ${directory.path}，取法要跟着改');
    }

    for (final file in directories
        .expand((d) => d.listSync(recursive: true))
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (file.path.contains('mermaid')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        for (final match in sentence.allMatches(lines[i])) {
          final text = match.group(1)!;
          if (notProse.hasMatch(text)) continue;
          if (!text.contains(' ') && !shortLabels.contains(text)) continue;
          if (allowed.keys.any(text.startsWith)) continue;
          offenders.add('${file.path}:${i + 1}  "$text"');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: '写死的英文会给所有语言的读者看到；'
            '加一个 l10n 键，或把它写进 allowed 并说明理由');
  });

  test('the list of exceptions is still describing something real', () {
    // Guards the guard: an allowance for a string that no longer exists reads
    // as a considered decision and is only a leftover, and it goes on
    // silencing whatever else happens to start with those words.
    final source = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    for (final entry in allowed.entries) {
      expect(source, contains(entry.key),
          reason: '${entry.key} 已经不在 lib/ui 里了，这条例外可以删掉');
      expect(entry.value, isNotEmpty);
    }
  });
}
