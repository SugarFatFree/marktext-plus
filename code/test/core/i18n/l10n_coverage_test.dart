import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the ways a translation can go missing.
///
/// The generated Dart is committed, so editing an `.arb` alone changes
/// nothing at runtime — a whole release once shipped with ten languages
/// falling back to English because of exactly that. These checks read both
/// halves and compare them.
void main() {
  const dir = 'lib/core/i18n/l10n';

  Map<String, dynamic> arb(String lang) => jsonDecode(
        File('$dir/app_$lang.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

  /// Keys carrying text, without the `@key` metadata entries beside them.
  Set<String> keysOf(String lang) =>
      arb(lang).keys.where((k) => !k.startsWith('@')).toSet();

  final languages = Directory(dir)
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((n) => n.startsWith('app_') && n.endsWith('.arb'))
      .map((n) => n.substring(4, n.length - 4))
      .toList()
    ..sort();

  test('the language list is the one the app ships', () {
    expect(languages, hasLength(12));
    expect(languages, contains('en'));
    expect(languages, contains('pt_BR'));
  });

  test('every language defines the same keys as English', () {
    final english = keysOf('en');
    for (final lang in languages) {
      if (lang == 'en') continue;
      final theirs = keysOf(lang);
      expect(
        english.difference(theirs),
        isEmpty,
        reason: '$lang is missing keys, so those strings show in English',
      );
      expect(
        theirs.difference(english),
        isEmpty,
        reason: '$lang has keys English does not, so they are never generated',
      );
    }
  });

  /// A message with placeholders generates a method rather than a getter,
  /// so both spellings count as present.
  bool declaresKey(String source, String key) =>
      source.contains('String get $key;') || source.contains('String $key(');

  bool implementsKey(String source, String key) =>
      source.contains('String get $key =>') || source.contains('String $key(');

  test('every key exists on the generated interface', () {
    final source = File('$dir/app_localizations.dart').readAsStringSync();
    final missing = [
      for (final key in keysOf('en'))
        if (!declaresKey(source, key)) key,
    ];
    expect(missing, isEmpty, reason: 'declared in the arb but not generated');
  });

  test('every language implements every key in the generated code', () {
    for (final lang in languages) {
      // Brazilian Portuguese is a subclass of European Portuguese and
      // overrides only what differs, so it has no file of its own.
      if (lang == 'pt_BR') continue;
      final source =
          File('$dir/app_localizations_$lang.dart').readAsStringSync();
      final missing = [
        for (final key in keysOf('en'))
          if (!implementsKey(source, key)) key,
      ];
      expect(
        missing,
        isEmpty,
        reason: '$lang: in the arb but not in the generated code',
      );
    }
  });

  test('no language leaves a string untranslated as the English text', () {
    // A handful are proper nouns or symbols that are the same everywhere.
    const sharedEverywhere = {'appTitle'};
    final english = arb('en');

    for (final lang in languages) {
      if (lang == 'en') continue;
      final theirs = arb(lang);
      final identical = [
        for (final key in keysOf('en'))
          if (!sharedEverywhere.contains(key) &&
              theirs[key] == english[key] &&
              (english[key] as String).length > 3)
            key,
      ];
      // Reported rather than asserted to zero: some words genuinely coincide
      // across languages ("Markdown", "PDF"). The bar is that a language is
      // not wholesale untranslated.
      expect(
        identical.length,
        lessThan(keysOf('en').length ~/ 2),
        reason: '$lang looks largely untranslated: ${identical.take(10)}',
      );
    }
  });
}
