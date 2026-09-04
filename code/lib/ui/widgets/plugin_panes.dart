import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/plugin_provider.dart';
import '../../core/config/app_config.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../editor/markdown_renderer.dart';
import '../../services/plugin_script_runtime.dart';
import '../../providers/editor_provider.dart';
import '../../services/plugin_document_edit.dart';

/// The document, and up to three panes a plugin filled.
///
/// The shape follows the count, and is symmetrical at every step:
///
/// * nothing filled — the document has the whole tab;
/// * one pane — the document and the pane, side by side, half each;
/// * two panes — the top half split down the middle, the second pane taking
///   the bottom half whole;
/// * three panes — both halves split down the middle, four equal cells.
///
/// The dividers drag, like the one between source and preview this was
/// modelled on. It used to be trim rather than a grid — a fixed strip down one
/// side, a fixed band along the bottom — so a translation got a sliver beside
/// the document it translated and no two cells were the same size.
///
/// A slot decides which pane is which, not where it lands: a plugin that fills
/// only the corner should not leave two empty cells to get there.
class PluginPanes extends ConsumerStatefulWidget {
  const PluginPanes({required this.document, super.key});

  final Widget document;

  @override
  ConsumerState<PluginPanes> createState() => _PluginPanesState();
}

class _PluginPanesState extends ConsumerState<PluginPanes> {
  /// Where the vertical divider sits, as a fraction of the width. Half, so
  /// what a plugin produced gets the same room as what it was produced from.
  double _columns = 0.5;
  double _rows = 0.5;

  /// Whether the reader moved the split to the other half.
  ///
  /// Null until they do, so the plugin's own choice — which it makes by
  /// filling `right` or not — is what they see first. After that it is theirs:
  /// which half is divided is a view of the same three panes, not a decision
  /// the plugin gets to keep making.
  bool? _splitTop;

  /// Kept off the edges, so a pane can always be grabbed again after a drag.
  static const _least = 0.15;
  static const _most = 0.85;

  /// Writes what a pane holds into the document.
  ///
  /// The permission is checked here rather than trusted from the plugin: the
  /// flag says the plugin offered, and the permission says whether the editor
  /// agreed.
  void _apply(PluginPaneContent content) {
    final tabs = ref.read(tabProvider);
    final tabId = tabs.activeTabId;
    final tab = tabs.tabs.where((t) => t.id == tabId).firstOrNull;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (tab == null || tabId == null) return;

    final plugin = ref
        .read(installedPluginManifestsProvider)
        .valueOrNull
        ?.where((p) => p.name == content.pluginName)
        .firstOrNull;
    final edit = plugin == null
        ? null
        : PluginDocumentEdit.of(
            plugin,
            document: tab.content,
            selection: content.replaces,
            replacement: content.text,
          );
    if (edit == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n?.pluginCannotEdit(content.pluginName) ?? ''),
        ),
      );
      return;
    }

    // Through the history first, so one press of undo takes it back.
    ref.read(editorProvider.notifier).pushHistory(edit.before);
    ref.read(tabProvider.notifier).updateContent(tabId, edit.after);
    ref.read(pluginPanesProvider.notifier).close(tabId, content.slot);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n?.pluginApplied ?? '')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only this tab's. A pane belongs to the document it was opened beside;
    // showing every tab's would put a translation of one file next to another.
    final tabs = ref.watch(tabProvider);
    final tabId = tabs.activeTabId ?? '';
    final panes = ref.watch(pluginPanesProvider)[tabId] ??
        const <PluginPaneSlot, PluginPaneContent>{};

    // A tab that has been closed keeps nothing.
    ref.listen(tabProvider, (_, next) {
      ref.read(pluginPanesProvider.notifier).retain(
            next.tabs.map((tab) => tab.id).toSet(),
          );
    });
    // In the order slots are declared, so the shape of the grid is settled by
    // how many panes there are and stays put as more arrive.
    final ordered = [
      for (final slot in PluginPaneSlot.values)
        if (panes[slot] != null) panes[slot]!,
    ];

    // The split view's two halves are two cells. That is what this grid was
    // for: the editor could already divide a tab between source and preview,
    // and the point was to offer that division out. Counting the document as
    // one cell however it was drawn is what put source, preview and a
    // translation side by side in three columns.
    final documentCells =
        ref.watch(settingsProvider).editMode == EditMode.split ? 2 : 1;

    if (ordered.isEmpty) return widget.document;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        Widget columns(Widget left, Widget beside) => Row(
              children: [
                SizedBox(width: width * _columns - _Grip.half, child: left),
                _Grip(
                  key: const Key('plugin-panes-column-divider'),
                  vertical: true,
                  onDrag: (delta) => setState(() {
                    _columns = (_columns + delta / width).clamp(_least, _most);
                  }),
                ),
                SizedBox(
                  width: width * (1 - _columns) - _Grip.half,
                  child: beside,
                ),
              ],
            );

        Widget rows(Widget above, Widget under) => Column(
              children: [
                SizedBox(height: height * _rows - _Grip.half, child: above),
                _Grip(
                  key: const Key('plugin-panes-row-divider'),
                  vertical: false,
                  onDrag: (delta) => setState(() {
                    _rows = (_rows + delta / height).clamp(_least, _most);
                  }),
                ),
                SizedBox(
                  height: height * (1 - _rows) - _Grip.half,
                  child: under,
                ),
              ],
            );

        // A split document already fills its row, so every pane goes below it:
        // one takes the bottom row whole, two divide it. Its own halves are
        // the divided ones and the editor is not going to reorder source and
        // preview to satisfy a button, so there is nothing to flip.
        // Four cells is the most there are, so a split document leaves room
        // for two panes and any beyond that are not drawn. The count decides
        // the shape here rather than being capped somewhere earlier: one rule,
        // in one place.
        if (documentCells == 2) {
          return rows(
            widget.document,
            ordered.length == 1
                ? PluginPaneView(content: ordered.first, onApply: () => _apply(ordered.first))
                : columns(
                    PluginPaneView(content: ordered[0], onApply: () => _apply(ordered[0])),
                    PluginPaneView(content: ordered[1], onApply: () => _apply(ordered[1])),
                  ),
          );
        }

        // One pane is one pane: beside the document, half each, whichever slot
        // it claimed. There is no second row to make.
        if (ordered.length == 1) {
          return columns(
            widget.document,
            PluginPaneView(content: ordered.first, onApply: () => _apply(ordered.first)),
          );
        }

        // Three cells: one half divided and the other whole. Which half is the
        // plugin's to suggest — filling `right` puts a pane beside the
        // document — and the reader's to change.
        if (ordered.length == 2) {
          final splitTop =
              _splitTop ?? panes.containsKey(PluginPaneSlot.right);
          void flip() => setState(() => _splitTop = !splitTop);

          if (splitTop) {
            return rows(
              columns(
                widget.document,
                PluginPaneView(content: ordered[0], onFlip: flip, onApply: () => _apply(ordered[0])),
              ),
              PluginPaneView(content: ordered[1], onFlip: flip, onApply: () => _apply(ordered[1])),
            );
          }
          return rows(
            widget.document,
            columns(
              PluginPaneView(content: ordered[0], onFlip: flip, onApply: () => _apply(ordered[0])),
              PluginPaneView(content: ordered[1], onFlip: flip, onApply: () => _apply(ordered[1])),
            ),
          );
        }

        // Four cells: the document top left, a pane in each of the rest. The
        // rows share a divider, so the columns line up.
        return rows(
          columns(widget.document, PluginPaneView(content: ordered[0], onApply: () => _apply(ordered[0]))),
          columns(
            PluginPaneView(content: ordered[1], onApply: () => _apply(ordered[1])),
            PluginPaneView(content: ordered[2], onApply: () => _apply(ordered[2])),
          ),
        );
      },
    );
  }
}

/// A divider that can be dragged, like the one between source and preview.
class _Grip extends StatefulWidget {
  const _Grip({required this.vertical, required this.onDrag, super.key});

  final bool vertical;
  final void Function(double delta) onDrag;

  static const thickness = 8.0;
  static const half = thickness / 2;

  @override
  State<_Grip> createState() => _GripState();
}

class _GripState extends State<_Grip> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bar = Container(
      width: widget.vertical ? _Grip.thickness : null,
      height: widget.vertical ? null : _Grip.thickness,
      color: _dragging
          ? theme.colorScheme.primary.withValues(alpha: 0.5)
          : theme.dividerColor,
      child: Center(
        child: Container(
          width: widget.vertical ? 2 : null,
          height: widget.vertical ? null : 2,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
    return MouseRegion(
      cursor: widget.vertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onHorizontalDragStart:
            widget.vertical ? (_) => setState(() => _dragging = true) : null,
        onHorizontalDragUpdate: widget.vertical
            ? (details) => widget.onDrag(details.delta.dx)
            : null,
        onHorizontalDragEnd:
            widget.vertical ? (_) => setState(() => _dragging = false) : null,
        onVerticalDragStart:
            widget.vertical ? null : (_) => setState(() => _dragging = true),
        onVerticalDragUpdate: widget.vertical
            ? null
            : (details) => widget.onDrag(details.delta.dy),
        onVerticalDragEnd:
            widget.vertical ? null : (_) => setState(() => _dragging = false),
        child: bar,
      ),
    );
  }
}

/// One pane: what the plugin called it, what it said, and a way to close it.
class PluginPaneView extends ConsumerWidget {
  const PluginPaneView({
    required this.content,
    this.onFlip,
    this.onApply,
    super.key,
  });

  final PluginPaneContent content;

  /// Writes what this pane holds into the document. Null when the plugin did
  /// not offer it, or when the editor is not going to allow it.
  final VoidCallback? onApply;

  /// Moves the split to the other half. Only three cells have another half to
  /// move it to: two have no second row, and four are already both split.
  final VoidCallback? onFlip;

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
    // Where the progress goes depends on whether there is anything to read
    // yet. An empty pane with a spinner in the title bar and nothing under it
    // is a pane that looks broken; once the first block lands, the spinner
    // belongs out of the way of what the reader came to read.
    final waitingForFirst = content.busy && content.text.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        content.title.isEmpty
                            ? content.pluginName
                            : content.title,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (content.busy && !waitingForFirst) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n?.pluginWorking ?? '',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Offered only when the plugin asked and it is not still
              // filling: accepting half a rewrite would write half a rewrite.
              if (content.canApply && !content.busy)
                TextButton.icon(
                  key: const Key('plugin-pane-apply'),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(l10n?.pluginApply ?? ''),
                  onPressed: onApply,
                ),
              if (onFlip != null)
                IconButton(
                  key: const Key('plugin-panes-flip'),
                  tooltip: l10n?.pluginFlipSplit,
                  icon: const Icon(Icons.swap_vert, size: 17),
                  visualDensity: VisualDensity.compact,
                  onPressed: onFlip,
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
                    .close(ref.read(tabProvider).activeTabId ?? '',
                        content.slot),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: waitingForFirst
              ? Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n?.pluginWorking ?? '',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : _body(context, ref),
        ),
      ],
    );
  }
}
