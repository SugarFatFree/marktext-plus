import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// The list an agent is shown, and the list the editor implements.
///
/// These were two hand-written lists, and they drifted: `open_file` and
/// `run_plugin_command` sat in the schema for months with no implementation
/// anywhere, so an agent that read the schema and called one got told the
/// action was not available. The schema now generates its names from
/// [McpAction] and the handler switches on the same type, which the compiler
/// checks for exhaustiveness. These tests hold the generating end still.
void main() {
  Map<String, dynamic> controlSchema() {
    final control = const McpToolset().all.firstWhere((t) => t.name == 'control');
    return control.schema['properties'] as Map<String, dynamic>;
  }

  test('every action offered is an action the editor has a name for', () {
    final offered =
        (controlSchema()['action'] as Map<String, dynamic>)['enum'] as List;

    // Not `containsAll` in one direction only: an action missing from the
    // schema is just as wrong as one the editor cannot carry out.
    expect(
      offered,
      unorderedEquals([for (final a in McpAction.values) a.wireName]),
    );
  });

  test('the wire names are the snake_case an agent sends', () {
    expect(McpAction.setViewMode.wireName, 'set_view_mode');
    expect(McpAction.byWireName('close_pane'), McpAction.closePane);
  });

  test('a name nothing implements resolves to nothing', () {
    // `open_file` is still not implemented and so is still not offered.
    // `run_plugin_command` was in the same position until the widget layer
    // registered a handler for it, which is what it needed all along.
    expect(McpAction.byWireName('open_file'), isNull);
    expect(McpAction.byWireName('setViewMode'), isNull);
    expect(McpAction.byWireName(null), isNull);
  });

  test('running a plugin command is offered again, now that it exists', () {
    expect(McpAction.byWireName('run_plugin_command'),
        McpAction.runPluginCommand);

    final props = controlSchema();
    expect(props.keys, contains('pluginId'));
    expect(props.keys, contains('command'));
    for (final key in ['pluginId', 'command']) {
      expect(
        (props[key] as Map<String, dynamic>)['description'],
        isNotNull,
        reason: '$key 只有类型没有说明，调用方猜不出该填什么',
      );
    }
  });

  test('control takes no argument no action reads', () {
    // `path` outlived `open_file` because `new_tab` names a tab with it.
    // Anything here that nothing reads invites a caller to fill it in and
    // wait for something that will not happen.
    const read = {'action', 'path', 'tabId', 'mode', 'content', 'slot',
        'pluginId', 'command', 'panelId', 'answer'};
    expect(controlSchema().keys.toSet().difference(read), isEmpty);
  });

  test('control says what it does, and does not promise more', () {
    final control =
        const McpToolset().all.firstWhere((t) => t.name == 'control');
    // Every action the enum holds should be recognisable in that sentence,
    // and nothing else should be.
    expect(control.description, contains('view mode'));
    expect(control.description, contains('plugin command'));
    expect(control.description, isNot(contains('open a file')));
  });

  group('a refusal is a refusal in the protocol too', () {
    // The sentence was always honest — "there is no tab x" — and `isError`
    // said false beside it, which is the field a caller checks. Driving a
    // running editor showed it: every refusal came back looking like success.
    Future<Map<String, dynamic>> control(
      McpOutcome Function(String action) answer,
    ) async {
      final tools = McpToolset(
        perform: (action, arguments) async => answer(action),
      );
      return tools.call('control', {'action': 'close_pane'});
    }

    test('something the editor did is not an error', () async {
      final result = await control((_) => mcpDid('closed the right pane'));
      expect(result['isError'], isFalse);
      expect(
        (result['content'] as List).first['text'],
        'closed the right pane',
      );
    });

    test('something it would not do is', () async {
      final result = await control((_) => mcpRefused('no right pane was open'));
      expect(
        result['isError'],
        isTrue,
        reason: '编辑器没做到，协议层却报成功——调用方看的正是这个字段',
      );
      expect(
        (result['content'] as List).first['text'],
        'no right pane was open',
        reason: '句子照说，不因为是拒绝就变含糊',
      );
    });

    test('an action with no handler at all is an error', () async {
      final tools = const McpToolset();
      final result = await tools.call('control', {'action': 'new_tab'});
      expect(result['isError'], isTrue);
    });
  });

  group('running a plugin command answers the way every other action does', () {
    // Both of these were found by driving a real editor, with the suite green.
    // The handler lives in the widget layer, so nothing here had exercised the
    // path from `control` down to it.
    Future<Map<String, dynamic>> run(
      Future<McpOutcome> Function(String plugin, String command) handler,
    ) async {
      final tools = McpToolset(
        perform: (action, arguments) =>
            handler('${arguments['pluginId']}', '${arguments['command']}'),
      );
      return tools.call('control', {
        'action': 'run_plugin_command',
        'pluginId': 'com.example.p',
        'command': 'do.thing',
      });
    }

    test('a command that ran is not an error', () async {
      final result = await run((_, command) async => mcpDid('ran $command'));
      expect(result['isError'], isFalse);
      expect((result['content'] as List).first['text'], 'ran do.thing');
    });

    test('a plugin that is not installed is', () async {
      final result = await run(
        (plugin, _) async => mcpRefused('no plugin called "$plugin" is installed'),
      );
      expect(
        result['isError'],
        isTrue,
        reason: '插件不在也报成功，调用方会以为命令跑过了',
      );
    });

    test('a command the plugin has not got is, and names the ones it has',
        () async {
      final result = await run(
        (plugin, command) async => mcpRefused(
          '"$plugin" has no command "$command"; it has one.real, two.real',
        ),
      );

      expect(result['isError'], isTrue);
      final said = (result['content'] as List).first['text'] as String;
      expect(
        said,
        contains('one.real'),
        reason: '猜错命令名的调用方，最需要的是真实的那份名单',
      );
      expect(
        said,
        isNot(endsWith('it has ')),
        reason: '名单是空的——多半是查错了字段，而不是这个插件真的没有命令',
      );
    });
  });

  test('get_state says which kind of character it counts', () {
    // The editor counts two ways and calls both "characters". The status bar
    // counts code points, so an emoji is one — that is what a reader would
    // count. `get_state` reports UTF-16 units, because it is polled and
    // counting code points would walk every open document each time.
    //
    // Both are defensible and they disagree: 79 characters written over the
    // interface came back as 90. A caller comparing the two numbers is
    // entitled to know why, so the description says so.
    final state =
        const McpToolset().all.firstWhere((t) => t.name == 'get_state');

    expect(state.description, contains('UTF-16'));
    expect(
      state.description,
      contains('code point'),
      reason: '只说自己数什么还不够，要说清与状态栏的差别在哪',
    );
  });
}
