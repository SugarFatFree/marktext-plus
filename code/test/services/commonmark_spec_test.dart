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
    out = out.replaceAll(' class="hljs"', '');
    out = out.replaceAll(RegExp(r' class="language-[^"]*"'), '');
    // Two spellings of a void element.
    out = out.replaceAll('<hr />', '<hr>').replaceAll('<br />', '<br>');
    // This editor treats a newline inside a paragraph as a line break, in the
    // preview, in Word and in HTML alike; CommonMark folds it into a space.
    // That is a product decision, so both sides are folded to a space here.
    out = out.replaceAll('<br>', ' ');
    out = out.replaceAll(RegExp(r'\s+'), ' ');
    out = out.replaceAll('> <', '><');
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

    // Measured 2026-08-29. Raise it whenever the work raises it; never lower
    // it to make a change pass.
    const floor = 259;
    expect(passed, greaterThanOrEqualTo(floor),
        reason: '解析能力相比 $floor 例退步了');
    if (passed > floor) {
      // ignore: avoid_print
      print('CommonMark: $passed/648 — 高于下限 $floor，可以把下限提上来');
    }
  });

  test('a delimiter with a space just inside it does not emphasise', () {
    // The single-asterisk branch already refused this — which is why
    // `2 * 3 * 4` was safe — but `**`, `***`, `__` and `___` did not, so
    // prose with spaced asterisks in it came out bold.
    for (final source in ['2 ** 3 ** 4', '** foo bar**', '__ foo bar__']) {
      final spans =
          (MarkdownParser().parse('$source\n').single as ParagraphNode)
              .inlineSpans;
      expect(spans.where((s) => s.type == InlineType.bold), isEmpty,
          reason: source);
    }

    // And still emphasises when there is no space.
    final bold = (MarkdownParser().parse('**foo bar**\n').single
            as ParagraphNode)
        .inlineSpans
        .where((s) => s.type == InlineType.bold);
    expect(bold, hasLength(1));
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
