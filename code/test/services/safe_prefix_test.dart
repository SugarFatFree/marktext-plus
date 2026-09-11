import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/cost_limits.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Showing the top of a large document while the rest is still being parsed.
///
/// Parsing costs about 0.02–0.04 ms per block with no hot spot to remove, so a
/// five megabyte document takes roughly three seconds during which the screen
/// is empty. A prefix parsed first puts the top up immediately.
///
/// The prefix has to be a *prefix*: its line numbers are then the same numbers
/// as in the whole document, so the blocks carry the right source ranges with
/// no arithmetic — and those ranges are what editing a block in the preview
/// depends on. These tests are mostly about that.
void main() {
  final parser = MarkdownParser();

  String doc(int paragraphs) => List.generate(
        paragraphs,
        (i) => '## Heading $i\n\nParagraph $i with **bold** and `code`.\n',
      ).join('\n');

  test('a short document is not split at all', () {
    expect(MarkdownParser.safePrefix(doc(10)), isNull,
        reason: '短文档整篇解析更快，切开只是徒增一次解析');
  });

  // A document whose lines are long: prose written without hard wrapping, a
  // pasted log, a base64 blob. Few lines, many bytes.
  String longLines(int lines, int perLine) => List.generate(
        lines,
        (i) => '## Section $i\n\n${'word ' * (perLine ~/ 5)}',
      ).join('\n\n');

  test('a document can be too large without being too many lines', () {
    // 8.6 MB in 1199 lines took 3999 ms to parse whole, with nothing on
    // screen for all of it. The line count said "short document" the entire
    // time, because the count was the only thing being asked.
    final source = longLines(300, 30000);
    expect(source.length, greaterThan(8 * 1024 * 1024));
    expect('\n'.allMatches(source).length + 1, lessThan(1500),
        reason: '前提是这份文档的行数确实在阈值以下，否则这条测的是另一回事');

    expect(MarkdownParser.safePrefix(source), isNotNull,
        reason: '八兆的文档不该因为行数少就整篇挡在首帧前面');
  });

  test('the prefix is bounded in size, not only in lines', () {
    // The middle case is the one that looks fine and is not: 4.6 MB over
    // 1599 lines did return a prefix — of 4,506,654 characters. The cut fell
    // at line 1500 of 1599, so "the top of the document" was almost all of
    // it, and the first frame waited for 2141 ms of the 2141.
    final source = longLines(400, 12000);
    final prefix = MarkdownParser.safePrefix(source);

    expect(prefix, isNotNull);
    expect(prefix!.length, lessThan(source.length ~/ 4),
        reason: '前缀存在的意义是先画出一小截；和整篇一样大的前缀什么也没省下');
  });

  test('an ordinary document is cut where it always was', () {
    // The byte budget sits above 1500 lines of ordinary prose, so documents
    // that wrap normally keep the behaviour they had. Only the long-line
    // shapes above change.
    final source = doc(1200);
    final prefix = MarkdownParser.safePrefix(source);

    expect(prefix, isNotNull);
    final lines = '\n'.allMatches(prefix!).length + 1;
    expect(lines, greaterThanOrEqualTo(1500),
        reason: '普通文档仍旧按行数切，字节预算不该提前把它截短');
  });

  test('a huge fenced block counts toward the budget', () {
    // The character count is taken before the loop's `continue`s, and this is
    // why: a fence's lines cost the parser what any other line costs. Counted
    // after them, a document that opens with a large code block would spend
    // none of its budget crossing it and get no prefix at all.
    //
    // The cut cannot land inside the fence, so what this asks is that it
    // lands soon after it closes rather than never.
    // Few lines, many bytes — deliberately. Written with 2000 short lines
    // instead, the fence alone crosses the 1500-line threshold and the cut
    // happens for that reason, so the test passes either way and proves
    // nothing about where the counting goes.
    final code = List.generate(100, (i) => 'const line$i = "${'x' * 5000}";')
        .join('\n');
    final source = '```js\n$code\n```\n\n${doc(50)}';
    expect(code.length, greaterThan(200 * 1024));
    expect('\n'.allMatches(source).length + 1, lessThan(1500),
        reason: '前提是行数不越线，否则这条测的是行数规则');

    final prefix = MarkdownParser.safePrefix(source);
    expect(prefix, isNotNull,
        reason: '一份以大代码块开头的文档，也该先画出一截');
    expect(prefix, contains('```js'));
    expect(prefix!.length, lessThan(source.length),
        reason: '前缀要真的比整篇短');
  });

  test('the prefix keeps the whole-document line numbering', () {
    final source = doc(1200);
    final prefix = MarkdownParser.safePrefix(source);
    expect(prefix, isNotNull);

    final fromPrefix = parser.parse(prefix!);
    final fromWhole = parser.parse(source);
    expect(fromPrefix.length, lessThan(fromWhole.length));

    for (var i = 0; i < fromPrefix.length; i++) {
      expect(fromPrefix[i].runtimeType, fromWhole[i].runtimeType,
          reason: '第 $i 块的类型和整篇解析不一致');
      expect(fromPrefix[i].sourceStart, fromWhole[i].sourceStart,
          reason: '第 $i 块的起始行和整篇解析不一致 —— 块编辑会改错行');
      expect(fromPrefix[i].sourceEnd, fromWhole[i].sourceEnd);
    }
  });

  /// A document whose fenced block straddles the cut.
  ///
  /// The block has to *contain* the first blank line the cut is allowed to
  /// take, which means it has to start just before line 1500 and run past it.
  /// Filling with 1490 paragraph-and-blank pairs — as this did — puts the
  /// fence at line 2980, a thousand lines past a cut that had already been
  /// taken among the filler: the fence was never in the prefix, so counting
  /// its markers there counted zero of them and passed no matter what.
  String straddling(String open, String inner, String close) {
    final source = StringBuffer();
    // No blank lines here: the cut may not be taken before line 1500 anyway,
    // and a blank one inside the filler would only make the test depend on
    // where exactly it fell.
    for (var i = 0; i < 1495; i++) {
      source.writeln('line $i');
    }
    source.writeln(open);
    source.writeln(inner);
    // Blank lines from here on, so the first one the cut may take is inside
    // the block. A reader of this fixture should be able to see that a cut
    // taken at all is a cut taken in the wrong place.
    for (var i = 0; i < 200; i++) {
      source.writeln('  var x$i = $i;');
      source.writeln();
    }
    source.writeln(inner);
    source.writeln(close);
    source.writeln();
    source.writeln('after');
    return source.toString();
  }

  test('the cut is never inside a fenced code block', () {
    final prefix = MarkdownParser.safePrefix(straddling('```dart', 'x', '```'));
    expect(prefix, isNotNull);
    expect(RegExp(r'^```', multiLine: true).allMatches(prefix!).length.isEven,
        isTrue,
        reason: '前缀里的代码围栏没有配对，说明切在了围栏中间');
  });

  test('a fence shown inside a longer fence does not end it', () {
    // A document explaining markdown puts ``` inside a ```` block — this
    // project's own README does. The cut compared only the fence character,
    // so the inner run ended the block here while the parser kept it open,
    // and the cut landed in the middle of the code it must never halve.
    final prefix =
        MarkdownParser.safePrefix(straddling('````markdown', '```', '````'));
    expect(prefix, isNotNull);
    expect(RegExp(r'^````', multiLine: true).allMatches(prefix!).length.isEven,
        isTrue,
        reason: '前缀里的外层围栏没有配对，说明切在了 ```` 块中间');
  });

  test('a tilde block is not closed by backticks', () {
    final prefix = MarkdownParser.safePrefix(straddling('~~~', '```', '~~~'));
    expect(prefix, isNotNull);
    expect(RegExp(r'^~~~', multiLine: true).allMatches(prefix!).length.isEven,
        isTrue,
        reason: '``` 不能闭合 ~~~，它们是不同的字符');
  });

  test('the cut is never inside a raw-text HTML block', () {
    // `<pre>`, `<script>`, `<style>` and `<textarea>` run to their closing tag
    // however far down it is — the parser says so beside `_rawTextHtmlTags`.
    // Cut in half, the prefix holds a block with no end, and that block then
    // swallows everything after it in the prefix: the reader sees the top of
    // their document with a chunk of it rendered as raw text until the whole
    // parse arrives. The source ranges are wrong for that moment too, and
    // editing a block in the preview is what those ranges are for.
    //
    // Blank lines inside the block are what makes this reachable at all: the
    // cut looks for a blank line outside everything, and inside one of these
    // it is not outside anything.
    final filler = List.generate(740, (i) => 'Paragraph $i.\n').join('\n');
    for (final tag in ['pre', 'script', 'style', 'textarea']) {
      final block = '<$tag>\n'
          '${List.generate(40, (i) => 'line $i\n').join('\n')}\n'
          '</$tag>\n';
      final prefix = MarkdownParser.safePrefix('$filler\n$block\nAfter.\n');
      if (prefix == null) continue;
      if (!prefix.contains('<$tag>')) continue; // cut before it: fine
      expect(prefix, contains('</$tag>'),
          reason: '<$tag> 被切成两半，前缀里没有它的闭合标签');
    }
  });

  test('front matter is never cut in half', () {
    final source = StringBuffer()
      ..writeln('---')
      ..writeln('title: test')
      ..writeln('---')
      ..writeln();
    for (var i = 0; i < 1600; i++) {
      source.writeln('paragraph $i');
      source.writeln();
    }

    final prefix = MarkdownParser.safePrefix(source.toString())!;
    final nodes = parser.parse(prefix);
    expect(nodes.first, isA<FrontMatterNode>());
  });

  /// Every block the prefix produced is the same block the whole document did.
  ///
  /// Start, kind and end. Comparing only the start — which this did — cannot
  /// see the failure that matters: the block a cut halves is the last one in
  /// the prefix, and its start is right by definition. Its *end* is where the
  /// prefix stopped rather than where the block does, and its kind can change
  /// outright when an opener loses its closer.
  ///
  /// A correctly cut prefix ends at a blank line outside everything, so every
  /// block in it is complete and every field should agree.
  void agrees(String what, String source) {
    final prefix = MarkdownParser.safePrefix(source);
    if (prefix == null) return;
    final fromPrefix = parser.parse(prefix);
    final fromWhole = parser.parse(source);
    for (var i = 0; i < fromPrefix.length; i++) {
      expect(fromPrefix[i].sourceStart, fromWhole[i].sourceStart,
          reason: '$what 第 $i 块的起始行对不上');
      expect(fromPrefix[i].type, fromWhole[i].type,
          reason: '$what 第 $i 块的种类变了：'
              '${fromPrefix[i].type} vs ${fromWhole[i].type}');
      expect(fromPrefix[i].sourceEnd, fromWhole[i].sourceEnd,
          reason: '$what 第 $i 块的结束行对不上——'
              '切点把它截断了，而它的起始行看起来完全正常');
    }
  }

  test('a document of things that must not be halved survives the cut', () {
    // The corpus below is real documents, and none of them happens to carry a
    // long raw-text HTML block with blank lines in it — so the comparison it
    // makes could not fire even once the assertions above were sharp enough.
    // This one is built to carry every kind that runs to a closing marker,
    // each with a blank line inside it, at a size past the threshold.
    final filler = List.generate(740, (i) => 'Paragraph $i.\n').join('\n');
    String withBlanks(String open, String close) =>
        '$open\n${List.generate(30, (i) => 'line $i\n').join('\n')}\n$close\n';

    for (final (name, open, close) in [
      ('fence', '```', '```'),
      ('tilde fence', '~~~', '~~~'),
      ('maths', r'$$', r'$$'),
      ('pre', '<pre>', '</pre>'),
      ('script', '<script>', '</script>'),
      ('style', '<style>', '</style>'),
      ('textarea', '<textarea>', '</textarea>'),
    ]) {
      agrees(name, '$filler\n${withBlanks(open, close)}\nAfter.\n');
    }
  });

  /// The scan stops at the cut, so a bigger document does not cost more.
  ///
  /// This is a different property from the one `cost_stays_linear_test` holds
  /// over parsing and search — theirs is that the work tracks the input, and
  /// this one's is that it does *not*, because the loop returns at the first
  /// blank line past the threshold and never sees the rest of the file.
  ///
  /// Written after a change of mine put four `RegExp` constructions on every
  /// line of this loop, which cost a third of the function on a 1.6 MB
  /// document. Nothing in the suite could have seen it: parsing and search
  /// have a budget, and this had none. A constant factor is still not what
  /// this catches — that would need a wall-clock limit, which this project
  /// refuses for good reasons — but the early return going away, or the scan
  /// turning superlinear, is exactly what it does.
  test('a longer document does not make the prefix scan longer', () {
    String document(int paragraphs) => List.generate(
          paragraphs,
          (i) => 'Paragraph $i with some text in it.\n',
        ).join('\n');

    final unit = document(4000);
    final four = document(4000 * costSpan);
    expect(four.length, greaterThan(unit.length * 3.9));

    MarkdownParser.safePrefix(unit); // warm the JIT before either measurement

    int fastest(int times, void Function() body) {
      var best = 1 << 30;
      for (var i = 0; i < times; i++) {
        final watch = Stopwatch()..start();
        body();
        watch.stop();
        if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
      }
      return best;
    }

    final one = fastest(5, () => MarkdownParser.safePrefix(unit));
    final many = fastest(5, () => MarkdownParser.safePrefix(four));

    // Not 1.0: the same work on a larger string still allocates differently,
    // and a limit that goes red on an idle machine teaches people to ignore
    // it. Two is far below the four it would take to mean "reads it all".
    expect(
      many,
      lessThan(one * 2),
      reason: '四倍长的文档让前缀扫描花了 ${(many / one).toStringAsFixed(1)} 倍时间'
          '（$one µs → $many µs）——它本该在切点就停下，'
          '所以多出来的长度不该被读到',
    );
  });

  test('every fixture either stays whole or splits cleanly', () {
    final files = [
      File('test/fixtures/showcase.md'),
      ...Directory('../docs')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];

    for (final file in files) {
      agrees(file.path, file.readAsStringSync());
    }
  });
}
