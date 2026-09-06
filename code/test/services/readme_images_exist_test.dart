import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every picture the READMEs point at is still there.
///
/// The eight theme shots live under `docs/v1.1.2/`, four versions back, which
/// is exactly the kind of directory someone tidies up. They are what the
/// project's front page shows: losing them turns the top of the repository
/// into a column of broken images, and nothing in the test suite would have
/// noticed.
///
/// This checks the files exist, which is all a test can check. Whether they
/// still look like the application is for a person to say — the release
/// checklist asks that separately.
void main() {
  test('the READMEs point at pictures that exist', () {
    final root = Directory.current.parent; // tests run inside code/
    final readmes = [
      File('${root.path}/README.md'),
      ...Directory(
        '${root.path}/docs/i18n',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.md')),
    ];
    expect(
      readmes.where((f) => f.existsSync()),
      hasLength(12),
      reason: '英文 README 加 11 份翻译，数量变了就该看看这条测试',
    );

    final missing = <String>{};
    final seen = <String>{};
    for (final readme in readmes) {
      for (final match in RegExp(
        r'docs/[A-Za-z0-9._/-]+\.(?:png|gif|jpg)',
      ).allMatches(readme.readAsStringSync())) {
        final relative = match.group(0)!;
        seen.add(relative);
        if (!File('${root.path}/$relative').existsSync()) {
          missing.add('$relative（${readme.uri.pathSegments.last}）');
        }
      }
    }

    expect(seen, isNotEmpty, reason: '一张图都没找到，说明这条正则跟文档对不上了');
    expect(missing, isEmpty, reason: '首页会显示成一列裂图：$missing');
  });

  test('the READMEs link to things that exist', () {
    // Everything else they point at: other documents, directories, files.
    //
    // The plugin SDK's README was broken this way for a week — its release
    // commit rewrote all twelve documents from an older copy, putting back a
    // directory name that had changed and a tool that had been deleted, and
    // shipped. Nothing there was watching, and nothing here was watching for
    // anything but pictures. A release is exactly when those twelve files get
    // rewritten, and this project's release checklist says to update the
    // README.
    final root = Directory.current.parent;
    final readmes = [
      File('${root.path}/README.md'),
      ...Directory('${root.path}/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];

    final missing = <String>{};
    var checked = 0;
    for (final readme in readmes) {
      final from = readme.parent.path;
      for (final match in RegExp(r'\]\((?!https?:|#|mailto:)([^)]+)\)')
          .allMatches(readme.readAsStringSync())) {
        final target = match.group(1)!.split('#').first.trim();
        if (target.isEmpty) continue;
        checked++;
        final resolved = File('$from/$target').absolute.uri.normalizePath();
        final path = resolved.toFilePath();
        if (!File(path).existsSync() && !Directory(path).existsSync()) {
          missing.add('$target（${readme.uri.pathSegments.last}）');
        }
      }
    }

    expect(checked, greaterThan(10),
        reason: '只找到 $checked 个链接，说明这条正则跟文档对不上了');
    expect(missing, isEmpty, reason: '这些链接点开是 404：$missing');
  });

  test('the translations have the same shape as the English README', () {
    // Twelve copies of one document. A section added to the English one and
    // not to the other eleven is a reader in another language being told
    // less, and nothing says so — the wording differs by design, so a diff
    // is no use. The count of headings and fenced blocks is not.
    //
    // The plugin SDK shipped a release where all twelve were rewritten from
    // an older copy; a release is when these files get touched together, and
    // this project's checklist says to update the README.
    final root = Directory.current.parent;
    (int, int, int) shape(File file) {
      final text = file.readAsStringSync();
      return (
        RegExp(r'^## ', multiLine: true).allMatches(text).length,
        RegExp(r'^### ', multiLine: true).allMatches(text).length,
        '```'.allMatches(text).length ~/ 2,
      );
    }

    final english = shape(File('${root.path}/README.md'));
    expect(english.$1, greaterThan(3),
        reason: '英文 README 只数出 ${english.$1} 个二级标题，八成是没读对');

    final off = <String>[];
    for (final file in Directory('${root.path}/docs/i18n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))) {
      final theirs = shape(file);
      if (theirs != english) {
        off.add('${file.uri.pathSegments.last}: $theirs ≠ $english');
      }
    }
    expect(off, isEmpty,
        reason: '这几份翻译和英文版的结构对不上（标题数/代码块数）：$off');
  });
}
