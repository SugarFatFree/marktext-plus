import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// What goes out over the automation interface is written in one language.
///
/// Everything an agent is told — tool descriptions, refusals, the answers to
/// what it did — is English, with one exception nobody had compared against
/// the rest: the twenty-two reasons a setting is not settable were Chinese,
/// so a caller got "no tab to close" and "there is no tab X" in English and
/// `aiApiKey 不经过这个接口：凭据，永远不经过这个接口` in Chinese.
///
/// This is not about which language is right. The reader's own interface is
/// translated into twelve and that is the point of it; the wire is a protocol
/// with one audience, and a protocol that answers in two languages is one an
/// ordinary consumer of it cannot read half of.
///
/// Pinned across the three files the wire is written in rather than over the
/// strings themselves: their comments are English too, so anything in CJK in
/// them is either a message or a mistake.
void main() {
  final cjk = RegExp(r'[一-鿿぀-ヿ]');

  test('nothing the wire says is written in another language', () {
    final offenders = <String>[];
    for (final path in const [
      'lib/services/mcp_tools.dart',
      'lib/providers/mcp_provider.dart',
      'lib/services/mcp_server.dart',
    ]) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (cjk.hasMatch(lines[i])) offenders.add('$path:${i + 1} ${lines[i].trim()}');
      }
    }
    expect(offenders, isEmpty,
        reason: '这几行会原样发给调用方，而接口其余部分是英文');
  });

  test('every reason a setting is refused says something', () {
    // The guard above only says what language they are in. A reason that is
    // empty, or that repeats the setting's own name, tells the caller nothing
    // — and the point of a refusal here is that the caller can decide what to
    // do instead.
    expect(McpSettings.notOverTheWire, isNotEmpty);
    McpSettings.notOverTheWire.forEach((name, reason) {
      expect(reason.trim().length, greaterThan(8), reason: '$name 的理由太短');
      expect(reason, isNot(contains(name)), reason: '$name 的理由只是把名字重复了一遍');
    });
  });
}
