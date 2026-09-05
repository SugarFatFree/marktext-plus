import 'dart:async';
import '../../core/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import 'source_editor.dart';
import 'markdown_renderer.dart';

class SplitEditor extends ConsumerStatefulWidget {
  final String initialContent;
  final ValueChanged<String>? onChanged;

  /// Which tab this editor is showing; forwarded so undo history stays
  /// separate per document.
  final String tabId;

  /// Bumped by the owner when [initialContent] was replaced from outside —
  /// the document was reloaded after changing on disk.
  final int externalRevision;

  const SplitEditor({
    super.key,
    required this.tabId,
    this.initialContent = '',
    this.externalRevision = 0,
    this.onChanged,
  });

  @override
  ConsumerState<SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends ConsumerState<SplitEditor> {
  late String _content;
  late String _renderedContent;

  /// Incremented whenever the preview pane rewrites the source, so the source
  /// pane knows to adopt it.
  ///
  /// Added to the owner's revision before being passed down, so a reload from
  /// disk and an edit made in the preview both reach the source pane.
  int _externalRevision = 0;

  /// Filled from settings in initState; 0.5 only until then.
  double _splitRatio = 0.5;
  Timer? _splitPersistTimer;
  bool _isDragging = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // The divider position was written to config on every drag and never read
    // back, so the split reset to even halves on each launch.
    _splitRatio = ref
        .read(settingsProvider)
        .splitRatio
        .clamp(AppConstants.minSplitRatio, AppConstants.maxSplitRatio);
    _content = widget.initialContent;
    _renderedContent = widget.initialContent;
  }

  @override
  void didUpdateWidget(SplitEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalRevision == oldWidget.externalRevision) return;
    if (widget.initialContent == _content) return;

    // The document was reloaded under us; both panes show the new text.
    _debounce?.cancel();
    setState(() {
      _content = widget.initialContent;
      _renderedContent = widget.initialContent;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _splitPersistTimer?.cancel();
    super.dispose();
  }

  void _onContentChanged(String newContent) {
    // No setState: _content only feeds SourceEditor.initialContent, which the
    // editor reads once. Rebuilding the whole editor on every keystroke to
    // hand it back the text it just produced was wasted work.
    _content = newContent;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
        const Duration(milliseconds: AppConstants.debounceDelay), () {
      if (!mounted) return;
      setState(() {
        _renderedContent = newContent;
      });
      widget.onChanged?.call(newContent);
    });
  }

  /// An edit made in the preview pane — a ticked checkbox, a block edited in
  /// place. The source pane has to be told, which is what [_externalRevision]
  /// is for.
  void _onPreviewEdited(String newContent) {
    _debounce?.cancel();
    setState(() {
      _content = newContent;
      _renderedContent = newContent;
      _externalRevision++;
    });
    widget.onChanged?.call(newContent);
  }

  void _onDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _splitRatio =
          (_splitRatio * constraints.maxWidth + details.delta.dx) /
          constraints.maxWidth;
      _splitRatio = _splitRatio
          .clamp(AppConstants.minSplitRatio, AppConstants.maxSplitRatio);
      _persistSplitRatio();
    });
  }

  /// Stores the divider position, debounced so a drag is not a write per frame.
  void _persistSplitRatio() {
    _splitPersistTimer?.cancel();
    _splitPersistTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref
          .read(settingsProvider.notifier)
          .updateConfig((c) => c.copyWith(splitRatio: _splitRatio));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftWidth = constraints.maxWidth * _splitRatio;
        final rightWidth = constraints.maxWidth * (1 - _splitRatio);

        return Row(
          children: [
            SizedBox(
              width: leftWidth - 4,
              child: SourceEditor(
                tabId: widget.tabId,
                initialContent: _content,
                externalRevision: _externalRevision + widget.externalRevision,
                onChanged: _onContentChanged,
                // Only here: the pane has a preview beside it to tell.
                reportsScrollPosition: true,
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragStart: (_) {
                  setState(() {
                    _isDragging = true;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  _onDragUpdate(details, constraints);
                },
                onHorizontalDragEnd: (_) {
                  setState(() {
                    _isDragging = false;
                  });
                },
                child: Container(
                  width: 8,
                  color: _isDragging
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : theme.dividerColor,
                  child: Center(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: rightWidth - 4,
              child: Container(
                color: theme.scaffoldBackgroundColor,
                // Without this the preview pane was read-only in split
                // mode: task-list checkboxes did nothing and a block could
                // not be edited in place, unlike in preview mode.
                child: MarkdownRenderer(
                  markdown: _renderedContent,
                  onSourceChanged: _onPreviewEdited,
                  // And only here: the preview has a pane to follow.
                  followsSource: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
