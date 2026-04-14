import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/editor_provider.dart';

class FindReplaceBar extends ConsumerStatefulWidget {
  final TextEditingController textController;

  const FindReplaceBar({
    super.key,
    required this.textController,
  });

  @override
  ConsumerState<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends ConsumerState<FindReplaceBar> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();

  bool _caseSensitive = false;
  bool _wholeWord = false;
  bool _useRegex = false;
  bool _showReplace = false;

  List<TextRange> _matches = [];
  int _currentMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _findController.addListener(_onFindTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  void _onFindTextChanged() {
    _findMatches();
  }

  void _findMatches() {
    final text = widget.textController.text;
    final pattern = _findController.text;

    if (pattern.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    final matches = <TextRange>[];

    if (_useRegex) {
      try {
        final regex = RegExp(
          pattern,
          caseSensitive: _caseSensitive,
        );
        for (final match in regex.allMatches(text)) {
          matches.add(TextRange(start: match.start, end: match.end));
        }
      } catch (e) {
        // Invalid regex
      }
    } else {
      String searchText = text;
      String searchPattern = pattern;

      if (!_caseSensitive) {
        searchText = text.toLowerCase();
        searchPattern = pattern.toLowerCase();
      }

      int index = 0;
      while (index < searchText.length) {
        final pos = searchText.indexOf(searchPattern, index);
        if (pos == -1) break;

        if (_wholeWord) {
          final isWordStart = pos == 0 || !_isWordChar(text[pos - 1]);
          final isWordEnd = pos + pattern.length >= text.length ||
              !_isWordChar(text[pos + pattern.length]);

          if (isWordStart && isWordEnd) {
            matches.add(TextRange(start: pos, end: pos + pattern.length));
          }
        } else {
          matches.add(TextRange(start: pos, end: pos + pattern.length));
        }

        index = pos + 1;
      }
    }

    setState(() {
      _matches = matches;
      _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
    });

    if (matches.isNotEmpty) {
      _highlightMatch(0);
    }
  }

  bool _isWordChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }

  void _highlightMatch(int index) {
    if (index < 0 || index >= _matches.length) return;

    final match = _matches[index];
    widget.textController.selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
  }

  void _findNext() {
    if (_matches.isEmpty) return;

    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    });
    _highlightMatch(_currentMatchIndex);
  }

  void _findPrevious() {
    if (_matches.isEmpty) return;

    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    });
    _highlightMatch(_currentMatchIndex);
  }

  void _replace() {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _matches.length) return;

    final match = _matches[_currentMatchIndex];
    final text = widget.textController.text;
    final replacement = _replaceController.text;

    final newText = text.substring(0, match.start) +
        replacement +
        text.substring(match.end);

    widget.textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: match.start + replacement.length,
      ),
    );

    _findMatches();
  }

  void _replaceAll() {
    if (_matches.isEmpty) return;

    final text = widget.textController.text;
    final replacement = _replaceController.text;
    final pattern = _findController.text;

    String newText = text;

    if (_useRegex) {
      try {
        final regex = RegExp(
          pattern,
          caseSensitive: _caseSensitive,
        );
        newText = text.replaceAll(regex, replacement);
      } catch (e) {
        // Invalid regex
        return;
      }
    } else {
      // Replace from end to start to maintain indices
      for (int i = _matches.length - 1; i >= 0; i--) {
        final match = _matches[i];
        newText = newText.substring(0, match.start) +
            replacement +
            newText.substring(match.end);
      }
    }

    widget.textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: 0),
    );

    _findMatches();
  }

  void _close() {
    ref.read(editorProvider.notifier).hideFindReplace();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _findController,
                  focusNode: _findFocusNode,
                  decoration: InputDecoration(
                    hintText: l10n.editFind,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    suffixText: _matches.isNotEmpty
                        ? '${_currentMatchIndex + 1}/${_matches.length}'
                        : null,
                  ),
                  onSubmitted: (_) => _findNext(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: _matches.isNotEmpty ? _findPrevious : null,
                tooltip: l10n.editFindPrevious,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: _matches.isNotEmpty ? _findNext : null,
                tooltip: l10n.editFindNext,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showReplace ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _showReplace = !_showReplace;
                  });
                },
                tooltip: l10n.editReplace,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: _close,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          if (_showReplace) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replaceController,
                    decoration: InputDecoration(
                      hintText: l10n.editReplace,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onSubmitted: (_) => _replace(),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _matches.isNotEmpty ? _replace : null,
                  child: Text(l10n.editReplace),
                ),
                TextButton(
                  onPressed: _matches.isNotEmpty ? _replaceAll : null,
                  child: Text(l10n.editReplaceAll),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOptionButton(
                label: 'Aa',
                tooltip: l10n.editCaseSensitive,
                isActive: _caseSensitive,
                onPressed: () {
                  setState(() {
                    _caseSensitive = !_caseSensitive;
                  });
                  _findMatches();
                },
              ),
              const SizedBox(width: 4),
              _buildOptionButton(
                label: '\\b',
                tooltip: l10n.editWholeWord,
                isActive: _wholeWord,
                onPressed: () {
                  setState(() {
                    _wholeWord = !_wholeWord;
                  });
                  _findMatches();
                },
              ),
              const SizedBox(width: 4),
              _buildOptionButton(
                label: '.*',
                tooltip: l10n.editRegex,
                isActive: _useRegex,
                onPressed: () {
                  setState(() {
                    _useRegex = !_useRegex;
                  });
                  _findMatches();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
