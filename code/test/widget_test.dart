import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marktext_plus/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MarkTextPlusApp()));
    expect(find.text('MarkText Plus V1.0.1'), findsOneWidget);
  });
}
