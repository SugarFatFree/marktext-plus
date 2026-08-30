import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// The 648 examples from the CommonMark 0.31.2 specification.
///
/// This parser is written from scratch, so the only honest way to know what it
/// does with the corner cases is to run the corner cases. The fixture is the
/// official `spec.txt`, split into its examples.
///
/// **This is a ratchet, not a conformance claim.** The number is far from 648
/// and some of the gap is deliberate — see [_normalise] — so what the test
/// asserts is that the score does not go *down*. A change that breaks parsing
/// somewhere unrelated shows up here as a drop, which is the thing worth
/// catching; raising the number is ordinary work, and the floor moves up with
/// it.
void main() {
  /// Folds away the differences that are known and intended, so what is left
  /// is a real disagreement. Every rule here needs a reason, or it is just
  /// hiding a bug.
  String normalise(String html) {
    var out = html;
    // Decoration the exporter adds for syntax highlighting; not parsing.
    //
    // One rule for the whole attribute rather than one per spelling: the two
    // classes are written together on a highlighted block — `class="hljs
    // language-ruby"` — which matched neither of the two patterns that used to
    // be here, so every highlighted example counted as a parse failure. The
    // spans carrying the colours go too; their text stays, so a real
    // difference in the code's content still shows.
    out = out.replaceAll(RegExp(r' class="(?:hljs|language-)[^"]*"'), '');
    // Innermost first, repeatedly, so a nested highlight unwraps in pairs.
    // Stripping every `</span>` instead would have taken the closing tag of
    // the one other span the exporter writes — inline maths — and left its
    // opening tag behind.
    final highlightSpan = RegExp(r'<span class="hljs-[^"]*">([^<]*)</span>');
    while (highlightSpan.hasMatch(out)) {
      out = out.replaceAllMapped(highlightSpan, (m) => m.group(1)!);
    }
    // Two spellings of a void element.
    out = out.replaceAll('<hr />', '<hr>').replaceAll('<br />', '<br>');
    out = out.replaceAll(RegExp(r' />'), '>');
    // This editor treats a newline inside a paragraph as a line break, in the
    // preview, in Word and in HTML alike; CommonMark folds it into a space.
    // That is a product decision, so both sides are folded to a space here.
    out = out.replaceAll('<br>', ' ');
    out = out.replaceAll(RegExp(r'\s+'), ' ');
    out = out.replaceAll('> <', '><');
    // CommonMark keeps the newline that ends a code block's content; this
    // exporter drops it. Nothing renders differently either way, and leaving
    // it in the comparison hid every real list failure behind a trailing
    // space.
    out = out.replaceAll(RegExp(r'\s+</code>'), '</code>');
    return out.trim();
  }

  late List<Map<String, dynamic>> examples;

  setUpAll(() {
    final raw =
        File('test/fixtures/commonmark_spec.json').readAsStringSync();
    examples = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  test('the fixture is the whole specification', () {
    expect(examples, hasLength(648));
    expect(examples.map((e) => e['section']).toSet().length,
        greaterThan(20));
  });

  test('no example makes the parser throw', () {
    // Separate from the score on purpose: a wrong answer is a difference of
    // opinion with the spec, and an exception is a document that cannot be
    // opened at all.
    final threw = <String>[];
    for (final example in examples) {
      try {
        MarkdownParser().parse(example['markdown'] as String);
      } catch (e) {
        threw.add('${example['section']}: $e');
      }
    }
    expect(threw, isEmpty);
  });

  test('the score does not fall', () {
    var passed = 0;
    for (final example in examples) {
      String produced;
      try {
        final ast = MarkdownParser().parse(example['markdown'] as String);
        produced = ast.map(ExportService.nodeToHtml).join('\n');
      } catch (_) {
        continue;
      }
      if (normalise(produced) == normalise(example['html'] as String)) {
        passed++;
      }
    }

    // Measured 2026-08-31. Raise it whenever the work raises it; never lower
    // it to make a change pass.
    //
    // The blocks are joined with a newline above, which `normalise` mostly
    // folds away — but not everywhere, and a scratch script joining them with
    // nothing counted one example differently. This is the number that
    // counts; anything measured another way is measuring another thing.
    const floor = 473;
    expect(passed, greaterThanOrEqualTo(floor),
        reason: '解析能力相比 $floor 例退步了');
    if (passed > floor) {
      // ignore: avoid_print
      print('CommonMark: $passed/648 — 高于下限 $floor，可以把下限提上来');
    }
  });

  test('a delimiter with a space just inside it does not emphasise', () {
    // Asserting the text that comes out, not merely that no bold span does.
    // The first version of this test checked for the absence of bold and
    // passed while the input was being turned into an *italic* containing a
    // literal asterisk — the `**` branch had been taught to refuse a space,
    // and the single-`*` branch picked up the pieces.
    for (final source in [
      '2 ** 3 ** 4',
      '** foo bar**',
      '__ foo bar__',
      '**foo bar **',
    ]) {
      final spans =
          (MarkdownParser().parse('$source\n').single as ParagraphNode)
              .inlineSpans;
      expect(spans.single.type, InlineType.text, reason: source);
      expect(spans.single.text, source,
          reason: '$source 被拆开或加了样式');
    }

    // And still emphasises when there is no space.
    for (final entry in {
      '**foo bar**': InlineType.bold,
      '*foo bar*': InlineType.italic,
      '__foo bar__': InlineType.bold,
      '_foo bar_': InlineType.italic,
    }.entries) {
      final spans = (MarkdownParser().parse('${entry.key}\n').single
              as ParagraphNode)
          .inlineSpans;
      expect(spans.single.type, entry.value, reason: entry.key);
      expect(spans.single.text, 'foo bar', reason: entry.key);
    }
  });

  test('an underscore inside a word does not emphasise, in any script', () {
    // The boundary was `[a-zA-Z0-9_]`, so it only recognised a Latin word.
    // Cyrillic and Chinese text with underscores in it came out emphasised
    // because the character before the delimiter was, to that class, not a
    // word character at all.
    for (final source in [
      'snake_case_name',
      'пристаням_стремятся_',
      '中文_强调_文字',
      'ファイル_名前_です',
    ]) {
      final spans =
          (MarkdownParser().parse('$source\n').single as ParagraphNode)
              .inlineSpans;
      expect(
          spans.where((s) =>
              s.type == InlineType.italic || s.type == InlineType.bold),
          isEmpty,
          reason: source);
    }

    // Standing alone it still emphasises, whatever the script.
    for (final source in ['_foo_', '_中文_']) {
      final spans =
          (MarkdownParser().parse('$source\n').single as ParagraphNode)
              .inlineSpans;
      expect(spans.where((s) => s.type == InlineType.italic), hasLength(1),
          reason: source);
    }
  });

  test('a paragraph does not keep the spaces its lines were indented by', () {
    // HTML collapses a leading space, so an export looked right; the preview
    // draws a Text widget, where the space is there on screen. A paragraph
    // under a list item came out visibly shifted.
    for (final source in ['   foo\n', 'one\n   two\n', '- item\n\n  after\n']) {
      for (final node in MarkdownParser().parse(source)) {
        if (node is! ParagraphNode) continue;
        for (final line in node.content.split('\n')) {
          expect(line, isNot(startsWith(' ')), reason: source);
        }
      }
    }
  });

  test('changing the bullet character starts a second list', () {
    // Someone who wants two lists next to each other writes the second with
    // a different marker; run together they were one list.
    final ast = MarkdownParser().parse('- foo\n- bar\n+ baz\n');
    final lists = ast.whereType<ListNode>().toList();
    expect(lists, hasLength(2));
    expect(lists.first.items, hasLength(2));
    expect(lists.last.items, hasLength(1));

    // The same run of markers is still one list.
    expect(
        MarkdownParser().parse('- foo\n- bar\n- baz\n')
            .whereType<ListNode>()
            .single
            .items,
        hasLength(3));
  });

  test('a link may have an empty destination', () {
    // `[TODO]()` is a placeholder people write; with a required destination
    // the whole thing fell back to literal text.
    final spans = (MarkdownParser().parse('[TODO]()\n').single as ParagraphNode)
        .inlineSpans;
    final link = spans.where((s) => s.type == InlineType.link);
    expect(link, hasLength(1));
    expect(link.single.text, 'TODO');
    expect(link.single.href, '');
  });

  test('a shortcut reference link resolves against its definition', () {
    // `[the docs]` with the definition at the bottom is the ordinary way to
    // use reference links; only the two-bracket forms were read, so the
    // shortcut came out as literal text.
    final ast = MarkdownParser()
        .parse('See [the docs] for more.\n\n[the docs]: /guide "Guide"\n');
    final link = (ast.first as ParagraphNode)
        .inlineSpans
        .where((s) => s.type == InlineType.link);
    expect(link, hasLength(1));
    expect(link.single.text, 'the docs');
    expect(link.single.href, '/guide');
    expect(link.single.title, 'Guide');
  });

  test('the shortcut form works for images too', () {
    final ast = MarkdownParser()
        .parse('![a cat]\n\n[a cat]: cat.png\n');
    final image = (ast.first as ParagraphNode)
        .inlineSpans
        .where((s) => s.type == InlineType.image);
    expect(image, hasLength(1));
    expect(image.single.href, 'cat.png');
  });

  test('brackets with no definition behind them stay as prose', () {
    // Prose is full of square brackets that are not links. Turning `[sic]`
    // into a link to nowhere would be worse than not supporting the shortcut.
    for (final source in ['a note [sic] here', 'see [1] below', '[a [b] c]']) {
      final spans =
          (MarkdownParser().parse('$source\n').single as ParagraphNode)
              .inlineSpans;
      expect(spans.where((s) => s.type == InlineType.link), isEmpty,
          reason: source);
      expect(spans.single.text, source,
          reason: '$source 被拆成了多个文本 span');
    }
  });

  test('a heading may be indented by up to three spaces', () {
    // CommonMark allows three spaces before any block and calls four an
    // indented code block. `   # 标题` used to come out as a paragraph with a
    // literal hash in it.
    for (final indent in ['', ' ', '  ', '   ']) {
      final ast = MarkdownParser().parse('$indent# 标题\n');
      expect(ast.single, isA<HeadingNode>(), reason: '缩进 ${indent.length} 格');
      expect((ast.single as HeadingNode).content, '标题');
    }
    // Four is code, not a heading.
    expect(MarkdownParser().parse('    # 标题\n').single,
        isA<CodeBlockNode>());
  });

  test('a heading with nothing after it is still a heading', () {
    // The state a heading passes through while it is being typed.
    for (final source in ['#', '# ', '###']) {
      final ast = MarkdownParser().parse('$source\n');
      expect(ast.single, isA<HeadingNode>(), reason: source);
      expect((ast.single as HeadingNode).content, '', reason: source);
    }
  });

  test('seven hashes is not a heading', () {
    expect(MarkdownParser().parse('####### 七个\n').single,
        isA<ParagraphNode>());
  });

  test('the outline lists only headings written flush left', () {
    // It reads the raw text, so it cannot tell a top-level heading written
    // with three spaces from one belonging to a list item. Listing a step's
    // heading would put an entry in the outline that the preview has no
    // scroll target for, and move every entry after it to the wrong place.
    final outline = MarkdownParser.headingOutline(
      '# 一\n\n1. 步骤\n\n   ### 步骤里的\n\n## 二\n',
    );
    expect(outline.map((h) => h.text).toList(), ['一', '二']);
  });

  test('a code span written across two lines is still a code span', () {
    // The regex is not dotAll, so `[^`].*?[^`]` could not cross a newline and
    // a wrapped command was left with its backticks showing.
    final ast = MarkdownParser().parse('Use `flutter build\nwindows` here.\n');
    final spans = (ast.single as ParagraphNode).inlineSpans;
    final code = spans.where((s) => s.type == InlineType.code).toList();
    expect(code, hasLength(1));
    expect(code.single.text, 'flutter build windows',
        reason: 'CommonMark 把行内代码里的换行折成空格');
  });
}
