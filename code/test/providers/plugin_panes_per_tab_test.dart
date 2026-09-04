import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// A pane belongs to the tab it was opened in.
///
/// It was one map for the whole editor, so a translation opened in one tab was
/// still on screen after switching to another — beside a document it had
/// nothing to do with. That is what made it read as a window of the
/// application rather than a part of the tab, whatever width it was drawn at.
void main() {
  PluginPaneContent content(String text, {bool busy = false}) =>
      PluginPaneContent(
        pluginName: 'AI Translate',
        title: '中文',
        text: text,
        slot: PluginPaneSlot.right,
        busy: busy,
      );

  test('a pane opened in one tab is not in another', () {
    final panes = PluginPanesNotifier();
    panes.show('tab-a', content('translation of A'));

    expect(panes.forTab('tab-a'), isNotEmpty);
    expect(panes.forTab('tab-b'), isEmpty,
        reason: '在别的标签页翻译的内容，不该跟着切过来');
  });

  test('two tabs each keep their own', () {
    final panes = PluginPanesNotifier();
    panes.show('tab-a', content('translation of A'));
    panes.show('tab-b', content('translation of B'));

    expect(panes.forTab('tab-a')[PluginPaneSlot.right]?.text,
        'translation of A');
    expect(panes.forTab('tab-b')[PluginPaneSlot.right]?.text,
        'translation of B');
  });

  test('appending adds to the tab it belongs to', () {
    final panes = PluginPanesNotifier();
    panes.show('tab-a', content('first'));
    panes.append('tab-a', content('second'));
    panes.append('tab-b', content('elsewhere'));

    expect(panes.forTab('tab-a')[PluginPaneSlot.right]?.text,
        'first\n\nsecond');
    expect(panes.forTab('tab-b')[PluginPaneSlot.right]?.text, 'elsewhere');
  });

  test('closing a pane closes it in that tab only', () {
    final panes = PluginPanesNotifier();
    panes.show('tab-a', content('A'));
    panes.show('tab-b', content('B'));
    panes.close('tab-a', PluginPaneSlot.right);

    expect(panes.forTab('tab-a'), isEmpty);
    expect(panes.forTab('tab-b'), isNotEmpty);
  });

  test('closing a tab takes its panes with it', () {
    final panes = PluginPanesNotifier();
    panes.show('tab-a', content('A'));
    panes.show('tab-b', content('B'));
    panes.retain({'tab-b'});

    expect(panes.forTab('tab-a'), isEmpty, reason: '标签页关了，它的窗格也该没了');
    expect(panes.forTab('tab-b'), isNotEmpty);
  });

  test('settling only touches the tab that was working', () {
    final panes = PluginPanesNotifier();
    panes.show('tab-a', content('half of it', busy: true));
    panes.show('tab-b', content('still going', busy: true));
    panes.settle('tab-a');

    expect(panes.forTab('tab-a')[PluginPaneSlot.right]?.busy, isFalse);
    expect(panes.forTab('tab-b')[PluginPaneSlot.right]?.busy, isTrue,
        reason: '一个标签页的运行结束，不该让另一个标签页的进度提示消失');
  });

  test('a tab nobody opened a pane in has none', () {
    expect(PluginPanesNotifier().forTab('tab-a'), isEmpty);
  });

  test('an empty tab id keeps nothing', () {
    // No document open, so nothing to put a pane beside.
    final panes = PluginPanesNotifier();
    panes.show('', content('nowhere'));
    expect(panes.forTab(''), isEmpty);
  });
}
