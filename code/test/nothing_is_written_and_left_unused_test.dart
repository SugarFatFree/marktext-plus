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
            // Without the parenthesis: a getter is used as `.runsCommands`,
            // and requiring `(` would report every extension of getters as
            // dead. The leading dot is still required, so a local variable of
            // the same name elsewhere does not count as a use.
            if (m != null) names.add('.${m.group(1)!}');
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

  test('every compile-time knob the code reads is supplied by some build', () {
    // The other half of the same shape, one level further out: a
    // `fromEnvironment` constant is *declared* in Dart and *supplied* in
    // YAML, by two different kinds of author, and the language cannot
    // complain — an undefined one silently takes its default.
    //
    // `APP_VERSION` was read in exactly one place, defined in none, and so
    // the handshake introduced every shipped build as "dev" for as long as
    // the feature existed (BUG-485). The type guard above could not see it:
    // the constant *was* used, by the thing that reported the wrong answer.
    final workflows = [
      File('../.github/workflows/ci.yml'),
      File('../.github/workflows/release.yml'),
    ];
    // Skipped rather than failed: a checkout of `code/` alone is a thing
    // people do, and a guard that always fails there teaches people to
    // ignore it.
    if (!workflows.every((f) => f.existsSync())) return;
    final supplied = workflows.map((f) => f.readAsStringSync()).join('\n');

    final reads = RegExp(r"fromEnvironment\(\s*'(\w+)'");
    final names = <String, String>{};
    for (final file in dartFiles('lib')) {
      final text = file.readAsStringSync();
      for (final match in reads.allMatches(text)) {
        names.putIfAbsent(match.group(1)!, () => file.path);
      }
    }
    expect(names, isNotEmpty, reason: '一个编译期常量都没读到，取法要跟着改');

    final undefined = [
      for (final entry in names.entries)
        if (!supplied.contains('--dart-define=${entry.key}='))
          '${entry.value}  ${entry.key}',
    ];
    expect(undefined, isEmpty,
        reason: '这些编译期常量没有任何构建传过——默认值就是它唯一的值，'
            '而读它的代码以为自己读到的是真话');
  });
}
