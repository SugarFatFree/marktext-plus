import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Every kind of block the parser can produce comes out of export as
/// something.
///
/// `ExportService.nodeToHtml` switches on the node and ends in a default,
/// because `MarkdownNode` is not sealed and cannot be — the switch has to
/// return a string for whatever it is handed. So a twelfth kind of block
/// would compile, parse, draw in the preview, and be dropped in silence on
/// the way out: the reader's exported PDF is simply missing a section, with
/// nothing anywhere saying which.
///
/// The list of kinds is read out of the parser rather than typed here, so
/// adding one fails this test by name until somebody writes a sample for it.
/// That is the only half a test can hold; the compiler cannot help while the
/// family stays open.
void main() {
  /// Markdown that produces each kind, and whether inline HTML must be on.
  const samples = <String, (String, bool)>{
    'HeadingNode': ('# A heading\n', false),
    'ParagraphNode': ('Just a sentence.\n', false),
    'CodeBlockNode': ('```dart\nvar x = 1;\n```\n', false),
    'ListNode': ('- one\n- two\n', false),
    'BlockquoteNode': ('> quoted\n', false),
    'HorizontalRuleNode': ('above\n\n---\n\nbelow\n', false),
    'TableNode': ('| a | b |\n|---|---|\n| 1 | 2 |\n', false),
    'MathBlockNode': (r'$$' '\nE = mc^2\n' r'$$' '\n', false),
    'FrontMatterNode': ('---\ntitle: T\n---\n\nbody\n', false),
    'FootnoteDefinitionNode': ('A claim[^1]\n\n[^1]: the note\n', false),
    'HtmlBlockNode': ('<div class="x">raw</div>\n', true),
  };

  /// The kinds the parser declares, taken from its source.
  Set<String> declared() {
    final source = File('lib/services/markdown_parser.dart').readAsStringSync();
    return RegExp(r'class (\w+) extends MarkdownNode\b')
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();
  }

  test('the parser declares the kinds this test knows about', () {
    // Guards the guard, both ways: a kind with no sample, and a sample for a
    // kind that no longer exists.
    final kinds = declared();
    expect(kinds, isNotEmpty, reason: '读不出块类型清单，取法要跟着改');
    expect(
      kinds.difference(samples.keys.toSet()).toList()..sort(),
      isEmpty,
      reason: '新的块类型没有样例——导出器的默认分支会把它静静丢掉',
    );
    expect(
      samples.keys.toSet().difference(kinds).toList()..sort(),
      isEmpty,
      reason: '样例写的类型解析器已经没有了',
    );
  });

  samples.forEach((kind, sample) {
    final (markdown, enableHtml) = sample;
    test('$kind comes out of export as something', () {
      final nodes = MarkdownParser(enableHtml: enableHtml).parse(markdown);
      final node = nodes.where((n) => n.runtimeType.toString() == kind);

      expect(node, isNotEmpty,
          reason: '这段 markdown 产生不出 $kind，样例要跟着改：$markdown');
      expect(
        ExportService.nodeToHtml(node.first),
        isNotEmpty,
        reason: '$kind 导出成空——读者的文件里会少一段，而没人会说',
      );
    });
  });
}
