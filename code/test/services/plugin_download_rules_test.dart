import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

/// The two rules a downloaded plugin has to satisfy.
///
/// Both were asked for together — marketplace downloads over HTTPS, verified
/// by SHA-256 — and neither was held by anything. Turning the digest
/// comparison off left all 2665 tests green, because the download talks to
/// the network and no test can reach it.
///
/// So the rules have names of their own now. The transfer is still untested;
/// what it is asked to enforce is not.
///
/// HTTPS was also only half enforced. The registry's own address is checked
/// where it is set; the address each plugin is downloaded from arrives inside
/// the registry's answer, was parsed out of JSON, and was used as given.
void main() {
  group('where a plugin may be downloaded from', () {
    test('https is allowed', () {
      PluginCatalogService.refuseInsecureDownload(
        Uri.parse('https://github.com/o/r/releases/download/v1/p.zip'),
      );
    });

    test('plain http is refused', () {
      expect(
        () => PluginCatalogService.refuseInsecureDownload(
          Uri.parse('http://github.com/o/r/releases/download/v1/p.zip'),
        ),
        throwsA(isA<FormatException>()),
        reason: '明文下载会在路上被换掉，而目录里的摘要来自同一次应答',
      );
    });

    test('a local file is refused', () {
      expect(
        () => PluginCatalogService.refuseInsecureDownload(
          Uri.parse('file:///tmp/anything.zip'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('the scheme is what decides, not the host', () {
      // `https://` on a host nobody has heard of is allowed; the rule is
      // about the transport, and the digest is what says the bytes are right.
      PluginCatalogService.refuseInsecureDownload(
        Uri.parse('https://plugins.example.invalid/p.zip'),
      );
    });
  });

  group('what the reader is told when discovery fails', () {
    test('the class name is not part of the message', () {
      // What the panel used to show: "HttpException: GitHub is rate-limiting
      // searches from this machine; try again in 385 seconds." The sentence
      // after the colon was written for the reader; the part before it was
      // written for a stack trace.
      expect(
        PluginCatalogService.describeError(
          const HttpException('GitHub is rate-limiting searches'),
        ),
        'GitHub is rate-limiting searches',
      );
      expect(
        PluginCatalogService.describeError(
          const FormatException('that release has no ZIP'),
        ),
        'that release has no ZIP',
      );
    });

    test('a network failure says what to check', () {
      final said = PluginCatalogService.describeError(
        const SocketException('Connection refused'),
      );
      expect(said, isNot(contains('SocketException')));
      expect(said, contains('proxy'),
          reason: '连不上时最可能的原因是网络或代理，直接说出来');
    });

    test('anything else is still said, rather than swallowed', () {
      expect(PluginCatalogService.describeError('a bare string'),
          'a bare string');
    });
  });

  test('the download actually applies both rules', () {
    // The blind spot the two groups above cannot see. Deleting the call from
    // `install` leaves every one of them green, and the rule becomes a
    // function nobody asks. Built-and-never-wired-up has happened seven times
    // in this repository, so the wiring is checked rather than assumed.
    final source =
        File('lib/services/plugin_catalog_service.dart').readAsStringSync();
    final install = source.substring(source.indexOf('Future<PluginManifest> install('));

    expect(install, contains('refuseInsecureDownload(downloadUrl)'),
        reason: '下载地址没有被检查过 https');
    expect(install, contains('digestMatches(bytes,'),
        reason: '下载下来的字节没有被对过摘要');
  });

  group('whether the bytes are the ones the catalog described', () {
    final bytes = utf8.encode('a plugin archive, more or less');
    final digest = sha256.convert(bytes).toString();

    test('the right digest matches', () {
      expect(PluginCatalogService.digestMatches(bytes, digest), isTrue);
    });

    test('one byte different does not', () {
      final tampered = [...bytes]..[0] ^= 1;
      expect(PluginCatalogService.digestMatches(tampered, digest), isFalse,
          reason: '改一个位就不是同一个文件了');
    });

    test('an empty expectation does not match anything', () {
      expect(PluginCatalogService.digestMatches(bytes, ''), isFalse,
          reason: '目录里没写摘要，不等于随便什么都算数');
    });

    test('the comparison is exact, including case', () {
      // Documented rather than assumed. Hex is case-insensitive by
      // definition, so this is stricter than it needs to be — and that is the
      // safe side: a case difference can only refuse a genuine file, never
      // let a tampered one through.
      expect(
        PluginCatalogService.digestMatches(bytes, digest.toUpperCase()),
        isFalse,
      );
    });
  });
}
