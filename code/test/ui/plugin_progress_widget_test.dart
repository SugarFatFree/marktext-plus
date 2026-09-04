import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';
import 'package:marktext_plus/ui/widgets/plugin_panes.dart';
import 'package:marktext_plus/ui/widgets/plugin_tip.dart';

/// Where the editor says a plugin is still working, and where it does not.
void main() {
  Widget host(Widget child) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  PluginPaneContent pane(String text, {required bool busy}) =>
      PluginPaneContent(
        pluginName: 'Demo',
        title: 'Translation',
        text: text,
        slot: PluginPaneSlot.right,
        busy: busy,
      );

  group('a pane filling a block at a time', () {
    testWidgets('with nothing yet, it says so where the text will be', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(PluginPaneView(content: pane('', busy: true))),
      );
      await tester.pump();

      final progress = find.byType(CircularProgressIndicator);
      expect(
        progress,
        findsOneWidget,
        reason: 'an empty pane with no sign of work looks broken',
      );
      // Below the divider, not up in the title bar: there is nothing to read
      // yet, so nothing to keep out of the way of.
      final divider = tester.getBottomLeft(find.byType(Divider).first).dy;
      expect(tester.getCenter(progress).dy, greaterThan(divider));
    });

    testWidgets('once the first block lands, the sign moves to the title', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(PluginPaneView(content: pane('first block', busy: true))),
      );
      await tester.pump();

      expect(find.text('first block'), findsOneWidget);
      final progress = find.byType(CircularProgressIndicator);
      expect(progress, findsOneWidget);
      final divider = tester.getTopLeft(find.byType(Divider).first).dy;
      expect(
        tester.getCenter(progress).dy,
        lessThan(divider),
        reason: 'the spinner must not sit on top of what arrived',
      );
    });

    testWidgets('a finished pane shows no sign of work at all', (tester) async {
      await tester.pumpWidget(
        host(PluginPaneView(content: pane('all of it', busy: false))),
      );
      await tester.pump();

      expect(find.text('all of it'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('the tip beside the text', () {
    testWidgets('nothing is drawn over the document until a plugin asks', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const PluginTipLayer(child: Text('the document'))),
      );
      await tester.pump();

      expect(find.text('the document'), findsOneWidget);
      // Scaffold brings its own Stack, so the absence is asserted on the tip
      // itself: with nothing to say, the layer draws its child and no card.
      expect(
        find.byIcon(Icons.close),
        findsNothing,
        reason: 'no tip means nothing to close',
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a waiting tip does not block the document', (tester) async {
      late WidgetRef captured;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  captured = ref;
                  return const PluginTipLayer(child: Text('the document'));
                },
              ),
            ),
          ),
        ),
      );
      captured.read(pluginTipProvider.notifier).working('Demo');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The whole point: what this replaced was a barrier over the window.
      // MaterialApp keeps one of its own, so the claim is that showing a tip
      // adds none — and that the card is a card, not the screen.
      expect(find.byType(ModalBarrier), findsOneWidget);
      expect(find.text('the document'), findsOneWidget);
      final screen = tester.getRect(find.byType(Scaffold));
      final card = tester.getRect(find.byType(PluginTipCard));
      expect(card.width, lessThan(screen.width * 0.75));
      expect(card.height, lessThan(screen.height * 0.75));
      // Pinned to the top right of the pane. A Stack sizes itself to its
      // non-positioned children, so without being told to fill, "twelve from
      // the right" was twelve from the right of the document text — the card
      // came out beside the first line, squeezed to nothing.
      expect(screen.right - card.right, closeTo(12, 1));
      expect(card.top - screen.top, closeTo(12, 1));
      expect(
        card.width,
        greaterThan(200),
        reason: 'a card squeezed to its own padding cannot be read or hit',
      );
    });

    testWidgets('a waiting tip can be dismissed by the reader', (tester) async {
      late WidgetRef captured;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  captured = ref;
                  return const PluginTipLayer(child: Text('the document'));
                },
              ),
            ),
          ),
        ),
      );
      captured.read(pluginTipProvider.notifier).working('Demo');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'a tip the reader closed must go, working or not',
      );
      expect(captured.read(pluginTipProvider), isNull);
    });

    testWidgets('an answer can be dismissed too', (tester) async {
      late WidgetRef captured;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  captured = ref;
                  return const PluginTipLayer(child: Text('the document'));
                },
              ),
            ),
          ),
        ),
      );
      captured
          .read(pluginTipProvider.notifier)
          .show(title: 'Demo', text: 'la traduction');
      await tester.pump();

      expect(find.text('la traduction'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('la traduction'), findsNothing);
    });
  });
}
