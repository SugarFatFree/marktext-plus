import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'source_editor.dart';
import 'markdown_renderer.dart';

class SplitEditor extends ConsumerStatefulWidget {
  final String initialContent;
  final ValueChanged<String>? onChanged;

  const SplitEditor({
    super.key,
    this.initialContent = '',
    this.onChanged,
  });

  @override
  ConsumerState<SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends ConsumerState<SplitEditor> {
  late String _content;
  late String _renderedContent;
  double _splitRatio = 0.5;
  bool _isDragging = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _content = widget.initialContent;
    _renderedContent = widget.initialContent;
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
