import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/editor_provider.dart';

/// One thing the slash menu can insert.
class SlashCommand {
  /// Creates a slash command.
  const SlashCommand({
    required this.id,
    required this.label,
    required this.keywords,
    required this.action,
    required this.icon,
  });

  /// Stable identifier, used by tests and by the keyword match.
  final String id;

  /// What the reader sees.
  final String label;

  /// Extra words the filter matches on, so `/表格` and `/table` both find it.
  final List<String> keywords;

  /// The formatting action to apply once the `/` has been taken back out.
  final FormatAction action;

  /// The glyph shown beside the label.
  final IconData icon;

  /// Whether this entry matches what has been typed after the slash.
  bool matches(String query) {
    if (query.isEmpty) return true;
    final lower = query.toLowerCase();
    return id.contains(lower) ||
        label.toLowerCase().contains(lower) ||
        keywords.any((word) => word.toLowerCase().contains(lower));
  }
}

/// The list of blocks `/` offers, in the order upstream MarkText offers them.
List<SlashCommand> slashCommands(AppLocalizations l10n) => [
      SlashCommand(
        id: 'bullet-list',
        label: l10n.formatUnorderedList,
        keywords: const ['ul', 'bullet', '无序', '列表'],
        action: FormatAction.unorderedList,
        icon: Icons.format_list_bulleted,
      ),
      SlashCommand(
        id: 'order-list',
        label: l10n.formatOrderedList,
        keywords: const ['ol', 'number', '有序', '列表'],
        action: FormatAction.orderedList,
        icon: Icons.format_list_numbered,
      ),
      SlashCommand(
        id: 'task-list',
        label: l10n.formatTaskList,
        keywords: const ['todo', 'task', 'check', '任务', '待办'],
        action: FormatAction.taskList,
        icon: Icons.checklist,
      ),
      SlashCommand(
        id: 'table',
        label: l10n.formatTable,
        keywords: const ['table', '表格'],
        action: FormatAction.table,
        icon: Icons.table_chart_outlined,
      ),
      SlashCommand(
        id: 'code-fence',
        label: l10n.formatCodeBlock,
        keywords: const ['code', 'fence', '代码'],
        action: FormatAction.codeBlock,
        icon: Icons.code,
      ),
      // Beside the code fence it resembles. About five entries fit before the
      // list has to be scrolled, so this one is reached either by scrolling or
      // — faster — by typing any of its keywords: `/mermaid`, `/图`, `/流程图`.
      // It is the block this editor is built around, and the only one with
      // three parts to remember: the fence, the word, and a first line that
      // decides what kind of diagram it is.
      SlashCommand(
        id: 'mermaid-block',
        label: l10n.formatMermaidBlock,
        keywords: const ['mermaid', 'diagram', 'flow', '图', '流程图', '图表'],
        action: FormatAction.mermaidBlock,
        icon: Icons.account_tree_outlined,
      ),
      SlashCommand(
        id: 'quote-block',
        label: l10n.formatQuoteBlock,
        keywords: const ['quote', '引用'],
        action: FormatAction.quoteBlock,
        icon: Icons.format_quote,
      ),
      SlashCommand(
        id: 'math-block',
        label: l10n.formatMathBlock,
        keywords: const ['math', 'latex', '公式', '数学'],
        action: FormatAction.mathBlock,
        icon: Icons.functions,
      ),
      SlashCommand(
        id: 'horizontal-line',
        label: l10n.formatHorizontalRule,
        keywords: const ['hr', 'rule', 'divider', '分隔'],
        action: FormatAction.horizontalRule,
        icon: Icons.horizontal_rule,
      ),
      SlashCommand(
        id: 'front-matter',
        label: l10n.formatFrontMatter,
        keywords: const ['yaml', 'meta', '元数据'],
        action: FormatAction.frontMatter,
        icon: Icons.article_outlined,
      ),
      // Last, not first as upstream has them. Upstream is a WYSIWYG, where a
      // heading has no other way in; here `##` is two keystrokes, so these are
      // for a reader who has just found `/` and does not know that yet. Six of
      // them at the top would push the blocks that are genuinely awkward to
      // type — the table, the fence, the diagram — off the visible list.
      for (var level = 1; level <= 6; level++)
        SlashCommand(
          id: 'heading-$level',
          label: l10n.formatHeading(level),
          keywords: ['h$level', '#' * level, 'heading', '标题'],
          action: _headingActions[level - 1],
          icon: Icons.title,
        ),
    ];

/// The menu that opens when `/` is typed at the start of an empty block.
///
/// Upstream MarkText calls it the quick-insert menu and gives it four of its
/// own end-to-end tests; it is how most people reach a table or a code fence
/// without learning the markdown for it. This editor had only the command
/// palette, which is a different thing: it is opened by a shortcut, it is not
/// anchored to the caret, and it does not take the `/` back out afterwards.
class SlashMenu extends StatefulWidget {
  /// Creates the menu.
  const SlashMenu({
    super.key,
    required this.commands,
    required this.onSelected,
    this.initialQuery = '',
  });

  /// What the menu offers.
  final List<SlashCommand> commands;

  /// Called with the chosen entry, or null when the reader gives up.
  final ValueChanged<SlashCommand?> onSelected;

  /// Text already typed after the slash.
  final String initialQuery;

  @override
  State<SlashMenu> createState() => _SlashMenuState();
}

class _SlashMenuState extends State<SlashMenu> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  final FocusNode _focusNode = FocusNode();
  int _selected = 0;

  List<SlashCommand> get _results =>
      widget.commands.where((c) => c.matches(_controller.text)).toList();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final results = _results;
    if (results.isEmpty) return;
    setState(() {
      _selected = (_selected + delta) % results.length;
      if (_selected < 0) _selected += results.length;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        widget.onSelected(null);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.tab:
        final results = _results;
        if (results.isEmpty) {
          // Nothing matches what was typed; treat it as ordinary text rather
          // than swallowing the key.
          widget.onSelected(null);
        } else {
          widget.onSelected(results[_selected.clamp(0, results.length - 1)]);
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.getTokens(
      Theme.of(context).brightness == Brightness.dark
          ? 'Dark Graphite'
          : 'Red Graphite',
    );
    final results = _results;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: tokens.colorSurface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280, maxWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: TextField(
                  controller: _controller,
                  autofocus: false,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixText: '/',
                  ),
                  onChanged: (_) => setState(() => _selected = 0),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: results.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final command = results[index];
                          return ListTile(
                            dense: true,
                            key: ValueKey('slash-${command.id}'),
                            selected: index == _selected,
                            leading: Icon(command.icon, size: 18),
                            title: Text(
                              command.label,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () => widget.onSelected(command),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The heading actions in level order, so the menu can be built with a loop.
const _headingActions = [
  FormatAction.heading1,
  FormatAction.heading2,
  FormatAction.heading3,
  FormatAction.heading4,
  FormatAction.heading5,
  FormatAction.heading6,
];
