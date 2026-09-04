import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/plugin_provider.dart';

/// A plugin's short answer, floating over the top-right of the document.
///
/// It replaces the modal dialog that used to carry these. A translation of a
/// selected sentence is read against the sentence, so the document has to stay
/// visible and stay scrollable — a barrier over the window made the one thing
/// the reader wanted to compare against unreachable, and did it for the whole
/// several seconds a model takes.
///
/// It does not scroll with the text: it is pinned to the pane, so the reader
/// can move through the document with the answer still in view.
class PluginTipLayer extends ConsumerWidget {
  const PluginTipLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tip = ref.watch(pluginTipProvider);
    if (tip == null) return child;

    // `expand`, because a Stack sizes itself to its non-positioned children:
    // left to itself it shrank to whatever the document happened to be, and
    // "twelve from the right" became twelve from the right of that. The card
    // came out 32 pixels wide beside the first line of text.
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(top: 12, right: 12, child: PluginTipCard(tip: tip)),
      ],
    );
  }
}

/// The card itself, named so its geometry can be asserted on: it is pinned to
/// a corner, and a Stack that sized itself to the document once put it in the
/// middle of the text at thirty-two pixels wide.
class PluginTipCard extends ConsumerWidget {
  const PluginTipCard({required this.tip, super.key});

  final PluginTip tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 380,
        // Tall enough to read an answer, short enough that the document it is
        // about is still there behind it.
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tip.title,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!tip.busy)
                    IconButton(
                      tooltip: l10n?.copy,
                      icon: const Icon(Icons.copy, size: 15),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: tip.text)),
                    ),
                  IconButton(
                    tooltip: l10n?.close,
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        ref.read(pluginTipProvider.notifier).dismiss(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Flexible(
                child: tip.busy
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n?.pluginWorking ?? '',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      )
                    : SingleChildScrollView(child: SelectableText(tip.text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
