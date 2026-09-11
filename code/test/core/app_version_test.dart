import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/constants.dart';

/// The version the app says it is.
///
/// It is written twice — `version:` in pubspec.yaml, which names the build,
/// and `AppConstants.appVersion`, which About shows and the update check
/// compares against. They drifted: the constant said 1.3.0 while the app
/// shipped 1.5.0, so About named a version that matched no release (#1), and
/// every release looked newer than 1.3.0, which meant anyone on a current
/// build was told forever that an update was waiting.
void main() {
  test('the version in About is the version that was built', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
        .firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml 里读不到版本号');

    expect(AppConstants.appVersion, match!.group(1),
        reason: 'AppConstants.appVersion 与 pubspec.yaml 对不上——'
            '「关于」会显示错的版本，更新检查也会一直提示有新版');
  });

  test('it is a plain three-part version, as the comparison assumes', () {
    // UpdateService._isNewer splits on dots and parses three integers; a
    // suffix like `1.5.1-beta` would parse as nothing and compare as zero.
    expect(RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$').hasMatch(AppConstants.appVersion),
        isTrue, reason: AppConstants.appVersion);
  });

  test('nothing else in the app writes a version out by hand', () {
    // The comment at the top of this file says `appVersion` is "what About
    // shows". It was not: About passed `applicationVersion: 'v1.0.1'`, a
    // literal, and had done through five minor releases. The guard compared
    // the two places the version is *meant* to live and never asked whether
    // the screen that shows it reads either of them.
    //
    // Then this guard repeated the mistake one level down. It was written to
    // match the shape that had broken — a quote, then the version, then a
    // quote — rather than the rule, which is that no version number is typed
    // out anywhere but the constant. `'MarkTextPlus/1.6.0'`, the user agent
    // sent to GitHub, has text in front of the number, so the quote does not
    // sit against it and the guard read straight past. It said 1.6.0 while
    // the app shipped 1.6.2, for the same reason About had said 1.0.1: two
    // places state the version and only one of them is ever updated.
    //
    // So the number is looked for anywhere inside a quoted string. What it
    // must not catch is a dotted number that is not a version: the address
    // `127.0.0.1` contains `0.0.1`, hence the refusal to match when another
    // digit or dot sits on either side.
    final offenders = <String>[];
    final version = RegExp(
      '([\'"])[^\'"\n]*?(?<![0-9.])[0-9]+\\.[0-9]+\\.[0-9]+(?![0-9.])'
      '[^\'"\n]*?\\1',
    );
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The constant itself, and the generated localisations, which carry
      // version numbers inside translated sentences.
      if (entity.path.endsWith('core/constants.dart')) continue;
      if (entity.path.contains('i18n/l10n')) continue;
      final source = entity.readAsStringSync();
      for (final line in const LineSplitter().convert(source)) {
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains('minAppVersion') || line.contains('example')) continue;
        if (version.hasMatch(line)) {
          offenders.add('${entity.path}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: '写死的版本号会在发版时被漏掉，而它就在用户看得到的地方：\n'
          '${offenders.join('\n')}',
    );
  });
}
