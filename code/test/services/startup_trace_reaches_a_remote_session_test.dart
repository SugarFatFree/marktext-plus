import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/startup_trace.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// The breakdown of a slow launch reaches a session that is not at the machine.
///
/// Only the milestones go to the application log, deliberately: forty `mark`
/// lines would push a plugin's output off the end of it. The breakdown goes to
/// `startup-trace.log`, and the comment above it says that file is the only
/// way to get the numbers back — true of a person sitting at the machine, and
/// false of a session driving the editor over MCP, which saw
/// "+901 ms before Dart" and had no way to ask where those milliseconds went.
/// Loading the executable, booting the engine and reading the snapshot are
/// three different problems.
void main() {
  test('the toolset offers it, and says when to reach for it', () {
    final tool = const McpToolset()
        .all
        .where((t) => t.name == 'read_startup_trace')
        .firstOrNull;
    expect(tool, isNotNull, reason: 'MCP 没有这个工具，远程会话就读不到明细');
    expect(tool!.description, contains('before Dart'),
        reason: '不说它能回答什么，调用方不会在启动慢的时候想到它');
  });

  test('it answers with the trace', () async {
    const toolset = McpToolset(startupTrace: _aTrace);
    final tool =
        toolset.all.firstWhere((t) => t.name == 'read_startup_trace');
    final answer = await tool.run(<String, dynamic>{});
    expect(answer.parts.single['text'], contains('engine start'));
    expect(answer.isError, isFalse);
  });

  test('no trace is a sentence, not an empty answer', () async {
    // An empty string reads as "the request failed" and sends whoever is
    // debugging a slow launch looking at the wrong thing.
    const toolset = McpToolset(startupTrace: _nothing);
    final tool =
        toolset.all.firstWhere((t) => t.name == 'read_startup_trace');
    final answer = await tool.run(<String, dynamic>{});
    expect(answer.parts.single['text'] as String, isNotEmpty);
    expect(answer.parts.single['text'], contains('no startup trace'));
  });

  test('what is in memory answers when nothing has reached disk', () {
    // The directory is resolved part way through startup, so the earliest and
    // most interesting marks exist before there is anywhere to write them.
    StartupTrace.mark('a step that happened');
    final text = StartupTrace.readBack();
    expect(text, contains('a step that happened'));
    expect(text, contains('not written to disk yet'),
        reason: '要说清楚这份是内存里的，不是文件里的');
  });

  test('a trace longer than the cap comes back from the end', () async {
    // The end is this launch; the beginning is a launch four ago.
    final directory = Directory.systemTemp.createTempSync('trace_');
    addTearDown(() => directory.deleteSync(recursive: true));
    File('${directory.path}${Platform.pathSeparator}startup-trace.log')
        .writeAsStringSync('${'x' * 3000}THE-END');
    StartupTrace.useDirectory(directory.path);

    final text = StartupTrace.readBack(atMost: 500);
    expect(text, contains('THE-END'));
    expect(text, contains('are not shown'));
    expect(text.length, lessThan(1000));
  });
}

String _aTrace() => '''
=== MarkText Plus startup trace ===
   190 ms  (+  190 ms)  process created → runner entry
   901 ms  (+  711 ms)  engine start → first Dart mark
''';

String _nothing() => '';
