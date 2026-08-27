import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../../services/image_service.dart';
import '../../services/markdown_parser.dart' as md;
import 'highlighting_controller.dart';
import '../../services/keybinding_service.dart';
import '../../utils/platform_utils.dart';

class SourceEditor extends ConsumerStatefulWidget {
  final String initialContent;
  final ValueChanged<String>? onChanged;

  /// Which tab this editor is showing.
  ///
  /// Undo history is kept per tab; without this the editor would share one
  /// stack across every open document.
  final String tabId;

  /// Bumped by the owner when [initialContent] was changed by something other
  /// than this editor — a checkbox ticked in the split preview, say.
  ///
  /// The content alone cannot be used as the signal: the owner's copy lags the
  /// controller by one keystroke while typing, and adopting it then would eat
  /// the character just typed.
  final int externalRevision;

  const SourceEditor({
    super.key,
    required this.tabId,
    this.initialContent = '',
    this.externalRevision = 0,
    this.onChanged,
  });

  @override
  ConsumerState<SourceEditor> createState() => _SourceEditorState();

  /// Any list marker, ordered or not, with an optional task box.
  static final _listPrefixRe = RegExp(
    r'^(\s*)(?:[-*+]\s+(?:\[[ xX]\]\s+)?|\d+[.)]\s+)',
  );

  /// A blockquote marker.
  static final _quotePrefixRe = RegExp(r'^(\s*)>\s?');

  /// A list marker at the start of a line, capturing its indentation.
  static final _listMarkerRe = RegExp(r'^(\s*)(?:[-*+]|\d+[.)])\s+');

  /// Leading whitespace, hoisted like its two siblings above.
  static final _leadingSpaceRe = RegExp(r'^\s*');

  /// Applies [prefix] to [line].
  ///
  /// Toggles off when the line already starts with exactly this prefix, and
  /// replaces a prefix of the same family otherwise — so applying "bullet
  /// list" to `1. item` gives `- item`, not `- 1. item`. Leading indentation
  /// is preserved, since it carries list nesting.
  ///
  /// Exposed for testing: this is pure string work, and testing it through the
  /// widget would need a whole editor to assert one line.
  /// Result of toggling an inline wrapper.
  @visibleForTesting
  static ({String text, int start, int end}) toggleWrap(
    String text,
    int start,
    int end,
    String before,
    String after,
  ) {
    final selected = text.substring(start, end);

    // A doubled marker belongs to the longer syntax: `**bold**` must not read
    // as an italic wrapper whose content happens to begin with `*`. Applying
    // italic to bold text should nest, giving `***bold***`.
    final doubled = before == after && selected.startsWith(before + before);

    if (!doubled &&
        selected.length >= before.length + after.length &&
        selected.startsWith(before) &&
        selected.endsWith(after)) {
      final inner = selected.substring(
        before.length,
        selected.length - after.length,
      );
      return (
        text: text.substring(0, start) + inner + text.substring(end),
        start: start,
        end: start + inner.length,
      );
    }

    // The markers may sit just outside the selection, which is what happens
    // when the user selects the words rather than the syntax.
    final hasBefore =
        start >= before.length &&
        text.substring(start - before.length, start) == before;
    final hasAfter =
        end + after.length <= text.length &&
        text.substring(end, end + after.length) == after;

    if (hasBefore && hasAfter) {
      final newStart = start - before.length;
      return (
        text:
            text.substring(0, newStart) +
            selected +
            text.substring(end + after.length),
        start: newStart,
        end: newStart + selected.length,
      );
    }

    final replacement = before + selected + after;
    return (
      text: text.substring(0, start) + replacement + text.substring(end),
      start: start + before.length,
      end: start + before.length + selected.length,
    );
  }

  /// Switches the list around [line] between tight and loose.
  ///
  /// A loose list has a blank line between its items, which markdown renders
  /// with the items spaced apart; a tight one runs them together. Upstream
  /// carries this as a checkbox in its Paragraph menu.
  ///
  /// Returns [source] unchanged when the caret is not in a list, or the list
  /// has a single item — there is nothing between one item to space out.
  @visibleForTesting
  static String toggleLooseList(String source, int line) {
    md.ListNode? list;
    for (final node in md.MarkdownParser().parse(source)) {
      if (node is md.ListNode &&
          line >= node.sourceStart &&
          line < node.sourceEnd) {
        list = node;
        break;
      }
    }
    if (list == null) return source;

    final lines = const LineSplitter().convert(source);
    final block = lines.sublist(list.sourceStart, list.sourceEnd);

    // Only the outermost items are spaced: a nested item sits deeper and
    // belongs to the item above it.
    final firstIndent =
        _listMarkerRe.firstMatch(block.first)?.group(1)?.length ?? 0;
    final starts = <int>{};
    for (var i = 0; i < block.length; i++) {
      final match = _listMarkerRe.firstMatch(block[i]);
      if (match != null && match.group(1)!.length == firstIndent) starts.add(i);
    }
    if (starts.length < 2) return source;

    final rewritten = <String>[];
    if (list.isLoose) {
      for (var i = 0; i < block.length; i++) {
        if (block[i].trim().isEmpty) {
          // Drop it only when what follows is the next item: a blank line
          // inside an item separates that item's own paragraphs.
          var next = i + 1;
          while (next < block.length && block[next].trim().isEmpty) {
            next++;
          }
          if (next < block.length && starts.contains(next)) continue;
        }
        rewritten.add(block[i]);
      }
    } else {
      final first = starts.reduce((a, b) => a < b ? a : b);
      for (var i = 0; i < block.length; i++) {
        if (starts.contains(i) && i != first) rewritten.add('');
        rewritten.add(block[i]);
      }
    }

    final updated = [...lines]
      ..replaceRange(list.sourceStart, list.sourceEnd, rewritten);
    // LineSplitter drops the final terminator; put it back if it was there.
    return updated.join('\n') + (source.endsWith('\n') ? '\n' : '');
  }

  @visibleForTesting
  static String applyLinePrefix(String line, String prefix) {
    final family = prefix.trimLeft().startsWith('>')
        ? _quotePrefixRe
        : _listPrefixRe;

    final indent = _leadingSpaceRe.firstMatch(line)!.group(0)!;
    final body = line.substring(indent.length);

    final existing = family.firstMatch(line);
    if (existing == null) return indent + prefix + body;

    // Compare against the whole marker the family matched, not just the
    // string's start: `- [x] item` begins with `- `, but applying "bullet
    // list" to it should drop the task box, not leave `[x] item` behind.
    final existingPrefix = line.substring(indent.length, existing.end);
    if (existingPrefix == prefix) {
      return indent + line.substring(existing.end);
    }

    return indent + prefix + line.substring(existing.end);
  }
}

class _SourceEditorState extends ConsumerState<SourceEditor> {
  late HighlightingController _controller;
  late ScrollController _editorScrollController;
  late ScrollController _gutterScrollController;
  Timer? _debounce;
  bool _isSyncingScroll = false;
  bool _isInitialized = false;

  /// Held from [initState] so [dispose] can still reach it.
  ///
  /// `ref` is off limits by the time dispose runs — riverpod marks the element
  /// disposed before the framework calls it — and reaching for it there threw
  /// a StateError that the framework swallowed, which meant the handback below
  /// never happened at all.
  late final EditorNotifier _editorNotifier;

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
  void didUpdateWidget(SourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalRevision == oldWidget.externalRevision) return;
    if (widget.initialContent == _controller.text) return;

    // Keep the caret where it was, as far as the new text allows.
    final offset = _controller.selection.baseOffset;
    _controller.value = TextEditingValue(
      text: widget.initialContent,
      selection: TextSelection.collapsed(
        offset: offset < 0 ? 0 : offset.clamp(0, widget.initialContent.length),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _editorNotifier = ref.read(editorProvider.notifier);
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
      ref
          .read(editorProvider.notifier)
          .setEditorScrollController(_editorScrollController);
      ref.read(editorProvider.notifier)
        ..setHistoryTab(widget.tabId)
        ..pushHistory(widget.initialContent);
      _isInitialized = true;

      // Listen for TOC scroll-to-line requests
      ref.listenManual(
        editorProvider.select((s) => s.targetScrollLine),
        (prev, next) => _scrollToTargetLine(next),
      );

      // A search hit opens the file and asks for its line in one breath, so
      // the request lands before this editor exists and the listener above
      // never sees it change. Honour whatever is already pending.
      _scrollToTargetLine(ref.read(editorProvider).targetScrollLine);
    });
  }

  /// Scrolls so that [line] — 1-based — is at the top of the viewport.
  void _scrollToTargetLine(int? line) {
    if (line == null || !_editorScrollController.hasClients) return;

    final config = ref.read(settingsProvider);
    final lineHeight = config.fontSize * config.lineHeight;
    final targetOffset = ((line - 1) * lineHeight).clamp(
      0.0,
      _editorScrollController.position.maxScrollExtent,
    );

    final currentOffset = _editorScrollController.offset;
    final viewportHeight = _editorScrollController.position.viewportDimension;
    final distance = (targetOffset - currentOffset).abs();
    final duration = distance > viewportHeight * 2
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 200);

    _editorScrollController.animateTo(
      targetOffset,
      duration: duration,
      curve: Curves.easeOut,
    );
    ref.read(editorProvider.notifier).clearScrollTarget();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.removeListener(_onSelectionChanged);
    _editorScrollController.removeListener(_onEditorScroll);

    // Hand the registration back before disposing, or the provider keeps
    // pointing at a dead controller — which the find bar reads as "a source
    // editor is on screen".
    _editorNotifier.clearController(_controller);
    _editorNotifier.clearEditorScrollController(_editorScrollController);

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
      ref
          .read(editorProvider.notifier)
          .updateSelection(text.substring(start, end));
    }

    _scrollToTypewriterPosition(line);
  }

  void _scrollToTypewriterPosition(int line) {
    final config = ref.read(settingsProvider);
    if (!config.typewriterMode) return;
    if (!_editorScrollController.hasClients) return;

    final lineHeight = config.fontSize * config.lineHeight;
    final viewportHeight = _editorScrollController.position.viewportDimension;
    final targetOffset =
        (line * lineHeight) - (viewportHeight / 2) + (lineHeight / 2);
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
    if (_gutterScrollController.hasClients &&
        _gutterScrollController.position.hasContentDimensions) {
      final offset = _editorScrollController.offset.clamp(
        _gutterScrollController.position.minScrollExtent,
        _gutterScrollController.position.maxScrollExtent,
      );
      _gutterScrollController.jumpTo(offset);
    }
    _isSyncingScroll = false;
  }

  /// Applies whatever the user has bound [event] to, if it edits the document.
  ///
  /// Undo and redo go to the editor's own history, which is what the Edit
  /// menu shows and what the toolbar's enabled state reflects. Left to
  /// Flutter, Ctrl+Z would drive the TextField's private history instead and
  /// the two would disagree.
  bool _handleBoundShortcut(KeyEvent event) {
    final action = KeybindingService().actionForEvent(
      event,
      isMacOS: PlatformUtils.isMacOS,
    );
    if (action == null) return false;

    final editor = ref.read(editorProvider.notifier);
    if (action == 'undo') {
      editor.undo();
      return true;
    }
    if (action == 'redo') {
      editor.redo();
      return true;
    }

    // Everything else that edits text shares its name with a FormatAction.
    for (final format in FormatAction.values) {
      if (format.name == action) {
        _applyFormat(format);
        return true;
      }
    }
    return false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Editing shortcuts live here rather than at the window level so that
    // Ctrl+A, Ctrl+Z and the rest still belong to the find bar or a settings
    // field when that is where the caret is. This runs before Flutter's own
    // text-editing shortcuts, which sit at the app root: key events travel up
    // from the focused node, so this ancestor sees them first.
    if (_handleBoundShortcut(event)) return KeyEventResult.handled;

    final selection = _controller.selection;
    if (!selection.isValid) return KeyEventResult.ignored;
    final text = _controller.text;

    // Handle Ctrl+V / Cmd+V: try to paste image from clipboard
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _handleImagePaste();
      // We always return ignored here so the TextField can handle
      // text paste as normal. If it was an image, _handleImagePaste
      // will insert the markdown asynchronously.
      return KeyEventResult.ignored;
    }

    // Handle tab: indent rather than move focus.
    //
    // A TextField gives Tab to the focus traversal by default, so pressing it
    // in the editor jumped to the next control instead of indenting — and the
    // tab size setting had nothing reading it.
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final indent = ' ' * ref.read(settingsProvider).tabSize;

      if (HardwareKeyboard.instance.isShiftPressed) {
        _outdentSelection(indent.length);
      } else {
        _indentSelection(indent);
      }
      return KeyEventResult.handled;
    }

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
        text:
            text.substring(0, offset) + char + closing + text.substring(offset),
        selection: TextSelection.collapsed(offset: offset + char.length),
      );
    } else {
      // Wrap selection
      final start = selection.start;
      final end = selection.end;
      final selected = text.substring(start, end);
      _controller.value = TextEditingValue(
        text:
            text.substring(0, start) +
            char +
            selected +
            closing +
            text.substring(end),
        selection: TextSelection(
          baseOffset: start + char.length,
          extentOffset: start + char.length + selected.length,
        ),
      );
    }
    return KeyEventResult.handled;
  }

  /// The image settings, which used to be stored and then ignored.
  ({ImageStorageMode mode, String folder}) _imagePreferences() {
    final config = ref.read(settingsProvider);
    return (
      mode: ImageStorageMode.fromConfig(config.imageStorageMode),
      folder: config.imageFolder,
    );
  }

  Future<void> _handleImagePaste() async {
    final activeTab = ref.read(activeTabProvider);
    final prefs = _imagePreferences();
    final imagePath = await ImageService.pasteImageFromClipboard(
      activeTab?.filePath,
      mode: prefs.mode,
      folder: prefs.folder,
    );
    if (imagePath != null && mounted) {
      _insertAtCursor('![image]($imagePath)');
    }
  }

  Future<void> _handleImageDrop(DropDoneDetails details) async {
    final activeTab = ref.read(activeTabProvider);
    final prefs = _imagePreferences();
    for (final file in details.files) {
      if (!ImageService.isImageFile(file.path)) continue;

      final link = await ImageService.storeImage(
        file.path,
        activeTab?.filePath,
        mode: prefs.mode,
        folder: prefs.folder,
      );
      if (!mounted) return;
      _insertAtCursor('![image]($link)');
    }
  }

  int _getLineCount() {
    return '\n'.allMatches(_controller.text).length + 1;
  }

  /// Puts a YAML front matter block at the very top of the document.
  ///
  /// Front matter is only front matter when it is the first thing in the
  /// file, so this ignores where the caret happens to be. A document that
  /// already starts with one is left alone and the caret moves into it,
  /// rather than growing a second block that would parse as a horizontal
  /// rule.
  void _insertFrontMatter() {
    final text = _controller.text;
    final lines = text.split('\n');

    if (lines.isNotEmpty &&
        md.MarkdownParser.isFrontMatterOpener(lines.first)) {
      // Just past the opening delimiter and its newline. Measured rather than
      // fixed at 4, since `{` opens a block just as `---` does.
      final offset = lines.first.trimRight().length + 1;
      _controller.selection = TextSelection.collapsed(offset: offset);
      return;
    }

    const block = '---\ntitle: \n---\n\n';
    _controller.value = TextEditingValue(
      text: block + text,
      // Just after "title: ", ready to type.
      selection: const TextSelection.collapsed(offset: 11),
    );
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
        _setHeadingLevel(1);
      case FormatAction.heading2:
        _setHeadingLevel(2);
      case FormatAction.heading3:
        _setHeadingLevel(3);
      case FormatAction.heading4:
        _setHeadingLevel(4);
      case FormatAction.heading5:
        _setHeadingLevel(5);
      case FormatAction.heading6:
        _setHeadingLevel(6);
      case FormatAction.promoteHeading:
        _shiftHeadingLevel(-1);
      case FormatAction.demoteHeading:
        _shiftHeadingLevel(1);
      case FormatAction.toParagraph:
        _setHeadingLevel(null);
      case FormatAction.orderedList:
        _applyLinePrefixAtCursor('1. ');
      case FormatAction.unorderedList:
        // The configured marker, which nothing was reading: choosing * or +
        // in settings still produced a dash.
        _applyLinePrefixAtCursor(
          '${ref.read(settingsProvider).bulletListMarker} ',
        );
      case FormatAction.taskList:
        _applyLinePrefixAtCursor('- [ ] ');
      case FormatAction.quoteBlock:
        _applyLinePrefixAtCursor('> ');
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
            selection: TextSelection(
              baseOffset: offset + 1,
              extentOffset: offset + 5,
            ),
          );
        } else {
          final selected = text.substring(selection.start, selection.end);
          final replacement = '[$selected](url)';
          _controller.value = TextEditingValue(
            text:
                text.substring(0, selection.start) +
                replacement +
                text.substring(selection.end),
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
            selection: TextSelection(
              baseOffset: offset + 2,
              extentOffset: offset + 5,
            ),
          );
        } else {
          final selected = text.substring(selection.start, selection.end);
          final replacement = '![$selected](url)';
          _controller.value = TextEditingValue(
            text:
                text.substring(0, selection.start) +
                replacement +
                text.substring(selection.end),
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
      case FormatAction.frontMatter:
        _insertFrontMatter();
      case FormatAction.htmlBlock:
        _insertAtCursor('<div>\n\n</div>');
      case FormatAction.looseList:
        _toggleLooseList();
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
            text:
                text.substring(0, selection.start) +
                cleaned +
                text.substring(selection.end),
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
          html = html.replaceAllMapped(
            RegExp(r'\*\*(.+?)\*\*'),
            (m) => '<strong>${m[1]}</strong>',
          );
          html = html.replaceAllMapped(
            RegExp(r'\*(.+?)\*'),
            (m) => '<em>${m[1]}</em>',
          );
          html = html.replaceAllMapped(
            RegExp(r'~~(.+?)~~'),
            (m) => '<del>${m[1]}</del>',
          );
          html = html.replaceAllMapped(
            RegExp(r'`(.+?)`'),
            (m) => '<code>${m[1]}</code>',
          );
          html = html.replaceAllMapped(
            RegExp(r'^#{6}\s+(.+)$', multiLine: true),
            (m) => '<h6>${m[1]}</h6>',
          );
          html = html.replaceAllMapped(
            RegExp(r'^#{5}\s+(.+)$', multiLine: true),
            (m) => '<h5>${m[1]}</h5>',
          );
          html = html.replaceAllMapped(
            RegExp(r'^#{4}\s+(.+)$', multiLine: true),
            (m) => '<h4>${m[1]}</h4>',
          );
          html = html.replaceAllMapped(
            RegExp(r'^#{3}\s+(.+)$', multiLine: true),
            (m) => '<h3>${m[1]}</h3>',
          );
          html = html.replaceAllMapped(
            RegExp(r'^#{2}\s+(.+)$', multiLine: true),
            (m) => '<h2>${m[1]}</h2>',
          );
          html = html.replaceAllMapped(
            RegExp(r'^#\s+(.+)$', multiLine: true),
            (m) => '<h1>${m[1]}</h1>',
          );
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
          text:
              '${text.substring(0, lineEnd)}\n$currentLine${text.substring(lineEnd)}',
          selection: TextSelection.collapsed(
            offset: lineEnd + 1 + currentLine.length,
          ),
        );
    }

    setState(() {});
  }

  void _wrapSelection(String before, String after) {
    final selection = _controller.selection;
    final text = _controller.text;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(start, text.length);

    final result = SourceEditor.toggleWrap(text, start, end, before, after);

    _controller.value = TextEditingValue(
      text: result.text,
      selection: result.start == result.end
          ? TextSelection.collapsed(offset: result.start)
          : TextSelection(baseOffset: result.start, extentOffset: result.end),
    );
  }

  /// Matches a heading marker at the start of a line.
  static final _headingPrefixRe = RegExp(r'^(#{1,6})\s+');

  /// Sets the current line's heading level, or clears it when [level] is null.
  ///
  /// Replaces any marker already there. Prepending unconditionally — which is
  /// what the heading actions used to do — turned `# Title` into `## # Title`
  /// rather than changing its level.
  void _setHeadingLevel(int? level) {
    final selection = _controller.selection;
    final text = _controller.text;
    final offset = selection.baseOffset.clamp(0, text.length);

    var lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    var lineEnd = text.indexOf('\n', lineStart);
    if (lineEnd == -1) lineEnd = text.length;

    final line = text.substring(lineStart, lineEnd);
    final existing = _headingPrefixRe.firstMatch(line);
    final body = existing == null ? line : line.substring(existing.end);

    final replacement = level == null ? body : '${'#' * level} $body';
    final delta = replacement.length - line.length;

    _controller.value = TextEditingValue(
      text:
          text.substring(0, lineStart) + replacement + text.substring(lineEnd),
      selection: TextSelection.collapsed(
        offset: (offset + delta).clamp(
          lineStart,
          lineStart + replacement.length,
        ),
      ),
    );
  }

  /// Current line's heading level, or 0 when it is not a heading.
  int _currentHeadingLevel() {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset.clamp(0, text.length);

    var lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    var lineEnd = text.indexOf('\n', lineStart);
    if (lineEnd == -1) lineEnd = text.length;

    final match = _headingPrefixRe.firstMatch(
      text.substring(lineStart, lineEnd),
    );
    return match == null ? 0 : match.group(1)!.length;
  }

  /// Moves the current line up or down the heading scale.
  ///
  /// Promoting (negative [delta]) past H1 turns the line back into a
  /// paragraph; demoting a paragraph starts it at H1. Demoting past H6 does
  /// nothing, since there is no deeper level to reach.
  void _shiftHeadingLevel(int delta) {
    final current = _currentHeadingLevel();

    if (current == 0) {
      if (delta > 0) _setHeadingLevel(1);
      return;
    }

    final next = current + delta;
    if (next < 1) {
      _setHeadingLevel(null);
    } else if (next <= 6) {
      _setHeadingLevel(next);
    }
  }

  /// Inserts [indent] at the cursor, or in front of every selected line.
  void _indentSelection(String indent) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isCollapsed) {
      final offset = selection.baseOffset;
      _controller.value = TextEditingValue(
        text: text.substring(0, offset) + indent + text.substring(offset),
        selection: TextSelection.collapsed(offset: offset + indent.length),
      );
      return;
    }

    final (start, end) = _selectedLineBounds();
    final lines = text.substring(start, end).split('\n');
    final replacement = lines.map((line) => '$indent$line').join('\n');

    _controller.value = TextEditingValue(
      text: text.substring(0, start) + replacement + text.substring(end),
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + replacement.length,
      ),
    );
  }

  /// Removes up to [width] columns of indentation from the affected lines.
  void _outdentSelection(int width) {
    final text = _controller.text;
    final (start, end) = _selectedLineBounds();
    final lines = text.substring(start, end).split('\n');

    final replacement = lines
        .map((line) {
          var removed = 0;
          var index = 0;
          while (index < line.length && removed < width && line[index] == ' ') {
            removed++;
            index++;
          }
          return line.substring(index);
        })
        .join('\n');

    _controller.value = TextEditingValue(
      text: text.substring(0, start) + replacement + text.substring(end),
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + replacement.length,
      ),
    );
  }

  /// Start and end offsets of the whole lines the selection touches.
  (int, int) _selectedLineBounds() {
    final selection = _controller.selection;
    final text = _controller.text;

    var start = text.lastIndexOf(
      '\n',
      selection.start > 0 ? selection.start - 1 : 0,
    );
    start = start == -1 ? 0 : start + 1;

    var end = text.indexOf('\n', selection.end);
    if (end == -1) end = text.length;

    return (start, end);
  }

  /// Applies [SourceEditor.toggleLooseList] to the document at the caret.
  void _toggleLooseList() {
    final text = _controller.text;
    final caret = _controller.selection.baseOffset.clamp(0, text.length);
    final before = text.substring(0, caret);
    final line = '\n'.allMatches(before).length;

    final updated = SourceEditor.toggleLooseList(text, line);
    if (updated == text) return;

    // Follow the caret's *content* line, not its line number: the toggle adds
    // or removes blank lines above it. Only blank lines change, so counting
    // non-blank lines identifies the same line in both texts.
    final oldLines = text.split('\n');
    final column = caret - (before.lastIndexOf('\n') + 1);
    var contentIndex = 0;
    for (var i = 0; i < line && i < oldLines.length; i++) {
      if (oldLines[i].trim().isNotEmpty) contentIndex++;
    }

    final newLines = updated.split('\n');
    var offset = 0;
    var seen = 0;
    for (var i = 0; i < newLines.length; i++) {
      if (newLines[i].trim().isEmpty) {
        offset += newLines[i].length + 1;
        continue;
      }
      if (seen == contentIndex) break;
      seen++;
      offset += newLines[i].length + 1;
    }

    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: (offset + column).clamp(0, updated.length),
      ),
    );
  }

  void _applyLinePrefixAtCursor(String prefix) {
    final selection = _controller.selection;
    final text = _controller.text;
    final offset = selection.baseOffset.clamp(0, text.length);

    var lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    var lineEnd = text.indexOf('\n', lineStart);
    if (lineEnd == -1) lineEnd = text.length;

    final line = text.substring(lineStart, lineEnd);
    final replacement = SourceEditor.applyLinePrefix(line, prefix);
    final delta = replacement.length - line.length;

    _controller.value = TextEditingValue(
      text:
          text.substring(0, lineStart) + replacement + text.substring(lineEnd),
      selection: TextSelection.collapsed(
        offset: (offset + delta).clamp(
          lineStart,
          lineStart + replacement.length,
        ),
      ),
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
        text:
            text.substring(0, selection.start) +
            replacement +
            text.substring(selection.end),
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
    final lineCount = _getLineCount();
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);

    // Watch only fields used by build to avoid unrelated rebuilds during scroll
    final pendingFormat = ref.watch(
      editorProvider.select((s) => s.pendingFormat),
    );
    if (pendingFormat != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFormat(pendingFormat);
        ref.read(editorProvider.notifier).clearFormat();
      });
    }

    final editorStyle = TextStyle(
      fontFamily: config.fontFamily,
      fontSize: config.fontSize,
      height: config.lineHeight,
    );

    // Update highlighter colors from theme tokens
    _controller.headingColor = tokens.syntaxHeading;
    _controller.boldColor = tokens.syntaxBold;
    _controller.codeColor = tokens.syntaxCode;
    _controller.linkColor = tokens.syntaxLink;
    _controller.defaultColor = tokens.colorText;
    _controller.quoteColor = tokens.syntaxQuote;
    _controller.commentColor = tokens.syntaxComment;

    // Dynamic gutter width
    final digits = lineCount < 10
        ? 1
        : (lineCount < 100 ? 2 : (lineCount < 1000 ? 3 : 4));
    final gutterWidth = (digits * 10.0 + 20).clamp(50.0, 70.0);

    // Current line for highlighting
    final currentLine = ref.watch(editorProvider.select((s) => s.cursorLine));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: gutterWidth,
          decoration: BoxDecoration(
            color: tokens.colorSurface,
            border: Border(
              right: BorderSide(color: tokens.colorBorder, width: 1),
            ),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              physics: const ClampingScrollPhysics(),
            ),
            child: ListView.builder(
              controller: _gutterScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: lineCount,
              itemExtent: config.fontSize * config.lineHeight,
              itemBuilder: (context, index) => Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: index == currentLine
                        ? tokens.colorText
                        : tokens.colorTextMuted,
                    fontFamily: config.fontFamily,
                    fontSize: 12,
                    height: config.lineHeight,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref
                      .read(editorProvider.notifier)
                      .setEditorTextFieldWidth(constraints.maxWidth);
                }
              });

              return Focus(
                onKeyEvent: _handleKeyEvent,
                child: DropTarget(
                  onDragDone: _handleImageDrop,
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
              );
            },
          ),
        ),
      ],
    );
  }
}
