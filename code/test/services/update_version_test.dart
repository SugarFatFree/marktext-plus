import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/constants.dart';
import 'package:marktext_plus/services/update_service.dart';

/// Which version is newer.
///
/// This one comparison decides whether the reader is interrupted with "an
/// update is waiting", and getting it wrong is not quiet: issue #1 was this
/// measuring every release against a constant that had stopped being updated,
/// so everyone on a current build was told for weeks that there was something
/// newer. It had no test at all — it only ever ran against whatever GitHub
/// answered that day.
void main() {
  bool newer(String remote, String current) =>
      UpdateService.isNewer(remote, current);

  test('a later patch, minor or major is newer', () {
    expect(newer('1.5.4', '1.5.3'), isTrue);
    expect(newer('1.6.0', '1.5.9'), isTrue);
    expect(newer('2.0.0', '1.9.9'), isTrue);
  });

  test('the same version is not newer', () {
    expect(newer('1.5.3', '1.5.3'), isFalse);
  });

  test('an earlier version is not newer', () {
    expect(newer('1.5.2', '1.5.3'), isFalse);
    expect(newer('1.4.9', '1.5.0'), isFalse);
  });

  test('parts are compared as numbers, not as text', () {
    // The classic one. As strings, "10" sorts before "9".
    expect(newer('1.10.0', '1.9.0'), isTrue);
    expect(newer('1.9.0', '1.10.0'), isFalse);
    expect(newer('1.5.10', '1.5.9'), isTrue);
    expect(newer('1.5.9', '1.5.10'), isFalse);
  });

  test('a missing part counts as zero', () {
    expect(newer('1.5', '1.5.0'), isFalse);
    expect(newer('1.5.3', '1.5'), isTrue);
  });

  test('anything unparseable is not newer', () {
    // Better to say nothing than to interrupt with a version that means
    // nothing. Only `vX.Y.Z` tags have ever been published here, but the
    // answer comes from a network response.
    expect(newer('abc', '1.5.3'), isFalse);
    expect(newer('', '1.5.3'), isFalse);
    expect(newer('v1.5.4', '1.5.3'), isFalse,
        reason: 'tag 的 v 前缀应在调用前剥掉，这里不该自己认');
  });

  test('the version this build reports is one it can compare', () {
    // A build whose own version does not parse would compare as 0.0.0 and be
    // told every release is newer — issue #1 wearing a different hat.
    expect(newer(AppConstants.appVersion, AppConstants.appVersion), isFalse);
    expect(newer('99.0.0', AppConstants.appVersion), isTrue);
    expect(newer('0.0.1', AppConstants.appVersion), isFalse);
  });
}
