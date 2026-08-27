import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/ui/widgets/mermaid_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MermaidRenderer', () {
    testWidgets('shows copy source button', (tester) async {
      const mermaidCode = '''graph TD
  A[Start] --> B[End]
''';

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: MermaidRenderer(
              code: mermaidCode,
              isDarkMode: false,
            ),
          ),
        ),
      );

      // Not pumpAndSettle(): MermaidDiagram starts in a loading state that
      // renders an indeterminate CircularProgressIndicator, whose animation
      // never stops. The toolbar under test renders on the first frame.
      await tester.pump();

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
      expect(find.byKey(const Key('mermaid-copy-source')), findsOneWidget);
    });

    testWidgets('copies mermaid source when button tapped', (tester) async {
      const mermaidCode = '''graph TD
  A[Start] --> B[End]
''';

      // Reading the clipboard back with Clipboard.getData deadlocks here: the
      // platform channel round trip needs the event loop to turn, and the test
      // body is awaiting it with nothing left to pump. Assert on the write
      // instead.
      MethodCall? clipboardCall;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') clipboardCall = call;
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: MermaidRenderer(
              code: mermaidCode,
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byKey(const Key('mermaid-copy-source')));
      await tester.pump();

      expect(clipboardCall, isNotNull, reason: 'no clipboard write happened');
      expect(clipboardCall!.arguments['text'], mermaidCode);
    });
  });
}
