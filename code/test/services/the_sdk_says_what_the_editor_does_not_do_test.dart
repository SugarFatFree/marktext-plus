import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the editor has not built, the SDK has to tell an author.
///
/// `what_a_plugin_declares_is_used_test` beside this holds the editor to its own
/// list: `toolbar` and `pages` are parsed and never looked at, and a compiled
/// plugin is installed and never started. It records that, and it says whoever
/// implements one of them must go and change the SDK's wording — in a sentence,
/// which is a reminder and not a check.
///
/// This is the check. The SDK's README and its eleven translations mark the
/// things the editor does not do, and the editor is the only side that knows
/// which those are. Each repository is internally consistent — the SDK compares
/// its twelve documents against each other and against its schema, and the
/// editor compares its own fields — and until now nothing compared the two.
///
/// The cost of the gap is an author's evening: the manifest field is accepted,
/// the plugin installs, and nothing happens.
void main() {
  String? findSdk() {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate =
          '${directory.path}/marktext-plus-plugins/marktext-plus-plugin-sdk';
      if (Directory('$candidate/packages').existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final sdk = findSdk();
  final skip = sdk == null ? 'SDK 仓库不在这台机器上' : null;

  List<File> readmes() => [
        File('$sdk/README.md'),
        ...Directory('$sdk/docs/i18n')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md')),
      ];

  /// A file's code, without its comment lines — the same reading the editor's
  /// own guard uses, for the same reason.
  String codeOf(File file) => file
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  group('the editor still does not draw these', () {
    // If one of these starts being drawn, the sibling guard fails first and
    // sends whoever did it here. Kept as a list rather than read from that
    // guard, because a list read from the thing it checks checks nothing.
    const undrawn = ['toolbar', 'pages'];

    test('the editor has not started drawing them behind our back', () {
      final drawn = <String>[];
      for (final field in undrawn) {
        final users = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => !f.path.endsWith('plugin_manifest.dart'))
            .where((f) => codeOf(f).contains('.$field'))
            .map((f) => f.path)
            .toList();
        if (users.isNotEmpty) drawn.add('$field ($users)');
      }
      expect(drawn, isEmpty,
          reason: '这些贡献点现在有人画了——把它从这张表挪走，'
              '并把 SDK 那一段「还没有东西画它们」改掉：$drawn');
    });

    test('every SDK README says so in the contribution points block', () {
      for (final file in readmes()) {
        final text = file.readAsStringSync();
        final block = RegExp(r'"menus":.*?"pages":[^\n]*', dotAll: true)
            .firstMatch(text);
        expect(block, isNotNull,
            reason: '${file.path} 里读不出贡献点块，取法要跟着改');
        // The block itself lists them; the paragraph under it is what says
        // nothing draws them. Both names have to appear in that paragraph,
        // whatever language it is written in.
        final after = text.substring(block!.end);
        final explanation = after.substring(0, after.length < 1200 ? after.length : 1200);
        for (final field in undrawn) {
          expect(explanation, contains('`$field`'),
              reason: '${file.path}: 贡献点块下面没有提到 `$field`——'
                  '作者照块抄，不会知道它今天什么也不做');
        }
      }
    }, skip: skip);
  });

  group('the editor still does not start a compiled plugin', () {
    test('nothing dispatches to the process host behind our back', () {
      final callers = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('plugin_manager.dart'))
          .where((f) => codeOf(f).contains('startPlugin'))
          .map((f) => f.path)
          .toList();
      expect(callers, isEmpty,
          reason: '有人开始启动编译型插件了（$callers）——'
              'SDK 里那三处 ‡ 的说法要跟着改');
    });

    test('every SDK README carries the mark that says so', () {
      for (final file in readmes()) {
        final marks = file.readAsStringSync().split('‡').length - 1;
        expect(marks, 3,
            reason: '${file.path} 有 $marks 个 ‡，应当是 3 个：'
                '运行时表里一个、表下的脚注一个、编译型插件那一节开头一个。'
                '少了任何一个，照那一节写完并编译出插件的人会发现编辑器不启动它');
      }
    });
  });

  group('the editor still draws two of three slots beside a split document',
      () {
    // The behaviour is pinned next door, in `plugin_panes_layout_test`: if the
    // grid starts drawing three panes beside a split document, that guard
    // fails first and its reason sends whoever did it here. Not asserted again
    // from this side by reading the source — a rename would fail it while
    // nothing about the promise had changed, and a guard that cries wolf is
    // the one people delete.

    test('every SDK README carries the mark that says so', () {
      for (final file in readmes()) {
        final marks = file.readAsStringSync().split('◆').length - 1;
        expect(marks, 1,
            reason: '${file.path} 有 $marks 个 ◆，应当是 1 个：'
                '三宫格那一段下面，说明分屏的文档占两格、第三个槽位不会被画。'
                '少了它，作者填满三个槽位又在分屏里读，会看不到自己要的东西');
      }
    }, skip: skip);
  });
}
