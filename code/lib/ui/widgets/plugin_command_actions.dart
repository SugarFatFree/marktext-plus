import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/plugin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ai_chat_service.dart';
import '../../services/plugin_command_service.dart';
import '../../services/plugin_manifest.dart';
import '../../services/plugin_script_runtime.dart';

/// Puts the commands installed plugins contribute into a right-click menu, and
/// carries out what those commands ask for.
///
/// Both panes call this. The source pane had the translate command and the
/// preview did not, so whether the reader saw it depended on which half of a
/// split view they had clicked in.
class PluginCommandActions {
  const PluginCommandActions._();

  /// Where in the editor a menu entry belongs. A plugin says this in its
  /// manifest; the host decides what that location actually looks like.
  static const editorContextMenu = 'editor.contextMenu';

  /// The entries for [location], in the reader's language.
  static List<ContextMenuButtonItem> menuItems({
    required BuildContext context,
    required WidgetRef ref,
    required String location,
    required String Function() selection,
    required String Function() document,
  }) {
    // What the installed plugins contribute is settled before anything is
    // read off the context: with no plugin contributing here there is nothing
    // to draw, and a pane that has no localisations — which is every editor
    // widget test — must not be made to fail looking them up.
    final contributions = [
      for (final plugin
          in ref.read(installedPluginManifestsProvider).valueOrNull ??
              const <PluginManifest>[])
        if (plugin.runtime == PluginRuntime.lua ||
            plugin.runtime == PluginRuntime.js)
          for (final menu in plugin.menus)
            if (menu.location == location) (plugin, menu),
    ];
    if (contributions.isEmpty) return const [];

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const [];
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final locale = Localizations.localeOf(context).toString();

    final items = <ContextMenuButtonItem>[];
    {
      for (final (plugin, menu) in contributions) {
        final strings = plugin.stringsFor(locale);
        items.add(
          ContextMenuButtonItem(
            // A plugin's own translation of its own label wins over the
            // English fallback it declared in the manifest.
            label: strings[menu.title] ?? menu.title,
            onPressed: () => _run(
              navigator: navigator,
              messenger: messenger,
              ref: ref,
              l10n: l10n,
              locale: locale,
              plugin: plugin,
              command: menu.id,
              selection: selection(),
              document: document(),
            ),
          ),
        );
      }
    }
    return items;
  }

  /// Drives one command to its end.
  ///
  /// The script is synchronous, so it hands back one action at a time and this
  /// performs it: ask the reader, call the model, show the result. The plugin
  /// keeps the prompt and the flow; the editor keeps the credentials.
  static Future<void> _run({
    required NavigatorState navigator,
    required ScaffoldMessengerState messenger,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required String locale,
    required PluginManifest plugin,
    required String command,
    required String selection,
    required String document,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final service = PluginCommandService(
      p.join(directory.path, 'plugins'),
      locale: locale,
    );

    var context = PluginScriptContext(
      command: command,
      selection: selection,
      document: document,
    );

    try {
      var action = service.start(plugin, context);

      // Bounded: a plugin that answers every question with another question
      // would otherwise keep the reader in a loop it controls.
      for (var step = 0; step < 8; step++) {
        switch (action) {
          case PluginAskAction(:final label, :final defaultValue):
            if (!navigator.mounted) return;
            final answer = await _ask(navigator.context, label, defaultValue);
            if (answer == null) return;
            context = context.withAnswer(answer);
            action = service.start(plugin, context);

          case PluginAiAction(:final prompt):
            if (!navigator.mounted) return;
            final reply = await _withProgress(
              navigator,
              l10n.pluginWorking,
              () => AiChatService.complete(
                config: ref.read(settingsProvider),
                prompt: prompt,
              ),
            );
            action = service.resumeWithResult(plugin, context, reply);

          case PluginDiffAction(:final original, :final result):
            if (!navigator.mounted) return;
            await showDialog<void>(
              context: navigator.context,
              builder: (_) => _SideBySideDialog(
                title: plugin.name,
                original: original,
                result: result,
                l10n: l10n,
              ),
            );
            return;

          case PluginNotifyAction(:final message):
            messenger.showSnackBar(SnackBar(content: Text(message)));
            return;

          case PluginReplaceAction():
            // Reserved for plugins that declare `document.write`. Until the
            // editor grants that, saying so beats silently doing nothing.
            messenger.showSnackBar(SnackBar(
              content: Text(l10n.pluginCannotEdit(plugin.name)),
            ));
            return;

          case PluginNoAction():
            return;
        }
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.pluginTooManySteps)));
    } catch (error) {
      if (!navigator.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('$error')));
        return;
      }
      await _showFailure(navigator.context, l10n, plugin.name, '$error');
    } finally {
      await service.flush(plugin);
      service.dispose();
    }
  }

  static Future<String?> _ask(
    BuildContext context,
    String label,
    String initial,
  ) async {
    final controller = TextEditingController(text: initial);
    final l10n = AppLocalizations.of(context)!;
    final answer = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    return (answer == null || answer.isEmpty) ? null : answer;
  }

  /// Runs [work] with a dialog on screen, because a model call takes seconds
  /// and a window that does nothing for seconds reads as a command that never
  /// fired.
  static Future<String> _withProgress(
    NavigatorState navigator,
    String message,
    Future<String> Function() work,
  ) async {
    showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
    try {
      return await work();
    } finally {
      if (navigator.canPop()) navigator.pop();
    }
  }

  static Future<void> _showFailure(
    BuildContext context,
    AppLocalizations l10n,
    String plugin,
    String error,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pluginFailed(plugin)),
        content: SingleChildScrollView(child: SelectableText(error)),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: error));
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.copy),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

/// The plugin's result beside what it was given. Nothing is written back: a
/// result the reader has not read is not an edit they asked for.
class _SideBySideDialog extends StatelessWidget {
  const _SideBySideDialog({
    required this.title,
    required this.original,
    required this.result,
    required this.l10n,
  });

  final String title;
  final String original;
  final String result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: (size.width * 0.8).clamp(360.0, 1100.0),
        height: (size.height * 0.7).clamp(280.0, 720.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _pane(context, l10n.pluginOriginal, original)),
            const SizedBox(width: 16),
            Expanded(child: _pane(context, l10n.pluginResult, result)),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(text: result)),
          icon: const Icon(Icons.copy),
          label: Text(l10n.copy),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _pane(BuildContext context, String heading, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(child: SelectableText(body)),
            ),
          ),
        ),
      ],
    );
  }
}
