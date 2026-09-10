import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "Small" is a claim with exactly one number behind it.
///
/// The README says how many packages this depends on directly, in thirteen
/// places across twelve languages, because staying light is the first thing it
/// promises and that count is the only measurement of it.
///
/// Every one of them was wrong, and the English file disagreed with itself:
/// the prose said 22 in one paragraph and 23 in another, the comparison table
/// said 22, and `pubspec.yaml` listed 26. A number repeated in thirteen places
/// and checked in none drifts on the first change and then keeps drifting.
void main() {
  final root = Directory.current.parent;

  int declared() {
    final pubspec = File('${root.path}/code/pubspec.yaml').readAsStringSync();
    final start = pubspec.indexOf('\ndependencies:');
    expect(start, isNot(-1));
    // The next top-level key, whichever it is. Ending at `dev_dependencies:`
    // by name held only while nothing came between them — and then
    // `dependency_overrides:` did, and every package pinned there counted as
    // one this project chose, which is the opposite of what an override is.
    final next = RegExp(r'^[a-z_]+:', multiLine: true)
        .allMatches(pubspec)
        .map((m) => m.start)
        .firstWhere((at) => at > start + 1, orElse: () => pubspec.length);
    final end = next;
    expect(end, greaterThan(start), reason: 'pubspec 的依赖段找不到了');

    // `flutter:` is the SDK itself rather than a package chosen for this
    // project, so it is not one of the things the claim is about.
    return RegExp(r'^  ([a-z_0-9]+):', multiLine: true)
        .allMatches(pubspec.substring(start, end))
        .map((m) => m.group(1)!)
        .where((name) => name != 'flutter')
        .length;
  }

  test('the pubspec is read, and lists a plausible number', () {
    // Guards the guard: a parse that stopped working would return 0 and every
    // document would then have to say "0 dependencies" to pass.
    expect(declared(), greaterThan(10));
    expect(declared(), lessThan(60), reason: '数出六十个，多半是把 dev 依赖也算进来了');
  });

  test('every README says the same number, and it is the real one', () {
    final expected = '${declared()}';
    final files = [
      File('${root.path}/README.md'),
      ...Directory('${root.path}/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];
    // English is README.md at the root; the other eleven are translations.
    expect(files.length, 12, reason: '英文一份加十一份翻译');

    // The wording differs by language; the digits do not. Every place any of
    // them talks about direct dependencies is a line holding this number.
    final wrong = <String>[];
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final lines = file.readAsLinesSync();
      final about = lines.where(
        (line) => RegExp(
          // Case-insensitive: the comparison tables capitalise the phrase —
          // "**Direkte Abhängigkeiten**", "**Dependencias directas**" — and a
          // case-sensitive pattern read six translations as mentioning their
          // dependency count once when each says it twice. The guard was
          // missing exactly the rows this bug lived in.
          r'direct dependenc|直接依赖|直接依存|직접 의존|прямы|зависимост|'
          r'direkte Abhängigkeit|dependencias directas|dépendances directes|'
          r'dipendenze dirette|dependências diretas|'
          // Arabic: the root اعتماد covers both "dependency" and
          // "credentials", and one line is about the editor holding the API
          // key. Pairing it with مباشر ("direct") separates them.
          r'اعتماد\S*\s+\S*مباشر|الاعتماديات المباشرة',
          caseSensitive: false,
        ).hasMatch(line),
      );

      expect(about, isNotEmpty, reason: '$name 不再提直接依赖了，说法变了就要更新这条守卫');
      for (final line in about) {
        if (!line.contains(expected)) wrong.add('$name: $line');
      }
    }

    expect(
      wrong,
      isEmpty,
      reason:
          'pubspec 里是 $expected 个直接依赖，这些地方说的是别的数：\n'
          '${wrong.join('\n')}',
    );
  });
}
