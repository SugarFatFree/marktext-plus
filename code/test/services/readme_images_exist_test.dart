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
}
