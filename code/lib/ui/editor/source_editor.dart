import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import 'highlighting_controller.dart';

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
  late HighlightingController _controller;
  late ScrollController _editorScrollController;
  late ScrollController _gutterScrollController;
  Timer? _debounce;
  bool _isSyncingScroll = false;
  bool _isInitialized = false;

  static const _autoPairs = <String, String>{
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
    '`': '`',
    '*': '*',
    '~': '~',
  };

  TextEditingController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = HighlightingController(
      text: widget.initialContent,
      headingColor: Colors.orange,
      boldColor: Colors.blue,
      codeColor: Colors.green,
      linkColor: Colors.cyan,
      defaultColor: Colors.white,
    );
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

      // Listen for TOC scroll-to-line requests
      ref.listenManual(editorProvider.select((s) => s.targetScrollLine), (prev, next) {
        if (next != null && _editorScrollController.hasClients) {
          final config = ref.read(settingsProvider);
          final lineHeight = config.fontSize * config.lineHeight;
          final offset = ((next - 1) * lineHeight).clamp(
            0.0,
            _editorScrollController.position.maxScrollExtent,
          );
          _editorScrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          ref.read(editorProvider.notifier).clearScrollTarget();
        }
      });
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final selection = _controller.selection;
    if (!selection.isValid) return KeyEventResult.ignored;
    final text = _controller.text;

    // Handle backspace: delete empty pairs
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (!selection.isCollapsed) return KeyEventResult.ignored;
      final offset = selection.baseOffset;
      if (offset <= 0 || offset >= text.length) return KeyEventResult.ignored;

      final before = text[offset - 1];
      final after = text[offset];
      // Check if cursor is between a matching pair
      if (_autoPairs[before] == after) {
        _controller.value = TextEditingValue(
          text: text.substring(0, offset - 1) + text.substring(offset + 1),
          selection: TextSelection.collapsed(offset: offset - 1),
        );
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Get the character for the key event
    final char = event.character;
    if (char == null || char.isEmpty) return KeyEventResult.ignored;

    // Check if it's an opening/self-closing pair character
    final closing = _autoPairs[char];
    if (closing == null) return KeyEventResult.ignored;

    // For symmetric pairs (", ', `, *, ~), skip if the char after cursor is
    // the same character and selection is collapsed — just move cursor forward
    if (char == closing && selection.isCollapsed) {
      final offset = selection.baseOffset;
      if (offset < text.length && text[offset] == char) {
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset + 1),
        );
        return KeyEventResult.handled;
      }
    }

    if (selection.isCollapsed) {
      // Insert pair and place cursor in the middle
      final offset = selection.baseOffset;
      _controller.value = TextEditingValue(
        text: text.substring(0, offset) + char + closing + text.substring(offset),
        selection: TextSelection.collapsed(offset: offset + char.length),
      );
    } else {
      // Wrap selection
      final start = selection.start;
      final end = selection.end;
      final selected = text.substring(start, end);
      _controller.value = TextEditingValue(
        text: text.substring(0, start) + char + selected + closing + text.substring(end),
        selection: TextSelection(
          baseOffset: start + char.length,
          extentOffset: start + char.length + selected.length,
        ),
      );
    }
    return KeyEventResult.handled;
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
      case FormatAction.underline:
        _wrapSelection('++', '++');
      case FormatAction.superscript:
        _wrapSelection('^', '^');
      case FormatAction.subscript:
        _wrapSelection('~', '~');
      case FormatAction.highlight:
        _wrapSelection('==', '==');
      case FormatAction.inlineCode:
        _wrapSelection('`', '`');
      case FormatAction.inlineMath:
        _wrapSelection('\$', '\$');
      case FormatAction.clearFormatting:
        if (!selection.isCollapsed) {
          final selected = text.substring(selection.start, selection.end);
          final cleaned = selected
              .replaceAll(RegExp(r'\*{1,3}|~~|`|==|\+\+|\^|~|\$'), '')
              .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
          _controller.value = TextEditingValue(
            text: text.substring(0, selection.start) + cleaned + text.substring(selection.end),
            selection: TextSelection(
              baseOffset: selection.start,
              extentOffset: selection.start + cleaned.length,
            ),
          );
        }
      case FormatAction.copyAsMarkdown:
        if (!selection.isCollapsed) {
          final selected = text.substring(selection.start, selection.end);
          Clipboard.setData(ClipboardData(text: selected));
        }
      case FormatAction.copyAsHtml:
        if (!selection.isCollapsed) {
          final selected = text.substring(selection.start, selection.end);
          var html = selected;
          html = html.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<strong>${m[1]}</strong>');
          html = html.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => '<em>${m[1]}</em>');
          html = html.replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => '<del>${m[1]}</del>');
          html = html.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => '<code>${m[1]}</code>');
          html = html.replaceAllMapped(RegExp(r'^#{6}\s+(.+)$', multiLine: true), (m) => '<h6>${m[1]}</h6>');
          html = html.replaceAllMapped(RegExp(r'^#{5}\s+(.+)$', multiLine: true), (m) => '<h5>${m[1]}</h5>');
          html = html.replaceAllMapped(RegExp(r'^#{4}\s+(.+)$', multiLine: true), (m) => '<h4>${m[1]}</h4>');
          html = html.replaceAllMapped(RegExp(r'^#{3}\s+(.+)$', multiLine: true), (m) => '<h3>${m[1]}</h3>');
          html = html.replaceAllMapped(RegExp(r'^#{2}\s+(.+)$', multiLine: true), (m) => '<h2>${m[1]}</h2>');
          html = html.replaceAllMapped(RegExp(r'^#\s+(.+)$', multiLine: true), (m) => '<h1>${m[1]}</h1>');
          Clipboard.setData(ClipboardData(text: html));
        }
      case FormatAction.selectAll:
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
      case FormatAction.duplicateLine:
        final offset = selection.baseOffset.clamp(0, text.length);
        int lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
        lineStart = lineStart == -1 ? 0 : lineStart + 1;
        int lineEnd = text.indexOf('\n', offset);
        lineEnd = lineEnd == -1 ? text.length : lineEnd;
        final currentLine = text.substring(lineStart, lineEnd);
        _controller.value = TextEditingValue(
          text: '${text.substring(0, lineEnd)}\n$currentLine${text.substring(lineEnd)}',
          selection: TextSelection.collapsed(offset: lineEnd + 1 + currentLine.length),
        );
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

    // Update highlighter colors from current theme
    final isDark = theme.brightness == Brightness.dark;
    _controller.headingColor = isDark ? const Color(0xFFE5C07B) : const Color(0xFFC18401);
    _controller.boldColor = isDark ? const Color(0xFF61AFEF) : const Color(0xFF4078F2);
    _controller.codeColor = isDark ? const Color(0xFF98C379) : const Color(0xFF50A14F);
    _controller.linkColor = isDark ? const Color(0xFF56B6C2) : const Color(0xFF0184BC);
    _controller.defaultColor = theme.colorScheme.onSurface;

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
          child: Focus(
            onKeyEvent: _handleKeyEvent,
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
        ),
      ],
    );
  }
}
