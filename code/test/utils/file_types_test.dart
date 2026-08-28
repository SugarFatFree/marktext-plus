import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/utils/file_utils.dart';

/// The file types this editor opens.
///
/// There were six copies of this list — the startup argument filter, the
/// sidebar's search, `FileNode.isMarkdown`, and three file pickers — plus a
/// seventh in the installer's registry entries. They agreed by luck. Adding a
/// type meant editing seven places, and whichever was missed failed in its own
/// way: a file that opens but cannot be searched, one the picker will not
/// show, or one Windows offers this app for and the app then ignores.
void main() {
  test('the dotted list is derived from the plain one, not written twice', () {
    expect(FileUtils.markdownExtensionsWithDot,
        FileUtils.markdownExtensions.map((e) => '.$e').toList());
    expect(FileUtils.markdownExtensionsWithDot.every((e) => e.startsWith('.')),
        isTrue);
    expect(FileUtils.markdownExtensionsWithDot.toSet(),
        hasLength(FileUtils.markdownExtensions.length),
        reason: '有重复项，多半是插值写成了字面量');
  });

  test('isMarkdownFile accepts every listed type and rejects others', () {
    for (final ext in FileUtils.markdownExtensions) {
      expect(FileUtils.isMarkdownFile('/notes/file.$ext'), isTrue, reason: ext);
      expect(FileUtils.isMarkdownFile('/notes/FILE.${ext.toUpperCase()}'),
          isTrue,
          reason: '$ext 大写形式');
    }
    for (final ext in ['pdf', 'png', 'docx', 'mdx']) {
      expect(FileUtils.isMarkdownFile('/notes/file.$ext'), isFalse,
          reason: ext);
    }
  });

  test('the installer offers exactly the types the app opens', () {
    // The registry entries live in the workflow, so they cannot import this
    // list; this is what keeps the two honest. Windows offering the app for a
    // type it then refuses to open is a double click that appears to do
    // nothing.
    final workflow = File('../.github/workflows/ci.yml').readAsStringSync();
    final registered = RegExp(r'Software\\Classes\\\.(\w+)\\OpenWithProgids')
        .allMatches(workflow)
        .map((m) => m.group(1)!)
        .toSet();

    expect(registered, FileUtils.markdownExtensions.toSet(),
        reason: '安装包注册的扩展名和应用能打开的对不上');
  });

  test('the installer replaces the executable rather than keeping the old one',
      () {
    // Without ignoreversion, Inno compares version resources and keeps the
    // installed .exe when the versions match — and this app's version resource
    // never changes. Three rounds of native fixes were installed and never ran
    // because of it.
    final workflow = File('../.github/workflows/ci.yml').readAsStringSync();
    final filesLine = workflow
        .split('\n')
        .firstWhere((line) => line.contains('DestDir: "{app}"'));

    expect(filesLine, contains('ignoreversion'));
  });

  test('every CI build stamps a different version onto the executable', () {
    // Inno compares version resources when deciding whether to replace a file.
    // With every build stamped 1.4.0.1 it kept the installed runner, and only
    // the Dart snapshot was ever updated — three rounds of native fixes were
    // installed and never ran. `ignoreversion` fixes that outright; the build
    // number removes the reason it happened.
    final workflow = File('../.github/workflows/ci.yml').readAsStringSync();

    expect(workflow, contains('--build-number='),
        reason: '每次构建版本号相同，正是安装包跳过覆盖的成因');
    expect(workflow, isNot(contains('AppVersion=0.0.0')),
        reason: '安装包对每个版本都显示 0.0.0');
  });
}
