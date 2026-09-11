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

  /// The English half is English and the two halves say the same things.
  ///
  /// Written after the Chinese sections for three changes were appended just
  /// above the `## 中文` marker instead of below it: they landed at the end of
  /// the English half, and the Chinese half never got them at all. Nothing
  /// noticed — the file existed, it was long enough, and both languages were
  /// present somewhere in it.
  ///
  /// Headings only. A Chinese section quite properly contains English
  /// identifiers, so looking for Latin letters in the Chinese half would find
  /// them everywhere; a heading in the English half that is written in Chinese
  /// is unambiguous.
  test('the release notes keep each language on its own side', () {
    final dir = current();
    if (dir == null) return;
    final text = File('${dir.path}/release-notes.md').readAsStringSync();
    const marker = '\n## 中文';
    final split = text.indexOf(marker);
    if (split < 0) return; // A version whose notes are in one language only.

    List<String> headings(String half) => RegExp(r'^### (.+)$', multiLine: true)
        .allMatches(half)
        .map((m) => m.group(1)!)
        .toList();

    final english = headings(text.substring(0, split));
    final chinese = headings(text.substring(split));
    expect(english, isNotEmpty, reason: '英文半区读不出小节，取法要跟着改');

    final cjk = RegExp(r'[一-鿿]');
    final wrongSide = english.where(cjk.hasMatch).toList();
    expect(
      wrongSide,
      isEmpty,
      reason: '这些中文小节落在了英文半区——多半是插到了「## 中文」上面：\n'
          '${wrongSide.join('\n')}',
    );

    expect(
      chinese,
      hasLength(english.length),
      reason: '两半区的小节数对不上（英文 ${english.length}，中文 ${chinese.length}）'
          '——有一半读者会少看到一条',
    );
  });

  /// The manual test has been thought about as far as the fixes go.
  ///
  /// It was written, substantial, and stopped at BUG-371 while `bugfix.md`
  /// had run on to BUG-393 — so it covered none of the previous day's
  /// interface work, which is the part only a person can check. The file was
  /// too large and too finished-looking for its own emptiness to show, and a
  /// count of its size would not have found it: it was already several times
  /// longer than a size guard would have asked for.
  ///
  /// So the plan states how far it has been thought about, and this compares
  /// that with how far the fixes go. Not every fix needs a step — most of the
  /// last few were guards and documents — but somebody has to have decided
  /// that, and moving the marker is where they decide it.
  test('the manual test says how far it has been thought through', () {
    final dir = current();
    if (dir == null) return;

    int? highest(String text) {
      final numbers = RegExp(r'BUG-(\d+)')
          .allMatches(text)
          .map((m) => int.parse(m.group(1)!));
      return numbers.isEmpty ? null : numbers.reduce((a, b) => a > b ? a : b);
    }

    final fixed = highest(File('${dir.path}/bugfix.md').readAsStringSync());
    expect(fixed, isNotNull, reason: 'bugfix.md 里读不出编号，取法要跟着改');

    final plan = File('${dir.path}/manual-test.md').readAsStringSync();
    final claimed = RegExp(r'<!--\s*人工测试已考虑到 BUG-(\d+)\s*-->')
        .firstMatch(plan);
    expect(claimed, isNotNull,
        reason: '${dir.path}/manual-test.md 没有「已考虑到 BUG-N」的标记');

    expect(
      int.parse(claimed!.group(1)!),
      fixed,
      reason: '人工测试计划考虑到的编号和 bugfix.md 的最新一条对不上——'
          '要么给新修复加一条步骤，要么想清楚它不需要，再把标记抬上去',
    );
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

      // An empty table means one of two things, and they must not be
      // confused: the extraction stopped matching (the table is there and
      // this test went blind), or the version genuinely has none of these
      // yet — a release that only fixes defects has no FEAT, and the first
      // day of any version has neither. Only the second is allowed, and only
      // when the document says so in as many words, because a parser that
      // matches nothing will never be carrying that line.
      final declaresNone = text.contains('<!-- 本版暂无 $prefix -->');
      expect(tabled.isNotEmpty || declaresNone, isTrue,
          reason: '$file 的总览表格读不出条目。真的一条都没有，就写一行 '
              '`<!-- 本版暂无 $prefix -->`；否则是取法要跟着改');
      if (declaresNone) {
        expect(written, isEmpty,
            reason: '$file 说本版暂无 $prefix，正文里却写了：$written');
      }
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
