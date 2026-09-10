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

/// Asking a server for something: one of these is one wait to be bounded.
final _sendsARequest = RegExp(r'\.(?:get|post|put|delete|head|patch|open)Url\s*\(');

/// Bounding one. `.timeout(` counts because `update_service` used it before
/// there was anywhere shared to put this, and it does the same job.
final _boundsTheWait = RegExp(r'\.(?:answeredWithin|timeout)\s*\(');

void main() {
  test('every request opened is a request bounded', () {
    // Counted, not merely looked for. The first version of this guard asked
    // whether the file contained `answeredWithin` anywhere at all, and it was
    // green while six requests in two of these files had no bound: one call
    // site was enough to satisfy it and the rest rode along. A list that
    // checks off "present" cannot see the difference between one and seven.
    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final code = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      if (!_opensAConnection.hasMatch(code)) continue;

      final asked = _sendsARequest.allMatches(code).length;
      final bounded = _boundsTheWait.allMatches(code).length;
      if (bounded < asked) {
        offenders.add('${file.path}  发出 $asked 个请求，只限住 $bounded 个');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: '这些文件发起的请求多过设了上限的：\n'
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
