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
      panes.show('tab-a', pane('first', busy: true));
      panes.append('tab-a', pane('second'));
      final content = panes.forTab('tab-a')[PluginPaneSlot.right]!;
      expect(content.text, 'first\n\nsecond');
      expect(content.busy, isFalse, reason: 'the last block finished the run');
    });

    test('appending while more is coming stays working', () {
      final panes = PluginPanesNotifier();
      panes.show('tab-a', pane('first', busy: true));
      panes.append('tab-a', pane('second', busy: true));
      expect(panes.forTab('tab-a')[PluginPaneSlot.right]!.busy, isTrue);
    });

    test('a pane can be told the run ended even if nothing arrived', () {
      // A model call that throws must not leave a pane spinning forever.
      final panes = PluginPanesNotifier();
      panes.show('tab-a', pane('', busy: true));
      panes.settle('tab-a');
      expect(panes.forTab('tab-a')[PluginPaneSlot.right]!.busy, isFalse);
    });

    test('settling a pane does not disturb its text', () {
      final panes = PluginPanesNotifier();
      panes.show('tab-a', pane('half a translation', busy: true));
      panes.settle('tab-a');
      expect(panes.forTab('tab-a')[PluginPaneSlot.right]!.text, 'half a translation');
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

  group('asking in the card the answer appears in', () {
    test('a question is a tip, not a window of its own', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pluginTipProvider.notifier).ask(
        title: 'Demo',
        question: 'Target language',
        choices: const ['English', '中文'],
      );
      final tip = container.read(pluginTipProvider)!;
      expect(tip.asking, isTrue);
      expect(tip.question, 'Target language');
      expect(tip.choices, ['English', '中文']);
      expect(tip.busy, isFalse, reason: '在等读者，不是在等模型');
    });

    test('answering completes the run that was waiting', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final asked = container.read(pluginTipProvider.notifier).ask(
        title: 'Demo',
        question: 'Target language',
        choices: const [],
      );
      container.read(pluginTipProvider.notifier).answerWith('中文');
      expect(await asked.future, '中文');
      expect(container.read(pluginTipProvider), isNull,
          reason: '答完了就该收起来');
    });

    test('closing the card declines, rather than hanging the run', () async {
      // A run awaiting a future nobody completes is a plugin that never
      // finishes and a service that is never disposed.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final asked = container.read(pluginTipProvider.notifier).ask(
        title: 'Demo',
        question: 'Target language',
        choices: const [],
      );
      container.read(pluginTipProvider.notifier).dismiss();
      expect(await asked.future, isNull);
    });

    test('a question is not mistaken for work in progress', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pluginTipProvider.notifier).ask(
        title: 'Demo',
        question: 'Target language',
        choices: const [],
      );
      // dismissIfWaiting takes down a tip that is waiting on the model. A
      // question is waiting on the reader, and taking it down would answer it
      // for them.
      container.read(pluginTipProvider.notifier).dismissIfWaiting();
      expect(container.read(pluginTipProvider)?.asking, isTrue);
    });
  });

  group('the question remembers last time', () {
    test('the answer a plugin remembered is the one already filled in', () {
      // The plugin keeps the reader's last choice; offering it as one chip
      // among many still asks them to pick it again every single time.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pluginTipProvider.notifier).ask(
        title: 'Demo',
        question: 'Target language',
        choices: const ['English', '中文', '日本語'],
        answer: '中文',
      );
      expect(container.read(pluginTipProvider)!.suggested, '中文');
    });

    test('with nothing remembered, nothing is filled in', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pluginTipProvider.notifier).ask(
        title: 'Demo',
        question: 'Target language',
        choices: const ['English'],
      );
      expect(container.read(pluginTipProvider)!.suggested, isEmpty);
    });
  });
}
