import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The two call sites that ignored a failure, held to reporting it.
///
/// Both live behind something a widget test cannot easily reach — a menu that
/// opens a dialog, and a popup on the status bar — so this reads the source
/// instead. That pins the shape of the code rather than its behaviour, which
/// is weaker; it is here because the alternative was nothing at all, and both
/// of these are about the reader believing a write happened when it did not.
void main() {
  /// The body of the `catch` guarding [call], or null when there is none.
  ///
  /// Matched as "the call sits inside a try, and the catch that follows" —
  /// not as a range between two landmarks, which is what the first version
  /// did and which put the catch outside the range it was looking in.
  String? catchAround(String path, String call) {
    final source = File(path).readAsStringSync();
    final match = RegExp(
      r'try \{[^{}]*' +
          RegExp.escape(call) +
          r'[^{}]*\} catch \(\w+\) \{(.*?)\n(\s*)\}',
      dotAll: true,
    ).firstMatch(source);
    return match?.group(1);
  }

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
}
