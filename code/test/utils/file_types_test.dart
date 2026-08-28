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
    for (final ext in ['pdf', 'png', 'docx', 'json']) {
      expect(FileUtils.isMarkdownFile('/notes/file.$ext'), isFalse,
          reason: ext);
    }
  });

  test('both installers offer exactly the types the app opens', () {
    // The registry entries live in the workflows, so they cannot import this
    // list; this is what keeps them honest. Windows offering the app for a
    // type it then refuses to open is a double click that appears to do
    // nothing.
    //
    // Both workflows, not just one: this guarded ci.yml alone while
    // release.yml — the installer people actually download — had drifted to
    // three of the seven types, and nothing said so.
    for (final path in [
      '../.github/workflows/ci.yml',
      '../.github/workflows/release.yml',
    ]) {
      final workflow = File(path).readAsStringSync();
      final registered = RegExp(r'Software\\Classes\\\.(\w+)\\OpenWithProgids')
          .allMatches(workflow)
          .map((m) => m.group(1)!)
          .toSet();

      expect(registered, FileUtils.markdownExtensions.toSet(),
          reason: '$path 注册的扩展名和应用能打开的对不上');
    }
  });

  test('the Linux mime definition globs the types the app opens', () {
    // A glob the app does not accept is worse than a missing one: the file
    // manager hands the path over, the startup filter drops it, and the app
    // opens on an empty window.
    final xml =
        File('linux/packaging/marktext-plus.xml').readAsStringSync();
    final globbed = RegExp(r'<glob pattern="\*\.(\w+)"/>')
        .allMatches(xml)
        .map((m) => m.group(1)!)
        .toSet();

    // `txt` and `text` are plain text, declared through the desktop entry's
    // MimeType instead; globbing them as markdown would relabel every text
    // file on the system.
    expect(globbed,
        FileUtils.markdownExtensions.toSet().difference({'txt', 'text'}),
        reason: 'mime 声明的扩展名和应用能打开的对不上');
  });

  test('the macOS bundle declares the types the app opens', () {
    // Without this the app is never offered for a markdown file on macOS at
    // all — the one platform where the association was left undone.
    final plist = File('macos/Runner/Info.plist').readAsStringSync();
    final types = RegExp(
            r'<key>CFBundleTypeExtensions</key>\s*<array>(.*?)</array>',
            dotAll: true)
        .allMatches(plist)
        .expand((m) => RegExp(r'<string>(\w+)</string>')
            .allMatches(m.group(1)!)
            .map((e) => e.group(1)!))
        .toSet();

    expect(types, FileUtils.markdownExtensions.toSet(),
        reason: 'Info.plist 声明的扩展名和应用能打开的对不上');
  });

  test('the file channel has one name, spelled the same in three languages',
      () {
    // Dart listens on it, the GTK runner pushes a second launch's arguments
    // down it, and the macOS app delegate pushes Finder's documents down it.
    // A typo in any one of them is a double click that silently does nothing.
    const name = 'com.marktextplus/files';
    expect(File('lib/main.dart').readAsStringSync(), contains(name));
    expect(File('linux/runner/my_application.cc').readAsStringSync(),
        contains(name));
    expect(File('macos/Runner/AppDelegate.swift').readAsStringSync(),
        contains(name));
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
