import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
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
import '../widgets/slash_menu.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../widgets/language_picker.dart';
import '../../services/html_to_markdown.dart';
import '../../services/clipboard_service.dart';
import '../../services/table_edit_service.dart';
import '../../services/block_move_service.dart';
import '../widgets/format_toolbar.dart';

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
    this.reportsScrollPosition = false,
  });

  /// Whether to publish the line at the top of the viewport, for a preview
  /// beside this pane to follow. Only split view wants it; on its own the
  /// pane has nobody to tell.
  final bool reportsScrollPosition;

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
  /// The characters a list action writes in front of a line.
  ///
  /// The bullet the reader chose, for every kind of bullet: a task list wrote
  /// a dash whatever the setting said, so choosing `*` gave one list written
  /// with stars and the next with dashes, in the same document.
  static String listPrefixFor(FormatAction action, String bulletMarker) =>
      switch (action) {
        FormatAction.orderedList => '1. ',
        FormatAction.taskList => '$bulletMarker [ ] ',
        _ => '$bulletMarker ',
      };

  /// The markers each inline command wraps a selection in.
  ///
  /// One table, because two editors carry these commands out: this pane and
  /// the preview's block editor, which holds a block's markdown and is an
  /// ordinary text field. Written twice they would drift — a command added
  /// here and not there would simply do nothing in the preview, silently,
  /// which is how that whole class of bug in this codebase has looked.
  static const wrapMarkers = <FormatAction, (String, String)>{
    FormatAction.bold: ('**', '**'),
    FormatAction.italic: ('*', '*'),
    FormatAction.strikethrough: ('~~', '~~'),
    FormatAction.inlineCode: ('`', '`'),
    FormatAction.inlineMath: (r'$', r'$'),
    FormatAction.highlight: ('==', '=='),
    FormatAction.underline: ('++', '++'),
    FormatAction.superscript: ('^', '^'),
    FormatAction.subscript: ('~', '~'),
  };

  /// Where the text a paste just inserted sits, given what the document
  /// looked like before it.
  ///
  /// The framework replaces the selection with the plain flavour and the
  /// handlers here put something better in its place, so they have to know
  /// exactly what to take back out. Subtracting the two lengths alone gives
  /// the *net* change, which is the pasted length only when nothing was
  /// selected: pasting five characters over three grew the document by two.
  /// Reading that as the pasted length left three characters of the raw paste
  /// behind and wrote the replacement over the text after it.
  static ({int start, int end}) pastedRange({
    required int lengthBefore,
    required int selectionStart,
    required int selectionEnd,
    required int lengthAfter,
  }) {
    final start = selectionStart.clamp(0, lengthBefore);
    final removed = selectionEnd.clamp(start, lengthBefore) - start;
    final pasted = lengthAfter - lengthBefore + removed;
    return (start: start, end: start + (pasted < 0 ? 0 : pasted));
  }

  /// A URL, and only a URL: what a paste has to be for it to become a link.
  ///
  /// A scheme is required. `www.example.com` written in a sentence is prose,
  /// and turning a paste of it into a link would be guessing.
  static final _pastedUrlRe =
      RegExp(r'^(?:(?:https?|ftp|file):\/\/|mailto:)\S+$', caseSensitive: false);

  /// The markdown a paste of [pasted] over [selected] should produce, or null
  /// when this is an ordinary paste.
  ///
  /// Selecting some words and pasting a web address over them is how a link
  /// gets written in every other editor; here it replaced the words with the
  /// address, and the words had to be typed again.
  static String? linkFromPaste(String selected, String pasted) {
    if (selected.isEmpty || selected.contains('\n')) return null;
    final url = pasted.trim();
    if (!_pastedUrlRe.hasMatch(url)) return null;
    // Pasting a URL over something that is already a link would nest one
    // inside the other, which markdown has no meaning for.
    if (selected.contains('](')) return null;
    return '[$selected]($url)';
  }

  /// The line [line] becomes at heading [level], or as a paragraph when
  /// [level] is null.
  ///
  /// The rule for what counts as a heading is the parser's, not a second copy
  /// of it. A local `^(#{1,6})\s+` missed the three columns of indentation
  /// the format allows and the empty heading a line passes through while it is
  /// being typed, so `   ## Title` gained a marker instead of changing level,
  /// and asking for a paragraph left it a heading.
  static String applyHeadingLevel(String line, int? level) {
    final body = md.MarkdownParser.headingTextOf(line) ?? line;
    return level == null ? body : '${'#' * level} $body';
  }

  static ({String text, int start, int end}) toggleWrap(
    String text,
    int start,
    int end,
    String before,
    String after,
  ) {
    // Emphasis markers have to touch the words they mark. `**加粗。**后面` is
    // not bold anywhere — the closing run sits between a full stop and a
    // letter, which the format says can neither open nor close — and a reader
    // who selects a sentence including its punctuation and presses Ctrl+B
    // would otherwise be handed markup that renders as its own asterisks.
    // The punctuation goes outside the markers, where it reads the same and
    // the emphasis works: `**加粗**。后面`.
    //
    // Only for the markers the rule applies to — `*`, `_` and GFM's `~~`,
    // which marked and GitHub judge the same way. Inline code, and this
    // editor's own `==` and `++`, have no such rule and wrap whatever is
    // selected, punctuation and all.
    //
    // This parser is more forgiving than GitHub about `~~文字。~~后面`, and
    // stays so — a document should not stop rendering because it was opened
    // here. What is written from here is another matter: markup this editor
    // produces should mean the same wherever it is read.
    final flanks = before == after &&
        (before.startsWith('*') ||
            before.startsWith('_') ||
            before.startsWith('~'));

    // A selection covering more than one block is marked block by block.
    // Wrapping it whole put the markers around a blank line, a list's own
    // bullets, or a heading's `#` — none of which is emphasis anywhere, so
    // selecting two paragraphs and pressing Ctrl+B produced asterisks on
    // screen and a heading that had stopped being a heading.
    final segments = _inlineSegments(text, start, end);
    if (segments.length > 1) {
      return _wrapEach(text, segments, before, after, flanks);
    }
    if (segments.length == 1) {
      start = segments.single.$1;
      end = segments.single.$2;
    }

    if (flanks) {
      final trimmed = _trimForFlanking(text, start, end);
      if (trimmed != null) {
        start = trimmed.$1;
        end = trimmed.$2;
      }
    }

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

  /// The runs of ordinary text inside a selection, one per block.
  ///
  /// A blank line ends a block, and a line that opens one — a heading, a list
  /// item, a quote — carries a marker that belongs to the structure rather
  /// than to the words, so the marker is left out. What comes back is what a
  /// reader meant to mark when they dragged across half a document.
  static List<(int, int)> _inlineSegments(String text, int start, int end) {
    final segments = <(int, int)>[];
    var lineStart = start;
    var previousHadMarker = true;

    while (lineStart < end) {
      var hadMarker = false;
      var lineEnd = text.indexOf('\n', lineStart);
      if (lineEnd == -1 || lineEnd > end) lineEnd = end;

      var from = lineStart;
      var to = lineEnd;
      // A marker only counts when the selection reaches the line's own start;
      // half a line selected from the middle is just text.
      if (from == 0 || (from > 0 && text[from - 1] == '\n')) {
        final marker = _blockMarkerRe.matchAsPrefix(text, from);
        if (marker != null && marker.end <= to) {
          from = marker.end;
          hadMarker = true;
        }
      }
      while (to > from && text[to - 1].trim().isEmpty) {
        to--;
      }
      while (from < to && text[from].trim().isEmpty) {
        from++;
      }
      if (from < to) {
        // Two plain lines of one paragraph are one run: emphasis crosses a
        // line break inside a block, so marking them separately would put in
        // markers the document does not need. Only a blank line or a line
        // that opens a block of its own starts a new run.
        final joinable = !hadMarker &&
            !previousHadMarker &&
            segments.isNotEmpty &&
            from > 0 &&
            text[from - 1] == '\n' &&
            segments.last.$2 == from - 1;
        if (joinable) {
          segments[segments.length - 1] = (segments.last.$1, to);
        } else {
          segments.add((from, to));
        }
        previousHadMarker = hadMarker;
      } else {
        // A blank line: whatever follows it belongs to another block.
        previousHadMarker = true;
      }

      lineStart = lineEnd + 1;
    }
    return segments;
  }

  /// What opens a block: a heading, a bullet, a step, a quote, a task box.
  static final _blockMarkerRe = RegExp(
    r'\s*(?:#{1,6}\s+|>\s?|(?:[-*+]|\d{1,9}[.)])\s+(?:\[[ xX]\]\s+)?)',
  );

  /// Wraps each run separately, last first so the earlier offsets still hold.
  static ({String text, int start, int end}) _wrapEach(
    String text,
    List<(int, int)> segments,
    String before,
    String after,
    bool flanks,
  ) {
    // Already marked everywhere? Then this is the second press, and it takes
    // the marking off — the same toggle a single run gets.
    final wrapped = segments.every((s) {
      final piece = text.substring(s.$1, s.$2);
      return piece.length >= before.length + after.length &&
          piece.startsWith(before) &&
          piece.endsWith(after);
    });

    var out = text;
    for (final segment in segments.reversed) {
      var (from, to) = segment;
      if (wrapped) {
        out = out.replaceRange(
          from,
          to,
          out.substring(from + before.length, to - after.length),
        );
        continue;
      }
      if (flanks) {
        final trimmed = _trimForFlanking(out, from, to);
        if (trimmed != null) {
          from = trimmed.$1;
          to = trimmed.$2;
        }
      }
      out = out.replaceRange(
        from,
        to,
        before + out.substring(from, to) + after,
      );
    }

    final first = segments.first.$1;
    final grew = out.length - text.length;
    return (text: out, start: first, end: segments.last.$2 + grew);
  }

  /// Shrinks a selection past the whitespace and punctuation at its ends, so
  /// emphasis markers land where they can open and close.
  ///
  /// Returns null when there is nothing but punctuation to mark — a selection
  /// of `——` is wrapped as it is rather than as nothing.
  static (int, int)? _trimForFlanking(String text, int start, int end) {
    var from = start;
    var to = end;
    bool trimmable(String c) => c.trim().isEmpty || _flankingPunctuation.hasMatch(c);

    while (from < to && trimmable(text[from])) {
      from++;
    }
    while (to > from && trimmable(text[to - 1])) {
      to--;
    }
    if (from >= to) return null;
    return (from, to);
  }

  /// Sentence punctuation, listed rather than taken as a range.
  ///
  /// A range of "everything the format calls punctuation" would include the
  /// markdown characters themselves, and trimming those breaks what is being
  /// marked: applying italic to `**bold**` would eat the asterisks and take a
  /// layer off instead of adding one, and bolding `见[链接](url)` would move
  /// the closing bracket outside and leave a link that is no longer a link.
  ///
  /// The CJK marks are the reason this exists: a sentence in Chinese ends in
  /// `。` far more often than an English one ends in `.` inside the words a
  /// reader would select.
  static final _flankingPunctuation = RegExp(
    '[' r'.,;:!?' '\u2018\u2019\u201c\u201d'
    '\u3002\uff0c\u3001\uff1b\uff1a\uff01\uff1f'
    '\u2026\u2014\u00b7\uff5e'
    '\u300c\u300d\u300e\u300f\uff08\uff09'
    '\u300a\u300b\u3008\u3009\u3010\u3011'
    ']',
  );

  /// The outermost block containing [line], or null when [line] is blank
  /// space between blocks.
  static md.MarkdownNode? _blockAt(String source, int line) {
    for (final node in md.MarkdownParser().parse(source)) {
      if (line >= node.sourceStart && line < node.sourceEnd) return node;
    }
    return null;
  }

  /// Opens an empty paragraph below the block at [line].
  ///
  /// Anchored on the *outermost* block, as upstream's "Create Paragraph Below"
  /// is: a caret inside a blockquote gets a paragraph after the whole quote,
  /// not a line inside it.
  ///
  /// Returns the new text and the line the caret belongs on.
  @visibleForTesting
  static (String, int) createParagraphBelow(String source, int line) {
    final node = _blockAt(source, line);
    // The caret already sits on a blank line, which is somewhere to write.
    if (node == null) return (source, line);

    final lines = const LineSplitter().convert(source);
    final at = node.sourceEnd;
    // A blank line either side, so what is typed is its own paragraph rather
    // than a continuation of the block above or the one below.
    final followedByContent = at < lines.length && lines[at].trim().isNotEmpty;
    final opened = [...lines]
      ..insertAll(at, followedByContent ? ['', '', ''] : ['', '']);
    final trailing = source.endsWith('\n') || source.isEmpty ? '\n' : '';
    return (opened.join('\n') + trailing, at + 1);
  }

  /// Removes the outermost block at [line].
  ///
  /// Takes one blank line with it so deleting a block does not leave a growing
  /// gap; an empty document is what upstream leaves behind when the last block
  /// goes.
  @visibleForTesting
  static (String, int) deleteParagraphAt(String source, int line) {
    final node = _blockAt(source, line);
    if (node == null) return (source, line);

    final lines = const LineSplitter().convert(source);
    var start = node.sourceStart;
    var end = node.sourceEnd;
    if (end < lines.length && lines[end].trim().isEmpty) {
      end++;
    } else if (start > 0 && lines[start - 1].trim().isEmpty) {
      start--;
    }

    final remaining = [...lines]..removeRange(start, end);
    if (remaining.every((line) => line.trim().isEmpty)) return ('', 0);
    final trailing = source.endsWith('\n') ? '\n' : '';
    return (
      remaining.join('\n') + trailing,
      start.clamp(0, remaining.length - 1),
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

  /// The gutter's own box, so a line's position on screen can be turned into
  /// a position inside it.
  final GlobalKey _gutterKey = GlobalKey();

  /// When this pane was last moved by the preview rather than by the reader.
  /// Without it the two panes would answer each other's moves and chase one
  /// another down the document.
  DateTime? _movedByPreview;

  /// The line numbers on screen right now, and where each one sits.
  ///
  /// Read from the editor's own text layout rather than counted off at a
  /// fixed height. The gutter used to be a list of equal-height rows, one per
  /// line of source — which is only right while no line wraps. A paragraph in
  /// Markdown is usually a single long line, so it wraps as a matter of
  /// course, and one wrapped paragraph put the numbers 153 pixels out of step
  /// with the text they number. There is no setting to turn the gutter off,
  /// so everyone saw it.
  List<({int number, double dy})> _gutterMarks = const [];
  Timer? _debounce;
  bool _isInitialized = false;

  /// Held from [initState] so [dispose] can still reach it.
  ///
  /// `ref` is off limits by the time dispose runs — riverpod marks the element
  /// disposed before the framework calls it — and reaching for it there threw
  /// a StateError that the framework swallowed, which meant the handback below
  /// never happened at all.
  late final EditorNotifier _editorNotifier;

  static const _bracketPairs = <String, String>{
    '(': ')',
    '[': ']',
    '{': '}',
  };

  static const _quotePairs = <String, String>{
    '"': '"',
    "'": "'",
  };

  static const _markdownPairs = <String, String>{
    '`': '`',
    '*': '*',
    '~': '~',
  };

  /// Closing characters back to their opening ones, for the pairs that are
  /// not symmetric.
  ///
  /// Typing `)` to finish `(x` is what fingers do — the bracket that was
  /// inserted automatically is not something anyone sees themselves type — so
  /// the one already sitting there has to be stepped over rather than doubled.
  /// Upstream MarkText does the same in `shouldRemoveClosingChar`, where
  /// `[}\])]` sits next to the quotes.
  static const _closingBrackets = <String, String>{
    ')': '(',
    ']': '[',
    '}': '{',
  };

  /// The pairs the reader has actually asked for.
  ///
  /// One map used to hold all three kinds unconditionally, so nobody could
  /// turn any of it off. The markdown ones are the reason it matters: typing
  /// `*` to begin emphasis and being handed `**` with the caret in the middle
  /// interrupts the sentence for some people and helps others. Upstream
  /// MarkText has had these as three separate switches all along.
  Map<String, String> get _autoPairs {
    final config = ref.read(settingsProvider);
    return {
      if (config.autoPairBracket) ..._bracketPairs,
      if (config.autoPairQuote) ..._quotePairs,
      if (config.autoPairMarkdownSyntax) ..._markdownPairs,
    };
  }

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

      // And the other half of the split view's scrolling: where the preview
      // has been scrolled to.
      if (widget.reportsScrollPosition) {
        ref.listenManual(
          editorProvider.select((s) => s.syncPreviewLine),
          (prev, next) {
            if (next != null) _followPreviewToLine(next);
          },
        );
      }
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
    // Overlay entries outlive the widget unless they are taken down.
    _slashMenu?.remove();
    _slashMenu = null;
    _languagePicker?.remove();
    _languagePicker = null;
    _formatToolbar?.remove();
    _formatToolbar = null;
    _fieldFocus.dispose();
    _editorScrollController.dispose();

    super.dispose();
  }

  /// The text as it stood at the previous change, so the character that was
  /// just typed can be recognised.
  String _previousText = '';

  /// Characters that end a word, and so end an undo step.
  ///
  /// Undo used to be governed by the 300 ms debounce alone: a paragraph typed
  /// without pausing produced no snapshot at all until the writer stopped, so
  /// one press of undo took the whole paragraph away. Upstream MarkText fixed
  /// the same fault (#3825) and its end-to-end test spells out the result —
  /// typing `hello world` and pressing undo once leaves `hello`.
  ///
  /// The CJK punctuation is here for the same reason the Latin punctuation
  /// is: a sentence written in Chinese has no spaces to break it up, and
  /// without these its undo steps would be paragraph-sized again.
  static final _wordBoundary = RegExp(r'[\s.,;:!?)\]}"\u3001\u3002\uff0c'
      r'\uff1b\uff1a\uff01\uff1f\u201d\u2019\uff09\u3011\u300b]');

  /// Open while the format toolbar is showing over a selection.
  OverlayEntry? _formatToolbar;

  /// The selection the toolbar was placed for, so a rebuild that does not move
  /// it does not tear the overlay down and put it back.
  TextSelection? _toolbarSelection;

  /// The text field itself, so the toolbar can be positioned against it rather
  /// than against the widget as a whole — the gutter sits to its left, and the
  /// difference is exactly the gutter's width.
  final GlobalKey _fieldKey = GlobalKey();

  /// The field's focus, so the toolbar knows whether the editor is the thing
  /// being used, and so the caret can be handed back after a button is
  /// pressed — pressing one takes focus away from the field.
  final FocusNode _fieldFocus = FocusNode();

  /// Open while the slash menu is showing, so it can be taken down again.
  OverlayEntry? _slashMenu;

  /// Where the `/` that opened the menu sits, so it can be removed when a
  /// block is chosen.
  int _slashOffset = -1;

  /// Opens the quick-insert menu if `/` was just typed where a block can
  /// start.
  ///
  /// Only at the beginning of an otherwise empty line: `/` is an ordinary
  /// character in prose — a path, a date, "and/or" — and a menu that appeared
  /// every time one was typed would be in the way far more often than not.
  void _maybeOpenSlashMenu(String text, String? justTyped) {
    if (justTyped != '/' || _slashMenu != null) return;
    final offset = _controller.selection.baseOffset;
    if (offset < 1) return;
    // `offset - 2` is negative when the slash is the document's first
    // character, and `lastIndexOf` throws a RangeError on a negative start —
    // inside a text-change listener, where nothing reports it. The menu
    // simply never appeared, with no error anywhere to say why.
    final searchFrom = offset - 2;
    final lineStart =
        searchFrom < 0 ? 0 : text.lastIndexOf('\n', searchFrom) + 1;
    if (text.substring(lineStart, offset - 1).trim().isNotEmpty) return;

    final context = this.context;
    final overlay = Overlay.maybeOf(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null || !box.hasSize) return;

    _slashOffset = offset - 1;
    final origin = box.localToGlobal(Offset.zero);
    final l10n = AppLocalizations.of(context)!;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: origin.dx + 60,
        top: origin.dy + 40,
        child: SlashMenu(
          commands: slashCommands(l10n),
          onSelected: _closeSlashMenu,
        ),
      ),
    );
    _slashMenu = entry;
    overlay.insert(entry);
  }

  /// Shows the format toolbar over the selection, or takes it down.
  ///
  /// Upstream MarkText shows one on every selection. Here it appears only for
  /// a selection inside a single line: a strip floating over a paragraph-sized
  /// block would cover the text it is about, and every command on it is in the
  /// Format menu and on a shortcut anyway.
  void _syncFormatToolbar() {
    final selection = _controller.selection;
    final text = _controller.text;
    if (!selection.isValid ||
        selection.isCollapsed ||
        !_fieldFocus.hasFocus) {
      _closeFormatToolbar();
      return;
    }
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (text.substring(start, end).contains('\n')) {
      _closeFormatToolbar();
      return;
    }

    if (_formatToolbar != null && _toolbarSelection == selection) return;
    _closeFormatToolbar();

    final position = _toolbarPosition(text, start, end);
    if (position == null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    _toolbarSelection = selection;
    final entry = OverlayEntry(
      builder: (_) {
        // Recomputed on every build so the strip follows the text when the
        // editor is scrolled.
        final at = _toolbarPosition(_controller.text, start, end);
        if (at == null) return const SizedBox.shrink();
        return Positioned(
          left: at.dx,
          top: at.dy,
          child: FormatToolbar(
            items: formatToolbarItems(l10n),
            themeName: ref.read(settingsProvider).themeName,
            onSelected: (action) {
              // The selection is what the command is about, and tapping the
              // toolbar must not be allowed to take it away first.
              _fieldFocus.requestFocus();
              _applyFormat(action);
              _closeFormatToolbar();
            },
          ),
        );
      },
    );
    _formatToolbar = entry;
    overlay.insert(entry);
  }

  /// Where the toolbar's top-left corner goes, in screen coordinates.
  ///
  /// Measured rather than estimated: the prefix of the line is laid out with
  /// the editor's own text style, so a proportional font, a CJK character and
  /// a tab all land where they actually are.
  Offset? _toolbarPosition(String text, int start, int end) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final config = ref.read(settingsProvider);
    final style = TextStyle(
      fontFamily: config.fontFamily,
      fontSize: config.fontSize,
      height: config.lineHeight,
    );
    final (line, column) = _positionOf(text, start);
    final lineStart = start - column;
    final painter = TextPainter(
      text: TextSpan(text: text.substring(lineStart, start), style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final prefixWidth = painter.width;
    painter.dispose();

    final lineHeight = config.fontSize * config.lineHeight;
    final scroll =
        _editorScrollController.hasClients ? _editorScrollController.offset : 0.0;

    // `_fieldPadding` is the text field's own content padding, which the text
    // starts after.
    // From the toolbar itself, so the two cannot disagree about how tall it
    // is — a stale copy here would put the strip over the line it is about.
    const toolbarHeight = FormatToolbar.height;
    const gap = 4.0;
    var dx = _fieldPadding + prefixWidth;
    var dy = _fieldPadding + line * lineHeight - scroll - toolbarHeight - gap;

    // Below the line instead when there is no room above it, which is the
    // case on the document's first line.
    if (dy < 0) dy = _fieldPadding + (line + 1) * lineHeight - scroll + gap;

    final origin = box.localToGlobal(Offset.zero);
    final toolbarWidth = FormatToolbar.widthFor(6);
    final maxDx = box.size.width - toolbarWidth;
    return Offset(
      origin.dx + (maxDx > 0 ? dx.clamp(0.0, maxDx) : 0.0),
      origin.dy + dy,
    );
  }

  void _closeFormatToolbar() {
    _formatToolbar?.remove();
    _formatToolbar = null;
    _toolbarSelection = null;
  }

  /// The text field's content padding, which the toolbar has to account for
  /// when it measures from the field's own corner.
  static const double _fieldPadding = 8;

  /// Takes the menu down, and applies [command] if one was chosen.
  void _closeSlashMenu(SlashCommand? command) {
    _slashMenu?.remove();
    _slashMenu = null;

    if (command == null) {
      _slashOffset = -1;
      return;
    }

    // The `/` was the reader asking for the menu, not text they wanted. It
    // comes out before the block goes in, or every insertion would leave one
    // behind.
    final text = _controller.text;
    if (_slashOffset >= 0 && _slashOffset < text.length &&
        text[_slashOffset] == '/') {
      _controller.value = TextEditingValue(
        text: text.substring(0, _slashOffset) +
            text.substring(_slashOffset + 1),
        selection: TextSelection.collapsed(offset: _slashOffset),
      );
    }
    _slashOffset = -1;

    ref.read(editorProvider.notifier).applyFormat(command.action);
  }

  /// Open while the code-fence language picker is showing.
  OverlayEntry? _languagePicker;

  /// Where the language being typed starts, so it can be replaced.
  int _languageStart = -1;

  /// The fence line the reader has already answered for.
  ///
  /// Writing the chosen language back into the fence is itself a text change,
  /// and the caret stays on that line — so without this the picker reopened
  /// on the language it had just inserted, and there was no way to close it
  /// except to leave the line.
  String? _languageSettled;

  /// An opening code fence, and whatever has been typed as its language.
  static final _openFenceRe = RegExp(r'^\s*(?:`{3,}|~{3,})([A-Za-z0-9+#._-]*)\s*$');

  /// Shows or hides the language picker according to where the caret is.
  ///
  /// Upstream MarkText opens it while the fence's language is being typed and
  /// closes it when the caret leaves — nine of its end-to-end tests are about
  /// this one control. Without it the language has to be typed exactly and
  /// from memory, and a fence with a misspelt language is drawn as plain,
  /// unhighlighted code with nothing to say why.
  void _syncLanguagePicker(String text) {
    final offset = _controller.selection.baseOffset;
    if (offset < 0) {
      _closeLanguagePicker(null);
      return;
    }

    final searchFrom = offset - 1;
    final lineStart =
        searchFrom < 0 ? 0 : text.lastIndexOf('\n', searchFrom) + 1;
    var lineEnd = text.indexOf('\n', lineStart);
    if (lineEnd < 0) lineEnd = text.length;
    // Only while the caret is on that line: leaving it puts the picker away,
    // which is what stops it hanging over the code being written.
    if (offset > lineEnd) {
      _closeLanguagePicker(null);
      return;
    }

    final match = _openFenceRe.firstMatch(text.substring(lineStart, lineEnd));
    if (match == null) {
      _closeLanguagePicker(null);
      return;
    }

    final query = match.group(1)!;
    final line = text.substring(lineStart, lineEnd);
    if (_languageSettled == line) return;
    _languageSettled = null;
    _languageStart = lineEnd - query.length;
    _showLanguagePicker(query);
  }

  void _showLanguagePicker(String query) {
    _languagePicker?.remove();
    _languagePicker = null;

    final overlay = Overlay.maybeOf(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null || !box.hasSize) return;

    final origin = box.localToGlobal(Offset.zero);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: origin.dx + 60,
        top: origin.dy + 40,
        child: LanguagePicker(
          query: query,
          onSelected: _closeLanguagePicker,
        ),
      ),
    );
    _languagePicker = entry;
    overlay.insert(entry);
  }

  /// Takes the picker away, writing [language] into the fence if one was
  /// chosen.
  void _closeLanguagePicker(String? language) {
    if (_languagePicker == null) return;
    _languagePicker?.remove();
    _languagePicker = null;

    if (language == null) {
      // Dismissed rather than answered: the line stays as it is, and the
      // picker must not come back for it either.
      final text = _controller.text;
      final offset = _controller.selection.baseOffset.clamp(0, text.length);
      final lineStart =
          offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
      var lineEnd = text.indexOf('\n', lineStart);
      if (lineEnd < 0) lineEnd = text.length;
      _languageSettled = text.substring(lineStart, lineEnd);
      _languageStart = -1;
      return;
    }
    if (_languageStart < 0) return;

    final text = _controller.text;
    var end = text.indexOf('\n', _languageStart);
    if (end < 0) end = text.length;
    final start = _languageStart.clamp(0, text.length);
    final updated = text.substring(0, start) + language + text.substring(end);
    // Remember the line as it now reads, so the change this makes does not
    // bring the picker straight back.
    final lineStart = start == 0 ? 0 : updated.lastIndexOf('\n', start - 1) + 1;
    var lineEnd = updated.indexOf('\n', lineStart);
    if (lineEnd < 0) lineEnd = updated.length;
    _languageSettled = updated.substring(lineStart, lineEnd);

    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + language.length),
    );
    _languageStart = -1;
  }

  /// Replaces a just-pasted plain flavour with markdown built from the HTML
  /// flavour, when the clipboard carried one.
  ///
  /// Copying a table or a list out of a browser puts both flavours on the
  /// clipboard. Only the plain one was ever read, so what arrived was the
  /// words with their columns and bullets flattened out of them.
  ///
  /// The plain paste is allowed to happen first and is then replaced: reading
  /// the other flavour is asynchronous, and holding the keystroke until it
  /// answers would make every paste feel slow — including the great majority
  /// that have no HTML at all.
  Future<void> _handleRichPaste() async {
    final selectionBefore = _controller.selection;
    final textBefore = _controller.text;
    final lengthBefore = textBefore.length;
    final selected = selectionBefore.isValid && !selectionBefore.isCollapsed
        ? textBefore.substring(selectionBefore.start, selectionBefore.end)
        : '';

    // Read after the paste has landed, so what was inserted can be seen. The
    // plain flavour is allowed to arrive first on purpose: waiting on the
    // clipboard before every paste would make every paste feel slow.
    final html = await ClipboardService.readHtml();
    if (!mounted) return;

    final text = _controller.text;
    final range = SourceEditor.pastedRange(
      lengthBefore: lengthBefore,
      selectionStart: selectionBefore.isValid ? selectionBefore.start : 0,
      selectionEnd: selectionBefore.isValid ? selectionBefore.end : 0,
      lengthAfter: text.length,
    );
    if (range.end <= range.start || range.end > text.length) return;
    final pasted = text.substring(range.start, range.end);

    // A web address dropped on some selected words is a link, whichever
    // flavour the clipboard also carried: copying an address out of a browser
    // brings an HTML flavour with it, and converting that would throw the
    // words away.
    final link = SourceEditor.linkFromPaste(selected, pasted);
    final replacement = link ??
        (html == null ? null : HtmlToMarkdown.convert(html));
    if (replacement == null) return;

    _controller.value = TextEditingValue(
      text: text.substring(0, range.start) +
          replacement +
          text.substring(range.end),
      selection: TextSelection.collapsed(
        offset: range.start + replacement.length,
      ),
    );
  }

  /// Whether an input method is in the middle of composing a word.
  ///
  /// A pinyin or kana IME rewrites the text on every keystroke while the
  /// reader is still choosing — `hao`, `hao,`, `hao,s` — and only the final
  /// choice is what they typed. Recording those as history put candidate
  /// strings the reader never wrote into undo: pressing undo after typing
  /// 你好 offered `hao,` back.
  bool get _isComposing => _controller.value.composing.isValid;

  void _onTextChanged() {
    final text = _controller.text;

    // A word has just been finished: close the undo step here rather than
    // waiting for the writer to pause. Exactly one character longer than the
    // last state, and that character ends a word — anything else (a paste, a
    // deletion, a replacement) is left to the debounce.
    final justTyped = text.length == _previousText.length + 1 &&
            text.startsWith(_previousText)
        ? text.substring(text.length - 1)
        : null;
    _previousText = text;

    if (_isInitialized &&
        !_isComposing &&
        justTyped != null &&
        _wordBoundary.hasMatch(justTyped)) {
      ref.read(editorProvider.notifier).pushHistory(text);
    }

    // Neither menu belongs on screen while a word is being composed: the `/`
    // of a half-typed candidate is not a request for the insert menu.
    if (_isInitialized && !_isComposing) {
      _maybeOpenSlashMenu(text, justTyped);
      _syncLanguagePicker(text);
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Still composing after the pause — a reader thinking about which
      // candidate to pick — so the half-written word is not history yet. The
      // change is still handed on, or the preview would freeze mid-word.
      if (_isInitialized && !_isComposing) {
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
    final (line, col) = _positionOf(text, offset);

    // The picker follows the caret: it belongs to the fence line and has to
    // go away when the caret leaves it.
    if (_isInitialized) _syncLanguagePicker(text);

    ref.read(editorProvider.notifier).updateCursor(line, col);

    if (_isInitialized) _syncFormatToolbar();

    // The selected text used to be pushed into EditorState here, on every
    // change of selection. Nothing ever read it, and each write was a second
    // state change per cursor move on top of the position above.

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
    // The toolbar is placed in screen coordinates, so it has to be moved when
    // the text under it moves. Rebuilding the entry is enough; it recomputes
    // the position from the current scroll offset.
    _formatToolbar?.markNeedsBuild();
    _updateGutterMarks();
    _reportTopLine();
  }

  /// Scrolls so that source [line] is at the top, because the preview beside
  /// us has been scrolled there.
  ///
  /// The line's position comes from the text layout rather than from a line
  /// height multiplied out: with a wrapped paragraph the two are not the same
  /// number, and in Markdown a paragraph is normally one long line.
  void _followPreviewToLine(int line) {
    if (!widget.reportsScrollPosition) return;
    if (!_editorScrollController.hasClients) return;
    final editable = _renderEditable();
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (editable == null || box == null || !box.hasSize) return;

    final starts = _ensureLineStarts(_controller.text);
    final index = (line - 1).clamp(0, starts.length - 1);
    final rect =
        editable.getLocalRectForCaret(TextPosition(offset: starts[index]));
    final lineTop = editable.localToGlobal(Offset(0, rect.top)).dy;
    final paneTop = box.localToGlobal(Offset.zero).dy;

    final position = _editorScrollController.position;
    final target = (_editorScrollController.offset + (lineTop - paneTop))
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - _editorScrollController.offset).abs() < 1) return;
    _movedByPreview = DateTime.now();
    _editorScrollController.jumpTo(target);
  }

  /// Tells whoever is beside us which line is at the top of the viewport.
  ///
  /// The exact line, from the layout — not the offset divided by a line
  /// height, which stops being the line the moment a paragraph wraps, and in
  /// Markdown a paragraph is normally one long line.
  void _reportTopLine() {
    if (!widget.reportsScrollPosition) return;
    final moved = _movedByPreview;
    if (moved != null &&
        DateTime.now().difference(moved) < const Duration(milliseconds: 200)) {
      return;
    }
    final editable = _renderEditable();
    if (editable == null) return;
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final at = editable.getPositionForPoint(Offset(0, top));
    final line = _positionOf(_controller.text, at.offset).$1;
    ref.read(editorProvider.notifier).reportSourceLine(line + 1);
  }

  /// The render object that laid the text out, found by descending from the
  /// field. Asking it where a line begins is the only way to be sure the
  /// number beside it is beside it.
  RenderEditable? _renderEditable() {
    final root = _fieldKey.currentContext?.findRenderObject();
    if (root == null) return null;
    RenderEditable? found;
    void visit(RenderObject node) {
      if (found != null) return;
      if (node is RenderEditable) {
        found = node;
        return;
      }
      node.visitChildren(visit);
    }

    visit(root);
    return found;
  }

  /// Works out which line numbers are on screen and where to draw them.
  ///
  /// Only the visible ones: a five megabyte document has no business asking
  /// the layout about lines nobody is looking at.
  void _updateGutterMarks() {
    final editable = _renderEditable();
    final gutter = _gutterKey.currentContext?.findRenderObject() as RenderBox?;
    if (editable == null || gutter == null || !gutter.hasSize) return;

    final gutterTop = gutter.localToGlobal(Offset.zero).dy;
    final gutterBottom = gutterTop + gutter.size.height;

    final text = _controller.text;
    final starts = _ensureLineStarts(text);

    // Where the top of the gutter falls in the text, so the walk starts at
    // the first line that could be visible rather than at the first line.
    final atTop = editable.getPositionForPoint(Offset(0, gutterTop));
    var line = _positionOf(text, atTop.offset).$1;
    if (line > 0) line--;

    final marks = <({int number, double dy})>[];
    while (line < starts.length && marks.length < 500) {
      final rect =
          editable.getLocalRectForCaret(TextPosition(offset: starts[line]));
      final y = editable.localToGlobal(Offset(0, rect.top)).dy;
      if (y > gutterBottom) break;
      if (y + rect.height >= gutterTop) {
        marks.add((number: line + 1, dy: y - gutterTop));
      }
      line++;
    }

    if (marks.length == _gutterMarks.length) {
      var same = true;
      for (var i = 0; i < marks.length; i++) {
        if (marks[i] != _gutterMarks[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    if (mounted) setState(() => _gutterMarks = marks);
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
      // Shift is the escape hatch: paste exactly what the plain flavour says,
      // with no conversion. Upstream MarkText has the same command, and it
      // exists precisely because converting is the default.
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      _handleImagePaste();
      _handleRichPaste();
      // Ignored either way so the TextField still pastes the plain flavour if
      // neither of those has anything to offer; both replace what they
      // inserted only once they know they have something better.
      return KeyEventResult.ignored;
    }

    // Enter inside a list carries the list on, which is what every editor
    // does and what upstream gives each block its own handler for. Without it
    // a writer types the marker again on every line, and the numbering by
    // hand.
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed &&
        selection.isCollapsed) {
      final offset = selection.baseOffset;
      final lineStart = text.lastIndexOf('\n', offset - 1) + 1;
      final line = text.substring(lineStart, offset);
      final carry = md.MarkdownParser.listContinuation(line);

      if (carry != null) {
        // An item with nothing in it is how a writer ends a list: the marker
        // comes off rather than another one appearing below it.
        final replacement = carry.isEmpty ? '' : '\n${carry.marker}';
        final from = carry.isEmpty ? lineStart : offset;
        _controller.value = TextEditingValue(
          text: text.substring(0, from) + replacement + text.substring(offset),
          selection:
              TextSelection.collapsed(offset: from + replacement.length),
        );
        return KeyEventResult.handled;
      }
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

    // A closing bracket typed onto the one already there steps past it
    // instead of adding a second. Symmetric characters are handled further
    // down, where they are their own closing character.
    final opener = _closingBrackets[char];
    if (opener != null && selection.isCollapsed) {
      final offset = selection.baseOffset;
      if (_autoPairs.containsKey(opener) &&
          offset < text.length &&
          text[offset] == char) {
        _controller.selection = TextSelection.collapsed(offset: offset + 1);
        return KeyEventResult.handled;
      }
      // Any other closing bracket is an ordinary character; leave it to the
      // framework rather than swallowing the key.
      return KeyEventResult.ignored;
    }

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
      final offset = selection.baseOffset;
      // Only pair where the closing character would not land in the way.
      // Typing `"` in front of `foo` used to give `""foo`, so the spurious
      // one had to be deleted straight away. Upstream MarkText pairs only at
      // the end of the line or before whitespace; a closing bracket counts as
      // out of the way too, since `(|)` is how a nested call gets written.
      if (offset < text.length) {
        final next = text[offset];
        final isSpace = next.trim().isEmpty;
        final isClosing = _closingBrackets.containsKey(next);
        if (!isSpace && !isClosing) return KeyEventResult.ignored;
      }
      // Insert pair and place cursor in the middle
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
      _insertAtCursor(
          '![image](${ImageService.markdownDestination(imagePath)})');
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
      _insertAtCursor(
          '![image](${ImageService.markdownDestination(link)})');
    }
  }

  /// Offset of the first character of each line, for the text it was built
  /// from.
  ///
  /// Both the gutter and the cursor readout need to turn offsets into line
  /// and column, and both used to do it by walking the whole document — the
  /// gutter counting newlines in `build`, the cursor taking
  /// `text.substring(0, offset).split('\n')`. On a five megabyte document
  /// that is 33 ms and 61 ms respectively, paid on **every cursor move**,
  /// and the second one also allocated a list of 290 000 strings to read two
  /// numbers off it.
  ///
  /// Built once per edit (46 ms at five megabytes) and searched in about half
  /// a microsecond, so moving the caret costs nothing at all.
  List<int> _lineStarts = const [0];
  String? _lineStartsSource;

  List<int> _ensureLineStarts(String text) {
    // Identity, not equality: comparing two five megabyte strings for every
    // keystroke would put back a good part of what this saves. The controller
    // hands back the same instance while the text is unchanged; a different
    // instance holding the same text only costs one rebuild.
    if (identical(_lineStartsSource, text)) return _lineStarts;
    final starts = <int>[0];
    for (final match in '\n'.allMatches(text)) {
      starts.add(match.end);
    }
    _lineStarts = starts;
    _lineStartsSource = text;
    return starts;
  }

  /// The 0-based line [offset] falls on, and how far into it.
  (int, int) _positionOf(String text, int offset) {
    final starts = _ensureLineStarts(text);
    var low = 0;
    var high = starts.length - 1;
    var line = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (starts[mid] <= offset) {
        line = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return (line, offset - starts[line]);
  }

  int _getLineCount() => _ensureLineStarts(_controller.text).length;

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
      // Every inline wrap, from the one table both editors read.
      case FormatAction.bold:
      case FormatAction.italic:
      case FormatAction.strikethrough:
      case FormatAction.inlineCode:
      case FormatAction.inlineMath:
      case FormatAction.highlight:
      case FormatAction.underline:
      case FormatAction.superscript:
      case FormatAction.subscript:
        final markers = SourceEditor.wrapMarkers[action]!;
        _wrapSelection(markers.$1, markers.$2);
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
      case FormatAction.unorderedList:
      case FormatAction.taskList:
        _applyLinePrefixAtCursor(
          SourceEditor.listPrefixFor(
            action,
            ref.read(settingsProvider).bulletListMarker,
          ),
        );
      case FormatAction.quoteBlock:
        _applyLinePrefixAtCursor('> ');
      case FormatAction.codeBlock:
        _insertBlock('```\n', '\n```');
      case FormatAction.mermaidBlock:
        // A diagram that draws something the moment it is inserted, rather
        // than an empty fence: the arrow is the syntax worth showing, and the
        // node names are letters so the skeleton reads the same in every
        // language the editor speaks.
        _insertAtCursor('```mermaid\ngraph TD\n    A --> B\n```\n');
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
      case FormatAction.frontMatter:
        _insertFrontMatter();
      case FormatAction.htmlBlock:
        _insertAtCursor('<div>\n\n</div>');
      case FormatAction.looseList:
        _toggleLooseList();
      case FormatAction.createParagraph:
        _applyBlockEdit(SourceEditor.createParagraphBelow);
      case FormatAction.deleteParagraph:
        _applyBlockEdit(SourceEditor.deleteParagraphAt);
      case FormatAction.tableInsertRowAbove:
        _applyTableEdit(TableEdit.insertRowAbove);
      case FormatAction.tableInsertRowBelow:
        _applyTableEdit(TableEdit.insertRowBelow);
      case FormatAction.tableDeleteRow:
        _applyTableEdit(TableEdit.deleteRow);
      case FormatAction.tableInsertColumnLeft:
        _applyTableEdit(TableEdit.insertColumnLeft);
      case FormatAction.tableInsertColumnRight:
        _applyTableEdit(TableEdit.insertColumnRight);
      case FormatAction.tableDeleteColumn:
        _applyTableEdit(TableEdit.deleteColumn);
      case FormatAction.tableAlignLeft:
        _applyTableEdit(TableEdit.alignLeft);
      case FormatAction.tableAlignCenter:
        _applyTableEdit(TableEdit.alignCenter);
      case FormatAction.tableAlignRight:
        _applyTableEdit(TableEdit.alignRight);
      case FormatAction.tableAlignNone:
        _applyTableEdit(TableEdit.alignNone);
      case FormatAction.tableTidy:
        _applyTableEdit(TableEdit.tidy);
      case FormatAction.moveBlockUp:
        _moveBlock(up: true);
      case FormatAction.moveBlockDown:
        _moveBlock(up: false);
      case FormatAction.clearFormatting:
        if (!selection.isCollapsed) {
          final selected = text.substring(selection.start, selection.end);
          final cleaned = selected
              .replaceAll(RegExp(r'\*{1,3}|~~|`|==|\+\+|\^|~|\$'), '')
              // Same heading rule as everywhere else: indentation counts,
              // and `#tag` is not a heading to strip.
              .replaceAll(
                RegExp(r'^ {0,3}#{1,6}(?:[ \t]+|$)', multiLine: true),
                '',
              );
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
    final replacement = SourceEditor.applyHeadingLevel(line, level);
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

    return md.MarkdownParser.headingLevelOf(
          text.substring(lineStart, lineEnd),
        ) ??
        0;
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

  /// Runs a block-level edit that reports where the caret should land.
  /// Trades the block under the caret with the one before or after it.
  ///
  /// With a selection, the lines it touches move instead — the selection is
  /// the reader saying which lines they mean.
  void _moveBlock({required bool up}) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.baseOffset < 0) return;
    final result = BlockMoveService.move(
      text,
      selection.baseOffset.clamp(0, text.length),
      selection.extentOffset.clamp(0, text.length),
      up: up,
    );
    if (result == null) return;
    ref.read(editorProvider.notifier).pushHistory(text);
    _controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection(
        baseOffset: result.base,
        extentOffset: result.extent,
      ),
    );
  }

  /// Rewrites the table under the caret.
  ///
  /// Does nothing when the caret is not in a table, or when the edit does not
  /// apply — neither the header row nor the last column can be removed. The
  /// menu disables those entries, so this is the keyboard path failing safely
  /// rather than the ordinary way in.
  void _applyTableEdit(TableEdit edit) {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset;
    if (offset < 0) return;
    final result = TableEditService.apply(text, offset.clamp(0, text.length),
        edit);
    if (result == null) return;
    // A snapshot first: the whole table is reformatted, so a single undo has
    // to take the reader back to what they had.
    ref.read(editorProvider.notifier).pushHistory(text);
    _controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.offset),
    );
  }

  void _applyBlockEdit((String, int) Function(String, int) edit) {
    final text = _controller.text;
    final caret = _controller.selection.baseOffset.clamp(0, text.length);
    final line = '\n'.allMatches(text.substring(0, caret)).length;

    final (updated, targetLine) = edit(text, line);
    if (updated == text) return;

    final lines = updated.split('\n');
    var offset = 0;
    for (var i = 0; i < targetLine && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, updated.length),
      ),
    );
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

  /// Adds or removes [prefix] on every line the selection touches.
  ///
  /// It used to act on the line holding the caret and nothing else, so
  /// selecting three lines and asking for a bullet list bulleted one of them
  /// (#3). Turning a block of lines into a list is the ordinary reason anyone
  /// selects several lines at once.
  ///
  /// Whether it adds or removes is decided for the block as a whole: if every
  /// line already carries the prefix it comes off all of them, otherwise it
  /// goes on all of them. Deciding line by line would toggle a half-marked
  /// block into its own inverse, which never leaves it uniform.
  void _applyLinePrefixAtCursor(String prefix) {
    final selection = _controller.selection;
    final text = _controller.text;
    final anchor = selection.baseOffset.clamp(0, text.length);
    final head = selection.isValid
        ? selection.extentOffset.clamp(0, text.length)
        : anchor;
    final from = anchor < head ? anchor : head;
    final to = anchor < head ? head : anchor;

    var blockStart = text.lastIndexOf('\n', from > 0 ? from - 1 : 0);
    blockStart = blockStart == -1 ? 0 : blockStart + 1;
    // A selection that ends exactly at a line start does not include that
    // line: dragging down to the beginning of the next line should not mark
    // it too.
    final searchFrom = to > from && to > 0 && text[to - 1] == '\n' ? to - 1 : to;
    var blockEnd = text.indexOf('\n', searchFrom);
    if (blockEnd == -1) blockEnd = text.length;

    final lines = text.substring(blockStart, blockEnd).split('\n');
    final allMarked = lines.every(
      (line) => SourceEditor.applyLinePrefix(line, prefix).length < line.length,
    );
    final replaced = [
      for (final line in lines)
        allMarked || SourceEditor.applyLinePrefix(line, prefix).length >
                line.length
            ? SourceEditor.applyLinePrefix(line, prefix)
            : line,
    ].join('\n');

    final replacement = replaced;
    final delta = replacement.length - (blockEnd - blockStart);

    _controller.value = TextEditingValue(
      text: text.substring(0, blockStart) +
          replacement +
          text.substring(blockEnd),
      // The block stays selected, so the same key can be pressed again to
      // take the markers off; a collapsed caret would make that impossible
      // without reselecting.
      selection: from == to
          ? TextSelection.collapsed(
              offset: (anchor + delta).clamp(
                blockStart,
                blockStart + replacement.length,
              ),
            )
          : TextSelection(
              baseOffset: blockStart,
              extentOffset: blockStart + replacement.length,
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
    // Not while the preview has a block open: in split view both panes are on
    // screen and both would otherwise apply the same command, in two
    // different places. The pane being typed in takes it.
    final previewEditing =
        ref.watch(editorProvider.select((s) => s.previewBlockEditing));
    if (pendingFormat != null && !previewEditing) {
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

    // The same limit the preview applies. The setting is called "editor
    // maximum width" and only the preview honoured it, so a wide window put
    // the preview in a measured column and left the source spanning the whole
    // screen — and in split view the two halves did not line up. Upstream
    // describes the setting as "the maximum editor area width", which is both
    // of them.
    final maxWidth = ref.watch(settingsProvider).editorMaxWidth.toDouble();

    // Current line for highlighting
    final currentLine = ref.watch(editorProvider.select((s) => s.cursorLine));

    // After the text has been laid out, and not before: the numbers are
    // placed from that layout. Nothing happens when the answer is the same as
    // last time, so this settles in a frame rather than looping.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGutterMarks());

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(
          builder: (context, outer) {
            // Room under the last line, so it can be scrolled up to where the
            // eye is instead of staying pinned to the bottom edge (#2). Every
            // editor worth the name does this; HBuilder X, which the report
            // pointed at, does it too.
            //
            // The gutter gets exactly the same room: it is a separate scroll
            // view kept in step with the text, and giving one of them more to
            // scroll than the other makes the line numbers stop while the
            // text carries on.
            final bottomRoom = outer.maxHeight.isFinite
                ? (outer.maxHeight * 0.6).clamp(0.0, 600.0)
                : 0.0;
            return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              key: _gutterKey,
              width: gutterWidth,
              decoration: BoxDecoration(
                color: tokens.colorSurface,
                border: Border(
                  right: BorderSide(color: tokens.colorBorder, width: 1),
                ),
              ),
              // Each number is placed where its line actually starts, which
              // the editor's layout is asked for. A scrolling list of
              // equal-height rows cannot do that: a wrapped line is taller
              // than one row and every number below it slid up.
              child: ClipRect(
                child: Stack(
                  children: [
                    for (final mark in _gutterMarks)
                      Positioned(
                        top: mark.dy,
                        right: 8,
                        child: Text(
                          '${mark.number}',
                          style: TextStyle(
                            color: mark.number - 1 == currentLine
                                ? tokens.colorText
                                : tokens.colorTextMuted,
                            fontFamily: config.fontFamily,
                            fontSize: 12,
                            height: config.lineHeight,
                          ),
                        ),
                      ),
                  ],
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
                        key: _fieldKey,
                        focusNode: _fieldFocus,
                        controller: _controller,
                        scrollController: _editorScrollController,
                        maxLines: null,
                        expands: true,
                        style: editorStyle,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomRoom),
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
          },
        ),
      ),
    );
  }
}
