import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every type this project defines is used by something.
///
/// "Written but never wired up" is a shape this repository keeps producing,
/// and dead code is worse than merely wasteful when it describes how the
/// editor works. `DiagramWidget` said, in its own doc comment, that Mermaid
/// is rendered in exported HTML by a CDN script and that the preview shows
/// diagram source with a marker beside it. Neither has been true for a long
/// time — diagrams are drawn in Dart and embedded on export — so anyone who
/// opened that file learned two false things about the architecture.
///
/// Alongside it: a `ParseToken` and its `TokenType` vocabulary, for a
/// tokeniser this line-based parser never had; a table of `MermaidThemes`;
/// and two enums naming relationship kinds that nothing reads.
///
/// A type is counted as used when anything outside its own definition names
/// it. That is what lets a `State` class live — the widget's `createState`
/// names it — while a class only its own constructor mentions does not.
void main() {
  final declaration = RegExp(
    r'^(?:abstract |sealed |final |base |interface )*(class|enum|mixin|extension) ([A-Z]\w+)',
  );

  /// A member declared directly inside a type: two spaces in, then a call.
  final member = RegExp(r'^  (?:[\w<>?,\[\] ]+ )?(\w+)\s*[(=]');

  /// Defined and unused on purpose, and why.
  const allowed = <String, String>{};

  List<File> dartFiles(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'))
      .toList();

  test('no type is defined and then named nowhere else', () {
    final sources = {
      for (final file in [...dartFiles('lib'), ...dartFiles('test')])
        file.path: file.readAsLinesSync(),
    };
    expect(sources, isNotEmpty, reason: '一个 dart 文件都没读到，取法要跟着改');

    final unused = <String>[];
    var declared = 0;

    sources.forEach((path, lines) {
      if (!path.startsWith('lib/')) return;
      for (var i = 0; i < lines.length; i++) {
        final match = declaration.firstMatch(lines[i]);
        if (match == null) continue;
        declared++;
        final keyword = match.group(1)!;
        final name = match.group(2)!;

        // The definition runs to the next line that closes at column zero.
        var end = i;
        while (end < lines.length && lines[end].trimRight() != '}') {
          end++;
        }

        // An extension is never named where it is used — `answeredWithin(...)`
        // says nothing about `AnsweredWithin`. What has to be reachable is
        // what it declares, so for those look for the members instead.
        final names = <String>[];
        if (keyword == 'extension') {
          for (var j = i + 1; j < lines.length && lines[j].trimRight() != '}'; j++) {
            final m = member.firstMatch(lines[j]);
            if (m != null) names.add('.${m.group(1)!}(');
          }
        } else {
          names.add(name);
        }
        final named = RegExp(
          names.map((n) => n.startsWith('.') ? RegExp.escape(n) : '\\b$n\\b')
              .join('|'),
        );
        var used = false;
        for (final entry in sources.entries) {
          for (var j = 0; j < entry.value.length; j++) {
            if (entry.key == path && j >= i && j <= end) continue;
            if (!named.hasMatch(entry.value[j])) continue;
            used = true;
            break;
          }
          if (used) break;
        }
        if (!used && !allowed.containsKey('$path:$name')) {
          unused.add('$path:${i + 1}  $name');
        }
      }
    });

    expect(declared, greaterThan(300), reason: '读出的类型太少，取法要跟着改');
    expect(unused, isEmpty,
        reason: '定义了却没有任何地方用到；删掉它，'
            '或把 <文件>:<类型名> 写进 allowed 并说明理由');
  });
}
