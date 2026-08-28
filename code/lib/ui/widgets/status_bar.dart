import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/word_count_provider.dart';
import '../../services/update_service.dart';
import '../editor/syntax_highlighter.dart';
import '../../models/file_encoding.dart';
import '../../models/line_ending.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final wordCount = ref.watch(wordCountProvider);
    // Losing the syntax colours on a huge file is otherwise unexplained. This
    // reads only the boolean, so typing does not rebuild the status bar.
    final highlightOff = ref.watch(
      activeTabProvider.select(
        (tab) =>
            (tab?.content.length ?? 0) >
            IncrementalMarkdownHighlighter.maxHighlightedLength,
      ),
    );
    final lineEnding = ref.watch(
      activeTabProvider.select((tab) => tab?.lineEnding ?? LineEnding.lf),
    );
    final encoding = ref.watch(
      activeTabProvider.select(
        (tab) => tab?.encoding ?? FileEncoding.utf8Encoding,
      ),
    );
    final updateState = ref.watch(updateProvider);
    final l10n = AppLocalizations.of(context)!;
    final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
    final style = TextStyle(fontSize: 12, color: tokens.colorTextMuted);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(top: BorderSide(color: tokens.colorBorder, width: 1)),
      ),
      // What fits, in order of what a reader can least do without. The bar was
      // striped from about 790 pixels down, and it cannot wrap or scroll —
      // a Spacer needs a bounded width, which a scrolling row does not give.
      // So the least useful counts stand down instead.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showParagraphs = width >= 820;
          final showChars = width >= 700;
          final showDocumentKind = width >= 600;
          final showEncoding = width >= 440;
          final showLineEnding = width >= 380;
          return Row(
        children: [
          Text(
            l10n.statusLine(
              editorState.cursorLine + 1,
              editorState.cursorCol + 1,
            ),
            style: style,
          ),
          _divider(tokens),
          // Was `l10n.statusEncoding`, which is the literal string "UTF-8" in
          // every language file — the same fiction the line ending indicator
          // used to tell. A document that opened as mojibake is otherwise a
          // mystery, and "Latin-1" here is the explanation.
          if (showEncoding) ...[
            Text(encoding.label, style: style),
            _divider(tokens),
          ],
          if (showDocumentKind) ...[
            Text(l10n.statusMarkdown, style: style),
            _divider(tokens),
          ],
          // Was the literal "LF" regardless of what the file actually used.
          //
          // Clickable, which is how the upstream editor's Edit menu offers the
          // same choice — and how a status bar usually offers it. No new copy
          // is needed: the label is "LF" or "CRLF" in every language.
          if (showLineEnding)
            _LineEndingButton(lineEnding: lineEnding, style: style),
          if (highlightOff) ...[
            _divider(tokens),
            Text(l10n.statusHighlightOff, style: style),
          ],
          const Spacer(),
          if (updateState.availableUpdate != null &&
              !updateState.dismissed) ...[
            _buildUpdateIndicator(
              updateState.availableUpdate!,
              tokens,
              ref,
              l10n,
            ),
            _divider(tokens),
          ],
          Text('${l10n.statusWords}: ${wordCount.words}', style: style),
          if (showChars) ...[
            _divider(tokens),
            Text('${l10n.statusChars}: ${wordCount.characters}', style: style),
          ],
          if (showParagraphs) ...[
            _divider(tokens),
            Text(
              '${l10n.statusParagraphs}: ${wordCount.paragraphs}',
              style: style,
            ),
          ],
        ],
          );
        },
      ),
    );
  }

  Widget _buildUpdateIndicator(
    UpdateInfo update,
    AppThemeTokens tokens,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.colorAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A bare version number does not say what it is; the tooltip does.
          Tooltip(
            message: l10n.updateAvailable,
            child: InkWell(
              onTap: () => launchUrl(Uri.parse(update.url)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.system_update,
                    size: 14,
                    color: tokens.colorAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'v${update.version}',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.colorAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // UpdateNotifier.dismiss and its label both existed, with nothing
          // calling them: the badge could not be got rid of.
          //
          // Dismissing also records the version. `skipVersion` was written
          // into the config, read when deciding whether to show the badge, and
          // never set by anything — so the badge came back on the next launch
          // however many times it was waved away.
          Tooltip(
            message: l10n.updateDismiss,
            child: InkWell(
              onTap: () {
                ref.read(updateProvider.notifier).dismiss();
                ref.read(settingsProvider.notifier).updateConfig(
                      (c) => c.copyWith(skipVersion: update.version),
                    );
              },
              child: Icon(Icons.close, size: 12, color: tokens.colorAccent),
            ),
          ),
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

/// The line ending indicator, which switches convention when clicked.
class _LineEndingButton extends ConsumerWidget {
  const _LineEndingButton({required this.lineEnding, required this.style});

  final LineEnding lineEnding;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);

    return MouseRegion(
      cursor: activeTab == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: activeTab == null
            ? null
            : () => ref
                  .read(tabProvider.notifier)
                  .setLineEnding(
                    activeTab.id,
                    lineEnding == LineEnding.lf
                        ? LineEnding.crlf
                        : LineEnding.lf,
                  ),
        child: Text(lineEnding.label, style: style),
      ),
    );
  }
}
