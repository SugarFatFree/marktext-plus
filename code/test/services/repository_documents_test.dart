import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// The parser run over this repository's own markdown.
///
/// Every other parser test is a crafted input: someone thought of the case, so
/// the case is covered. This one is the opposite — a megabyte of documents
/// nobody wrote for the parser, read for shapes that mean a rule fired where
/// it should not have. It found nothing on the day it was written, which is
/// the point: it is here for the change that has not been made yet.
void main() {
  late List<File> documents;

  setUpAll(() {
    // Run from `code/`, so the repository root is one level up.
    documents = Directory('..')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.md') &&
            !f.path.contains('/.git/') &&
            !f.path.contains('node_modules'))
        .toList();
  });

  test('there are documents to read', () {
    // Guard on the guard: a wrong path here would make every test below pass
    // by having nothing to look at.
    expect(documents.length, greaterThan(20));
  });

  /// Reports every document whose HTML matches [bad], with a line of context.
  void noneMatch(String what, RegExp bad) {
    final offenders = <String>[];
    for (final file in documents) {
      final html = MarkdownParser()
          .parse(file.readAsStringSync())
          .map(ExportService.nodeToHtml)
          .join();
      final match = bad.firstMatch(html);
      if (match != null) {
        offenders.add('${file.path}: ${match.group(0)}');
      }
    }
    expect(offenders, isEmpty, reason: '$what（前几处：${offenders.take(3)}）');
  }

  test('no empty list item', () {
    // An empty marker continues a list; one appearing here would mean a line
    // of prose was read as a marker.
    noneMatch('出现了空列表项', RegExp(r'<li>\s*</li>'));
  });

  test('no anchor inside an anchor', () {
    noneMatch('出现了嵌套锚点', RegExp(r'<a[^>]*>(?:(?!</a>).)*<a'));
  });

  test('no markup left literal inside emphasis', () {
    noneMatch('强调里残留了链接标记',
        RegExp(r'<(?:strong|em)>[^<]*\[[^<\]]*\]\('));
  });

  test('no markup left literal inside a link or a heading', () {
    noneMatch('链接文字里残留了 **', RegExp(r'<a [^>]*>[^<]*\*\*'));
    noneMatch('标题里残留了 **', RegExp(r'<h[1-6]>[^<]*\*\*'));
  });

  test('every document parses without throwing', () {
    for (final file in documents) {
      expect(
        () => MarkdownParser().parse(file.readAsStringSync()),
        returnsNormally,
        reason: file.path,
      );
    }
  });
}
