import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight_core.dart' show Node;

import 'code_highlighting.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tab_info.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/text_search_service.dart';
import '../../providers/tab_provider.dart';
import '../../services/markdown_parser.dart' as md;
import '../../services/export_service.dart';
import '../../services/clipboard_service.dart';
import 'mermaid/parser/mermaid_parser.dart';
import '../widgets/mermaid_renderer.dart';
import '../../services/file_service.dart';

class MarkdownRenderer extends ConsumerStatefulWidget {
  final String markdown;

  /// Called with the whole updated document when the preview edits it —
  /// a block edited in place, or a task checkbox toggled.
  ///
  /// Leaving this null keeps the preview read-only.
  final ValueChanged<String>? onSourceChanged;

  const MarkdownRenderer({
    super.key,
    required this.markdown,
    this.onSourceChanged,
  });

  @override
  ConsumerState<MarkdownRenderer> createState() => _MarkdownRendererState();
}

class _MarkdownRendererState extends ConsumerState<MarkdownRenderer> {
  // Maps source line number → GlobalKey, used for TOC scroll targeting.
  // Build phase rebuilds this map fresh per pass to avoid stale duplicates.
  final _headingKeys = <int, GlobalKey>{};
  int _matchCounter = 0;
  final _recognizers = <TapGestureRecognizer>[];
  /// Rebuilt when the inline-HTML setting changes, which is the only thing
  /// that alters how a parser reads the same text.
  md.MarkdownParser _inlineParser = md.MarkdownParser();

  // AST cache — only re-parse when markdown content changes
  String? _cachedMarkdown;
  List<md.MarkdownNode>? _cachedNodes;
  List<int>? _cachedHeadingLines;

  // In-place block editing state. Null means nothing is being edited.
  md.MarkdownNode? _editingNode;
  final _editController = TextEditingController();
  late final FocusNode _editFocusNode;

  // Progressive rendering state.
  //
  // Every frame rebuilds all the blocks rendered so far, so adding a fixed 50
  // per frame made the total work quadratic: a 5000-block document took 100
  // frames and built about 250000 widgets. Doubling gets to the same place in
  // eight frames.
  /// The document whose full parse is still owed, when only a prefix of it has
  /// been parsed so far. Null when what is cached is the whole thing.
  String? _awaitingFullParse;

  int _renderedNodeCount = 0;
  bool _batchScheduled = false;
  static const _initialBatchSize = 50;
  static const _maxBatchSize = 2000;

  /// One [GlobalKey] per heading position, kept between frames.
  ///
  /// These used to be allocated fresh on every build, which changes each
  /// heading's identity and forces Flutter to discard and rebuild its element
  /// every frame. Keys are per *index* rather than per line so that two
  /// headings reported on the same line still get distinct keys — the same
  /// GlobalKey appearing twice in one tree is a crash.
  final _headingKeysByIndex = <int, GlobalKey>{};

  /// Parse raw markdown to find heading line numbers (1-based),
  /// matching the same logic used by the TOC panel.
  List<int> _findHeadingLines(String markdown) {
    return md.MarkdownParser.headingOutline(markdown)
        .map((heading) => heading.line)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _editFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _cancelEdit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    // Clicking away commits, matching how the source editor behaves.
    _editFocusNode.addListener(() {
      if (!_editFocusNode.hasFocus) _commitEdit();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        editorProvider.select((s) => s.targetScrollLine),
        (prev, next) => _scrollToTargetLine(next),
      );

      // A request made before this widget existed — the search panel opening a
      // file and asking for its line in one breath — never reaches the
      // listener above, which only fires on a change.
      _scrollToTargetLine(ref.read(editorProvider).targetScrollLine);
    });
  }

  void _scrollToTargetLine(int? line) {
    if (line == null) return;

    final key = _keyForLine(line);
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    ref.read(editorProvider.notifier).clearScrollTarget();
  }

  /// The key of the block the preview should scroll to for source [line].
  ///
  /// Only headings carry a key — giving every block one would mean a GlobalKey
  /// per node, which is exactly the per-node cost the progressive renderer
  /// exists to avoid. A search hit lands on an ordinary line, so it falls back
  /// to the heading above it: near enough to read from, and free.
  GlobalKey? _keyForLine(int line) {
    final exact = _headingKeys[line];
    if (exact != null) return exact;

    var best = -1;
    GlobalKey? bestKey;
    for (final entry in _headingKeys.entries) {
      if (entry.key <= line && entry.key > best) {
        best = entry.key;
        bestKey = entry.value;
      }
    }
    return bestKey;
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// Follows a link from the preview: a web address in the browser, a relative
  /// path as a new tab.
  ///
  /// Everything here can fail on input the document is free to contain.
  /// `Uri.parse` throws on `http://[bad` and on a non-numeric port,
  /// `launchUrl` throws when the desktop has no handler registered for the
  /// scheme, and reading a neighbouring file can fail on permissions. None of
  /// the three call sites awaits this, so a throw used to escape as an
  /// unhandled asynchronous error with nothing shown to the person clicking.
  Future<void> _openLink(String href) async {
    try {
      await _followLink(href);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.linkOpenFailed)),
      );
    }
  }

  Future<void> _followLink(String href) async {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      final uri = Uri.tryParse(href);
      if (uri == null) throw FormatException('not a URI', href);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw StateError('no handler for $href');
      return;
    }

    final activeTabId = ref.read(tabProvider).activeTabId;
    final activeTab = ref
        .read(tabProvider)
        .tabs
        .where((tab) => tab.id == activeTabId)
        .firstOrNull;
    final baseDir = activeTab?.filePath != null
        ? p.dirname(activeTab!.filePath!)
        : null;
    final resolvedPath = baseDir != null
        ? p.normalize(p.join(baseDir, href))
        : p.normalize(href);
    final file = File(resolvedPath);
    if (!file.existsSync()) return;

    final opened = await FileService().readFileWithLineEnding(resolvedPath);
    ref
        .read(tabProvider.notifier)
        .addTab(
          TabInfo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            filePath: resolvedPath,
            fileName: p.basename(resolvedPath),
            content: opened.content,
            lineEnding: opened.lineEnding,
            encoding: opened.encoding,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final theme = Theme.of(context);
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);
    // Only the preview's search state, not the whole of it. Watching the whole
    // provider meant every cursor move and every change of selection in the
    // source pane rebuilt the entire preview — in split view, on every arrow
    // key — and the preview rebuilds every block it has rendered so far.
    ref.watch(
      editorProvider.select(
        (s) => (
          s.previewSearchQuery,
          s.previewSearchCaseSensitive,
          s.previewSearchWholeWord,
          s.previewSearchUseRegex,
          s.previewCurrentMatchIndex,
        ),
      ),
    );

    // Also when the inline-HTML setting changes: the text is the same but the
    // parse is not, and without this the preview kept the old rendering until
    // the next keystroke.
    if (_inlineParser.enableHtml != config.enableHtml) {
      _inlineParser = md.MarkdownParser(enableHtml: config.enableHtml);
      _cachedMarkdown = null;
    }

    // Only re-parse when markdown content actually changes
    if (_cachedMarkdown != widget.markdown) {
      _cachedMarkdown = widget.markdown;
      final parser = md.MarkdownParser(enableHtml: config.enableHtml);
      // A long document is parsed in two goes: enough of the top to put
      // something on screen, then the whole of it on the next frame. Parsing
      // costs about 0.02–0.04 ms a block and has no hot spot left to remove,
      // so a five megabyte document took about three seconds during which
      // there was nothing to look at. The prefix keeps the document's own line
      // numbering, so the blocks it yields carry the ranges that editing a
      // block in the preview depends on.
      final prefix = md.MarkdownParser.safePrefix(widget.markdown);
      _cachedNodes = parser.parse(prefix ?? widget.markdown);
      _awaitingFullParse = prefix == null ? null : widget.markdown;
      if (_awaitingFullParse != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _finishParse());
      }
      _cachedHeadingLines = _findHeadingLines(widget.markdown);
      // Keep what is already on screen. Restarting from the first batch made
      // the preview collapse to the top of the document and re-expand on
      // every keystroke in split mode.
      _renderedNodeCount = _renderedNodeCount.clamp(0, _cachedNodes!.length);
      // The node being edited belonged to the previous parse and its line
      // range no longer describes this document.
      _editingNode = null;
    }
    final nodes = _cachedNodes!;
    final headingLines = _cachedHeadingLines!;

    // Progressive rendering: show the first blocks immediately, then fill in.
    if (_renderedNodeCount == 0) {
      _renderedNodeCount = nodes.length > _initialBatchSize
          ? _initialBatchSize
          : nodes.length;
    }
    if (_renderedNodeCount < nodes.length) {
      _scheduleNextBatch(nodes.length);
    }

    final widgets = <Widget>[];
    _matchCounter = 0;
    // Rebuild heading key map fresh each frame so duplicate or unknown
    // line numbers can't share the same GlobalKey across siblings.
    _headingKeys.clear();

    int headingIndex = 0;
    for (int i = 0; i < _renderedNodeCount; i++) {
      final node = nodes[i];
      switch (node) {
        case md.HeadingNode():
          final lineNum = headingIndex < headingLines.length
              ? headingLines[headingIndex]
              : -1;
          headingIndex++;
          // Always allocate a fresh key for each heading; only the first
          // heading at a given lineNum is registered for scroll targeting.
          final key = _headingKeysByIndex.putIfAbsent(
            headingIndex - 1,
            () => GlobalKey(),
          );
          if (lineNum > 0) {
            _headingKeys.putIfAbsent(lineNum, () => key);
          }
          widgets.add(
            _wrapEditable(node, tokens, _buildHeading(node, theme, tokens, key: key)),
          );
        case md.ParagraphNode():
          widgets.add(_wrapEditable(node, tokens, _buildParagraph(node, theme)));
        case md.CodeBlockNode():
          widgets.add(
            _wrapEditable(node, tokens, _buildCodeBlock(node, theme, tokens)),
          );
        case md.ListNode():
          widgets.add(_wrapEditable(node, tokens, _buildList(node, theme)));
        case md.BlockquoteNode():
          widgets.add(
            _wrapEditable(node, tokens, _buildBlockquote(node, theme, tokens)),
          );
        case md.HorizontalRuleNode():
          widgets.add(
            _wrapEditable(
              node,
              tokens,
              Divider(thickness: 1, color: tokens.colorBorder),
            ),
          );
        case md.TableNode():
          widgets.add(_wrapEditable(node, tokens, _buildTable(node, theme)));
        case md.MathBlockNode():
          widgets.add(_wrapEditable(node, tokens, _buildMathBlock(node, theme)));
        case md.FrontMatterNode():
          widgets.add(_wrapEditable(node, tokens, _buildFrontMatter(node, theme)));
        case md.FootnoteDefinitionNode():
          widgets.add(
            _wrapEditable(node, tokens, _buildFootnoteDefinition(node, theme)),
          );
        case md.HtmlBlockNode():
          widgets.add(_wrapEditable(node, tokens, _buildHtmlBlock(node, theme)));
      }
    }

    // Add loading indicator if more nodes are pending
    if (_renderedNodeCount < nodes.length) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyC &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          // Let SelectionArea handle the copy first, then enhance with HTML format
          Future.delayed(
            const Duration(milliseconds: 100),
            () => _enhanceClipboardWithHtml(),
          );
        }
        return KeyEventResult.ignored;
      },
      child: SingleChildScrollView(
        child: SelectionArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: config.editorMaxWidth.toDouble(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widgets,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Flips the checkbox marker on one task line and writes the list back.
  ///
  /// The parser consumes exactly one source line per list item, so item
  /// [index] is line [index] of the list's own source.
  void _toggleTask(md.ListNode node, int index, bool checked) {
    final onChanged = widget.onSourceChanged;
    if (onChanged == null) return;

    final lines = md.MarkdownParser.sourceOfBlock(
      widget.markdown,
      node,
    ).split('\n');
    if (index < 0 || index >= lines.length) return;

    final line = lines[index];
    final updated = checked
        ? line.replaceFirst(RegExp(r'\[\s\]'), '[x]')
        : line.replaceFirst(RegExp(r'\[[xX]\]'), '[ ]');
    if (updated == line) return;

    lines[index] = updated;
    onChanged(
      md.MarkdownParser.replaceBlock(widget.markdown, node, lines.join('\n')),
    );
  }

  // ------------------------------------------------------- in-place editing

  /// Wraps a rendered block so a double tap swaps it for its markdown source.
  ///
  /// Double tap rather than single: the preview sits inside a SelectionArea,
  /// and a single tap would fight text selection and link taps.
  Widget _wrapEditable(
      md.MarkdownNode node, AppThemeTokens tokens, Widget child) {
    if (widget.onSourceChanged == null) return child;

    if (identical(_editingNode, node)) {
      return _buildBlockEditor(node);
    }

    // A task list has its own tap targets. Wrapping it in a double-tap
    // recogniser puts that recogniser in the gesture arena, where it holds on
    // for the double-tap timeout before conceding — so every checkbox would
    // sit dead for ~300ms before responding. Ticking a box is the far more
    // frequent action, so it wins: these blocks stay directly interactive and
    // are edited from the source pane instead.
    if (node is md.ListNode && node.items.any((item) => item.isTask)) {
      return child;
    }

    // A diagram is the same story: its toolbar has four buttons, and every one
    // of them sat dead for the double-tap timeout while the recogniser waited
    // to see whether a second tap was coming. It carries its own "edit source"
    // button, so it needs the gesture even less than a task list does.
    if (node is md.CodeBlockNode &&
        MermaidParser.handlesLanguage(node.language)) {
      return child;
    }

    return PreviewEditableBlock(
      hoverColor: tokens.colorSurfaceHover,
      onEdit: () => _startEditing(node),
      child: child,
    );
  }

  /// Replaces the prefix parsed for the first frame with the whole document.
  ///
  /// Gives up quietly if the document changed in the meantime — the next build
  /// has already started its own parse, and finishing this one would put the
  /// previous document back on screen.
  void _finishParse() {
    final source = _awaitingFullParse;
    if (source == null || !mounted || source != widget.markdown) return;
    _awaitingFullParse = null;

    final config = ref.read(settingsProvider);
    final nodes =
        md.MarkdownParser(enableHtml: config.enableHtml).parse(source);
    if (!mounted) return;
    setState(() {
      _cachedNodes = nodes;
      // Whatever is already on screen stays on screen; the rest fills in the
      // way it does for a document that was parsed in one go.
      _renderedNodeCount = _renderedNodeCount.clamp(0, nodes.length);
    });
  }

  void _startEditing(md.MarkdownNode node) {
    // Whatever holds focus has to give it up first. A double tap comes from a
    // gesture recogniser, which never takes focus; the diagram's "edit source"
    // button is a real button and does. Leaving it focused while an editor
    // that commits on losing focus mounts beside it is asking for the editor
    // to close the moment focus settles.
    FocusManager.instance.primaryFocus?.unfocus();

    final source = md.MarkdownParser.sourceOfBlock(widget.markdown, node);
    _editController.value = TextEditingValue(
      text: source,
      selection: TextSelection.collapsed(offset: source.length),
    );
    setState(() => _editingNode = node);
    // Focus after the editor exists in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editFocusNode.requestFocus();
    });
  }

  /// Writes the edited text back into the document.
  ///
  /// Clearing [_editingNode] before unfocusing is what stops [_cancelEdit]
  /// from committing through the focus listener.
  void _commitEdit() {
    final node = _editingNode;
    if (node == null) return;
    _editingNode = null;

    final updated = md.MarkdownParser.replaceBlock(
      widget.markdown,
      node,
      _editController.text,
    );

    if (updated == widget.markdown) {
      if (mounted) setState(() {});
      return;
    }
    widget.onSourceChanged?.call(updated);
  }

  void _cancelEdit() {
    if (_editingNode == null) return;
    setState(() => _editingNode = null);
    _editFocusNode.unfocus();
  }

  Widget _buildBlockEditor(md.MarkdownNode node) {
    final config = ref.read(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.colorAccent),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: TextField(
        controller: _editController,
        focusNode: _editFocusNode,
        maxLines: null,
        autofocus: true,
        style: TextStyle(
          fontFamily: config.codeFontFamily,
          fontFamilyFallback: const ['monospace'],
          fontSize: config.fontSize,
          height: config.lineHeight,
          color: tokens.colorText,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Future<void> _enhanceClipboardWithHtml() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final selectedText = data?.text;
    if (selectedText == null || selectedText.isEmpty) return;

    // Convert selected markdown text to HTML
    final html = _selectedTextToHtml(selectedText);
    await ClipboardService.copyWithHtml(selectedText, html);
  }

  String _selectedTextToHtml(String markdown) {
    final parser = md.MarkdownParser();
    final nodes = parser.parse(markdown);
    final buffer = StringBuffer();
    for (final node in nodes) {
      buffer.writeln(ExportService.nodeToHtml(node));
    }
    return buffer.toString();
  }

  void _scheduleNextBatch(int totalNodes) {
    if (_batchScheduled) return;
    _batchScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _batchScheduled = false;
      if (!mounted || _renderedNodeCount >= totalNodes) return;
      setState(() {
        final step = _renderedNodeCount < _maxBatchSize
            ? _renderedNodeCount
            : _maxBatchSize;
        _renderedNodeCount = (_renderedNodeCount + step).clamp(0, totalNodes);
      });
      // The next build schedules the batch after this one, if any is left.
    });
  }

  Widget _buildHeading(
    md.HeadingNode node,
    ThemeData theme,
    AppThemeTokens tokens, {
    Key? key,
  }) {
    final style = switch (node.level) {
      1 => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: tokens.colorText,
      ),
      2 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: tokens.colorText,
      ),
      3 => TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: tokens.colorText,
      ),
      _ => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: tokens.colorTextMuted,
      ),
    };

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            _buildInlineSpans(node.inlineSpans, theme, style),
            style: style,
            strutStyle: StrutStyle(
              fontSize: style.fontSize,
              height: style.height ?? 1.4,
              forceStrutHeight: true,
            ),
          ),
          if (node.level == 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Divider(
                height: 1,
                thickness: 1,
                color: tokens.colorBorder,
              ),
            ),
        ],
      ),
    );
  }

  static final _defaultTextStyle = TextStyle(
    fontSize: 16,
    height: 1.6,
    leadingDistribution: TextLeadingDistribution.even,
    fontFamilyFallback: AppTheme.platformFontFallback,
  );
  static final _defaultStrutStyle = StrutStyle(
    fontSize: 16,
    height: 1.6,
    forceStrutHeight: true,
    leadingDistribution: TextLeadingDistribution.even,
    fontFamilyFallback: AppTheme.platformFontFallback,
  );

  Widget _buildParagraph(md.ParagraphNode node, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text.rich(
        _buildInlineSpans(node.inlineSpans, theme, _defaultTextStyle),
        strutStyle: _defaultStrutStyle,
      ),
    );
  }

  Widget _buildCodeBlock(
    md.CodeBlockNode node,
    ThemeData theme,
    AppThemeTokens tokens,
  ) {
    final lang = node.language.toLowerCase();
    // Asks the parser what it can draw rather than keeping a second list here,
    // which drifted out of step with the parser as types were implemented.
    if (MermaidParser.handlesLanguage(lang)) {
      return MermaidRenderer(
        code: node.code,
        isDarkMode: theme.brightness == Brightness.dark,
        // Its own double tap opens fullscreen, so the diagram gets a toolbar
        // button instead of the gesture every other block is edited by.
        onEditSource: widget.onSourceChanged == null
            ? null
            : () => _startEditing(node),
      );
    }

    final baseCodeStyle = _codeStyle();
    // Skip highlighting for very large blocks to keep first-render responsive
    final canHighlight = node.language.isNotEmpty && node.code.length <= 20000;

    final wraps = ref.read(settingsProvider).wrapCodeBlocks;

    Widget body = canHighlight
        ? Text.rich(
            TextSpan(
              style: _buildCodeTextStyle(baseCodeStyle),
              children: _buildHighlightedCodeSpans(node.code, node.language),
            ),
            softWrap: wraps,
            overflow: wraps ? TextOverflow.clip : TextOverflow.visible,
          )
        : Text(
            node.code,
            style: baseCodeStyle,
            softWrap: wraps,
            overflow: wraps ? TextOverflow.clip : TextOverflow.visible,
          );

    if (!wraps) {
      // Scrolls rather than wraps. A wrapped line of code loses its
      // indentation and breaks in the middle of a name; for prose that is
      // right and for code it is the opposite of what reading it needs.
      body = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: body,
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: body,
    );
  }

  TextStyle _buildCodeTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      color: githubTheme['root']?.color ?? const Color(0xff000000),
    );
  }

  List<TextSpan> _buildHighlightedCodeSpans(
    String source,
    String language, {
    int tabSize = 8,
  }) {
    final nodes = CodeHighlighting.instance
        .parse(source.replaceAll('\t', ' ' * tabSize), language: language)
        .nodes;
    if (nodes == null || nodes.isEmpty) {
      return [TextSpan(text: source)];
    }
    return _convertHighlightNodes(nodes, githubTheme);
  }

  List<TextSpan> _convertHighlightNodes(
    List<Node> nodes,
    Map<String, TextStyle> theme,
  ) {
    final spans = <TextSpan>[];
    var currentSpans = spans;
    final stack = <List<TextSpan>>[];

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(text: node.value, style: theme[node.className!]),
        );
        return;
      }

      if (node.children == null) return;

      if (node.className == null) {
        for (final child in node.children!) {
          traverse(child);
        }
        return;
      }

      final nestedSpans = <TextSpan>[];
      currentSpans.add(
        TextSpan(children: nestedSpans, style: theme[node.className!]),
      );
      stack.add(currentSpans);
      currentSpans = nestedSpans;

      for (final child in node.children!) {
        traverse(child);
      }

      currentSpans = stack.removeLast();
    }

    for (final node in nodes) {
      traverse(node);
    }

    return spans;
  }

  Widget _buildList(md.ListNode node, ThemeData theme) {
    final markers = md.MarkdownParser.listMarkers(node.items);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < node.items.length; i++)
            _buildListItem(node, node.items[i], i, markers[i], theme),
        ],
      ),
    );
  }

  /// Space under one item.
  ///
  /// A list whose items are separated by blank lines is loose, and CommonMark
  /// renders each item as a paragraph — which is what puts air between them.
  /// Drawing it as tight as a list written without gaps threw away spacing
  /// the author asked for.
  double _itemGap(md.ListNode node) => node.isLoose ? 12 : 4;

  Widget _buildListItem(
    md.ListNode listNode,
    md.ListItem item,
    int index,
    String marker,
    ThemeData theme,
  ) {
    if (item.isTask) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16 + item.depth * 20.0,
          bottom: _itemGap(listNode),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.isChecked,
              onChanged: widget.onSourceChanged != null
                  ? (value) => _toggleTask(listNode, index, value ?? false)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                _buildInlineSpans(item.inlineSpans, theme, _defaultTextStyle),
                strutStyle: _defaultStrutStyle,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      // Nested items step in; without this a sub-list rendered flush with its
      // parent and the structure was invisible.
      padding: EdgeInsets.only(
        left: 24 + item.depth * 20.0,
        bottom: _itemGap(listNode),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(marker, style: _defaultTextStyle),
          Expanded(
            child: Text.rich(
              _buildInlineSpans(item.inlineSpans, theme, _defaultTextStyle),
              strutStyle: _defaultStrutStyle,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders one block inside a quote.
  ///
  /// Deliberately narrower than the top-level switch: a quoted block is not
  /// separately editable, does not take part in heading scroll targets, and
  /// cannot be a diagram, so it needs none of that machinery.
  Widget _buildQuotedNode(
    md.MarkdownNode node,
    ThemeData theme,
    AppThemeTokens tokens,
  ) {
    return switch (node) {
      md.HeadingNode() => _buildHeading(node, theme, tokens),
      md.ParagraphNode() => _buildParagraph(node, theme),
      md.CodeBlockNode() => _buildCodeBlock(node, theme, tokens),
      md.ListNode() => _buildList(node, theme),
      md.BlockquoteNode() => _buildBlockquote(node, theme, tokens),
      md.HorizontalRuleNode() => Divider(
        thickness: 1,
        color: tokens.colorBorder,
      ),
      md.TableNode() => _buildTable(node, theme),
      md.MathBlockNode() => _buildMathBlock(node, theme),
      md.FrontMatterNode() => _buildFrontMatter(node, theme),
      md.FootnoteDefinitionNode() => _buildFootnoteDefinition(node, theme),
      md.HtmlBlockNode() => _buildHtmlBlock(node, theme),
      // MarkdownNode is not sealed, so the analyser cannot see that the cases
      // above are all of its subtypes. Showing the source beats dropping the
      // content if a new kind of node ever turns up here.
      _ => Text(node.rawContent, style: _defaultTextStyle),
    };
  }

  Widget _buildBlockquote(
    md.BlockquoteNode node,
    ThemeData theme,
    AppThemeTokens tokens,
  ) {
    return Container(
      // A quote inside a quote is built inside this container, so its own
      // border and padding already step it in; adding the depth again here
      // indented the inner quote twice.
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: tokens.colorAccent, width: 3)),
        color: tokens.colorAccentMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      // A quote holds blocks, not just a run of text: quoting a list or a
      // heading used to show the source markers as literal characters.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final child in node.children)
            _buildQuotedNode(child, theme, tokens),
        ],
      ),
    );
  }

  Widget _buildTable(md.TableNode node, ThemeData theme) {
    final colCount = node.headers.length;
    final config = ref.watch(settingsProvider);
    final isSplitMode = config.editMode == EditMode.split;

    // In split mode, enable horizontal scroll for narrow space
    // In preview mode, use flexible width with text wrapping
    final tableWidget = Table(
      border: TableBorder.symmetric(
        inside: BorderSide(color: theme.dividerColor),
      ),
      defaultColumnWidth: isSplitMode
          ? const IntrinsicColumnWidth()
          : const FlexColumnWidth(),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          children: [
            for (var i = 0; i < node.headers.length; i++)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text.rich(
                  _buildInlineSpans(
                    _inlineParser.parseInline(node.headers[i]),
                    theme,
                    theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textAlign: _getAlignment(node.alignments, i),
                  softWrap: true,
                ),
              ),
          ],
        ),
        for (final row in node.rows)
          TableRow(
            children: [
              for (var i = 0; i < colCount; i++)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text.rich(
                    _buildInlineSpans(
                      _inlineParser.parseInline(i < row.length ? row[i] : ''),
                      theme,
                      const TextStyle(),
                    ),
                    textAlign: _getAlignment(node.alignments, i),
                    softWrap: true,
                  ),
                ),
            ],
          ),
      ],
    );

    final tableContainer = Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: tableWidget,
    );

    // Only enable horizontal scroll in split mode
    if (isSplitMode) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: tableContainer,
      );
    }

    return tableContainer;
  }

  TextAlign _getAlignment(List<String> alignments, int index) {
    if (index >= alignments.length) return TextAlign.left;
    return switch (alignments[index]) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
  }

  Widget _buildMathBlock(md.MathBlockNode node, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Math.tex(
          node.expression,
          textStyle: theme.textTheme.bodyLarge,
          // Without this the package prints its own exception into the page —
          // `ParseException: Undefined control sequence: \foo`, in English, in
          // body text, indistinguishable from something the reader wrote. What
          // they need to see is the formula they typed and that it did not
          // come out.
          onErrorFallback: (_) => Text(
            node.expression,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  /// The face chosen for code, wherever code is shown.
  ///
  /// The setting had nothing reading it at all once; then the fenced code
  /// block started reading it and the other four places that draw monospace
  /// text did not. Picking a code font changed the blocks and left inline
  /// `code`, front matter, html blocks and the block editor in the platform's
  /// generic face — the same font setting producing two different fonts on
  /// one screen. One source, so the next place to draw code cannot drift.
  TextStyle _codeStyle({double? fontSize, Color? color}) {
    final config = ref.read(settingsProvider);
    return TextStyle(
      fontFamily: config.codeFontFamily,
      // A face that is not installed falls back rather than to the UI font.
      fontFamilyFallback: const ['monospace'],
      fontSize: fontSize ?? config.codeFontSize,
      color: color,
    );
  }

  Widget _buildFrontMatter(md.FrontMatterNode node, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(node.content, style: _codeStyle()),
    );
  }

  Widget _buildFootnoteDefinition(
    md.FootnoteDefinitionNode node,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${node.id}]: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: Text(node.content, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildHtmlBlock(md.HtmlBlockNode node, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(node.html, style: _codeStyle()),
    );
  }

  /// Split a text span into segments with search highlighting applied.
  List<InlineSpan> _applySearchHighlight(
    String text,
    TextStyle? style,
    EditorState editorState,
  ) {
    final query = editorState.previewSearchQuery;
    if (query.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    // One scanner for the app: the find bar counts the matches and this
    // highlights them, and when each had its own the two disagreed about
    // overlapping hits — `aa` in `aaaa` was two there and three here, and the
    // overlapping ranges spliced below drew six characters where there are
    // four.
    final matchRanges = TextSearch.matches(
      text,
      query,
      caseSensitive: editorState.previewSearchCaseSensitive,
      wholeWord: editorState.previewSearchWholeWord,
      useRegex: editorState.previewSearchUseRegex,
    );

    if (matchRanges.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final result = <InlineSpan>[];
    int lastEnd = 0;
    final currentIdx = editorState.previewCurrentMatchIndex;

    for (final range in matchRanges) {
      // Belt and braces: an overlapping range would re-emit text already
      // written and the paragraph would show more characters than it has.
      if (range.start < lastEnd) continue;
      if (range.start > lastEnd) {
        result.add(
          TextSpan(text: text.substring(lastEnd, range.start), style: style),
        );
      }
      final isCurrent = _matchCounter == currentIdx;
      result.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: style?.copyWith(
            backgroundColor: isCurrent
                ? Colors.orange.withValues(alpha: 0.6)
                : Colors.yellow.withValues(alpha: 0.4),
          ),
        ),
      );
      _matchCounter++;
      lastEnd = range.end;
    }
    if (lastEnd < text.length) {
      result.add(TextSpan(text: text.substring(lastEnd), style: style));
    }
    return result;
  }

  TextSpan _buildInlineSpans(
    List<md.InlineSpan> spans,
    ThemeData theme,
    TextStyle? baseStyle,
  ) {
    final children = <InlineSpan>[];
    final es = ref.read(editorProvider);
    final hasSearch = es.previewSearchQuery.isNotEmpty;

    for (final span in spans) {
      switch (span.type) {
        case md.InlineType.text:
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, baseStyle, es));
          } else {
            children.add(TextSpan(text: span.text, style: baseStyle));
          }
        case md.InlineType.boldItalic:
          final s = baseStyle?.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          );
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.bold:
          final s = baseStyle?.copyWith(fontWeight: FontWeight.bold);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.italic:
          final s = baseStyle?.copyWith(fontStyle: FontStyle.italic);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.code:
          final s = baseStyle?.copyWith(
            fontFamily: ref.read(settingsProvider).codeFontFamily,
            fontFamilyFallback: const ['monospace'],
            fontSize: (baseStyle.fontSize ?? 16) * 0.9,
            height: baseStyle.height,
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.6),
          );
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: ' ${span.text} ', style: s));
          }
        case md.InlineType.link:
          final s = baseStyle?.copyWith(
            color: theme.colorScheme.primary,
            // Remove underline decoration to avoid triggering rebuild on Ctrl press
            decoration: TextDecoration.none,
          );
          // Check modifier state at click time, not during build
          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              if (span.href != null &&
                  (HardwareKeyboard.instance.isControlPressed ||
                      HardwareKeyboard.instance.isMetaPressed)) {
                _openLink(span.href!);
              }
            };
          _recognizers.add(recognizer);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(
              TextSpan(text: span.text, style: s, recognizer: recognizer),
            );
          }
        case md.InlineType.image:
          children.add(_buildImageSpan(span, theme));
        case md.InlineType.strikethrough:
          final s = baseStyle?.copyWith(decoration: TextDecoration.lineThrough);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.mathInline:
          children.add(
            WidgetSpan(
              child: Math.tex(
                span.text,
                textStyle: baseStyle,
                // On one line, always. A formula sits inside a sentence, and
                // the package's default is a multi-line English exception —
                // which wraps, pushes the line apart and buries the sentence.
                // The reader's own text, in the error colour, says the same
                // thing without any of that.
                onErrorFallback: (_) => Text(
                  span.text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: baseStyle?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          );
        case md.InlineType.highlight:
          final s = baseStyle?.copyWith(
            backgroundColor: Colors.yellow.withValues(alpha: 0.4),
          );
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.superscript:
          children.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: Text(
                  span.text,
                  style: baseStyle?.copyWith(
                    fontSize: (baseStyle.fontSize ?? 14) * 0.75,
                  ),
                ),
              ),
            ),
          );
        case md.InlineType.subscript:
          children.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Transform.translate(
                offset: const Offset(0, 4),
                child: Text(
                  span.text,
                  style: baseStyle?.copyWith(
                    fontSize: (baseStyle.fontSize ?? 14) * 0.75,
                  ),
                ),
              ),
            ),
          );
        case md.InlineType.underline:
          final s = baseStyle?.copyWith(decoration: TextDecoration.underline);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.footnoteRef:
          children.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Text(
                '[${span.text}]',
                style: baseStyle?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: (baseStyle.fontSize ?? 14) * 0.75,
                ),
              ),
            ),
          );
      }
    }

    return TextSpan(children: children);
  }

  InlineSpan _buildImageSpan(md.InlineSpan span, ThemeData theme) {
    final href = span.href;
    if (href == null || href.isEmpty) {
      return TextSpan(
        text: '[${span.text}]',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    // Folded into the key so "reload images" makes the widget resolve again:
    // emptying the cache does not by itself disturb a picture already on
    // screen.
    final revision = ref.watch(
      editorProvider.select((state) => state.imageRevision),
    );

    Widget imageWidget;
    if (href.startsWith('http://') || href.startsWith('https://')) {
      imageWidget = Image.network(
        href,
        key: ValueKey('image:$revision:$href'),
        errorBuilder: (context, error, stackTrace) => Text(
          '[${span.text}]',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    } else {
      final file = File(href);
      imageWidget = Image.file(
        file,
        key: ValueKey('image:$revision:$href'),
        errorBuilder: (context, error, stackTrace) => Text(
          '[${span.text}]',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }

    // A badge is an image wrapped in a link, so it opens the link when tapped.
    final linkHref = span.linkHref;
    if (linkHref != null && linkHref.isNotEmpty) {
      imageWidget = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openLink(linkHref),
          child: imageWidget,
        ),
      );
    }

    return WidgetSpan(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: imageWidget,
      ),
    );
  }
}


/// A preview block that says it can be edited.
///
/// Public only so a test can point at it: a SelectionArea installs text-cursor
/// MouseRegions of its own all over the preview, so "is there a text cursor
/// here" cannot tell this wrapper apart from the selection machinery.
///
/// Double tap has always worked, but nothing on screen said so: the pointer
/// stayed an arrow and the block looked as inert as printed paper, so the
/// preview read as something you can only look at. The text cursor and the
/// quiet wash of colour are the two ordinary ways a surface says "there is
/// text here you can get at".
///
/// It keeps its own hover flag rather than lifting it into the renderer's
/// state: a setState up there rebuilds every block in the batch, which is
/// exactly the waste that moving the caret used to cause.
///
/// A MouseRegion is deliberately the only thing added. This file has already
/// been through the gesture arena twice — the double-tap recogniser left the
/// diagram toolbar and every task-list checkbox dead for the double-tap
/// timeout — and a MouseRegion does not enter the arena at all.
class PreviewEditableBlock extends StatefulWidget {
  @visibleForTesting
  const PreviewEditableBlock({
    super.key,
    required this.hoverColor,
    required this.onEdit,
    required this.child,
  });

  final Color hoverColor;
  final VoidCallback onEdit;
  final Widget child;

  @override
  State<PreviewEditableBlock> createState() => PreviewEditableBlockState();
}

class PreviewEditableBlockState extends State<PreviewEditableBlock> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onDoubleTap: widget.onEdit,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
