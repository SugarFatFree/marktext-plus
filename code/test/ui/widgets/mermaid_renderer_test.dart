import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/widgets/mermaid_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MermaidRenderer', () {
    testWidgets('shows copy source button', (tester) async {
      const mermaidCode = '''graph TD
  A[Start] --> B[End]
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MermaidRenderer(
              code: mermaidCode,
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
      expect(find.text('复制源码'), findsOneWidget);
    });

    testWidgets('copies mermaid source when button tapped', (tester) async {
      const mermaidCode = '''graph TD
  A[Start] --> B[End]
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MermaidRenderer(
              code: mermaidCode,
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('复制源码'));
      await tester.pump();

      final clipboardData = await Clipboard.getData('text/plain');
      expect(clipboardData?.text, mermaidCode);
    });
  });
}
