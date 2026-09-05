import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every constant in `AppConstants` is read from there by at least one place.
///
/// The file said so in a comment and could not enforce it: fourteen of its
/// eighteen constants were read by nobody. That is not merely clutter —
/// `minWindowWidth` said 800 while the window would happily go to 480, and
/// `maxRecentFiles` said twenty against a hard-coded ten, because a value
/// nothing reads is a value nothing keeps true.
///
/// A default only `AppConfig` uses belongs in `AppConfig`; a minimum only
/// `WindowPlacement` enforces belongs there. This test is the rule the
/// comment describes, in a form that can fail.
void main() {
  test('nothing in AppConstants is dead', () {
    final source = File('lib/core/constants.dart').readAsStringSync();
    final names = RegExp(
      r'static const \w+(?:<[^>]+>)? (\w+)\s*=',
    ).allMatches(source).map((m) => m.group(1)!).toList();

    expect(names, isNotEmpty, reason: '正则没匹配到常量，说明它该更新了');

    final lib = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('core/constants.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    final unread = [
      for (final name in names)
        if (!lib.contains('AppConstants.$name')) name,
    ];

    expect(
      unread,
      isEmpty,
      reason:
          '这些常量没有任何地方读：$unread\n'
          '要么让使用点引用它，要么把它删掉——'
          '一个没人读的值迟早会和真正生效的那个分家',
    );
  });
}
