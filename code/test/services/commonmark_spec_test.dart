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
/// What the remaining 147 are made of, measured 2026-09-11 at 501.
///
/// Written down so the next person does not spend an evening finding out.
/// The sections are named as the specification names them.
///
/// | Failing | Section | Worth chasing? |
/// |---------|---------|----------------|
/// | 31/90 | Links | The realistic forms all work. What is left is URL syntax at the edges: a destination with *two* levels of nested parentheses (one level — `/wiki/Mercury_(planet)` — works), `(title)` as a title delimiter instead of quotes, percent-encoding of a backslash, entity decoding inside a destination, and several unclosed-angle-bracket cases. The fix means editing a forty-group regular expression with a backreference by absolute number, which has frozen the preview twice on pathological input. Not worth it for these. |
/// | 23/44 + 18/20 | HTML blocks, Raw HTML | **Deliberate.** Inline HTML is an allowlist of formatting tags — `b`, `em`, `mark`, `sub`, `ruby` and the rest of `_inlineHtmlTypes` — and everything else is escaped. The comment beside that list says why: a tag wrapping other markup needs a real HTML parser, and guessing is worse than leaving it as written. These 41 are the price of that decision, not a gap in it. |
/// | 12/48 + 9/27 | List items, Lists | Examined 2026-09-11. One was worth fixing and is fixed: an ordered list may interrupt a paragraph only when numbered 1. Most of the rest turns on a marker with nothing after it — `-` alone is an empty list item to CommonMark and a paragraph here, which cascades (`-\n  foo\n-` comes out as a setext H2). Allowing it means `_ulRe` accepting an empty tail, and then `---` is a list item whose content is `--` unless the thematic-break and setext rules win first. Trading thematic breaks and setext headings, both everywhere, for empty bullets, which are rare, is a bad bargain; whoever takes it on should start with the precedence and not with the pattern. The remainder is content-block parsing inside an item — `- # Foo`, `- - foo`, indented code as an item's first block. |
/// | 9/27 + 6/19 | Link reference definitions, Autolinks | Same URL-syntax edges as Links. |
/// | 4/22 | Code spans | Examined 2026-09-11. One was worth fixing and is fixed: a backslash inside a code span is a backslash, not an escape. The four left are precedence — a code span against a link (`[not a `link](/foo`)`), against raw HTML, against an autolink, and a run of three backticks with no closing run of three. Each is an ordering question inside the forty-group pattern, and reordering it is how this parser has frozen the preview before. |
/// | 4/25 | Block quotes | Examined 2026-09-11. All four are indented code inside a quote and lazy continuation: `>     foo` is four columns past the marker and so a code block, and `> foo` followed by an indented line is the same paragraph rather than a list. Both need the block parser to count columns after the quote marker, which it does not do anywhere yet. A real gap, and a day's work rather than an hour's. |
/// | the rest | scattered | One or two each. Hard line breaks are mostly the deliberate newline decision [normalise] folds away. |
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
    // Innermost first, repeatedly, so a nested highlight unwraps in pairs.
    // Stripping every `</span>` instead would have taken the closing tag of
    // the one other span the exporter writes — inline maths — and left its
    // opening tag behind.
    //
    // Before the attribute is stripped, not after. These two rules ran the
    // other way round, and the first one deleted `class="hljs-keyword"` —
    // it begins with `hljs` — so the pattern below, which matches on exactly
    // that attribute, never matched anything. Every highlighted code block
    // kept its spans and counted as a parse failure: the score this file
    // reports was lower than the parser deserved, and the comment above said
    // the spans went while they stayed.
    final highlightSpan = RegExp(r'<span class="hljs-[^"]*">([^<]*)</span>');
    while (highlightSpan.hasMatch(out)) {
      out = out.replaceAllMapped(highlightSpan, (m) => m.group(1)!);
    }
    out = out.replaceAll(RegExp(r' class="(?:hljs|language-)[^"]*"'), '');
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

    // Measured 2026-08-31 at 493, raised to 495 on 2026-09-08 when an item
    // left blank stopped nesting the rest of its list. Raise it whenever the
    // work raises it; never lower it to make a change pass.
    //
    // 503 on 2026-09-11, when a backslash inside a code span stopped being an
    // escape — `` `\.` `` had been coming out as `.`.
    //
    // 502 the same day, when a numbered list stopped interrupting a paragraph
    // unless it is numbered 1 — a wrapped sentence beginning "14." was being
    // turned into a list.
    //
    // 501 the same day, when a backtick fence stopped opening on a line that
    // carries another backtick: `` ``` aa ``` `` is a code span, and opening a
    // block there took the rest of the document with it.
    //
    // 499 the same day, when a fence indented four columns stopped opening a
    // code block — CommonMark makes that an indented code block, and the
    // highlighter had always read it that way while the parser had not.
    //
    // 497 the same day, and that one was not the parser getting better: the
    // two rules that fold away syntax highlighting ran in the wrong order, so
    // the one that unwraps the spans never matched and every highlighted code
    // block counted as a failure. The parser had been right about them all
    // along and this file was saying otherwise.
    //
    // The blocks are joined with a newline above, which `normalise` mostly
    // folds away — but not everywhere, and a scratch script joining them with
    // nothing counted one example differently. This is the number that
    // counts; anything measured another way is measuring another thing.
    const floor = 503;
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
