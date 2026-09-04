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
class PluginTipLayer extends ConsumerStatefulWidget {
  const PluginTipLayer({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PluginTipLayer> createState() => _PluginTipLayerState();
}

class _PluginTipLayerState extends ConsumerState<PluginTipLayer> {
  /// Where the reader dragged the card, from the top right. Null until they
  /// move it, so a fresh tip appears in the corner it is expected in.
  Offset? _moved;

  static const _inset = 12.0;

  @override
  Widget build(BuildContext context) {
    final tip = ref.watch(pluginTipProvider);

    // The Stack is always here, whether or not there is anything to put in it.
    // Returning the child directly when there was no tip moved the editor's
    // element in the tree every time one came or went, so Flutter tore down
    // the whole document subtree and built it again — which the reader saw as
    // the window flashing.
    //
    // LayoutBuilder is outside the Stack, not between it and the card:
    // `Positioned` only positions when it is a direct child of a Stack, and
    // anything in between turns it into an ordinary child that `expand` then
    // stretches to the whole pane.
    return LayoutBuilder(
      builder: (context, constraints) {
        final at = _moved ?? const Offset(_inset, _inset);
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (tip != null)
              Positioned(
                top: at.dy,
                right: at.dx,
                child: PluginTipCard(
                  tip: tip,
                  onDrag: (delta) => setState(() {
                    // Kept wholly inside the pane, its own width included: a
                    // card that walks off the edge cannot be grabbed again to
                    // bring it back.
                    final rightMost = (constraints.maxWidth -
                            PluginTipCard.maxWidth -
                            _inset)
                        .clamp(_inset, double.infinity);
                    final lowest = (constraints.maxHeight -
                            PluginTipCard.grabHeight)
                        .clamp(_inset, double.infinity);
                    _moved = Offset(
                      (at.dx - delta.dx).clamp(_inset, rightMost),
                      (at.dy + delta.dy).clamp(_inset, lowest),
                    );
                  }),
                  onDismiss: () {
                    setState(() => _moved = null);
                    ref.read(pluginTipProvider.notifier).dismiss();
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class PluginTipCard extends ConsumerStatefulWidget {
  const PluginTipCard({
    required this.tip,
    this.onDrag,
    this.onDismiss,
    super.key,
  });

  final PluginTip tip;

  /// Dragging the title bar moves the card, the way a window moves.
  final void Function(Offset delta)? onDrag;
  final VoidCallback? onDismiss;

  /// How wide the card ever gets.
  ///
  /// The layer needs it to keep a dragged card inside the pane, and there is
  /// one definition so the two cannot disagree: bounding the drag by the pane
  /// alone let the card walk off the left edge by its own width, where nothing
  /// could grab it to bring it back.
  static const maxWidth = 380.0;

  /// Enough of the card to grab it by, kept on screen vertically.
  static const grabHeight = 60.0;

  @override
  ConsumerState<PluginTipCard> createState() => _PluginTipCardState();
}

class _PluginTipCardState extends ConsumerState<PluginTipCard> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    ref.read(pluginTipProvider.notifier).answerWith(value);
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
    final onDrag = widget.onDrag;
    final onDismiss = widget.onDismiss;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: PluginTipCard.maxWidth,
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
                    child: MouseRegion(
                      cursor: SystemMouseCursors.move,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: onDrag == null
                            ? null
                            : (details) => onDrag(details.delta),
                        child: Text(
                          tip.title,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  if (!tip.busy && !tip.asking)
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
                    onPressed: onDismiss ??
                        () => ref.read(pluginTipProvider.notifier).dismiss(),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Flexible(
                child: tip.asking
                    ? _question(context, tip)
                    : tip.busy
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
                    : SingleChildScrollView(
                        child: SelectableText(tip.text),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The question, in the card the answer will appear in.
  ///
  /// The chips are a shortcut, not a cage: pressing one fills the box, and
  /// anything typed instead is taken as it stands.
  Widget _question(BuildContext context, PluginTip tip) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tip.question!, style: theme.textTheme.bodySmall),
          if (tip.choices.isNotEmpty) ...[
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final choice in tip.choices)
                    ChoiceChip(
                      label: Text(choice),
                      visualDensity: VisualDensity.compact,
                      selected: value.text.trim() == choice,
                      onSelected: (_) => _controller.value = TextEditingValue(
                        text: choice,
                        selection:
                            TextSelection.collapsed(offset: choice.length),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(isDense: true),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: _submit,
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ),
        ],
      ),
    );
  }
}
