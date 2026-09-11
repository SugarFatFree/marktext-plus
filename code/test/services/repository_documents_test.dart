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
            !f.path.contains('node_modules') &&
            // Not the packages this project depends on. `flutter pub get`
            // symlinks them under `*/flutter/ephemeral/.plugin_symlinks`, so
            // they were being read as though they were this repository's own
            // documents — and the set of them depends on which platforms have
            // been built, which made the corpus different on every machine
            // while `greaterThan(20)` below passed either way. One of them is
            // 95% a single code sample, which is perfectly reasonable for an
            // example's README and is not a shape this project can hold
            // anybody to.
            !f.path.contains('ephemeral'))
        .toList();
  });

  test('there are documents to read', () {
    // Guard on the guard: a wrong path here would make every test below pass
    // by having nothing to look at.
    // Raised from 20 once the corpus stopped depending on what had been
    // built: there are over a hundred, so 20 would no longer notice a path
    // that had gone wrong.
    expect(documents.length, greaterThan(50));
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

  test('no code block swallowed the document it is in', () {
    // The shape a fence rule gets wrong. BUG-428 was a line reading
    // `` ``` aa ``` `` — a code span to CommonMark — opening a fence that
    // never closed, so everything after it became code; BUG-427 was four
    // columns of indentation opening one in the preview only. Neither is
    // visible in any single crafted input this suite would have thought of,
    // and both are unmistakable here: a document is prose with code in it,
    // not one code block.
    //
    // Measured over this repository's own documents, the largest single code
    // block is 28.5% of its file — `docs/v1.0.1/设计规格文档.md`. Half is
    // comfortably above that and far below a document that was eaten.
    final offenders = <String>[];
    for (final file in documents) {
      final source = file.readAsStringSync();
      if (source.length < 500) continue;
      var biggest = 0;
      for (final node in MarkdownParser().parse(source)) {
        if (node.type == NodeType.codeBlock &&
            node.rawContent.length > biggest) {
          biggest = node.rawContent.length;
        }
      }
      if (biggest * 2 > source.length) {
        offenders.add('${file.path}: '
            '${(biggest * 100 / source.length).round()}% of it is one code block');
      }
    }
    expect(offenders, isEmpty,
        reason: '某处围栏规则把文档吞掉了：\n${offenders.join('\n')}');
  });

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

  test('no changelog section is written twice in one release', () {
    // Entries appended under a fresh heading rather than into the one already
    // there: both plugin repositories had grown a second `### Fixed` inside
    // `[Unreleased]`, and one a second `### Added`. Nothing is lost, and a
    // reader looking for what was fixed finds half of it and stops.
    //
    // Per release section, not per file — the same heading under a later
    // version is exactly right. The plugin repositories are checked by
    // `sdk_schema_agrees_test`, which knows how to skip when they are absent.
    final file = File('${Directory.current.parent.path}/CHANGELOG.md');
    expect(file.existsSync(), isTrue);

    final doubled = <String>[];
    for (final section in file
        .readAsStringSync()
        .split(RegExp(r'^## ', multiLine: true))
        .skip(1)) {
      final version = section.split('\n').first.trim();
      final seen = <String>{};
      for (final match
          in RegExp(r'^### (.+)$', multiLine: true).allMatches(section)) {
        final heading = match.group(1)!.trim();
        if (!seen.add(heading)) doubled.add('$version: 「$heading」出现了两次');
      }
    }
    expect(doubled, isEmpty, reason: doubled.join('\n'));
  });
}
