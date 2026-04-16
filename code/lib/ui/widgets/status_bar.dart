import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/word_count_provider.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final wordCount = ref.watch(wordCountProvider);
    final l10n = AppLocalizations.of(context)!;
    final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
    final style = TextStyle(fontSize: 12, color: tokens.colorTextMuted);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          top: BorderSide(color: tokens.colorBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(l10n.statusLine(editorState.cursorLine + 1, editorState.cursorCol + 1), style: style),
          _divider(tokens),
          Text(l10n.statusEncoding, style: style),
          _divider(tokens),
          Text(l10n.statusMarkdown, style: style),
          _divider(tokens),
          Text(l10n.statusLineFeed, style: style),
          const Spacer(),
          Text('${l10n.statusWords}: ${wordCount.words}', style: style),
          _divider(tokens),
          Text('${l10n.statusChars}: ${wordCount.characters}', style: style),
          _divider(tokens),
          Text('${l10n.statusParagraphs}: ${wordCount.paragraphs}', style: style),
        ],
      ),
    );
  }

  Widget _divider(AppThemeTokens tokens) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: tokens.colorBorder,
    );
  }
}
