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
///
/// A file also counts when it imports `package:http`, which opens its own
/// client inside `IOClient` and never names the type. That omission made
/// this gate turn away the one file the comment above holds up as the
/// example that got it right: `update_service` has no `HttpClient(` in it,
/// so the guard read past it entirely, and an unbounded `http.get` added
/// beside the bounded one kept every test green.
bool _opensAConnection(String code) =>
    RegExp(r'(?<![A-Za-z])HttpClient\s*\(').hasMatch(code) ||
    _usesHttpPackage(code);

/// Asking a server for something: one of these is one wait to be bounded.
final _sendsARequest = RegExp(r'\.(?:get|post|put|delete|head|patch|open)Url\s*\(');

/// The other way this app sends one.
///
/// `dart:io` names its methods `getUrl`, so the pattern above is specific
/// enough to read the whole tree with. `package:http` names them `get`, and
/// the guard counted none of them: an unbounded `http.get` could be added to
/// `update_service.dart` and this test stayed green, because the one bound
/// already in that file covered a request count of zero. The shape the guard
/// was written for was the one that had broken, not the rule.
///
/// `.get(` on its own is far too common to look for everywhere, so it is
/// only counted inside a file that imports `package:http` — where a call by
/// that name is a request and almost nothing else. `.send(` is in the list
/// for the streamed form; outside these files it would collide with
/// `SendPort.send`.
final _sendsAnHttpPackageRequest =
    RegExp(r'\.(?:get|post|put|delete|head|patch|read|send)\s*\(');

/// Whether the file above is one of those.
bool _usesHttpPackage(String code) => code.contains("package:http/");

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
      if (!_opensAConnection(code)) continue;

      final asked = _sendsARequest.allMatches(code).length +
          (_usesHttpPackage(code)
              ? _sendsAnHttpPackageRequest.allMatches(code).length
              : 0);
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
        .where((f) => _opensAConnection(f.readAsStringSync()))
        .length;
    expect(seen, greaterThanOrEqualTo(5),
        reason: 'AI 对话、AI 连接测试、插件市场、插件取图，加上更新检查——'
            '最后一个用的是 package:http，曾经不在这个门槛里');
  });
}
