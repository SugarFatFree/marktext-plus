import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/app.dart';
import 'package:marktext_plus/core/constants.dart';
import 'package:marktext_plus/ui/widgets/app_menu_bar.dart';

/// About says which version this is.
///
/// It said `v1.0.1` while the app shipped 1.6.1 — five minor releases, in the
/// one dialog a reader opens to find out what they are running. The guard next
/// to `AppConstants.appVersion` compares it against pubspec.yaml and its own
/// comment calls the constant "what About shows"; nothing ever checked that
/// claim, and it was false.
///
/// `app_version_test` now refuses a version literal anywhere in `lib`. This
/// opens the dialog instead, because a scan cannot see the box quietly
/// showing some other field, or nothing at all.
void main() {
  testWidgets('the About box names the version that was built', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        // The same key the dialog reaches for at runtime.
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: AppMenuBar.showAbout,
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text('v${AppConstants.appVersion}'),
      findsOneWidget,
      reason: '「关于」没有显示这次构建的版本',
    );
    expect(find.text('MarkText Plus'), findsWidgets);
  });
}
