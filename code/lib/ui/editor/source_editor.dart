import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';

class SourceEditor extends ConsumerStatefulWidget {
  final String initialContent;
  final ValueChanged<String>? onChanged;

  const SourceEditor({
    super.key,
    this.initialContent = '',
    this.onChanged,
  });

  @override
  ConsumerState<SourceEditor> createState() => _SourceEditorState();
}

class _SourceEditorState extends ConsumerState<SourceEditor> {
  late TextEditingController _controller;
  late ScrollController _editorScrollController;
  late ScrollController _gutterScrollController;
  Timer? _debounce;
  bool _isSyncingScroll = false;
  bool _isInitialized = false;

  TextEditingController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _editorScrollController = ScrollController();
    _gutterScrollController = ScrollController();
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);
    _editorScrollController.addListener(_onEditorScroll);

    // Register controller with editor provider and push initial history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).setController(_controller);
      ref.read(editorProvider.notifier).pushHistory(widget.initialContent);
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.removeListener(_onSelectionChanged);
    _editorScrollController.removeListener(_onEditorScroll);
    _controller.dispose();
    _editorScrollController.dispose();
    _gutterScrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_isInitialized) {
        ref.read(editorProvider.notifier).pushHistory(_controller.text);
      }
      widget.onChanged?.call(_controller.text);
    });
  }

  void _onSelectionChanged() {
    final selection = _controller.selection;
    if (!selection.isValid) return;

    final text = _controller.text;
    final offset = selection.baseOffset.clamp(0, text.length);
    final textBefore = text.substring(0, offset);
    final lines = textBefore.split('\n');
    final line = lines.length - 1;
    final col = lines.last.length;

    ref.read(editorProvider.notifier).updateCursor(line, col);

    if (selection.isCollapsed) {
      ref.read(editorProvider.notifier).updateSelection('');
    } else {
      final start = selection.start.clamp(0, text.length);
      final end = selection.end.clamp(0, text.length);
      ref.read(editorProvider.notifier).updateSelection(text.substring(start, end));
    }

    _scrollToTypewriterPosition(line);
  }

  void _scrollToTypewriterPosition(int line) {
    final config = ref.read(settingsProvider);
    if (!config.typewriterMode) return;
    if (!_editorScrollController.hasClients) return;

    final lineHeight = config.fontSize * config.lineHeight;
    final viewportHeight = _editorScrollController.position.viewportDimension;
    final targetOffset = (line * lineHeight) - (viewportHeight / 2) + (lineHeight / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _editorScrollController.position.maxScrollExtent,
    );

    _editorScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _onEditorScroll() {
    if (_isSyncingScroll) return;
    _isSyncingScroll = true;
    if (_gutterScrollController.hasClients) {
      _gutterScrollController.jumpTo(_editorScrollController.offset);
    }
    _isSyncingScroll = false;
  }

  int _getLineCount() {
    return '\n'.allMatches(_controller.text).length + 1;
  }

  void _applyFormat(FormatAction action) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (!selection.isValid) return;

    switch (action) {
      case FormatAction.bold:
        _wrapSelection('**', '**');
      case FormatAction.italic:
        _wrapSelection('*', '*');
      case FormatAction.strikethrough:
        _wrapSelection('~~', '~~');
      case FormatAction.heading1:
        _insertLinePrefix('# ');
      case FormatAction.heading2:
        _insertLinePrefix('## ');
      case FormatAction.heading3:
        _insertLinePrefix('### ');
      case FormatAction.heading4:
        _insertLinePrefix('#### ');
      case FormatAction.heading5:
        _insertLinePrefix('##### ');
      case FormatAction.heading6:
        _insertLinePrefix('###### ');
      case FormatAction.orderedList:
        _insertLinePrefix('1. ');
      case FormatAction.unorderedList:
        _insertLinePrefix('- ');
      case FormatAction.taskList:
        _insertLinePrefix('- [ ] ');
      case FormatAction.quoteBlock:
        _insertLinePrefix('> ');
      case FormatAction.codeBlock:
        _insertBlock('```\n', '\n```');
      case FormatAction.mathBlock:
        _insertBlock('\$\$\n', '\n\$\$');
      case FormatAction.table:
        _insertAtCursor(
          '| Column 1 | Column 2 | Column 3 |\n'
          '| -------- | -------- | -------- |\n'
          '|          |          |          |\n',
        );
      case FormatAction.link:
        if (selection.isCollapsed) {
          final offset = selection.baseOffset;
          const insert = '[text](url)';
          _controller.value = TextEditingValue(
            text: text.substring(0, offset) + insert + text.substring(offset),
            selection: TextSelection(baseOffset: offset + 1, extentOffset: offset + 5),
          );
        } else {
          final selected = text.substring(selection.start, selection.end);
          final replacement = '[$selected](url)';
          _controller.value = TextEditingValue(
            text: text.substring(0, selection.start) + replacement + text.substring(selection.end),
            selection: TextSelection(
              baseOffset: selection.start + selected.length + 3,
              extentOffset: selection.start + selected.length + 6,
            ),
          );
        }
      case FormatAction.image:
        if (selection.isCollapsed) {
          final offset = selection.baseOffset;
          const insert = '![alt](url)';
          _controller.value = TextEditingValue(
            text: text.substring(0, offset) + insert + text.substring(offset),
            selection: TextSelection(baseOffset: offset + 2, extentOffset: offset + 5),
          );
        } else {
          final selected = text.substring(selection.start, selection.end);
          final replacement = '![$selected](url)';
          _controller.value = TextEditingValue(
            text: text.substring(0, selection.start) + replacement + text.substring(selection.end),
            selection: TextSelection(
              baseOffset: selection.start + selected.length + 4,
              extentOffset: selection.start + selected.length + 7,
            ),
          );
        }
      case FormatAction.horizontalRule:
        _insertAtCursor('\n---\n');
    }

    setState(() {});
  }

  void _wrapSelection(String before, String after) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isCollapsed) {
      final offset = selection.baseOffset;
      final insert = '$before$after';
      _controller.value = TextEditingValue(
        text: text.substring(0, offset) + insert + text.substring(offset),
        selection: TextSelection.collapsed(offset: offset + before.length),
      );
    } else {
      final selected = text.substring(selection.start, selection.end);
      final replacement = '$before$selected$after';
      _controller.value = TextEditingValue(
        text: text.substring(0, selection.start) + replacement + text.substring(selection.end),
        selection: TextSelection(
          baseOffset: selection.start + before.length,
          extentOffset: selection.start + before.length + selected.length,
        ),
      );
    }
  }

  void _insertLinePrefix(String prefix) {
    final selection = _controller.selection;
    final text = _controller.text;
    final offset = selection.baseOffset.clamp(0, text.length);

    // Find the start of the current line
    int lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;

    _controller.value = TextEditingValue(
      text: text.substring(0, lineStart) + prefix + text.substring(lineStart),
      selection: TextSelection.collapsed(offset: offset + prefix.length),
    );
  }

  void _insertBlock(String before, String after) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isCollapsed) {
      final offset = selection.baseOffset;
      final insert = '$before$after';
      _controller.value = TextEditingValue(
        text: text.substring(0, offset) + insert + text.substring(offset),
        selection: TextSelection.collapsed(offset: offset + before.length),
      );
    } else {
      final selected = text.substring(selection.start, selection.end);
      final replacement = '$before$selected$after';
      _controller.value = TextEditingValue(
        text: text.substring(0, selection.start) + replacement + text.substring(selection.end),
        selection: TextSelection(
          baseOffset: selection.start + before.length,
          extentOffset: selection.start + before.length + selected.length,
        ),
      );
    }
  }

  void _insertAtCursor(String insert) {
    final selection = _controller.selection;
    final text = _controller.text;
    final offset = selection.baseOffset.clamp(0, text.length);

    _controller.value = TextEditingValue(
      text: text.substring(0, offset) + insert + text.substring(offset),
      selection: TextSelection.collapsed(offset: offset + insert.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineCount = _getLineCount();
    final config = ref.watch(settingsProvider);

    // Listen for pending format actions
    final editorState = ref.watch(editorProvider);
    if (editorState.pendingFormat != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFormat(editorState.pendingFormat!);
        ref.read(editorProvider.notifier).clearFormat();
      });
    }

    final editorStyle = TextStyle(
      fontFamily: config.fontFamily,
      fontSize: config.fontSize,
      height: config.lineHeight,
    );

    final gutterStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      fontFamily: config.fontFamily,
      fontSize: config.fontSize,
      height: config.lineHeight,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _gutterScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: lineCount,
              itemBuilder: (context, index) => Align(
                alignment: Alignment.centerRight,
                child: Text('${index + 1}', style: gutterStyle),
              ),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            scrollController: _editorScrollController,
            maxLines: null,
            expands: true,
            style: editorStyle,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(8),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}
