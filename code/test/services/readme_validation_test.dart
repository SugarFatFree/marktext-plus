import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

void main() {
  test('all README translations parse and export', () async {
    final repository = Directory.current.parent;
    final files = <File>[
      File('${repository.path}/README.md'),
      ...Directory('${repository.path}/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((file) =>
              file.path.contains('README_') && file.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path)),
    ];
    expect(files, hasLength(12));

    final output = await Directory.systemTemp.createTemp('readme_validation_');
    addTearDown(() => output.delete(recursive: true));
    for (final file in files) {
      final markdown = file.readAsStringSync();
      final nodes = MarkdownParser(enableHtml: true).parse(markdown);
      expect(nodes, isNotEmpty, reason: file.path);
      expect(markdown, isNot(contains('�')), reason: file.path);
      final comparison = markdown.indexOf('\n## ⚖️');
      expect(comparison, greaterThan(0), reason: file.path);
      final featureSection = markdown.substring(0, comparison);
      expect(
        RegExp(r'^### .+', multiLine: true).allMatches(featureSection),
        hasLength(4),
        reason: file.path,
      );
      expect(markdown, contains('MarkText Plus'), reason: file.path);

      final htmlPath = '${output.path}/${file.uri.pathSegments.last}.html';
      await ExportService.exportToHtml(markdown, htmlPath);
      expect(File(htmlPath).readAsStringSync(), isNotEmpty, reason: file.path);
    }
  });
}
