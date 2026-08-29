import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../editor/code_highlighting.dart';

/// The languages offered for a fenced code block, in the order they match.
///
/// A fuzzy match rather than a prefix one: upstream MarkText's picker answers
/// `ts` with `typescript` and `js` with `javascript`, which a prefix match
/// would not. The characters have to appear in order, which is enough to keep
/// `xml` from matching `markdown` while still finding it from `md`.
List<String> matchingLanguages(String query) {
  final lower = query.trim().toLowerCase();
  if (lower.isEmpty) return List.of(CodeHighlighting.languages);

  final exact = <String>[];
  final prefix = <String>[];
  final fuzzy = <String>[];
  for (final language in CodeHighlighting.languages) {
    if (language == lower) {
      exact.add(language);
    } else if (language.startsWith(lower)) {
      prefix.add(language);
    } else if (_subsequence(lower, language)) {
      fuzzy.add(language);
    }
  }
  return [...exact, ...prefix, ...fuzzy];
}

/// Whether every character of [needle] appears in [haystack], in order.
bool _subsequence(String needle, String haystack) {
  var at = 0;
  for (final rune in needle.runes) {
    at = haystack.indexOf(String.fromCharCode(rune), at);
    if (at < 0) return false;
    at++;
  }
  return true;
}

/// The list that opens while a code fence's language is being typed.
///
/// Upstream MarkText gives this nine end-to-end tests of its own. Without it
/// the language has to be typed exactly and from memory, and a fence with a
/// misspelt language is drawn as plain, unhighlighted code with nothing to
/// say why.
class LanguagePicker extends StatefulWidget {
  /// Creates the picker.
  const LanguagePicker({
    super.key,
    required this.query,
    required this.onSelected,
  });

  /// What has been typed after the fence so far.
  final String query;

  /// Called with the chosen language, or null when the reader gives up.
  final ValueChanged<String?> onSelected;

  @override
  State<LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  final FocusNode _focusNode = FocusNode();
  int _selected = 0;

  List<String> get _results => matchingLanguages(widget.query);

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(LanguagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _selected = 0;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final results = _results;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        widget.onSelected(null);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (results.isEmpty) return KeyEventResult.handled;
        setState(() => _selected = (_selected + 1) % results.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (results.isEmpty) return KeyEventResult.handled;
        setState(() =>
            _selected = (_selected - 1 + results.length) % results.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.tab:
        if (results.isEmpty) {
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
    final results = _results;
    // Nothing matches what was typed, so there is nothing to offer — and a
    // picker that stays open showing an empty box is in the way.
    if (results.isEmpty) return const SizedBox.shrink();

    final tokens = AppTheme.getTokens(
      Theme.of(context).brightness == Brightness.dark
          ? 'Dark Graphite'
          : 'Red Graphite',
    );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(6),
        color: tokens.colorSurface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220, maxWidth: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) => ListTile(
              dense: true,
              key: ValueKey('language-${results[index]}'),
              selected: index == _selected,
              title: Text(
                results[index],
                style: const TextStyle(fontSize: 13),
              ),
              onTap: () => widget.onSelected(results[index]),
            ),
          ),
        ),
      ),
    );
  }
}
