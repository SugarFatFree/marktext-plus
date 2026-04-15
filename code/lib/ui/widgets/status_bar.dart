import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/editor_provider.dart';
import '../../providers/word_count_provider.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final wordCount = ref.watch(wordCountProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            l10n.statusLine(editorState.cursorLine + 1, editorState.cursorCol + 1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _divider(context),
          Text(
            l10n.statusEncoding,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _divider(context),
          Text(
            l10n.statusMarkdown,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _divider(context),
          Text(
            'LF',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            '${l10n.statusWords}: ${wordCount.words}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _divider(context),
          Text(
            '${l10n.statusChars}: ${wordCount.characters}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _divider(context),
          Text(
            '${l10n.statusParagraphs}: ${wordCount.paragraphs}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).dividerColor,
    );
  }
}
