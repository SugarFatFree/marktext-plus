import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/editor_provider.dart';
import '../../providers/plugin_provider.dart';
import '../../providers/tab_provider.dart';
import '../../services/plugin_document_edit.dart';
import '../../services/plugin_script_runtime.dart';

/// Putting a plugin's answer into the document.
///
/// Lived inside the pane grid, which meant it was only offered there. A plugin
/// that says `apply = true` is offering the reader a rewrite to accept, and
/// running the same command from the right-hand rail gave them the text with
/// no way to accept it: the sink the rail passes carried the words and dropped
/// everything else the plugin had said about them.
abstract final class PluginApply {
  /// Replaces what [content] rewrote, or says why it cannot.
  ///
  /// Returns false when there was nothing to write into, so a caller can leave
  /// its own offer standing rather than closing over a failure.
  static bool into(
    WidgetRef ref,
    BuildContext context, {
    required String pluginName,
    required String replaces,
    required String text,
    PluginPaneSlot? closing,
  }) {
    final tabs = ref.read(tabProvider);
    final tabId = tabs.activeTabId;
    final tab = tabs.tabs.where((t) => t.id == tabId).firstOrNull;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (tab == null || tabId == null) return false;

    final plugin = ref
        .read(installedPluginManifestsProvider)
        .valueOrNull
        ?.where((p) => p.name == pluginName)
        .firstOrNull;
    final edit = plugin == null
        ? null
        : PluginDocumentEdit.of(
            plugin,
            document: tab.content,
            selection: replaces,
            replacement: text,
          );
    if (edit == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n?.pluginCannotEdit(pluginName) ?? '')),
      );
      return false;
    }

    // Through the history first, so one press of undo takes it back.
    // Named, not left to whatever the source editor said last: this runs from
    // preview mode too, where there is no source editor to have said anything.
    ref.read(editorProvider.notifier).pushHistory(edit.before, tabId: tabId);
    ref.read(tabProvider.notifier).updateContent(tabId, edit.after);
    if (closing != null) {
      ref.read(pluginPanesProvider.notifier).close(tabId, closing);
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n?.pluginApplied ?? '')),
    );
    return true;
  }
}
