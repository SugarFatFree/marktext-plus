import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';

/// Every setting written is a setting read back.
///
/// A field left out of `toJson` is a setting that reverts on the next launch,
/// and a key spelled one way when writing and another when reading is the
/// same thing with nothing to notice it: the file looks right, the reader
/// changes a setting, and it is gone tomorrow. No error is raised by either
/// half.
///
/// The existing tests check particular fields — the code font size, a list
/// holding something that is not a path. A fifty-second field added to the
/// class and to nothing else passes all of them.
///
/// The keys are compared rather than the field names. A source scan for names
/// cannot see `'codeFont'` written against `'code_font'` read, because both
/// halves mention `codeFontFamily`.
void main() {
  test('every key written is a key read, and the other way round', () {
    final source = File('lib/core/config/app_config.dart').readAsStringSync();

    // From running it, not from reading it.
    final written = AppConfig().toJson().keys.toSet();

    // `fromJson` reaches for its keys by name, so the source is where they
    // are. Comment lines are skipped: a key named in prose is not read.
    final read = <String>{
      for (final line in source.split('\n'))
        if (!line.trimLeft().startsWith('//'))
          ...RegExp(r"json\['(\w+)'\]").allMatches(line).map((m) => m.group(1)!),
    };

    expect(written, isNotEmpty, reason: 'toJson 什么也没产出，这条守卫已失效');
    expect(read, isNotEmpty, reason: 'fromJson 里一个键都没扫到');

    expect(written.difference(read), isEmpty,
        reason: '这些设置写得进去、读不回来，重启后就没了：'
            '${written.difference(read)}');
    expect(read.difference(written), isEmpty,
        reason: '这些键读了却从来没被写过，要么是拼写错了要么是早就废弃了：'
            '${read.difference(written)}');
  });

  test('a value of every field survives being written and read', () {
    // The keys agreeing is not the same as the values arriving. This changes
    // every field away from its default, in one go, and asks for the whole
    // map back — so a field written under the right key but parsed with the
    // wrong helper still shows up.
    final changed = AppConfig().copyWith(
      themeName: 'Nord',
      fontSize: 21,
      lineHeight: 1.9,
      codeFontFamily: 'Iosevka',
      codeFontSize: 17,
      editorMaxWidth: 999,
      enableHtml: true,
      wrapCodeBlocks: true,
      codeBlockLineNumbers: true,
      locale: 'ja',
      windowWidth: 1234,
      windowHeight: 567,
      isMaximized: true,
      autoSave: false,
    );

    final back = AppConfig.fromJson(changed.toJson());
    final expected = changed.toJson();
    final actual = back.toJson();

    for (final key in expected.keys) {
      expect(actual[key], expected[key],
          reason: '$key 写进去是 ${expected[key]}，读回来是 ${actual[key]}');
    }
  });
}
