import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every write to the editor's controller is on one side of a line, on purpose.
///
/// Two kinds of write live in `source_editor.dart`:
///
/// **A command** — a format action, a block move, a table edit, an indent, an
/// insert, cut, paste — has to be one press of Ctrl+Z. Twenty-five of them
/// wrote the controller directly and left the step boundary to the typing
/// debounce, which closes 300 ms after a pause, so two commands quicker than
/// that arrived as a single entry holding only the last state and one undo took
/// back both. They go through `_writeAsOneStep` now.
///
/// **A keystroke** — auto-pairing a bracket, closing a list on Enter, deleting
/// the other half of a pair, skipping over a quote already there — must *not*
/// get its own step, or undo becomes character-by-character. Those still write
/// the controller directly, and the debounce and the end-of-word rule own them.
///
/// The line between the two is a judgement, so it is written down here rather
/// than left to whoever reads the file next. A write in a method that is on
/// neither list turns this red, which is the only way a new one gets classified
/// rather than guessed at.
void main() {
  /// The methods and switch cases whose direct writes are deliberate, and why.
  ///
  /// Keyed by the enclosing name a write is found in.
  const typing = <String, String>{
    'didUpdateWidget':
        '外部文本进来（分屏预览里编辑、插件改写），历史归标签页记——recordExternalEdit',
    '_handleKeyEvent': '自动配对与回车续列表：每个按键一个撤销步会让撤销变成逐字',
    '_handleTextInput': '同上，按键路径',
  };

  test('every controller write is either one step or a keystroke', () {
    final lines =
        File('lib/ui/editor/source_editor.dart').readAsLinesSync();

    /// The nearest method or switch case above [index].
    String owner(int index) {
      for (var i = index; i >= 0; i--) {
        final match = RegExp(
          r'^\s*(?:@override\s*)?(?:case FormatAction\.(\w+)|'
          r'(?:static\s+)?(?:void|bool|Future<[^>]*>|KeyEventResult|String)\s+'
          r'(\w+)\s*\()',
        ).firstMatch(lines[i]);
        if (match != null) return match.group(1) ?? match.group(2)!;
      }
      return '<file>';
    }

    final direct = <String>[];
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].contains('_controller.value = ')) continue;
      direct.add(owner(i));
    }

    expect(direct, isNotEmpty, reason: '一处写入都没扫到，这条守卫已失效');

    // The entry point itself writes the controller, which is the one place a
    // direct write is the whole point.
    const entryPoint = '_writeAsOneStep';
    expect(direct, contains(entryPoint),
        reason: '入口自己没在写控制器了，取法要跟着改');

    final unclassified = direct
        .where((name) => name != entryPoint && !typing.containsKey(name))
        .toSet();
    expect(
      unclassified,
      isEmpty,
      reason: '这些地方直接写了控制器，既没走 _writeAsOneStep 也不在按键名单里：'
          '$unclassified\n'
          '命令式的编辑改用 _writeAsOneStep；确实属于打字的，加进 typing 并写明为什么',
    );

    for (final entry in typing.entries) {
      expect(entry.value.trim(), isNotEmpty,
          reason: '${entry.key} 在名单里但没写理由');
    }
  });

  test('the commands go through the one entry point', () {
    final source = File('lib/ui/editor/source_editor.dart').readAsStringSync();
    final through = '_writeAsOneStep('.allMatches(source).length - 1;
    expect(through, greaterThan(15),
        reason: '走 _writeAsOneStep 的地方只有 $through 处，'
            '命令式的编辑大概又直接写控制器去了');

    // The entry point records before it writes, and in that order.
    final body = source.substring(
      source.indexOf('void _writeAsOneStep('),
      source.indexOf('/// Whether an input method'),
    );
    final pushed = body.indexOf('pushHistory');
    final wrote = body.indexOf('_controller.value =');
    expect(pushed, greaterThan(-1), reason: '入口不记录了');
    expect(wrote, greaterThan(pushed),
        reason: '先写后记等于记下了改完之后的状态——那不是可以退回去的那一版');
  });
}
