import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/widgets/plugin_web_pane.dart';

/// What the log says about where a plugin's page went.
///
/// `ui.webview` is the one permission that hands a plugin a browser, and what
/// makes that acceptable is that the reader can afterwards see where it went.
/// A promise that cannot be checked is not a permission, so this checks it.
///
/// The first build listened for `onLoadResource` alone. Windows never sends
/// that event — its native side has no such method — so on the platform most
/// readers are on the log was empty. `onLoadStart` and `onUpdateVisitedHistory`
/// are sent there, and all three now arrive here.
void main() {
  test('a host is written once, however it was reached', () {
    final trail = PluginWebTrail();

    expect(
      trail.note('AI 助手', Uri.parse('https://api.example.com/v1/chat')),
      'webview AI 助手 → https://api.example.com',
    );
    expect(
      trail.note('AI 助手', Uri.parse('https://api.example.com/v1/other')),
      isNull,
      reason: '同一个主机只记一次：一页五十张图会把日志刷成流水账',
    );
    expect(
      trail.note('AI 助手', Uri.parse('https://elsewhere.example/x')),
      'webview AI 助手 → https://elsewhere.example',
    );
  });

  test('the address itself is never written down', () {
    final trail = PluginWebTrail();
    final line = trail.note(
      'AI 助手',
      Uri.parse('https://collector.example/?doc=the+whole+document'),
    );

    expect(line, isNotNull);
    expect(line, isNot(contains('doc=')),
        reason: '查询串可以夹带整篇文档，而这行要落到磁盘上');
    expect(line, isNot(contains('whole')));
  });

  test('the page sitting still is not a journey', () {
    final trail = PluginWebTrail();
    // The pane loads the plugin's HTML as inline data, so this arrives once
    // for every pane and means the page has not gone anywhere.
    expect(trail.note('AI 助手', Uri.parse('about:blank')), isNull);
    expect(trail.note('AI 助手', Uri.parse('data:text/html,<b>hi</b>')), isNull);
    expect(trail.note('AI 助手', null), isNull);
  });

  test('reaching for the disk is worth a line, host or no host', () {
    final trail = PluginWebTrail();
    expect(
      trail.note('AI 助手', Uri.parse('file:///etc/passwd')),
      'webview AI 助手 → file://',
      reason: '没有主机不等于没去过；页面去摸磁盘正是读者要知道的',
    );
  });

  test('the pane listens for every report an engine might send', () {
    // Read from the source, which is not how a test would rather work — but
    // no engine exists under `flutter test`, so there is nothing to make send
    // these. What went wrong once was not the handling of an event; it was an
    // event nobody had subscribed to, and that much the source does show.
    //
    // Each of the three is the only one that arrives somewhere:
    //   onLoadResource        — sub-resources; not sent by Windows at all
    //   onLoadStart           — where the page goes; Windows and Linux both
    //   onUpdateVisitedHistory — where it goes without reloading; both
    final source =
        File('lib/ui/widgets/plugin_web_pane.dart').readAsStringSync();
    for (final report in const [
      'onLoadResource:',
      'onLoadStart:',
      'onUpdateVisitedHistory:',
    ]) {
      final at = source.indexOf(report);
      expect(at, isNot(-1),
          reason: '少接一个回调，就有平台记不到 webview 去了哪；'
              '$report 是其中一个平台唯一的来源');
      // Subscribed *and* leading somewhere. Asking only whether the name
      // appears would stay green with all three wired to nothing, which is
      // the same silence in a different place.
      expect(
        source.substring(at, at + 80),
        contains('_note('),
        reason: '$report 接上了，但没有把地址交给记录的那一处',
      );
    }
  });
}