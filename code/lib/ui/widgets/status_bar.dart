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
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          top: BorderSide(color: tokens.colorBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            l10n.statusLine(editorState.cursorLine + 1, editorState.cursorCol + 1),
            style: TextStyle(fontSize: 12, color: tokens.colorTextMuted),
          ),
          _divider(tokens),
          Text(
            l10n.statusEncoding,
            style: TextStyle(fontSize: 12, color: tokens.colorTextMuted),
          ),
          _divider(tokens),
          Text(
            l10n.statusMarkdown,
            style: TextStyle(fontSize: 12, color: tokens.colorTextMuted),
          ),
          _divider(tokens),
          Text(
            'LF',
            style: TextStyle(fontSize: 12, color: tokens.colorTextMuted),
          ),
          const Spacer(),
          Text(
            '${l10n.statusWords}: ${wordCount.words}',
            style: TextStyle(fontSize: 12, color: tokens.colorTextMuted),
          ),
          _divider(tokens),
          Text(
            '${l10n.statusChars}: ${wordCount.characters}',
            style: TextStyle(fontSize: 12, color: tokens.colorTextMuted),
          ),
          _divider(tokens),
          Text(
            '${l10n.statusParagraphs}: ${wordCount.paragraphs}',
            style: TextStyle(fontSize: 12, color: tokens.colorTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppThemeTokens tokens) {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: tokens.colorBorder,
    );
  }
}
