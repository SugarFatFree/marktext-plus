import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/plugin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../editor/markdown_renderer.dart';
import '../../services/plugin_script_runtime.dart';

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

  /// Kept off the edges, so a pane can always be grabbed again after a drag.
  static const _least = 0.15;
  static const _most = 0.85;

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
    final filled = [
      for (final slot in PluginPaneSlot.values)
        if (panes[slot] != null) PluginPaneView(content: panes[slot]!),
    ];
    if (filled.isEmpty) return widget.document;

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget row(Widget left, Widget? beside) {
          if (beside == null) return left;
          final width = constraints.maxWidth;
          return Row(children: [
            SizedBox(width: width * _columns - _Grip.half, child: left),
            _Grip(
              key: const Key('plugin-panes-column-divider'),
              vertical: true,
              onDrag: (delta) => setState(() {
                _columns = (_columns + delta / width).clamp(_least, _most);
              }),
            ),
            SizedBox(width: width * (1 - _columns) - _Grip.half, child: beside),
          ]);
        }

        final top = row(widget.document, filled.first);
        if (filled.length == 1) return top;

        // Two panes leave the bottom half whole; three split it the same way
        // as the top, and the columns line up because they share the divider.
        final under = filled.length == 2
            ? filled[1]
            : row(filled[1], filled[2]);

        final height = constraints.maxHeight;
        return Column(children: [
          SizedBox(height: height * _rows - _Grip.half, child: top),
          _Grip(
            key: const Key('plugin-panes-row-divider'),
            vertical: false,
            onDrag: (delta) => setState(() {
              _rows = (_rows + delta / height).clamp(_least, _most);
            }),
          ),
          SizedBox(height: height * (1 - _rows) - _Grip.half, child: under),
        ]);
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
