import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/editor_provider.dart';

/// Who measures where a search match is, and what it costs to ask.
///
/// The notifier used to work it out itself, by laying the whole prefix out in
/// a TextPainter: 532 ms at one megabyte, 2.3 seconds at four, on every press
/// of Find Next. It now asks the pane, which has the text laid out already.
///
/// Two things are worth pinning down here: that the registered measurement is
/// what decides the target, and that asking does not cost anything that grows
/// with the document. Whether the pane's measurement is *right* is a question
/// about a real field and lives in
/// `a_search_jump_measures_instead_of_relaying_out_test`.
void main() {
  late ScrollController scroll;

  /// A scrollable tall enough to have somewhere to go, with the notifier
  /// wired to it the way the pane wires itself.
  Future<EditorNotifier> pump(WidgetTester tester, String text) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    scroll = ScrollController();
    addTearDown(scroll.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: const SizedBox(height: 100000, width: 400),
            ),
          ),
        ),
      ),
    );

    final notifier = container.read(editorProvider.notifier);
    notifier.setEditorScrollController(scroll);
    notifier.setController(TextEditingController(text: text));
    return notifier;
  }

  testWidgets('the registered measurement decides where to go', (
    tester,
  ) async {
    final notifier = await pump(tester, 'a\nb\nc');
    final asked = <int>[];
    notifier.setOffsetLocator((offset) {
      asked.add(offset);
      return 5000;
    });

    notifier.scrollToSearchMatch(4, 14, 1.5);
    await tester.pumpAndSettle();

    expect(asked, [4], reason: 'the pane is asked about the match offset');
    // A third of the viewport above the measured position.
    final viewport = scroll.position.viewportDimension;
    expect(scroll.position.pixels, closeTo(5000 - viewport / 3, 0.5));
  });

  testWidgets('with no pane to ask, the line height is the estimate', (
    tester,
  ) async {
    // Far enough down that the estimate clears the third of a viewport
    // subtracted from it. Ten lines in, the target came to 200 pixels against
    // a 200 pixel third, so both the estimate and no estimate at all clamped
    // to zero and the assertion held either way.
    final notifier = await pump(tester, List.filled(80, 'x').join('\n'));
    notifier.scrollToSearchMatch(60, 10, 2);
    await tester.pumpAndSettle();

    final viewport = scroll.position.viewportDimension;
    final estimate = 30 * 10 * 2 - viewport / 3;
    expect(estimate, greaterThan(100), reason: 'the case has to be visible');
    expect(scroll.position.pixels, closeTo(estimate, 0.5));
  });

  testWidgets('handing the locator back only works for the one registered', (
    tester,
  ) async {
    // The pane that replaces another registers before the outgoing one is
    // disposed, so clearing has to be by identity — the same reason
    // `clearController` checks. A bound method compares equal to itself, so
    // the pane can hand back the very tear-off it registered.
    final notifier = await pump(tester, 'a\nb\nc');
    double? mine(int offset) => 5000;
    double? someoneElses(int offset) => 9000;

    notifier.setOffsetLocator(mine);
    notifier.clearOffsetLocator(someoneElses);
    notifier.scrollToSearchMatch(0, 14, 1.5);
    await tester.pumpAndSettle();
    final viewport = scroll.position.viewportDimension;
    expect(
      scroll.position.pixels,
      closeTo(5000 - viewport / 3, 0.5),
      reason: 'another pane must not be able to unregister this one',
    );

    notifier.clearOffsetLocator(mine);
    notifier.scrollToSearchMatch(0, 14, 1.5);
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, 0, reason: 'back to the estimate');
  });

  testWidgets('asking does not cost the document', (tester) async {
    // Four megabytes, the size at which the TextPainter took 2.3 seconds. The
    // bound is fifteen times smaller than that and a hundred times larger
    // than what this path actually needs, so it separates "measured through
    // the pane" from "laid the document out again" without being a timing
    // test in any tighter sense.
    final line = '${'word ' * 15}\n';
    final text = line * (4 * 1024 * 1024 ~/ line.length);
    final notifier = await pump(tester, text);
    notifier.setOffsetLocator((offset) => 5000);

    final elapsed = Stopwatch()..start();
    notifier.scrollToSearchMatch(text.length - 1, 14, 1.5);
    elapsed.stop();
    await tester.pumpAndSettle();

    expect(
      elapsed.elapsedMilliseconds,
      lessThan(150),
      reason: 'took ${elapsed.elapsedMilliseconds} ms on a four megabyte '
          'document — something is reading all of it',
    );
  });
}
