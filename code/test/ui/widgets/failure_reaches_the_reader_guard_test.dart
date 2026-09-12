import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The call sites that ignored a failure, held to reporting it.
///
/// Both live behind something a widget test cannot easily reach — a menu that
/// opens a dialog, and a popup on the status bar — so this reads the source
/// instead. That pins the shape of the code rather than its behaviour, which
/// is weaker; it is here because the alternative was nothing at all, and both
/// of these are about the reader believing a write happened when it did not.
void main() {
  /// Every `catch` body guarding a call to [call] in [path].
  ///
  /// Matched as "the call sits inside a try, and the catch that follows" — not
  /// as a range between two landmarks, which is what the first version did and
  /// which put the catch outside the range it was looking in.
  ///
  /// The body may hold `${...}`, and nothing else with a brace in it. A string
  /// interpolation is the one ordinary reason for a brace inside a short try,
  /// and excluding braces outright found one of the two document reads and not
  /// the other — the one whose trace line reports `${bytes.length}`.
  ///
  /// Plural because failures in this repository come in pairs: the drop handler
  /// and the startup-argument handler read a document the same way, in two
  /// places, and a guard that stopped at the first would pass while the second
  /// stayed silent.
  List<String> everyCatchAround(String path, String call) => RegExp(
        r'try \{(?:[^{}]|\$\{[^{}]*\})*' +
            RegExp.escape(call) +
            r'(?:[^{}]|\$\{[^{}]*\})*\} catch \(\w+\) \{(.*?)\n(\s*)\}',
        dotAll: true,
      )
          .allMatches(File(path).readAsStringSync())
          .map((m) => m.group(1)!)
          .toList();

  /// The first of them, or null when there is none.
  String? catchAround(String path, String call) =>
      everyCatchAround(path, call).firstOrNull;

  test('choosing to overwrite reports a write that fails', () {
    final guarded = catchAround(
      'lib/ui/widgets/app_menu_bar.dart',
      'overwriteOnDisk(tab.id)',
    );

    expect(guarded, isNotNull, reason: '覆盖是读者对自己作品的决定，失败不能咽下去');
    expect(guarded, contains('reportSaveFailure'), reason: '要说出为什么写不进去');
    expect(
      guarded,
      contains('markDiskConflict'),
      reason: '写失败时冲突还在——横幅消失等于说覆盖成功了',
    );
  });

  test('choosing to reload reports a read that fails', () {
    // The sibling of the case above, in the same switch. The first version of
    // this fix wired up one of the two and left the other exactly as it was.
    final guarded =
        catchAround('lib/ui/widgets/app_menu_bar.dart', 'reloadFromDisk(tab.id)');

    expect(guarded, isNotNull,
        reason: '同一个对话框的另一半，不能只修一半');
    expect(guarded, contains('reportOpenFailure'));
  });

  test('rereading in another encoding reports a read that fails', () {
    final guarded = catchAround(
      'lib/ui/widgets/status_bar.dart',
      'rereadAs(id, chosen)',
    );

    expect(guarded, isNotNull);
    expect(
      guarded,
      contains('reportOpenFailure'),
      reason: '选了编码却什么都没变，读者得知道是文件读不了',
    );
  });

  test('a document that cannot be read says so, however it was opened', () {
    // Dropping a file and naming one on the command line both put up a tab
    // before the read, so a failure is a tab that appears and vanishes. The
    // file was there a moment earlier — the drop handler checks its type, and
    // the argument filter checks it exists — so reaching the catch means
    // permissions, a share that went away, or something deleting it in
    // between, and none of those are things the reader can guess.
    final guards =
        everyCatchAround('lib/ui/screens/home_screen.dart', '_readDocument(path)');

    expect(guards.length, 2,
        reason: '这里应当有两处（拖放、启动参数）。多了或少了，'
            '说明又添了一条打开文档的路——它也得上报');
    for (final guard in guards) {
      expect(guard, contains('removeTab'),
          reason: '读失败了，那个占位的标签页不能留在那里转圈');
      expect(guard, contains('reportOpenFailure'),
          reason: '标签页闪一下就没了、而且什么也没说——'
              '另外两种打开方式早就会说了');
    }
  });
}
