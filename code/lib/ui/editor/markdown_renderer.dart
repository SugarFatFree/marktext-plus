import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight_core.dart' show Node;

import 'code_highlighting.dart';
import 'syntax_highlighter.dart' show HighlightColors;
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
import 'source_editor.dart';
import '../../providers/settings_provider.dart';
import '../../services/text_search_service.dart';
import '../../providers/tab_provider.dart';
import '../../services/markdown_parser.dart' as md;
import '../../services/rich_copy_service.dart';
import '../../services/clipboard_service.dart';
import 'mermaid/parser/mermaid_parser.dart';
import '../widgets/mermaid_renderer.dart';
import '../widgets/plugin_command_actions.dart';
import '../../services/file_service.dart';
import 'bottom_room.dart';

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
    this.followsSource = false,
  });

  /// Whether to follow the editing pane's scrolling. Only split view wants
  /// it: on its own the preview has nobody to follow.
  final bool followsSource;

  /// Kept as a name on this class because tests and the source pane both
  /// reach for it here; the definition lives in `bottom_room.dart`, shared
  /// with the source pane so the two panes cannot drift apart.
  @visibleForTesting
  static double bottomRoomForHeight(double height) => bottomRoom(height);

  @override
  ConsumerState<MarkdownRenderer> createState() => _MarkdownRendererState();
}

class _MarkdownRendererState extends ConsumerState<MarkdownRenderer> {
  // Maps source line number → GlobalKey, used for TOC scroll targeting.
  // Build phase rebuilds this map fresh per pass to avoid stale duplicates.
  final _headingKeys = <int, GlobalKey>{};
  int _matchCounter = 0;
  /// One tap recognizer per link destination, kept between builds.
  ///
  /// These used to be built fresh on every build and the previous set thrown
  /// away at the top of the next one. A recognizer is not cheap: a paragraph
  /// carrying one link cost 114 us to rebuild against 45 us for the same
  /// paragraph without it — a link costs as much as a whole paragraph, and
  /// bold and inline code cost nothing at all. A page with five hundred links
  /// spent 25 ms of every rebuild here, and a rebuild is a caret move.
  ///
  /// Keyed by destination, because that is all the tap needs to know. Two
  /// links to the same place share one, which is correct: only one of them
  /// can be under the pointer.
  final _recognizersByHref = <String, TapGestureRecognizer>{};

  /// The destinations seen during the build now running, so the ones that
  /// have gone from the document can be disposed at the end of it.
  final _hrefsThisBuild = <String>{};

  /// One built widget per block, reused while nothing about how the document
  /// is drawn has changed.
  ///
  /// The blocks live in a Column, not a lazy list, so every one of them is
  /// rebuilt on every frame — and while a long document fills in, that is
  /// every frame for a while. A 216 KB document took 18.5 seconds to finish
  /// drawing, almost all of it rebuilding blocks that had not changed.
  ///
  /// Handing Flutter the same widget instance is what makes this pay: an
  /// element whose new widget is identical to its old one is not rebuilt, and
  /// a render object that was not marked dirty is not laid out again either.
  final _blockWidgets = <md.MarkdownNode, Widget>{};

  /// The preview's own scrolling, so it can be moved to follow the pane
  /// beside it.
  final ScrollController _previewScroll = ScrollController();

  /// The scroll view's box, for turning a heading's position on screen into a
  /// position inside the document.
  final GlobalKey _viewportKey = GlobalKey();

  /// When this pane was last moved by the pane beside it rather than by the
  /// reader.
  ///
  /// The two follow each other, so without this each would answer the other's
  /// move with one of its own and they would chase each other down the
  /// document. Whoever is being scrolled is the one driving; a move that
  /// arrives within a moment of a programmatic one is that move, not a reader.
  DateTime? _movedBySource;

  /// A scroll request that cannot be honoured until the rest of the document
  /// has been parsed.
  ///
  /// Kept here rather than left in the provider: the source pane listens for
  /// the same request and clears it as soon as *it* has scrolled, so by the
  /// time the parse finishes there would be nothing left to read. In split
  /// view that meant the preview never followed the outline at all.
  int? _pendingScrollLine;

  /// Everything a block's appearance depends on besides the block itself.
  /// When any of it changes the cache is thrown away whole, which is the only
  /// way to be sure a stale block never stays on screen.
  Object? _blockSignature;
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

  /// Stand-in for the block being appended at the end of the document.
  ///
  /// Reused rather than rebuilt so that `identical(_editingNode, node)` — how
  /// every other block decides whether it is the one being edited — keeps
  /// working for it too.
  final md.MarkdownNode _appendNode =
      md.ParagraphNode(content: '', inlineSpans: const []);

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

  /// Heading line numbers (1-based), taken from the blocks that were parsed.
  ///
  /// Read out of the AST rather than by scanning the text a second time. The
  /// second reading was a second implementation of "what counts as a heading",
  /// and the two had already disagreed twice — over a `#` inside front matter
  /// and over setext headings — each time putting every scroll target after
  /// the first disagreement on the wrong line. Taken from the nodes the
  /// preview actually drew, they cannot disagree.
  ///
  /// It is also 402 ms of work on a five megabyte document, and it ran on
  /// every content change, in build.
  List<int> _headingLinesOf(List<md.MarkdownNode> nodes) => [
        for (final node in nodes)
          if (node is md.HeadingNode) node.sourceStart + 1,
      ];

  @override
  void initState() {
    super.initState();
    _editFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _cancelEdit();
          return KeyEventResult.handled;
        }
        // Down from the last line, or up from the first, carries on into the
        // next block. Without it a reader has to press Escape and find the
        // next block with the mouse for every paragraph, which is not how
        // anyone writes. Only at the edges, so the arrows still move the
        // caret inside a block that has more than one line.
        if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
            _caretAtLastLine()) {
          _moveEditing(down: true);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
            _caretAtFirstLine()) {
          _moveEditing(down: false);
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

      // Where the pane beside this one is looking, which changes as the
      // reader scrolls rather than being a one-off request.
      if (widget.followsSource) {
        ref.listenManual(
          editorProvider.select((s) => s.syncSourceLine),
          (prev, next) {
            if (next != null) _syncToSourceLine(next);
          },
        );
        _previewScroll.addListener(_reportPreviewLine);
      }
    });
  }

  void _scrollToTargetLine(int? line) {
    if (line == null) return;

    // Draw down to the line before looking for its key.
    //
    // A long document arrives on screen a batch at a time, and a heading that
    // has not been drawn has no key — so asking for one sent [_keyForLine] to
    // its fallback, the last heading that *had* been drawn, which can be
    // thousands of lines short of where the reader asked to go. The target was
    // then cleared either way, so nothing ever corrected it: clicking an entry
    // near the end of a long document's outline landed somewhere else and
    // stayed there.
    if (_renderUpTo(line)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTargetLine(line);
      });
      return;
    }

    // Past the end of what has been parsed. Only a prefix of a long document
    // exists at first, and [_keyForLine] answers with the nearest heading
    // above rather than nothing — which here would be the last heading of the
    // prefix, taken as success and the request thrown away. Leave it standing;
    // [_adoptFullParse] asks again when the rest arrives.
    final parsed = _cachedNodes;
    if (_awaitingFullParse != null &&
        (parsed == null || parsed.isEmpty || line > parsed.last.sourceEnd)) {
      _pendingScrollLine = line;
      return;
    }
    _pendingScrollLine = null;

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

  /// Moves the preview so that source [line] is at the top of it.
  ///
  /// Split view had no scroll synchronisation at all: the preview stayed
  /// wherever it was while the editing pane moved, which is most of what a
  /// split view is for.
  ///
  /// Anchored on the headings rather than on a fraction of the way down.
  /// The two panes have nothing like the same height — a diagram is one line
  /// of source and half a screen of picture — so a fraction lands
  /// arbitrarily far from the text being written. Between two headings the
  /// position is interpolated, so it moves smoothly within a section rather
  /// than jumping only when one is crossed.
  void _syncToSourceLine(int line) {
    if (!widget.followsSource || !_previewScroll.hasClients) return;

    // The block may be below where the progressive render has got to, in
    // which case its heading has no key yet. Draw down to it and try again —
    // the reader is scrolling towards it anyway.
    if (_renderUpTo(line)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncToSourceLine(line);
      });
      return;
    }

    final target = _contentOffsetForLine(line);
    if (target == null) return;
    final position = _previewScroll.position;
    final clamped =
        target.clamp(position.minScrollExtent, position.maxScrollExtent);
    // Jumping, not animating: this runs on every scroll event, and an
    // animation started sixty times a second never finishes one.
    if ((clamped - _previewScroll.offset).abs() < 1) return;
    _movedBySource = DateTime.now();
    _previewScroll.jumpTo(clamped);
  }

  /// Tells the pane beside us which line the preview is showing.
  void _reportPreviewLine() {
    if (!widget.followsSource || !_previewScroll.hasClients) return;
    final moved = _movedBySource;
    if (moved != null &&
        DateTime.now().difference(moved) < const Duration(milliseconds: 200)) {
      return;
    }
    final line = _lineAtTopOfPreview();
    if (line == null) return;
    ref.read(editorProvider.notifier).reportPreviewLine(line);
  }

  /// The source line the top of the preview is showing.
  ///
  /// The inverse of [_contentOffsetForLine]: find the heading the reader has
  /// scrolled past, and count forwards through the lines by how far into that
  /// section they are.
  int? _lineAtTopOfPreview() {
    if (_headingKeys.isEmpty) return null;
    final at = _previewScroll.offset;

    int? here;
    double hereY = 0;
    int? next;
    double nextY = 0;
    for (final entry in _headingKeys.entries) {
      final y = _contentYOf(entry.value);
      if (y == null) continue;
      if (y <= at + 1 && (here == null || y > hereY)) {
        here = entry.key;
        hereY = y;
      }
      if (y > at + 1 && (next == null || y < nextY)) {
        next = entry.key;
        nextY = y;
      }
    }
    if (here == null) return 1;
    if (next == null || nextY <= hereY) return here;
    final through = ((at - hereY) / (nextY - hereY)).clamp(0.0, 1.0);
    return here + ((next - here) * through).round();
  }

  /// Where source [line] sits inside the preview's scrolling content.
  double? _contentOffsetForLine(int line) {
    if (_headingKeys.isEmpty) return null;
    int? at;
    int? next;
    for (final headingLine in _headingKeys.keys) {
      if (headingLine <= line && (at == null || headingLine > at)) {
        at = headingLine;
      }
      if (headingLine > line && (next == null || headingLine < next)) {
        next = headingLine;
      }
    }
    if (at == null) return 0;

    final start = _contentYOf(_headingKeys[at]!);
    if (start == null) return null;
    if (next == null || next == at) return start;
    final end = _contentYOf(_headingKeys[next]!);
    if (end == null) return start;
    final through = (line - at) / (next - at);
    return start + (end - start) * through;
  }

  /// A heading's distance from the top of the document, in the preview.
  double? _contentYOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || viewport == null || !box.hasSize || !viewport.hasSize) {
      return null;
    }
    final dy =
        box.localToGlobal(Offset.zero).dy - viewport.localToGlobal(Offset.zero).dy;
    return dy + _previewScroll.offset;
  }

  /// Extends the progressive render far enough to cover source [line].
  ///
  /// Returns whether it had to grow. False means the line is already drawn —
  /// or that there is nothing left to draw — and the caller can go on to look
  /// for its key.
  bool _renderUpTo(int line) {
    final nodes = _cachedNodes;
    if (nodes == null || _renderedNodeCount >= nodes.length) return false;

    // Source lines are numbered from one here and from zero on the node.
    var needed = nodes.length;
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i].sourceStart + 1 > line) {
        needed = i;
        break;
      }
    }
    if (needed < 1) needed = 1;
    if (needed <= _renderedNodeCount) return false;

    setState(() => _renderedNodeCount = needed);
    return true;
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
    for (final recognizer in _recognizersByHref.values) {
      recognizer.dispose();
    }
    _hoveredLink.dispose();
    _previewScroll.removeListener(_reportPreviewLine);
    _previewScroll.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  /// The recognizer for [href], made once and reused.
  TapGestureRecognizer _recognizerFor(String? href) {
    final key = href ?? '';
    _hrefsThisBuild.add(key);
    return _recognizersByHref.putIfAbsent(key, () {
      return TapGestureRecognizer()
        ..onTap = () {
          // The modifier is read when the link is clicked, not when it was
          // drawn, so the recognizer does not have to be rebuilt when Ctrl
          // goes down.
          if (key.isNotEmpty &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            _openLink(key);
          }
        };
    });
  }

  /// Throws away the recognizers for destinations the document no longer has.
  ///
  /// Called at the end of a build, when every link still in the document has
  /// asked for its recognizer. Doing it at the *start* — which is what
  /// rebuilding them all amounted to — also meant a tap in flight could reach
  /// a recognizer that had just been disposed.
  void _sweepRecognizers() {
    if (_recognizersByHref.length == _hrefsThisBuild.length) return;
    _recognizersByHref.removeWhere((href, recognizer) {
      if (_hrefsThisBuild.contains(href)) return false;
      recognizer.dispose();
      return true;
    });
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

  /// Schemes handed to the desktop rather than resolved as a file path.
  ///
  /// `mailto:` and `tel:` used to fall through to the relative-path branch,
  /// where they became a filename that does not exist — so clicking an address
  /// in the preview did nothing at all, silently.
  static final _launchableScheme =
      RegExp(r'^(https?|mailto|tel):', caseSensitive: false);

  /// Schemes that run code instead of going somewhere. A document is data,
  /// including one someone else wrote and sent over.
  static final _refusedScheme =
      RegExp(r'^(javascript|vbscript|data):', caseSensitive: false);

  Future<void> _followLink(String href) async {
    final collapsed = href.replaceAll(RegExp(r'[\s\u0000-\u001f]'), '');
    if (_refusedScheme.hasMatch(collapsed)) {
      throw FormatException('refused scheme', href);
    }
    if (_launchableScheme.hasMatch(collapsed)) {
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
            diskStamp: opened.stamp,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    _hrefsThisBuild.clear();
    final theme = Theme.of(context);

    // A format command while a block is open belongs to that block. The
    // source pane stands aside for it (it checks `previewBlockEditing`), so
    // exactly one of the two panes acts on it in split view.
    final pendingFormat =
        ref.watch(editorProvider.select((s) => s.pendingFormat));
    if (pendingFormat != null && _editingNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyFormatToBlock(pendingFormat);
        ref.read(editorProvider.notifier).clearFormat();
      });
    }

    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);
    // Read every build: the zoom commands change this setting, and the
    // preview has to follow them.
    _baseFontSize = config.fontSize;
    _baseLineHeight = config.lineHeight;
    // Only the preview's search state, not the whole of it. Watching the whole
    // provider meant every cursor move and every change of selection in the
    // source pane rebuilt the entire preview — in split view, on every arrow
    // key — and the preview rebuilds every block it has rendered so far.
    final search = ref.watch(
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
      _cachedHeadingLines = _headingLinesOf(_cachedNodes!);
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

    // A search numbers its matches by counting them as the blocks are built,
    // so a block that comes from the cache would not be counted and every
    // match after it would be numbered wrong. While a search is running,
    // nothing is cached.
    final searching = search.$1.isNotEmpty;
    final signature = (
      nodes,
      config.themeName,
      config.fontSize,
      config.lineHeight,
      config.wrapCodeBlocks,
      config.codeBlockLineNumbers,
      config.enableHtml,
      theme.brightness,
      widget.onSourceChanged == null,
      _editingNode,
      search,
    );
    final fullRebuild = _blockSignature != signature;
    if (fullRebuild) {
      _blockWidgets.clear();
      _blockSignature = signature;
    }

    /// The widget for [node], built once while the signature holds.
    Widget block(md.MarkdownNode node, Widget Function() draw) =>
        searching ? draw() : _blockWidgets.putIfAbsent(node, draw);

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
          widgets.add(block(
            node,
            () => _wrapEditable(
                node, tokens, _buildHeading(node, theme, tokens, key: key)),
          ));
        case md.ParagraphNode():
          widgets.add(block(node,
              () => _wrapEditable(node, tokens, _buildParagraph(node, theme))));
        case md.CodeBlockNode():
          widgets.add(block(node,
              () => _wrapEditable(node, tokens, _buildCodeBlock(node, theme, tokens))));
        case md.ListNode():
          widgets.add(block(node,
              () => _wrapEditable(node, tokens, _buildList(node, theme, tokens))));
        case md.BlockquoteNode():
          widgets.add(block(node,
              () => _wrapEditable(node, tokens, _buildBlockquote(node, theme, tokens))));
        case md.HorizontalRuleNode():
          widgets.add(block(
            node,
            () => _wrapEditable(
              node,
              tokens,
              Divider(thickness: 1, color: tokens.colorBorder),
            ),
          ));
        case md.TableNode():
          widgets.add(block(node,
              () => _wrapEditable(node, tokens, _buildTable(node, theme))));
        case md.MathBlockNode():
          widgets.add(block(node,
              () => _wrapEditable(node, tokens, _buildMathBlock(node, theme))));
        case md.FrontMatterNode():
          widgets.add(block(node,
              () => _wrapEditable(node, tokens, _buildFrontMatter(node, theme))));
        case md.FootnoteDefinitionNode():
          widgets.add(block(
            node,
            () => _wrapEditable(
                node, tokens, _buildFootnoteDefinition(node, theme)),
          ));
        case md.HtmlBlockNode():
          widgets.add(block(node,
              () => _wrapEditable(node, tokens, _buildHtmlBlock(node, theme))));
      }
    }

    // Somewhere to start writing.
    //
    // Until now the preview could only edit blocks that already existed: an
    // empty document rendered nothing at all, so there was no target to tap
    // and not a single character could be typed into it. Even in a written
    // document there was no way to add a block at the end — you had to switch
    // to the source pane. Upstream MarkText puts the caret at the end when the
    // space below the text is clicked, and this is that.
    if (widget.onSourceChanged != null && _renderedNodeCount >= nodes.length) {
      widgets.add(_buildAppendTarget(nodes.isEmpty, tokens));
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

    // Only after a build in which every block was actually drawn: a block
    // served from the cache never asks for its recognizer, so sweeping then
    // would dispose recognizers that are still on screen. The signature
    // includes the block list, so any change to the document clears the cache
    // and this runs.
    if (fullRebuild) _sweepRecognizers();

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
      child: Stack(
        children: [
          SingleChildScrollView(
        key: _viewportKey,
        controller: _previewScroll,
        child: SelectionArea(
          contextMenuBuilder: _buildPreviewContextMenu,
          onSelectionChanged: (content) => ref
              .read(editorProvider.notifier)
              .setSelectedText(content?.plainText ?? ''),
          // Centred inside a maximum width, which is right for a page of
          // prose and wrong for a caret waiting on an empty document: beside a
          // source pane that starts hard against the left, an editor floating
          // in the middle of the pane reads as something else entirely.
          child: Align(
            alignment: nodes.isEmpty
                ? AlignmentDirectional.topStart
                : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: config.editorMaxWidth.toDouble(),
              ),
              child: Padding(
                // Room under the last block, so it can be scrolled up to
                // where the eye is instead of staying pinned to the bottom
                // edge (#2). The source pane does the same, and in split view
                // the two have to agree or they stop lining up at the end of
                // the document.
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + _bottomRoom(context),
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
          // Along the bottom, over the text rather than in it: the hint has to
          // appear without moving the paragraph the pointer is resting on.
          _buildLinkHint(tokens),
        ],
      ),
    );
  }

  /// Flips the checkbox marker on one task line and writes the list back.
  ///
  /// The parser consumes exactly one source line per list item, so item
  /// [index] is line [index] of the list's own source.
  /// A line with any leading blockquote markers taken off.
  ///
  /// Only for deciding what the line *is*; what gets written back is the line
  /// as it was, markers and all.
  static String _withoutQuoteMarkers(String line) =>
      line.replaceFirst(RegExp(r'^\s*(?:>\s?)+'), '');

  void _toggleTask(md.ListNode node, int index, bool checked) {
    final onChanged = widget.onSourceChanged;
    if (onChanged == null) return;

    final lines = md.MarkdownParser.sourceOfBlock(
      widget.markdown,
      node,
    ).split('\n');

    // The line an item was written on, found by counting item lines rather
    // than assuming one line per item. A lazy continuation, the blank line of
    // a loose list, or a block carried under a step all shift the rest of the
    // items down — and the toggle then landed on a line with no box on it,
    // where it silently did nothing.
    var lineIndex = -1;
    var seen = -1;
    for (var i = 0; i < lines.length; i++) {
      // A list inside a quote arrives with its `>` markers still on, because
      // that is what has to be written back. Testing the line as it stands
      // found no list items at all, so `lineIndex` stayed at -1 and ticking a
      // box inside a quote did nothing whatever — no error, no change.
      // The question has to be the one the parser answered when it built the
      // items being counted: an empty marker is an item there, so it is an
      // item here.
      if (!md.MarkdownParser.continuesListItems(
        _withoutQuoteMarkers(lines[i]),
      )) {
        continue;
      }
      seen++;
      if (seen == index) {
        lineIndex = i;
        break;
      }
    }
    if (lineIndex < 0) return;

    final line = lines[lineIndex];
    final updated = checked
        ? line.replaceFirst(RegExp(r'\[\s\]'), '[x]')
        : line.replaceFirst(RegExp(r'\[[xX]\]'), '[ ]');
    if (updated == line) return;

    lines[lineIndex] = updated;
    onChanged(
      md.MarkdownParser.replaceBlock(widget.markdown, node, lines.join('\n')),
    );
  }

  // ------------------------------------------------------- in-place editing

  /// Whether [node] draws something tappable of its own, anywhere inside it.
  ///
  /// A task list's checkboxes and a diagram's toolbar are both hit by the same
  /// gesture-arena problem, and both are reachable from a quote or a list item
  /// as well as from the top level.
  static bool _holdsOwnControls(md.MarkdownNode node) {
    for (final descendant in md.MarkdownParser.walk([node])) {
      if (descendant is md.ListNode &&
          descendant.items.any((item) => item.isTask)) {
        return true;
      }
      if (descendant is md.CodeBlockNode &&
          MermaidParser.handlesLanguage(descendant.language)) {
        return true;
      }
    }
    return false;
  }

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

    // Anything with tap targets of its own is left alone. Wrapping it in a
    // double-tap recogniser puts that recogniser in the gesture arena, where
    // it holds on for the double-tap timeout before conceding — so a checkbox
    // or a diagram's toolbar button sits dead for ~300ms before responding,
    // which reads as a click that did nothing. Ticking a box and pressing a
    // toolbar button are the far more frequent actions, so they win: these
    // blocks stay directly interactive and are edited from the source pane.
    //
    // The test is on the whole subtree, not on the node itself. Both of these
    // rules were once written as "the node *is* a task list" and "the node
    // *is* a diagram", and a quote or a list item carrying one drew the same
    // controls behind the same recogniser — the fix had been made and then
    // not carried to the block one level up.
    if (_holdsOwnControls(node)) return child;

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
  void _finishParse() async {
    final source = _awaitingFullParse;
    if (source == null || !mounted || source != widget.markdown) return;
    _awaitingFullParse = null;

    final enableHtml = ref.read(settingsProvider).enableHtml;

    // Off this isolate. Parsing five megabytes takes about 3.5 seconds, and
    // it used to take them here, with the window frozen for every one of
    // them. Handing the finished blocks back costs about 140 ms of that —
    // measured, not assumed — so the freeze goes from three and a half
    // seconds to a seventh of one.
    //
    // Only large documents reach this at all: a document small enough for
    // `safePrefix` to decline is parsed whole on the first pass and never
    // schedules this.
    final List<md.MarkdownNode> nodes;
    try {
      nodes = await Isolate.run(
        () => md.MarkdownParser(enableHtml: enableHtml).parse(source),
      );
    } catch (_) {
      // An isolate that could not be spawned is not a reason to show half a
      // document forever: parse it here instead, slowly but correctly.
      if (!mounted || source != widget.markdown) return;
      final here = md.MarkdownParser(enableHtml: enableHtml).parse(source);
      _adoptFullParse(source, here);
      return;
    }

    _adoptFullParse(source, nodes);
  }

  /// Puts the finished blocks on screen, if they still describe the document.
  ///
  /// The check is repeated after the await: the reader may have typed while
  /// the other isolate was working, and the blocks it produced then describe
  /// a document that is no longer there.
  void _adoptFullParse(String source, List<md.MarkdownNode> nodes) {
    if (!mounted || source != widget.markdown) return;
    setState(() {
      _cachedNodes = nodes;
      _cachedHeadingLines = _headingLinesOf(nodes);
      // Whatever is already on screen stays on screen; the rest fills in the
      // way it does for a document that was parsed in one go.
      _renderedNodeCount = _renderedNodeCount.clamp(0, nodes.length);
    });

    // A scroll asked for while only the prefix existed was remembered rather
    // than thrown away, because the line it names may only now have a block to
    // point at.
    final pending = _pendingScrollLine;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTargetLine(pending);
      });
    }
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
    ref.read(editorProvider.notifier).setPreviewBlockEditing(true);
    // Focus after the editor exists in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editFocusNode.requestFocus();
    });
  }

  /// Writes the edited text back into the document.
  ///
  /// Whether the caret has no line below it inside the block being edited.
  bool _caretAtLastLine() {
    final selection = _editController.selection;
    if (!selection.isValid || !selection.isCollapsed) return false;
    final text = _editController.text;
    final at = selection.baseOffset.clamp(0, text.length);
    return !text.substring(at).contains('\n');
  }

  /// Whether the caret has no line above it inside the block being edited.
  bool _caretAtFirstLine() {
    final selection = _editController.selection;
    if (!selection.isValid || !selection.isCollapsed) return false;
    final text = _editController.text;
    final at = selection.baseOffset.clamp(0, text.length);
    return !text.substring(0, at).contains('\n');
  }

  /// Whether there is a block on the other side of [node] to move into.
  ///
  /// Below the last block there is always the blank space under the document,
  /// which is where the next paragraph goes — unless that is already what is
  /// being edited.
  bool _hasNeighbourBlock(
    md.MarkdownNode node, {
    required bool down,
    required bool wasAppend,
  }) {
    if (down) return !wasAppend;
    if (wasAppend) return (_cachedNodes ?? const []).isNotEmpty;
    for (final candidate in _cachedNodes ?? const <md.MarkdownNode>[]) {
      if (candidate.sourceEnd <= node.sourceStart) return true;
    }
    return false;
  }

  /// Commits the block being edited and opens the one before or after it.
  ///
  /// The neighbour is found by source line rather than by index, because
  /// committing may have changed how many blocks there are — a paragraph
  /// edited to contain a blank line becomes two — and an index captured
  /// beforehand would then point at the wrong one.
  void _moveEditing({required bool down}) {
    final node = _editingNode;
    if (node == null) return;
    final wasAppend = identical(node, _appendNode);

    // Is there anywhere to go? Asked before committing, because committing
    // closes the editor: pressing up in the document's first block used to
    // shut it and leave the reader with nothing focused, having asked only to
    // move the caret.
    if (!_hasNeighbourBlock(node, down: down, wasAppend: wasAppend)) return;

    // Where the edited block now ends, counted from the text as it stands
    // rather than from the node, whose range describes the document before
    // the edit.
    final lineCount = '\n'.allMatches(_editController.text).length + 1;
    final anchor = down ? node.sourceStart + lineCount : node.sourceStart;

    _commitEdit();
    if (mounted) setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nodes = _cachedNodes;
      if (nodes == null) return;
      md.MarkdownNode? target;
      for (final candidate in nodes) {
        if (down) {
          if (candidate.sourceStart >= anchor) {
            target = candidate;
            break;
          }
        } else if (candidate.sourceEnd <= anchor) {
          target = candidate;
        }
      }
      if (target != null) {
        _startEditing(target);
      } else if (down && !wasAppend) {
        // Past the last block is the blank space under the document, which is
        // where the next paragraph would go.
        _startEditingAtEnd();
      }
    });
  }

  /// Clearing [_editingNode] before unfocusing is what stops [_cancelEdit]
  /// from committing through the focus listener.
  void _commitEdit() {
    final node = _editingNode;
    if (node == null) return;
    _editingNode = null;
    ref.read(editorProvider.notifier).setPreviewBlockEditing(false);

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

  /// The tap target under the last block.
  ///
  /// A single tap, not the double tap every block uses: there is no text here
  /// to select and no link to follow, so nothing for the gesture to fight,
  /// and asking for a double tap on blank space is asking the reader to guess.
  Widget _buildAppendTarget(bool documentIsEmpty, AppThemeTokens tokens) {
    if (identical(_editingNode, _appendNode)) {
      return _buildBlockEditor(_appendNode);
    }
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startEditingAtEnd,
      child: Container(
        width: double.infinity,
        // Nothing to invite in split view: the source pane is right there with
        // a caret in it. Two invitations to start writing, side by side, and
        // pressing the one on the right opens a second editor that takes the
        // caret away from the one the reader was already looking at.
        constraints: BoxConstraints(
          minHeight: documentIsEmpty && !widget.followsSource ? 160 : 96,
        ),
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(top: 12),
        child: documentIsEmpty && l10n != null && !widget.followsSource
            ? Text(
                l10n.previewStartWriting,
                style: TextStyle(
                  color: tokens.colorTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              )
            : null,
      ),
    );
  }

  /// Opens an editor for a block that does not exist yet.
  ///
  /// The node is a stand-in whose line range is empty and sits at the end of
  /// the document, so committing it inserts rather than replaces — the same
  /// `replaceBlock` every other edit goes through.
  void _startEditingAtEnd() {
    FocusManager.instance.primaryFocus?.unfocus();
    final lineCount = const LineSplitter().convert(widget.markdown).length;
    _appendNode.sourceStart = lineCount;
    _appendNode.sourceEnd = lineCount;
    _editController.value = const TextEditingValue(text: '');
    setState(() => _editingNode = _appendNode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editFocusNode.requestFocus();
    });
  }

  void _cancelEdit() {
    if (_editingNode == null) return;
    setState(() => _editingNode = null);
    ref.read(editorProvider.notifier).setPreviewBlockEditing(false);
    _editFocusNode.unfocus();
  }

  /// Carries out a format command inside the block being edited.
  ///
  /// Without this the Format menu and every formatting shortcut were dead
  /// while a block was open in the preview — the reader was typing into a
  /// text field and Ctrl+B did nothing — and the command stayed pending, to
  /// go off later at whatever the caret happened to be when a source pane
  /// next appeared.
  void _applyFormatToBlock(FormatAction action) {
    // The same table the source pane reads, so a command added there cannot
    // quietly do nothing here.
    final wrap = SourceEditor.wrapMarkers[action];
    // Anything else — inserting a table, changing a heading level — is a
    // command about the document rather than about this block's text. It is
    // cleared rather than left pending, so it cannot fire somewhere else
    // later.
    if (wrap == null) return;

    final text = _editController.text;
    final selection = _editController.selection;
    if (!selection.isValid) return;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(start, text.length);

    final result = SourceEditor.toggleWrap(text, start, end, wrap.$1, wrap.$2);
    _editController.value = TextEditingValue(
      text: result.text,
      selection: result.start == result.end
          ? TextSelection.collapsed(offset: result.start)
          : TextSelection(baseOffset: result.start, extentOffset: result.end),
    );
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

  /// Puts an HTML flavour of the selection on the clipboard beside the text.
  ///
  /// Built from the blocks this preview drew, not by parsing what was copied.
  /// A selection here returns the *rendered* text — a heading comes back as
  /// `My Heading`, without the `#` — so feeding it back through the markdown
  /// parser, which is what this used to do, could only ever produce a
  /// paragraph. Pasting into Word lost every heading and every bold run, which
  /// is the whole thing rich copy exists to keep.
  /// The link the pointer is over, shown along the bottom of the preview.
  ///
  /// A notifier rather than a field set through setState. The bar is one small
  /// widget in a corner, and rebuilding the state rebuilt every block of the
  /// document to draw it: on a hundred kilobyte document that is 686 ms of the
  /// window standing still each time the pointer crosses a link, and again
  /// when it leaves.
  final _hoveredLink = ValueNotifier<String?>(null);

  void _showLinkHint(String href) {
    if (!mounted) return;
    _hoveredLink.value = href;
  }

  void _hideLinkHint() {
    if (!mounted) return;
    _hoveredLink.value = null;
  }

  /// A small bar naming the link under the pointer.
  ///
  /// Upstream MarkText floats a toolbar beside the link; a bar along the
  /// bottom does the part that matters — saying where the link goes before it
  /// is followed — without a popup that has to be positioned, kept on screen
  /// and dismissed.
  Widget _buildPreviewContextMenu(
      BuildContext context, SelectableRegionState state) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: [
        ...state.contextMenuButtonItems,
        ...PluginCommandActions.menuItems(
          context: context,
          ref: ref,
          location: PluginCommandActions.editorContextMenu,
          half: PluginEditorView.preview,
          selection: () => ref.read(editorProvider).selectedText,
          document: () => widget.markdown,
        ),
      ],
    );
  }

  Widget _buildLinkHint(AppThemeTokens tokens) {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredLink,
      builder: (context, href, _) => href == null
          ? const SizedBox.shrink()
          : _linkHintBar(href, tokens),
    );
  }

  Widget _linkHintBar(String href, AppThemeTokens tokens) {
    final l10n = AppLocalizations.of(context);

    return Positioned(
      left: 8,
      bottom: 8,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tokens.colorSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: tokens.colorBorder),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              l10n == null ? href : '$href  ·  ${l10n.linkOpenHint}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: tokens.colorTextMuted),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enhanceClipboardWithHtml() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final selectedText = data?.text;
    if (selectedText == null || selectedText.isEmpty) return;

    final nodes = _cachedNodes;
    if (nodes == null) return;

    final html = RichCopyService.htmlForSelection(nodes, selectedText);
    // Nothing written at all rather than something that does not describe what
    // was copied: the plain text is already on the clipboard and correct.
    if (html == null) return;

    await ClipboardService.copyWithHtml(selectedText, html);
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
        fontSize: _scaled(28),
        fontWeight: FontWeight.w700,
        color: tokens.colorText,
      ),
      2 => TextStyle(
        fontSize: _scaled(24),
        fontWeight: FontWeight.w600,
        color: tokens.colorText,
      ),
      3 => TextStyle(
        fontSize: _scaled(21),
        fontWeight: FontWeight.w600,
        color: tokens.colorText,
      ),
      _ => TextStyle(
        fontSize: _scaled(17),
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

  /// The size the preview's own sizes were written against.
  ///
  /// Everything here used to be a constant: body text at 16, headings at 28,
  /// 24, 21 and 17. That made the font size setting — and the zoom commands,
  /// which are that setting under another name — do nothing whatever in
  /// preview mode (#4). Scaling from the reader's size keeps the proportions
  /// the design was drawn with while letting them choose how big it all is.
  static const _designFontSize = 16.0;

  /// The reader's body size, and the line height they asked for.
  double _baseFontSize = _designFontSize;
  double _baseLineHeight = 1.6;

  /// How much empty space to leave under the last block.
  ///
  /// A share of the viewport rather than a fixed number: on a tall window a
  /// fixed 200 px is barely noticeable, and on a short one it is most of the
  /// screen.
  double _bottomRoom(BuildContext context) {
    final height = MediaQuery.maybeOf(context)?.size.height ?? 0;
    return MarkdownRenderer.bottomRoomForHeight(height);
  }

  /// A size from the original design, at the reader's scale.
  double _scaled(double designSize) =>
      designSize * (_baseFontSize / _designFontSize);

  TextStyle get _defaultTextStyle => TextStyle(
        fontSize: _baseFontSize,
        height: _baseLineHeight,
        leadingDistribution: TextLeadingDistribution.even,
        fontFamilyFallback: AppTheme.platformFontFallback,
      );
  StrutStyle get _defaultStrutStyle => StrutStyle(
        fontSize: _baseFontSize,
        height: _baseLineHeight,
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

    final numbered = ref.read(settingsProvider).codeBlockLineNumbers;
    final codeStyle = _buildCodeTextStyle(baseCodeStyle);

    Widget body;
    if (numbered) {
      body = _numberedCode(
        node,
        codeStyle: codeStyle,
        plainStyle: baseCodeStyle,
        highlighted: canHighlight,
        wraps: wraps,
        tokens: tokens,
      );
    } else {
      body = canHighlight
          ? Text.rich(
              TextSpan(
                style: codeStyle,
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

  /// A code block with a gutter of line numbers beside it.
  ///
  /// One row per line, so a line that wraps grows its own row and the number
  /// stays level with the line it belongs to. Drawing the code as one block
  /// of text and the numbers as another lines up only until something wraps.
  ///
  /// When the block scrolls instead of wrapping, only the code scrolls: the
  /// numbers are what tells the reader where they are, and they are no use
  /// slid off to the left.
  Widget _numberedCode(
    md.CodeBlockNode node,
    {required TextStyle codeStyle,
    required TextStyle plainStyle,
    required bool highlighted,
    required bool wraps,
    required AppThemeTokens tokens}) {
    final lines = highlighted
        ? CodeHighlighting.splitByLine(
            _buildHighlightedCodeSpans(node.code, node.language),
          )
        : [
            for (final line in node.code.split('\n'))
              [TextSpan(text: line, style: plainStyle)],
          ];
    // A trailing newline leaves an empty last line that no one wrote.
    if (lines.length > 1 && lines.last.isEmpty) lines.removeLast();

    final numberStyle = plainStyle.copyWith(
      color: tokens.colorTextMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final gutterWidth = 12.0 + 8.0 * '${lines.length}'.length;

    Widget numberCell(int index) => SizedBox(
          width: gutterWidth,
          child: Text(
            '${index + 1}',
            style: numberStyle,
            textAlign: TextAlign.right,
          ),
        );

    Widget codeCell(int index) => Text.rich(
          TextSpan(style: codeStyle, children: lines[index]),
          softWrap: wraps,
          overflow: wraps ? TextOverflow.clip : TextOverflow.visible,
        );

    if (wraps) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < lines.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                numberCell(i),
                const SizedBox(width: 12),
                Expanded(child: codeCell(i)),
              ],
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < lines.length; i++) numberCell(i)],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [for (var i = 0; i < lines.length; i++) codeCell(i)],
            ),
          ),
        ),
      ],
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
    final nodes = CodeHighlighting.highlight(
      source.replaceAll('\t', ' ' * tabSize),
      language: language,
    ).nodes;
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

  Widget _buildList(md.ListNode node, ThemeData theme, AppThemeTokens tokens) {
    final markers = md.MarkdownParser.listMarkers(node.items);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < node.items.length; i++)
            _buildListItem(node, node.items[i], i, markers[i], theme, tokens),
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
    AppThemeTokens tokens,
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
              child: _itemBody(item, theme, tokens),
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
            child: _itemBody(item, theme, tokens),
          ),
        ],
      ),
    );
  }

  /// An item's text, and the blocks written underneath it.
  ///
  /// A code fence beneath a numbered step, a second paragraph, a quote: these
  /// used to be rendered at the document's left margin, outside the step they
  /// belong to, because only [ListItem.inlineSpans] was drawn.
  Widget _itemBody(
    md.ListItem item,
    ThemeData theme,
    AppThemeTokens tokens,
  ) {
    final text = Text.rich(
      _buildInlineSpans(item.inlineSpans, theme, _defaultTextStyle),
      strutStyle: _defaultStrutStyle,
    );
    if (item.children.isEmpty) return text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        for (final child in item.children)
          _buildQuotedNode(child, theme, tokens),
      ],
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
      md.ListNode() => _buildList(node, theme, tokens),
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
                    node.headerSpansAt(i),
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
        for (var r = 0; r < node.rows.length; r++)
          TableRow(
            children: [
              for (var i = 0; i < colCount; i++)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text.rich(
                    _buildInlineSpans(
                      node.cellSpans(r, i),
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
            // The `^` belongs to the syntax — without it this reads as a link
            // reference definition, which is a different thing.
            '[^${node.id}]: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: node.inlineSpans.isEmpty
                ? Text(node.content, style: theme.textTheme.bodySmall)
                : Text.rich(
                    _buildInlineSpans(
                      node.inlineSpans,
                      theme,
                      theme.textTheme.bodySmall ?? const TextStyle(),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlBlock(md.HtmlBlockNode node, ThemeData theme) {
    // A comment is invisible. It still occupies a slot in the list so the
    // preview's block numbering stays in step with the source.
    if (node.isComment) return const SizedBox.shrink();
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

  /// Puts a link's tap target and hover hint on every piece of its text.
  ///
  /// Rebuilding rather than wrapping: a recognizer on a parent span is not
  /// inherited by its children, so the leaves are where it has to go.
  TextSpan _withLinkGestures(
    TextSpan span,
    TapGestureRecognizer recognizer,
    String? href,
  ) {
    final kids = span.children;
    return TextSpan(
      text: span.text,
      style: span.style,
      recognizer: span.text == null ? null : recognizer,
      mouseCursor:
          span.text == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: span.text == null || href == null
          ? null
          : (_) => _showLinkHint(href),
      onExit: span.text == null ? null : (_) => _hideLinkHint(),
      children: kids == null
          ? null
          : [
              for (final kid in kids)
                kid is TextSpan
                    ? _withLinkGestures(kid, recognizer, href)
                    : kid,
            ],
    );
  }

  /// The style one emphasis span applies on top of the style around it.
  ///
  /// Named rather than written into each arm because nesting needs the same
  /// answer from outside the switch: the children of a bold span are drawn
  /// with bold as their base.
  TextStyle? _emphasisStyle(md.InlineType type, TextStyle? base) =>
      switch (type) {
        md.InlineType.bold => base?.copyWith(fontWeight: FontWeight.bold),
        md.InlineType.italic => base?.copyWith(fontStyle: FontStyle.italic),
        md.InlineType.strikethrough =>
          base?.copyWith(decoration: TextDecoration.lineThrough),
        md.InlineType.underline =>
          base?.copyWith(decoration: TextDecoration.underline),
        md.InlineType.highlight => base?.copyWith(
            backgroundColor: HighlightColors.marked,
          ),
        _ => base,
      };

  TextSpan _buildInlineSpans(
    List<md.InlineSpan> spans,
    ThemeData theme,
    TextStyle? baseStyle,
  ) {
    final children = <InlineSpan>[];
    final es = ref.read(editorProvider);
    final hasSearch = es.previewSearchQuery.isNotEmpty;

    for (final span in spans) {
      // Emphasis holding markup of its own is drawn from its children, with
      // its own style as their base — so italic inside bold comes out both,
      // and a link inside bold is still clickable. Only emphasis carries
      // children, so the arms below are reached exactly as before otherwise.
      // A link is handled by its own arm below even when it nests: the arm is
      // what attaches the tap recognizer and the hover hint, and a link drawn
      // through this branch would look like a link and do nothing.
      if (span.children.isNotEmpty && span.type != md.InlineType.link) {
        children.add(_buildInlineSpans(
          span.children,
          theme,
          _emphasisStyle(span.type, baseStyle),
        ));
        continue;
      }
      switch (span.type) {
        case md.InlineType.text:
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, baseStyle, es));
          } else {
            children.add(TextSpan(text: span.text, style: baseStyle));
          }
        case md.InlineType.bold:
          final s = _emphasisStyle(span.type, baseStyle);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.italic:
          final s = _emphasisStyle(span.type, baseStyle);
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
          // No padding spaces around the text. They were there to keep the
          // ground off the letters, but a space is content: it was selected
          // with the run, copied with it, and counted in every offset — and
          // the search branch right above never added them, so opening the
          // find bar changed the length of the paragraph.
          //
          // Rich copy looks for the selected text in the text it builds from
          // the document, and two spaces that exist only on screen meant it
          // never found a paragraph with `code` in it: the copy fell through
          // to plain and took every heading, bold run and link with it.
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.link:
          final s = baseStyle?.copyWith(
            color: theme.colorScheme.primary,
            // Remove underline decoration to avoid triggering rebuild on Ctrl press
            decoration: TextDecoration.none,
          );
          final recognizer = _recognizerFor(span.href);
          if (span.children.isNotEmpty) {
            // The recognizer has to reach the leaves: a gesture on a TextSpan
            // covers that span's own text, not its children's, so a bold link
            // built as a wrapper around a bold child would not be clickable.
            children.add(_withLinkGestures(
              _buildInlineSpans(span.children, theme, s),
              recognizer,
              span.href,
            ));
          } else if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(
              TextSpan(
                text: span.text,
                style: s,
                recognizer: recognizer,
                // Where it goes, and how to go there. A link that only opens
                // with a modifier held, and shows neither its target nor that
                // requirement, is a link most readers will click once and give
                // up on.
                mouseCursor: SystemMouseCursors.click,
                onEnter: span.href == null
                    ? null
                    : (_) => _showLinkHint(span.href!),
                onExit: (_) => _hideLinkHint(),
              ),
            );
          }
        case md.InlineType.image:
          children.add(_buildImageSpan(span, theme));
        case md.InlineType.strikethrough:
          final s = _emphasisStyle(span.type, baseStyle);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.ruby:
          // The reading goes above the text, which is the whole point of ruby
          // and the one thing a run of styled text cannot express — so this is
          // a widget, sized down and baseline-aligned so the line it sits on
          // keeps its rhythm.
          final rubyBase = baseStyle ?? const TextStyle();
          children.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    span.title ?? '',
                    style: rubyBase.copyWith(
                      fontSize: (rubyBase.fontSize ?? 16) * 0.5,
                      height: 1.0,
                    ),
                  ),
                  Text(span.text, style: rubyBase.copyWith(height: 1.0)),
                ],
              ),
            ),
          );
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
          final s = _emphasisStyle(span.type, baseStyle);
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
          final s = _emphasisStyle(span.type, baseStyle);
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

  /// Turns a path written in the document into one the file system can use.
  ///
  /// `![](./img/x.png)` is how an image is ordinarily written, and the path is
  /// relative to the file the markdown is in. `File('./img/x.png')` resolves
  /// against the process's working directory — wherever the application was
  /// started from — so the picture was simply not found and the preview showed
  /// the alt text in red.
  ///
  /// The export side has resolved these correctly all along
  /// (`ExportService._resolveImagePath`), and following a relative *link* in
  /// this same file does too. This was the third place and the one that had
  /// not been given the same treatment.
  String _resolveAgainstDocument(String href) {
    if (p.isAbsolute(href)) return href;
    final state = ref.read(tabProvider);
    final tab =
        state.tabs.where((t) => t.id == state.activeTabId).firstOrNull;
    final path = tab?.filePath;
    // An unsaved document has no folder to be relative to; leaving the path
    // alone at least lets an absolute one keep working.
    if (path == null) return href;
    return p.normalize(p.join(p.dirname(path), href));
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

    // A tag may ask for a size; markdown's own syntax cannot. Only one of the
    // two is usually given, and the other is left to the picture's own
    // proportions rather than being guessed at.
    final askedWidth = span.width;
    final askedHeight = span.height;

    Widget imageWidget;
    if (href.startsWith('http://') || href.startsWith('https://')) {
      imageWidget = Image.network(
        href,
        width: askedWidth,
        height: askedHeight,
        fit: askedWidth != null && askedHeight != null ? BoxFit.fill : null,
        key: ValueKey('image:$revision:$href'),
        errorBuilder: (context, error, stackTrace) => Text(
          '[${span.text}]',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    } else {
      final file = File(_resolveAgainstDocument(href));
      imageWidget = Image.file(
        file,
        width: askedWidth,
        height: askedHeight,
        fit: askedWidth != null && askedHeight != null ? BoxFit.fill : null,
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
