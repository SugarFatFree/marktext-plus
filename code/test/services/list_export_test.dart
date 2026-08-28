import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A sub-list belongs inside the item it hangs off.
///
/// Every `<li>` was closed as soon as it was written, so a nested list came
/// out beside its parent rather than inside it. No list may contain another
/// list directly: browsers forgive it and it looks right on screen, but
/// validators reject it and anything that reads the structure — pasting into
/// Word, converting with pandoc — loses the level.
void main() {
  String htmlOf(String markdown) =>
      MarkdownParser().parse(markdown).map(ExportService.nodeToHtml).join();

  /// Reports the first structural fault in [html], or null when it is sound.
  String? faultIn(String html) {
    final stack = <String>[];
    for (final match in RegExp(r'</?(ul|ol|li)\b').allMatches(html)) {
      final tag = match.group(0)!;
      final name = match.group(1)!;
      if (tag.startsWith('</')) {
        if (stack.isEmpty || stack.last != name) return 'unbalanced $tag';
        stack.removeLast();
      } else {
        if (name != 'li' && stack.isNotEmpty && stack.last != 'li') {
          return '<$name> directly inside <${stack.last}>';
        }
        stack.add(name);
      }
    }
    return stack.isEmpty ? null : 'unclosed $stack';
  }

  const documents = {
    'three levels': '- one\n  - two\n    - three\n- back\n',
    'ordered inside ordered': '1. one\n   1. inner\n2. two\n',
    'bullets inside numbers': '1. one\n   - bullet\n2. two\n',
    'tasks': '- [ ] parent\n  - [x] child\n',
    'loose': '- one\n\n- two\n',
    'in and out repeatedly': '- one\n  - a\n- two\n  - b\n',
  };

  group('the exported list nests the way HTML requires', () {
    for (final entry in documents.entries) {
      test(entry.key, () {
        final html = htmlOf(entry.value);
        expect(faultIn(html), isNull, reason: html);
      });
    }

    test('the sub-list sits inside the item, not after it', () {
      // The shape that was wrong: `</li>` used to come before the `<ul>`.
      final html = htmlOf('- one\n  - two\n');
      expect(html, contains('<li>one'));
      expect(html.indexOf('<ul>', html.indexOf('one')),
          lessThan(html.indexOf('</li>', html.indexOf('one'))));
    });
  });

  group('what nesting must not have broken', () {
    test('an ordered list still starts where the author said', () {
      expect(htmlOf('3. three\n4. four\n'), contains('<ol start="3">'));
    });

    test('a bulleted sub-list under a numbered step is still bulleted', () {
      expect(htmlOf('1. one\n   - bullet\n'), contains('<ul>'));
    });

    test('a task keeps its checkbox at every level', () {
      final html = htmlOf('- [ ] parent\n  - [x] child\n');
      expect(html, contains('<input type="checkbox" disabled>'));
      expect(html, contains('<input type="checkbox" checked disabled>'));
    });

    test('a loose list still wraps its items in paragraphs', () {
      expect(htmlOf('- one\n\n- two\n'), contains('<li><p>one</p>'));
    });
  });
}
