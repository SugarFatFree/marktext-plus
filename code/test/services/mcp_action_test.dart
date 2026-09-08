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
    // The two that used to be advertised, and the shape of a typo.
    expect(McpAction.byWireName('open_file'), isNull);
    expect(McpAction.byWireName('run_plugin_command'), isNull);
    expect(McpAction.byWireName('setViewMode'), isNull);
    expect(McpAction.byWireName(null), isNull);
  });

  test('control no longer takes arguments only the removed actions read', () {
    // `pluginId` and `command` existed for `run_plugin_command`. Leaving them
    // in the schema would invite an agent to fill them in and wait.
    expect(controlSchema().keys, isNot(contains('pluginId')));
    expect(controlSchema().keys, isNot(contains('command')));
  });

  test('control says what it does, and does not promise more', () {
    final control = const McpToolset().all.firstWhere((t) => t.name == 'control');
    expect(control.description, isNot(contains('plugin command')));
    expect(control.description, contains('view mode'));
  });
}
