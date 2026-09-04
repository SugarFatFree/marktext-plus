import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/ui/widgets/plugin_command_actions.dart';

/// What the editor tells a plugin the reader is looking at.
void main() {
  test('in split view, the half the menu was opened in wins', () {
    // The bug: this reported `split`, which answers a different question than
    // the plugin is asking. A plugin can only fall back from it — the AI
    // translate plugin falls back to preview — so translating a document from
    // the source half came back rendered, beside the source it was meant to
    // be read against.
    expect(
      PluginCommandActions.viewFor(PluginEditorView.source, EditMode.split),
      'source',
    );
    expect(
      PluginCommandActions.viewFor(PluginEditorView.preview, EditMode.split),
      'preview',
    );
  });

  test('outside split view the half still wins, and agrees anyway', () {
    expect(
      PluginCommandActions.viewFor(PluginEditorView.source, EditMode.source),
      'source',
    );
    expect(
      PluginCommandActions.viewFor(PluginEditorView.preview, EditMode.preview),
      'preview',
    );
  });

  test('with no half to report, the mode is what there is', () {
    // The menu bar and the command palette are not in either half.
    expect(PluginCommandActions.viewFor(null, EditMode.split), 'split');
    expect(PluginCommandActions.viewFor(null, EditMode.source), 'source');
    expect(PluginCommandActions.viewFor(null, EditMode.preview), 'preview');
  });

  test('the names are the ones the SDK documents', () {
    // Plugins compare against these strings; renaming the enum would change
    // what every installed plugin sees.
    expect(PluginEditorView.values.map((v) => v.name), ['source', 'preview']);
  });
}
