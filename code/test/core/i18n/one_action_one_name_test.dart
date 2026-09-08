import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One action, one name — in every language.
///
/// The same eighteen actions are named twice in the ARB files, once under a
/// `format*`/`edit*` key that the menus and the command palette read, and once
/// under a `keybinding*` key that the shortcut list in Settings reads. Nothing
/// tied the two together, so a wording change on one side left the other
/// behind and the same command answered to two names.
///
/// Two had already drifted when this was written: `mathBlock` was 数学公式 in
/// the palette and 数学公式块 in Settings, and Russian spelled strikethrough
/// with and without its ё.
///
/// The duplication itself is left alone. Collapsing it means deleting keys
/// from twelve files and rewriting every reader, which is a bigger change than
/// the problem — and this catches the thing that actually reaches a reader.
void main() {
  /// The pairs, by the action they both name.
  const pairs = {
    'bold': ('formatBold', 'keybindingBold'),
    'italic': ('formatItalic', 'keybindingItalic'),
    'underline': ('formatUnderline', 'keybindingUnderline'),
    'strikethrough': ('formatStrikethrough', 'keybindingStrikethrough'),
    'highlight': ('formatHighlight', 'keybindingHighlight'),
    'codeBlock': ('formatCodeBlock', 'keybindingCodeBlock'),
    'inlineCode': ('formatInlineCode', 'keybindingInlineCode'),
    'inlineMath': ('formatInlineMath', 'keybindingInlineMath'),
    'mathBlock': ('formatMathBlock', 'keybindingMathBlock'),
    'link': ('formatLink', 'keybindingLink'),
    'image': ('formatImage', 'keybindingImage'),
    'table': ('formatTable', 'keybindingTable'),
    'orderedList': ('formatOrderedList', 'keybindingOrderedList'),
    'unorderedList': ('formatUnorderedList', 'keybindingUnorderedList'),
    'taskList': ('formatTaskList', 'keybindingTaskList'),
    'quoteBlock': ('formatQuoteBlock', 'keybindingQuoteBlock'),
    'selectAll': ('editSelectAll', 'keybindingSelectAll'),
    'duplicateLine': ('editDuplicateLine', 'keybindingDuplicateLine'),
  };

  final files = Directory('lib/core/i18n/l10n')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('there are twelve languages to check', () {
    // Guards the guard: a glob that matched nothing would pass every
    // assertion below in silence.
    expect(files.length, 12);
  });

  for (final file in files) {
    final language = file.path.split(Platform.pathSeparator).last;

    test('$language names each action the same way twice', () {
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final disagreements = <String>[];

      pairs.forEach((action, keys) {
        final (format, keybinding) = keys;
        expect(arb, contains(format), reason: '$language 缺 $format');
        expect(arb, contains(keybinding), reason: '$language 缺 $keybinding');
        if (arb[format] != arb[keybinding]) {
          disagreements.add(
            '$action: $format="${arb[format]}" ≠ '
            '$keybinding="${arb[keybinding]}"',
          );
        }
      });

      expect(
        disagreements,
        isEmpty,
        reason:
            '$language 里同一个动作有两个名字——命令面板与设置里会显示得不一样：\n'
            '${disagreements.join('\n')}',
      );
    });
  }
}
