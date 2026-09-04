import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/plugin_provider.dart';
import '../../services/plugin_catalog_service.dart';
import '../../services/plugin_manager.dart';
import '../../services/plugin_manifest.dart';
import '../editor/markdown_renderer.dart';

class PluginDetailView extends ConsumerStatefulWidget {
  const PluginDetailView({required this.plugin, super.key});

  final PluginCatalogEntry plugin;

  @override
  ConsumerState<PluginDetailView> createState() => _PluginDetailViewState();
}

class _PluginDetailViewState extends ConsumerState<PluginDetailView> {
  bool _installing = false;
  Object? _error;

  /// Kept, so switching tabs does not fetch the README again each time.
  Future<String>? _readme;

  static String _asDate(DateTime when) =>
      '${when.year}-${when.month.toString().padLeft(2, '0')}'
      '-${when.day.toString().padLeft(2, '0')}';

  Future<void> _install() async {
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      final dir = await getApplicationSupportDirectory();
      await PluginCatalogService().install(
        widget.plugin,
        PluginManager(p.join(dir.path, 'plugins')),
      );
      // What is installed changed, so every place that says so — this page
      // and the discover list behind it — has to be asked again.
      if (mounted) ref.invalidate(installedPluginManifestsProvider);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  /// Install, update, or the fact that this is already installed.
  ///
  /// Asked of what is on disk, not of the page: a search result always has a
  /// download URL, so a page built from one could never tell that the reader
  /// had installed the plugin a moment ago.
  Widget _installButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = PluginInstallState.of(
      widget.plugin,
      ref.watch(installedPluginManifestsProvider).valueOrNull ??
          const <PluginManifest>[],
    );
    final installed = state == PluginInstallState.installed;
    return OutlinedButton.icon(
      onPressed: (_installing || installed || widget.plugin.downloadUrl == null)
          ? null
          : _install,
      icon: _installing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(switch (state) {
              PluginInstallState.installed => Icons.check,
              PluginInstallState.updatable => Icons.upgrade,
              PluginInstallState.installable => Icons.download,
            }),
      label: Text(switch (state) {
        PluginInstallState.installed => l10n.pluginInstalled,
        PluginInstallState.updatable => l10n.pluginUpdateTo(
            widget.plugin.version,
          ),
        PluginInstallState.installable => l10n.pluginInstall,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // No close button: this is a tab, and the tab bar closes it.
                // A second one on the page itself invited the reader to press
                // the wrong one and wonder why the tab was still there.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.plugin.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Which version this is, and when it was put out. The
                      // page showed neither, so there was no way to tell what
                      // the Install button would install.
                      Text(
                        [
                          widget.plugin.version,
                          if (widget.plugin.publishedAt != null)
                            _asDate(widget.plugin.publishedAt!),
                          if (widget.plugin.isPrerelease)
                            AppLocalizations.of(context)!.pluginPrerelease,
                          // Only for something that came from a search. A
                          // plugin the reader installed is not an unverified
                          // stranger to them any more.
                          if (!widget.plugin.isInstalled)
                            'Community / Unverified',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // What it does. The page had the version, the date and
                      // the README, and nothing in between that answered the
                      // question someone opening it is asking.
                      if (widget.plugin.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.plugin.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                _installButton(context),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              '$_error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'About'),
                    Tab(text: "What's new"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      if (widget.plugin.repositoryUrl == null)
                        Center(
                          child: Text(
                            'This plugin did not say where it came from.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else
                        FutureBuilder<String>(
                        future: _readme ??= PluginCatalogService()
                            .fetchReadme(widget.plugin.repositoryUrl!),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: SelectableText('${snapshot.error}'));
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return MarkdownRenderer(markdown: snapshot.data!);
                        },
                      ),
                      // Whatever the release said had changed. Empty is said
                      // out loud rather than shown as a blank page.
                      widget.plugin.releaseNotes.isEmpty
                          ? Center(
                              child: Text(
                                'This release came with no notes.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                          : MarkdownRenderer(
                              markdown: widget.plugin.releaseNotes),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.plugin.repositoryUrl != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => launchUrl(
                widget.plugin.repositoryUrl!,
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open repository'),
            ),
          ),
        ),
      ],
    );
  }
}
