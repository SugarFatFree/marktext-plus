import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/plugin_provider.dart';
import '../../providers/settings_provider.dart';
import '../editor/markdown_renderer.dart';
import '../../services/plugin_script_runtime.dart';

/// The document, and up to three panes a plugin filled, as a two by two grid.
///
/// Nothing is drawn for a slot no plugin asked for: an empty pane is a strip
/// of nothing taking space from the document. With no panes at all this is the
/// document and no wrapper worth the name.
class PluginPanes extends ConsumerWidget {
  const PluginPanes({required this.document, super.key});

  final Widget document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panes = ref.watch(pluginPanesProvider);
    if (panes.isEmpty) return document;

    final right = panes[PluginPaneSlot.right];
    final bottom = panes[PluginPaneSlot.bottom];
    final corner = panes[PluginPaneSlot.corner];

    // The top row is the document and whatever sits beside it; the bottom row
    // is what sits under each of those. A row with nothing in it is not drawn,
    // so a plugin filling only the corner still gets a bottom row.
    Widget row(Widget left, PluginPaneContent? beside) => beside == null
        ? left
        : Row(children: [
            Expanded(child: left),
            const _Divider(vertical: true),
            SizedBox(width: 360, child: PluginPaneView(content: beside)),
          ]);

    final top = row(document, right);
    if (bottom == null && corner == null) return top;

    return Column(children: [
      Expanded(child: top),
      const _Divider(vertical: false),
      SizedBox(
        height: 240,
        child: row(
          bottom == null
              ? const SizedBox.expand()
              : PluginPaneView(content: bottom),
          corner,
        ),
      ),
    ]);
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colour = Theme.of(context).dividerColor;
    return vertical
        ? VerticalDivider(width: 1, thickness: 1, color: colour)
        : Divider(height: 1, thickness: 1, color: colour);
  }
}

/// One pane: what the plugin called it, what it said, and a way to close it.
class PluginPaneView extends ConsumerWidget {
  const PluginPaneView({required this.content, super.key});

  final PluginPaneContent content;

  /// Drawn the way the plugin asked, so a translated document can be read
  /// against the document it sits beside: rendered next to a preview, source
  /// next to source.
  Widget _body(BuildContext context, WidgetRef ref) {
    switch (content.render) {
      case PluginPaneRender.preview:
        return MarkdownRenderer(markdown: content.text);
      case PluginPaneRender.source:
        final config = ref.watch(settingsProvider);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            content.text,
            style: TextStyle(
              fontFamily: config.fontFamily,
              fontSize: config.fontSize,
              height: config.lineHeight,
            ),
          ),
        );
      case PluginPaneRender.text:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SelectableText(content.text),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  content.title.isEmpty ? content.pluginName : content.title,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: l10n?.copy,
                icon: const Icon(Icons.copy, size: 16),
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: content.text)),
              ),
              IconButton(
                tooltip: l10n?.close,
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: () => ref
                    .read(pluginPanesProvider.notifier)
                    .close(content.slot),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _body(context, ref)),
      ],
    );
  }
}
