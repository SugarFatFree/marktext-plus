import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// Where a plugin says it is still working.
///
/// It said so over the whole window: a modal barrier with a spinner, which
/// stopped the reader scrolling the document the translation was of. Work has
/// a place — the pane it is filling, or a tip beside the text — and that place
/// is not on top of everything.
void main() {
  PluginPaneContent pane(String text, {bool busy = false}) => PluginPaneContent(
    pluginName: 'Demo',
    title: 'Translation',
    text: text,
    slot: PluginPaneSlot.right,
    busy: busy,
  );

  group('a pane that is still filling', () {
    test('a pane can say it is still working', () {
      expect(pane('', busy: true).busy, isTrue);
      expect(pane('done').busy, isFalse);
    });

    test('withText keeps the working state', () {
      expect(pane('a', busy: true).withText('b').busy, isTrue);
    });

    test('appending carries the newer working state', () {
      // The last block arrives with nothing left to do. If append kept the
      // state of the pane already on screen, the spinner would never stop.
      final panes = PluginPanesNotifier();
      panes.show(pane('first', busy: true));
      panes.append(pane('second'));
      final content = panes.state[PluginPaneSlot.right]!;
      expect(content.text, 'first\n\nsecond');
      expect(content.busy, isFalse, reason: 'the last block finished the run');
    });

    test('appending while more is coming stays working', () {
      final panes = PluginPanesNotifier();
      panes.show(pane('first', busy: true));
      panes.append(pane('second', busy: true));
      expect(panes.state[PluginPaneSlot.right]!.busy, isTrue);
    });

    test('a pane can be told the run ended even if nothing arrived', () {
      // A model call that throws must not leave a pane spinning forever.
      final panes = PluginPanesNotifier();
      panes.show(pane('', busy: true));
      panes.settle();
      expect(panes.state[PluginPaneSlot.right]!.busy, isFalse);
    });

    test('settling a pane does not disturb its text', () {
      final panes = PluginPanesNotifier();
      panes.show(pane('half a translation', busy: true));
      panes.settle();
      expect(panes.state[PluginPaneSlot.right]!.text, 'half a translation');
    });
  });

  group('what an action asks for', () {
    PluginPaneAction action({String? next}) => PluginPaneAction(
      text: 'a block',
      title: 'Translation',
      slot: PluginPaneSlot.right,
      render: PluginPaneRender.preview,
      append: true,
      nextPrompt: next,
    );

    test('a next step means the pane is still working', () {
      expect(
        PluginPaneContent.fromAction(action(next: 'more'), 'Demo').busy,
        isTrue,
      );
    });

    test('no next step means it is done', () {
      expect(PluginPaneContent.fromAction(action(), 'Demo').busy, isFalse);
    });

    test('everything else comes across unchanged', () {
      final content = PluginPaneContent.fromAction(action(), 'Demo');
      expect(content.pluginName, 'Demo');
      expect(content.title, 'Translation');
      expect(content.text, 'a block');
      expect(content.slot, PluginPaneSlot.right);
      expect(content.render, PluginPaneRender.preview);
    });
  });

  group('the tip beside the text', () {
    test('nothing is shown until a plugin asks', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(pluginTipProvider), isNull);
    });

    test('a tip can be working, with no answer yet', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pluginTipProvider.notifier).working('Demo');
      final tip = container.read(pluginTipProvider)!;
      expect(tip.busy, isTrue);
      expect(tip.text, isEmpty);
      expect(tip.title, 'Demo');
    });

    test('the answer replaces the waiting, in the same tip', () {
      // Not a second window over the first: the reader is watching one place.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pluginTipProvider.notifier);
      notifier.working('Demo');
      notifier.show(title: 'Demo', text: 'la traduction');
      final tip = container.read(pluginTipProvider)!;
      expect(tip.busy, isFalse);
      expect(tip.text, 'la traduction');
    });

    test('a tip can be dismissed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pluginTipProvider.notifier).working('Demo');
      container.read(pluginTipProvider.notifier).dismiss();
      expect(container.read(pluginTipProvider), isNull);
    });
  });
}
