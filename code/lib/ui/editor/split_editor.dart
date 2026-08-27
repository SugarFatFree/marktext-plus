import 'dart:async';
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

  const SplitEditor({
    super.key,
    required this.tabId,
    this.initialContent = '',
    this.onChanged,
  });

  @override
  ConsumerState<SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends ConsumerState<SplitEditor> {
  late String _content;
  late String _renderedContent;
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
    _splitRatio = ref.read(settingsProvider).splitRatio.clamp(0.2, 0.8);
    _content = widget.initialContent;
    _renderedContent = widget.initialContent;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _splitPersistTimer?.cancel();
    super.dispose();
  }

  void _onContentChanged(String newContent) {
    setState(() {
      _content = newContent;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _renderedContent = newContent;
      });
      widget.onChanged?.call(newContent);
    });
  }

  void _onDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _splitRatio = (_splitRatio * constraints.maxWidth + details.delta.dx) / constraints.maxWidth;
      _splitRatio = _splitRatio.clamp(0.2, 0.8);
      _persistSplitRatio();
    });
  }

  /// Stores the divider position, debounced so a drag is not a write per frame.
  void _persistSplitRatio() {
    _splitPersistTimer?.cancel();
    _splitPersistTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(settingsProvider.notifier).updateConfig(
            (c) => c.copyWith(splitRatio: _splitRatio),
          );
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
                onChanged: _onContentChanged,
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
                child: MarkdownRenderer(markdown: _renderedContent),
              ),
            ),
          ],
        );
      },
    );
  }
}
