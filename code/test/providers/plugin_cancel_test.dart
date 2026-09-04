import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// Closing what a plugin is filling is how the reader stops it.
///
/// Two things went wrong when they did. The run went on appending blocks to a
/// pane they had closed, putting it straight back one block at a time; and the
/// run held a `WidgetRef` belonging to the widget that had just been disposed,
/// so the next read threw "Cannot use ref after the widget was disposed" —
/// including the reads in the `finally`, which always run.
void main() {
  PluginPaneContent pane(String text, {bool busy = true}) => PluginPaneContent(
    pluginName: 'Demo',
    title: 'Translation',
    text: text,
    slot: PluginPaneSlot.right,
    busy: busy,
  );

  test('a closed pane is gone, and a run can see that it is', () {
    final panes = PluginPanesNotifier();
    panes.show('tab-a', pane('first'));
    expect(panes.forTab('tab-a').containsKey(PluginPaneSlot.right), isTrue);
    panes.close('tab-a', PluginPaneSlot.right);
    expect(
      panes.forTab('tab-a').containsKey(PluginPaneSlot.right),
      isFalse,
      reason: 'the check a run makes before appending is this one',
    );
  });

  test('a dismissed tip is gone, and a run can see that it is', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pluginTipProvider.notifier).working('Demo');
    container.read(pluginTipProvider.notifier).dismiss();
    expect(container.read(pluginTipProvider), isNull);
  });

  testWidgets('a container outlives the widget that started the run', (
    tester,
  ) async {
    // What the fix rests on: the run reads through a container obtained while
    // a widget was certainly there, and that container keeps answering after
    // the widget is gone.
    late ProviderContainer container;
    var showChild = true;
    late StateSetter setter;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setter = setState;
              return showChild
                  ? Consumer(
                      builder: (context, ref, _) {
                        container = ProviderScope.containerOf(
                          context,
                          listen: false,
                        );
                        return const SizedBox();
                      },
                    )
                  : const SizedBox();
            },
          ),
        ),
      ),
    );

    setter(() => showChild = false);
    await tester.pump();

    // Would throw if this were a WidgetRef belonging to the widget above.
    container.read(pluginTipProvider.notifier).working('Demo');
    expect(container.read(pluginTipProvider)?.busy, isTrue);
    container.read(pluginPanesProvider.notifier).settle('tab-a');
  });
}
