import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/ui/screens/plugin_detail_view.dart';

/// What a plugin is allowed to do, said out loud.
///
/// The editor grew a real permission check — a plugin that did not ask for
/// `document.read` stopped being handed the document — but it never told the
/// reader what any plugin had asked for. `PluginPermission.describe` had a
/// sentence ready for all seventeen of them and the only thing that ever
/// called it was a test.
///
/// That leaves the reader in the worst position: the editor is refusing things
/// on their behalf, using a list they cannot see.
void main() {
  PluginManifest manifest(List<String> permissions) => PluginManifest.fromJson({
    'id': 'com.example.demo',
    'name': 'Demo',
    'version': '1.0.0',
    'runtime': 'lua',
    'entrypoint': 'plugin.lua',
    'permissions': permissions,
  });

  Future<void> show(WidgetTester tester, PluginCatalogEntry entry) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PluginDetailView(plugin: entry)),
        ),
      ),
    );
    await tester.pump();
  }

  test('an installed entry carries what the plugin asked for', () {
    final entry = PluginCatalogEntry.installed(
      manifest(const ['document.read', 'ai.chat']),
    );

    expect(entry.permissions, [
      'document.read',
      'ai.chat',
    ], reason: '页面只能显示条目带来的东西，manifest 留在服务层');
  });

  test('a community search result does not claim to know', () {
    // The permissions live in the package, and a search result has not
    // downloaded it. An empty list is "we have not seen it", and the page
    // says nothing rather than implying the plugin asked for nothing.
    final entry = PluginCatalogEntry(
      id: 'com.example.demo',
      name: 'Demo',
      version: '1.0.0',
      downloadUrl: Uri.https('example.com', '/p.zip'),
      sha256: 'abc',
    );

    expect(entry.permissions, isEmpty);
  });

  testWidgets('the page says what each permission lets the plugin do', (
    tester,
  ) async {
    await show(
      tester,
      PluginCatalogEntry.installed(
        manifest(const ['document.read', 'document.write', 'ai.chat']),
      ),
    );

    // The sentence, not the identifier: "document.read" tells the reader
    // nothing they did not already suspect.
    expect(
      find.text('Read the open document and your selection'),
      findsOneWidget,
    );
    expect(find.text('Change the open document'), findsOneWidget);
    expect(
      find.text('Ask the AI model you configured (never sees your API key)'),
      findsOneWidget,
    );
  });

  testWidgets('a permission this version does not understand is still shown', (
    tester,
  ) async {
    // A typo in a manifest — `documents.read` — grants nothing. Silently
    // dropping the line would leave the author, and the reader, staring at a
    // plugin that does nothing with no idea why.
    await show(
      tester,
      PluginCatalogEntry.installed(manifest(const ['documents.read'])),
    );

    expect(
      find.text('Unrecognised permission — this version grants nothing for it'),
      findsOneWidget,
    );
  });

  testWidgets('a plugin that asked for nothing says so', (tester) async {
    // Not an empty heading with nothing under it: "asks for nothing" is the
    // single best thing a plugin page can say, and it should be legible.
    await show(tester, PluginCatalogEntry.installed(manifest(const [])));

    expect(find.textContaining('nothing'), findsWidgets);
  });

  testWidgets('a search result shows no permission section at all', (
    tester,
  ) async {
    await show(
      tester,
      PluginCatalogEntry(
        id: 'com.example.demo',
        name: 'Demo',
        version: '1.0.0',
        downloadUrl: Uri.https('example.com', '/p.zip'),
        sha256: 'abc',
      ),
    );

    expect(
      find.text('Permissions'),
      findsNothing,
      reason: '装之前编辑器没见过包，说不出它要什么；空着比猜错好',
    );
  });
}
