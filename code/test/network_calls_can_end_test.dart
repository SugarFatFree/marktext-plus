import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every request this editor makes has to be able to end.
///
/// BUG-404: the AI stream waited for its socket to close and nothing else, so
/// a provider that keeps the connection open after its last event left the
/// editor spinning — measured at fifteen minutes, no error, nothing logged,
/// no way for the reader to stop it. Its three siblings had the same shape:
/// `update_service` bounded its wait, and the three written after it did not,
/// because the discipline was set down in one file and never checked anywhere.
///
/// So this is the check. It compares two lists that nothing else compares:
/// the places that open a connection, and the places that bound the wait for
/// a reply. A new network call that forgets fails here rather than in front of
/// a reader.
/// `HttpClient()` where it is being constructed, and not `createHttpClient(`
/// — the proxy override names the type without opening anything.
final _opensAConnection = RegExp(r'(?<![A-Za-z])HttpClient\s*\(');

void main() {
  test('a file that opens a connection also bounds the wait', () {
    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      // Comments talk about `HttpClient()` without calling it — the proxy
      // installer explains what it is — so read the code only.
      final code = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      if (!_opensAConnection.hasMatch(code)) continue;
      final bounded =
          code.contains('answeredWithin(') || code.contains('.timeout(');
      if (!bounded) offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason: '这些文件会发起请求，却没有给「对方一直不回话」设上限：\n'
          '${offenders.join('\n')}\n'
          '用 `answeredWithin(within, "对方是谁")`（core/net/answered_within.dart）。',
    );
  });

  test('the check would notice a call that forgot', () {
    // The guard above is worth only as much as its ability to fail: a scan
    // that matched nothing at all would also report no offenders. This proves
    // it looks at code, and that the pattern it looks for is the real one.
    final seen = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => _opensAConnection.hasMatch(f.readAsStringSync()))
        .length;
    expect(seen, greaterThanOrEqualTo(4),
        reason: 'AI 对话、AI 连接测试、插件市场、插件取图，至少这四处');
  });
}
