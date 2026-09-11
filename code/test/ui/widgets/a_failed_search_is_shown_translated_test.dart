import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';
import 'package:marktext_plus/ui/widgets/plugin_panel.dart';

/// The panel puts the failure on screen in the reader's language.
///
/// `a_failed_search_speaks_the_readers_language_test` covers the kinds; this
/// covers the call site, which is the half that can quietly come undone. A
/// panel changed back to printing `failure.describe()` compiles, passes every
/// other test in this suite, and shows English to a reader who has chosen
/// Chinese — which is exactly the state this work started from.
void main() {
  testWidgets('a search that could not reach GitHub says so in Chinese',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pluginDiscoveryProvider.notifier).failed(
          const PluginCatalogFailure(PluginCatalogFailureKind.unreachable),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(width: 900, height: 1400, child: PluginPanel()),
          ),
        ),
      ),
    );
    await tester.pump();

    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(find.text(zh.pluginCatalogUnreachable), findsOneWidget);
    // And not the English the service builds for the automation interface.
    expect(find.textContaining('could not reach GitHub'), findsNothing);
  });

  testWidgets('and rate limiting reaches the screen with its seconds',
      (tester) async {
    // The seconds are the only part a reader can act on. They are worked out
    // from a response header, so if the mapping loses them the reader is told
    // to wait without being told how long.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pluginDiscoveryProvider.notifier).failed(
          const PluginCatalogFailure(
            PluginCatalogFailureKind.rateLimited,
            retryAfter: 47,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(width: 900, height: 1400, child: PluginPanel()),
          ),
        ),
      ),
    );
    await tester.pump();

    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(find.text(zh.pluginCatalogRateLimitedIn(47)), findsOneWidget);
  });
}
