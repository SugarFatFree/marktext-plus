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
}
