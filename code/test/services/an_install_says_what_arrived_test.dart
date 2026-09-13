import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

/// The line the log carries after a plugin is installed.
///
/// Found by using the editor rather than by reading it: a plugin was updated
/// from 0.1.4 to 0.1.5 on a real machine over the automation socket, the answer
/// said so, and `read_logs` afterwards had nothing about it at all — while the
/// same log had a line for opening a document and two for drawing a preview.
///
/// Only the sentence is tested here. `install` builds an HTTPS client and talks
/// to the network, which [PluginCatalogService.refuseInsecureDownload]'s own
/// doc comment already says cannot be tested — and weakening that rule to reach
/// a log line would be trading a security boundary for a test. The other half,
/// that the sentence is actually written, was checked on the machine the defect
/// was found on.
void main() {
  PluginCatalogEntry entryFor({required String version, bool pre = false}) =>
      PluginCatalogEntry(
        id: 'com.example.thing',
        name: 'Thing',
        version: version,
        downloadUrl: Uri.https('example.test', '/thing.zip'),
        sha256: 'abc',
        isPrerelease: pre,
      );

  test('it names the plugin, the version, and that the digest was checked', () {
    final said = PluginCatalogService.installedLine(
      entryFor(version: 'v2.0.0'),
      43008,
    );
    expect(said, contains('com.example.thing'));
    expect(said, contains('v2.0.0'), reason: '要说清到底装了哪个版本');
    expect(said, contains('42 KB'));
    expect(said, contains('digest verified'),
        reason: '校验过才装，记录里也该看得出来');
  });

  test('a pre-release says that it is one', () {
    // This project's rule is that plugins stay pre-release, so which kind
    // arrived is worth a word.
    expect(
      PluginCatalogService.installedLine(
          entryFor(version: 'v2.0.0', pre: true), 1024),
      contains('pre-release'),
    );
    expect(
      PluginCatalogService.installedLine(entryFor(version: 'v2.0.0'), 1024),
      isNot(contains('pre-release')),
    );
  });
}
