import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/self_update_service.dart';

/// A silent install has to start the editor again.
///
/// Measured on the reader's machine on 2026-09-14: the editor updated itself,
/// the installer ran to completion — "Deinitializing Setup. Log closed." with
/// no error — the binary really was replaced, and **nothing came back**. The
/// editor had promised "this editor will close and come back".
///
/// Two things have to hold together for that promise to be true, and they are
/// written in two different files by two different kinds of author:
///
/// * the update runs the installer silently, because nobody is there to click
///   anything — `/VERYSILENT`, in `SelfUpdateService.installerArguments`;
/// * the installer's `[Run]` entry, the one thing that starts the editor again,
///   must not carry `skipifsilent`, which means exactly "do not run this when
///   Setup is silent".
///
/// It did carry it, in both workflows. `/RESTARTAPPLICATIONS` was supposed to
/// cover the gap through the Restart Manager and did not.
///
/// This is the reconciliation, because neither half is wrong on its own.
void main() {
  /// The workflow files, from `code/` where the tests run.
  final workflows = {
    'ci.yml': File('../.github/workflows/ci.yml'),
    'release.yml': File('../.github/workflows/release.yml'),
  };

  /// Skipped rather than failed when they are not there: a checkout of `code/`
  /// alone is a thing people do, and a guard that always fails there teaches
  /// people to ignore it.
  bool present() => workflows.values.every((f) => f.existsSync());

  test('the update still runs the installer silently', () {
    // The other half of the pair. If this ever stops being silent the flag
    // below becomes harmless again — and this test is where that is noticed.
    expect(
      SelfUpdateService.installerArguments(r'D:\somewhere'),
      contains('/VERYSILENT'),
      reason: '不再静默安装的话，下面那条对 skipifsilent 的要求就该重新想一遍',
    );
  });

  test('every installer launches the editor when it is done', () {
    if (!present()) return;
    final missing = <String>[];
    for (final entry in workflows.entries) {
      final text = entry.value.readAsStringSync();
      final runs = RegExp(r'Filename: "\{app\}\\marktext_plus\.exe";[^\n]*')
          .allMatches(text)
          .map((m) => m.group(0)!)
          .where((line) => line.contains('postinstall'))
          .toList();
      if (runs.length != 1) {
        missing.add('${entry.key}: 找到 ${runs.length} 条启动指令，取法要跟着改');
        continue;
      }
      if (runs.single.contains('skipifsilent')) {
        missing.add('${entry.key}: 启动指令带着 skipifsilent');
      }
    }
    expect(
      missing,
      isEmpty,
      reason: '自更新是用 /VERYSILENT 跑安装程序的，而 skipifsilent 的意思正是'
          '「静默时不要执行这一条」——带上它，编辑器装完就不会再起来：\n'
          '${missing.join('\n')}',
    );
  });

  test('the editor only promises to come back where it can', () {
    // The sentence the update answers with. It is true only because of the
    // entry above; if that entry goes, this sentence becomes the editor saying
    // something that is not so — which is the fault this project finds most
    // often.
    final source =
        File('lib/services/self_update_service.dart').readAsStringSync();
    expect(source, contains('this editor will close and come back'),
        reason: '这句承诺的措辞变了，守卫要跟着改');
  });
}
