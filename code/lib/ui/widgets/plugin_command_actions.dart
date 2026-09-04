import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/editor_provider.dart';
import '../../providers/plugin_provider.dart';
import '../../providers/tab_provider.dart';
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
/// Which half of the editor a command was started from.
///
/// In split view the editor is showing both at once, so "what is the reader
/// looking at" has no single answer — but the menu does: it was opened in one
/// half or the other. Reporting the mode instead sent plugins `split`, which
/// they can only fall back from; a translation of a source document came back
/// rendered, beside the source it could no longer be compared with.
enum PluginEditorView { source, preview }

class PluginCommandActions {
  const PluginCommandActions._();

  /// What to tell a plugin the reader is looking at.
  ///
  /// The half wins where there is one, because it is the more specific truth:
  /// a right-click happened somewhere. Only a command with no half — from the
  /// menu bar, or the command palette — falls back to the mode.
  static String viewFor(PluginEditorView? half, EditMode mode) =>
      half?.name ?? mode.name;

  /// Where in the editor a menu entry belongs. A plugin says this in its
  /// manifest; the host decides what that location actually looks like.
  static const editorContextMenu = 'editor.contextMenu';

  /// The entries for [location], in the reader's language.
  static List<ContextMenuButtonItem> menuItems({
    required BuildContext context,
    required WidgetRef ref,
    required String location,
    required PluginEditorView half,
    required String Function() selection,
    required String Function() document,
  }) {
    // Read once, here: what the reader has selected decides which entries are
    // worth offering at all. Both were offered before — "translate the
    // selection" with nothing selected, and "translate the document" while
    // pointing at a paragraph.
    final selected = selection();
    final hasSelection = selected.trim().isNotEmpty;
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
            if (menu.location == location &&
                menu.appliesTo(hasSelection: hasSelection))
              (plugin, menu),
    ];
    if (contributions.isEmpty) return const [];

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const [];
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final locale = Localizations.localeOf(context).toString();
    // Read here, while there is certainly a widget: the menu entry may be
    // pressed long after this list was built, and the run it starts may
    // outlive the pane it was started from.
    final container = ProviderScope.containerOf(context, listen: false);

    final items = <ContextMenuButtonItem>[];
    {
      for (final (plugin, menu) in contributions) {
        final strings = plugin.stringsFor(locale);
        items.add(
          ContextMenuButtonItem(
            // A plugin's own translation of its own label wins over the
            // English fallback it declared in the manifest.
            label: strings[menu.title] ?? menu.title,
            onPressed: () {
              // The toolbar does not take itself down when one of its own
              // buttons runs something, so it sat there over the document for
              // the whole translation and after it.
              ContextMenuController.removeAny();
              _run(
                navigator: navigator,
                messenger: messenger,
                container: container,
                l10n: l10n,
                locale: locale,
                plugin: plugin,
                command: menu.id,
                view: viewFor(half, container.read(settingsProvider).editMode),
                selection: selected,
                document: document(),
              );
            },
          ),
        );
      }
    }
    return items;
  }

  /// Runs one plugin command outside a context menu — from the menu bar, say.
  static Future<void> run(
    WidgetRef ref, {
    required BuildContext context,
    required PluginManifest plugin,
    required String command,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final tabs = ref.read(tabProvider);
    final active = tabs.tabs.where((tab) => tab.id == tabs.activeTabId);
    await _run(
      navigator: Navigator.of(context),
      messenger: ScaffoldMessenger.of(context),
      container: ProviderScope.containerOf(context, listen: false),
      l10n: l10n,
      locale: Localizations.localeOf(context).toString(),
      plugin: plugin,
      command: command,
      view: viewFor(null, ref.read(settingsProvider).editMode),
      selection: ref.read(editorProvider).selectedText,
      document: active.isEmpty ? '' : active.first.content,
    );
  }

  /// Runs a command and returns the text it wanted shown.
  ///
  /// For a place that draws the answer itself — a side-bar drawer — rather
  /// than one of the editor's own windows. A command that asks a question or
  /// calls a model is not for a panel: a panel is opened and answers, and
  /// anything that stops to ask is reported as text instead.
  static Future<String> textFor(
    WidgetRef ref, {
    required BuildContext context,
    required PluginManifest plugin,
    required String command,
  }) async {
    // Read before the await: after it the context may be gone, and the
    // reader's language is not worth a crash.
    final locale = Localizations.localeOf(context).toString();
    final container = ProviderScope.containerOf(context, listen: false);
    final directory = await getApplicationSupportDirectory();
    final service = PluginCommandService(
      p.join(directory.path, 'plugins'),
      locale: locale,
    );
    final tabs = container.read(tabProvider);
    final active = tabs.tabs.where((tab) => tab.id == tabs.activeTabId);

    try {
      final action = service.start(
        plugin,
        PluginScriptContext(
          command: command,
          selection: container.read(editorProvider).selectedText,
          document: active.isEmpty ? '' : active.first.content,
          view: viewFor(null, container.read(settingsProvider).editMode),
        ),
      );
      return switch (action) {
        PluginPaneAction(:final text) => text,
        PluginPanelAction(:final text) => text,
        PluginShowAction(:final text) => text,
        PluginNotifyAction(:final message) => message,
        PluginDiffAction(:final result) => result,
        PluginAskAction(:final label) =>
          '${plugin.name}: $label — a panel cannot ask a question',
        PluginAiAction() =>
          '${plugin.name}: a panel cannot wait for the model',
        _ => '',
      };
    } catch (error) {
      return '$error';
    } finally {
      await service.flush(plugin);
      service.dispose();
    }
  }

  /// Drives one command to its end.
  ///
  /// The script is synchronous, so it hands back one action at a time and this
  /// performs it: ask the reader, call the model, show the result. The plugin
  /// keeps the prompt and the flow; the editor keeps the credentials.
  ///
  /// Takes a [ProviderContainer] rather than a `WidgetRef`: a run outlives the
  /// widget that began it. Closing the pane, or the tab, while a model call is
  /// in flight disposed that widget, and the next `ref.read` — including the
  /// two in the `finally`, which always run — threw "Cannot use ref after the
  /// widget was disposed" in the reader's face. A container is the whole
  /// application's, and outlives any of this.
  static Future<void> _run({
    required NavigatorState navigator,
    required ScaffoldMessengerState messenger,
    required ProviderContainer container,
    required AppLocalizations l10n,
    required String locale,
    required PluginManifest plugin,
    required String command,
    required String view,
    required String selection,
    required String document,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final service = PluginCommandService(
      p.join(directory.path, 'plugins'),
      locale: locale,
    );

    // The tab this run belongs to, captured before anything can await: the
    // reader may switch tabs while a model is thinking, and the translation
    // belongs beside the document it was asked for, not beside whatever is on
    // screen when it comes back.
    final tabs = container.read(tabProvider);
    final tabId = tabs.activeTabId ?? '';

    var context = PluginScriptContext(
      command: command,
      selection: selection,
      document: document,
      view: view,
    );

    try {
      var action = service.start(plugin, context);

      // Bounded, but not so tightly that a plugin cannot walk a document: a
      // block at a time over a long file is many steps, and each one shows
      // its result. What needs the tight bound is questions, counted below.
      var questions = 0;
      for (var step = 0; step < 400; step++) {
        switch (action) {
          case PluginAskAction(
              :final label,
              :final defaultValue,
              :final choices
            ):
            // A plugin that answers every question with another question
            // would otherwise keep the reader in a loop it controls.
            if (++questions > 8) break;
            // Asked in the card the answer will appear in. It used to be a
            // modal dialog of its own — a second, larger window for one line
            // of input, on the way to an answer shown in a card a quarter its
            // size, with the document unreachable behind both.
            final asked = container.read(pluginTipProvider.notifier).ask(
                  title: plugin.name,
                  question: label,
                  choices: choices,
                  // Already filled in, not merely offered: it is what the
                  // reader chose last time, so pressing confirm repeats it.
                  answer: defaultValue,
                );
            final answer = await asked.future;
            if (answer == null) return;
            context = context.withAnswer(answer);
            action = service.start(plugin, context);

          case PluginAiAction(:final prompt):
            if (!navigator.mounted) return;
            // Said beside the document, not over it. A modal barrier stopped
            // the reader scrolling the very text the answer was about, for
            // the several seconds a model takes.
            container.read(pluginTipProvider.notifier).working(plugin.name);
            final reply = await AiChatService.complete(
              config: container.read(settingsProvider),
              prompt: prompt,
            );
            // Dismissing the tip is how the reader stops this. Coming back
            // with the answer they had just closed would make the close
            // button a suggestion.
            if (container.read(pluginTipProvider) == null) return;
            action = service.resumeWithResult(plugin, context, reply);

          case PluginShowAction(:final text, :final title):
            container.read(pluginTipProvider.notifier).show(
                  title: title.isEmpty ? plugin.name : title,
                  text: text,
                );
            return;

          case PluginPaneAction(
              :final append,
              :final nextPrompt,
              :final slot
            ):
            final content =
                PluginPaneContent.fromAction(action, plugin.name);
            final panes = container.read(pluginPanesProvider.notifier);
            // Closing the pane is how the reader stops this. Appending to a
            // pane they closed would put it straight back, one block at a
            // time, with no way to be rid of it.
            if (append &&
                !panes.forTab(tabId).containsKey(slot)) {
              return;
            }
            append ? panes.append(tabId, content) : panes.show(tabId, content);
            if (nextPrompt == null) return;
            // More to do, and the reader can already see what is done — so no
            // dialog over the top of it. This is what lets a plugin work
            // through a document a block at a time.
            final reply = await AiChatService.complete(
              config: container.read(settingsProvider),
              prompt: nextPrompt,
            );
            action = service.resumeWithResult(plugin, context, reply);

          case PluginPanelAction(:final text, :final title):
            // Beside the document, which is what the grid is for. It used to
            // have a container of its own — a fixed strip pinned to the far
            // right, outside the grid and outside the side bar — so the editor
            // had three places to put a result and the reader had no way to
            // tell which one a plugin would use.
            container.read(pluginPanesProvider.notifier).show(
                  tabId,
                  PluginPaneContent(
                    pluginName: plugin.name,
                    title: title,
                    text: text,
                    slot: PluginPaneSlot.right,
                  ),
                );
            return;

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
      // However the run ended — finished, threw, or ran out of steps — nothing
      // is still coming. A pane left spinning over half a translation, or a
      // tip left saying "working", would both be the editor saying something
      // untrue about itself.
      container.read(pluginPanesProvider.notifier).settle(tabId);
      container.read(pluginTipProvider.notifier).dismissIfWaiting();
      await service.flush(plugin);
      service.dispose();
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

