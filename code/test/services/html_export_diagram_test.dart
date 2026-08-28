import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Diagrams in an exported HTML file.
///
/// The export used to write the diagram's source into a `<pre class="mermaid">`
/// and leave a script from jsdelivr to draw it in the reader's browser. Offline
/// — or on a network that does not reach that CDN, which is most company
/// networks — every diagram in the file was blank. The PDF and Word exports had
/// always carried the drawn picture; only HTML did not.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('html_export_'));
  tearDown(() => root.deleteSync(recursive: true));

  /// A one-pixel PNG, which is all this needs: what matters is where the bytes
  /// end up, not what they draw.
  final png = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='));

  Future<String> export(String markdown,
      {Map<String, Uint8List>? images}) async {
    final path = '${root.path}/out.html';
    await ExportService.exportToHtml(markdown, path, mermaidImages: images);
    return File(path).readAsStringSync();
  }

  const oneDiagram = '# T\n\n```mermaid\nflowchart TD\n  A --> B\n```\n';

  /// The key a drawn diagram is stored under: the diagram itself.
  ///
  /// It used to be its position among the blocks, which held only while the
  /// side that drew the pictures and the side that placed them counted the
  /// same things. Both counted only the top level, so a diagram written under
  /// a numbered step reached the file with no picture at all.
  const drawn = 'flowchart TD\n  A --> B';

  test('a drawn diagram is carried inside the file', () async {
    final html = await export(oneDiagram, images: {drawn: png});

    expect(html, contains('data:image/png;base64,'));
    expect(html, isNot(contains('<pre class="mermaid">')));
  });

  test('with every diagram drawn, nothing is fetched to draw them', () async {
    final html = await export(oneDiagram, images: {drawn: png});

    expect(html, isNot(contains('mermaid.min.js')),
        reason: '所有图都内嵌了，还去取脚本就是白连一次网');
    expect(html, isNot(contains('mermaid.initialize')));
  });

  test('a diagram that could not be drawn keeps the old behaviour', () async {
    // Better a live attempt than an empty space.
    final html = await export(oneDiagram);

    expect(html, contains('<pre class="mermaid">'));
    expect(html, contains('mermaid.min.js'));
  });

  test('a failed diagram leaves the others alone', () async {
    const three =
        '```mermaid\nA\n```\n\n```mermaid\nB\n```\n\n```mermaid\nC\n```\n';
    final other = Uint8List.fromList([...png]);

    final html = await export(three, images: {'A': png, 'C': other});

    // Two embedded, one left to the script — and the script is still there
    // because one diagram needs it.
    expect('data:image/png;base64,'.allMatches(html).length, 2);
    expect('<pre class="mermaid">'.allMatches(html).length, 1);
    expect(html, contains('mermaid.min.js'));
  });

  test('a diagram under a numbered step gets its picture too', () async {
    // It is a block the step carries rather than a block of its own, so the
    // walk that finds diagrams has to go inside the list. Counting top-level
    // blocks missed it, and the export drew nothing where the diagram was.
    const inStep = '1. step\n\n   ```mermaid\n   A\n   ```\n';

    final html = await export(inStep, images: {'A': png});

    expect(html, contains('data:image/png;base64,'));
    expect(html, isNot(contains('<pre class="mermaid">')));
    expect(html, isNot(contains('mermaid.min.js')),
        reason: '这张图已经内嵌，不该再去取脚本');
  });

  test('a diagram inside a quote gets its picture too', () async {
    const inQuote = '> ```mermaid\n> A\n> ```\n';

    final html = await export(inQuote, images: {'A': png});

    expect(html, contains('data:image/png;base64,'));
  });

  test('a document with no diagrams asks for no diagram script', () async {
    final html = await export('# just text\n\nhello\n');

    expect(html, isNot(contains('mermaid.min.js')));
  });
}
