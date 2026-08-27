import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('export_image_test');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  /// Smallest valid PNG: a single transparent pixel.
  final onePixelPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  test('a relative image becomes a data URI', () async {
    File('${temp.path}/pic.png').writeAsBytesSync(onePixelPng);
    final docPath = '${temp.path}/note.md';
    final outPath = '${temp.path}/out.html';

    await ExportService.exportToHtml(
      '![a picture](pic.png)\n',
      outPath,
      sourcePath: docPath,
    );

    final html = File(outPath).readAsStringSync();
    // Exported HTML gets moved around, where a relative path no longer
    // resolves and the image breaks.
    expect(html, contains('src="data:image/png;base64,'));
    expect(html, isNot(contains('src="pic.png"')));
    expect(html, contains('alt="a picture"'));
  });

  test('a remote image is left as a URL', () async {
    final outPath = '${temp.path}/out.html';

    await ExportService.exportToHtml(
      '![remote](https://example.com/pic.png)\n',
      outPath,
      sourcePath: '${temp.path}/note.md',
    );

    expect(
      File(outPath).readAsStringSync(),
      contains('src="https://example.com/pic.png"'),
    );
  });

  test('a missing file stays a path rather than failing the export', () async {
    final outPath = '${temp.path}/out.html';

    await ExportService.exportToHtml(
      '![gone](nowhere.png)\n',
      outPath,
      sourcePath: '${temp.path}/note.md',
    );

    expect(File(outPath).readAsStringSync(), contains('src="nowhere.png"'));
  });

  test('without a source path local images are left alone', () async {
    File('${temp.path}/pic.png').writeAsBytesSync(onePixelPng);
    final outPath = '${temp.path}/out.html';

    await ExportService.exportToHtml('![a](pic.png)\n', outPath);

    expect(File(outPath).readAsStringSync(), contains('src="pic.png"'));
  });
}
