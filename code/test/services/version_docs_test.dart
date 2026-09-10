import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The two documents a release is checked against say the same thing twice.
///
/// `release.md` opens its "must check before releasing" list with exactly this:
/// the overview table's rows and the numbered sections below it have to cover
/// the same set. It has been a thing a person reads for, and reading forty-four
/// of these by hand found one where they had parted — v1.1.3 listed FEAT-002,
/// "single instance mode", in its table and never wrote it up.
///
/// Only the version being written now. The older directories are history, and
/// two of them would need editing rather than guarding: one lists a feature
/// nobody wrote up, the other has a placeholder row saying the release added
/// nothing.
void main() {
  final docs = Directory('../docs');

  /// The newest `vX.Y.Z` directory, which is the one being accumulated.
  Directory? current() {
    if (!docs.existsSync()) return null;
    final versions = docs
        .listSync()
        .whereType<Directory>()
        .where((d) => RegExp(r'/v\d+\.\d+\.\d+$').hasMatch(d.path))
        .toList();
    if (versions.isEmpty) return null;

    int rank(Directory d) {
      final parts = d.path.split('/v').last.split('.').map(int.parse).toList();
      return parts[0] * 1000000 + parts[1] * 1000 + parts[2];
    }

    versions.sort((a, b) => rank(a).compareTo(rank(b)));
    return versions.last;
  }

  test('there is a version directory to check', () {
    // Guards the guard: with none found, everything below passes by looping
    // over nothing.
    final dir = current();
    expect(dir, isNotNull, reason: 'docs/ 下找不到 vX.Y.Z 目录，取法要跟着改');
    expect(
      File('${dir!.path}/bugfix.md').existsSync(),
      isTrue,
      reason: '${dir.path} 缺 bugfix.md —— 版本文档规范要求两份都在',
    );
    expect(
      File('${dir.path}/PRD_需求文档.md').existsSync(),
      isTrue,
      reason: '${dir.path} 缺 PRD_需求文档.md',
    );
  });

  /// The other two documents a release is checked against.
  ///
  /// `release.md` lists nine things to check before releasing. Two of them are
  /// the tables above; two more are files that have to exist and be written —
  /// the release notes a reader gets, and the manual test somebody actually
  /// walks through, which is the whole of "未经人工测试不得发版".
  ///
  /// What this catches is a missing or empty file. What it does not catch is
  /// the failure that actually happened: `manual-test.md` was present and
  /// substantial and stopped at BUG-371, while `bugfix.md` had run on to
  /// BUG-393 — so the plan covered none of the interface changes from the day
  /// before, which are exactly the ones only a person can check. Comparing
  /// what the two cover is a reading, not a count, and it is still a reading.
  test('the release notes and the manual test are written', () {
    final dir = current();
    if (dir == null) return;

    for (final name in ['release-notes.md', 'manual-test.md']) {
      final file = File('${dir.path}/$name');
      expect(file.existsSync(), isTrue,
          reason: '${dir.path} 缺 $name —— 发布前检查的第 4 / 第 9 项');
      expect(file.readAsStringSync().trim().length, greaterThan(500),
          reason: '$name 几乎是空的，等于没写');
    }
  });

  for (final (file, prefix) in [
    ('bugfix.md', 'BUG'),
    ('PRD_需求文档.md', 'FEAT'),
  ]) {
    test('$file lists in its table exactly what it writes up', () {
      final dir = current();
      if (dir == null) return;
      final text = File('${dir.path}/$file').readAsStringSync();

      final tabled = RegExp(r'^\|\s*(' + prefix + r'-\d+)\s*\|', multiLine: true)
          .allMatches(text)
          .map((m) => m.group(1)!)
          .toSet();
      // Two heading styles are in use across the repository's history —
      // `## BUG-001 title` and `## BUG-074：title` — so this matches the
      // identifier and not what follows it.
      final written = RegExp(r'^#{2,4}\s*(' + prefix + r'-\d+)\b', multiLine: true)
          .allMatches(text)
          .map((m) => m.group(1)!)
          .toSet();

      expect(tabled, isNotEmpty, reason: '$file 的总览表格读不出条目，取法要跟着改');
      expect(
        tabled.difference(written).toList()..sort(),
        isEmpty,
        reason: '$file 的表格里有，正文里没有——发版前那份检查就是为这个',
      );
      expect(
        written.difference(tabled).toList()..sort(),
        isEmpty,
        reason: '$file 的正文里有，表格里没有——总览表格不能省',
      );
    });
  }
}
