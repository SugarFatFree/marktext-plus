import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/plugin_ui.dart';
import '../editor/markdown_renderer.dart';

/// Draws what a plugin described, as the editor's own widgets.
///
/// The plugin says what it wants and the editor decides how it looks, so a
/// plugin's form is themed like the rest of the application without the
/// plugin knowing what the theme is — and cannot draw outside the box it was
/// given.
///
/// The state lives here rather than in the plugin: a plugin that had to
/// remember what was typed in the form it drew one step ago would be keeping
/// a copy of something the editor already has, and the two copies would
/// disagree the first time a rebuild dropped one.
class PluginUiView extends StatefulWidget {
  const PluginUiView({
    required this.root,
    required this.onEvent,
    this.loadImage,
    super.key,
  });

  final PluginUiNode root;

  /// The id of what was used, and every input in the tree by id.
  final void Function(String id, Map<String, String> values) onEvent;

  /// Fetches the pictures the tree asks for. Null draws nothing in their
  /// place: a caller with no plugin directory to resolve against has nowhere
  /// to fetch them from.
  final Future<Uint8List> Function(String source)? loadImage;

  @override
  State<PluginUiView> createState() => _PluginUiViewState();
}

class _PluginUiViewState extends State<PluginUiView> {
  final Map<String, TextEditingController> _inputs = {};
  final Map<String, String> _chosen = {};

  /// Started once per source, so a rebuild does not fetch the same picture
  /// again — and a picture that failed stays failed until the tree changes
  /// rather than retrying on every frame.
  final Map<String, Future<Uint8List>> _pictures = {};

  @override
  void didUpdateWidget(PluginUiView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new tree is a new form. Keeping controllers for ids the plugin no
    // longer draws would leak them, and keeping their text would put an
    // answer from the last question into this one.
    if (!identical(oldWidget.root, widget.root)) _reset();
  }

  void _reset() {
    for (final controller in _inputs.values) {
      controller.dispose();
    }
    _inputs.clear();
    _chosen.clear();
    _pictures.clear();
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }

  TextEditingController _controllerFor(PluginUiInput node) => _inputs
      .putIfAbsent(node.id, () => TextEditingController(text: node.value));

  Map<String, String> _values() => {
    for (final entry in _inputs.entries) entry.key: entry.value.text,
    ..._chosen,
  };

  @override
  Widget build(BuildContext context) => _build(widget.root, Axis.vertical);

  Widget _build(PluginUiNode node, Axis within) {
    final theme = Theme.of(context);
    switch (node) {
      case PluginUiText(:final text, :final emphasis):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            text,
            style: emphasis ? theme.textTheme.titleSmall : null,
          ),
        );

      case PluginUiInput():
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextField(
            controller: _controllerFor(node),
            minLines: node.multiline ? 3 : null,
            maxLines: node.multiline ? null : 1,
            keyboardType: node.multiline
                ? TextInputType.multiline
                : TextInputType.text,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: node.placeholder.isEmpty ? null : node.placeholder,
            ),
          ),
        );

      case PluginUiChips(:final id, :final options):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: _chosen[id] == option,
                  // Choosing is an event of its own: a plugin may act on the
                  // choice alone, and one that waits for a button still has
                  // the value in `values`.
                  onSelected: (_) {
                    setState(() => _chosen[id] = option);
                    widget.onEvent(id, _values());
                  },
                ),
            ],
          ),
        );

      case PluginUiButton(:final id, :final label, :final primary):
        void press() => widget.onEvent(id, _values());
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: primary
              ? FilledButton(onPressed: press, child: Text(label))
              : TextButton(onPressed: press, child: Text(label)),
        );

      case PluginUiSelect(:final id, :final options, :final value):
        final chosen = _chosen[id] ??
            (value.isNotEmpty && options.contains(value) ? value : null);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: DropdownButtonFormField<String>(
            initialValue: chosen,
            isDense: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final option in options)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (picked) {
              if (picked == null) return;
              setState(() => _chosen[id] = picked);
              widget.onEvent(id, _values());
            },
          ),
        );

      case PluginUiCheckbox(:final id, :final label, :final value):
        final ticked = _chosen[id] == null ? value : _chosen[id] == 'true';
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          value: ticked,
          title: Text(label),
          onChanged: (picked) {
            setState(() => _chosen[id] = (picked ?? false).toString());
            widget.onEvent(id, _values());
          },
        );

      // The editor's own renderer, so a plugin's answer looks like the
      // document it is about rather than like flat text with its `##` showing.
      case PluginUiMarkdown(:final source):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: MarkdownRenderer(markdown: source),
        );

      case PluginUiImage(:final source, :final height):
        final loader = widget.loadImage;
        if (loader == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: FutureBuilder<Uint8List>(
            future: _pictures.putIfAbsent(source, () => loader(source)),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // Said rather than left blank: a picture that did not arrive
                // looks like the plugin forgot to draw one.
                return Text(
                  '${snapshot.error}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                );
              }
              final bytes = snapshot.data;
              if (bytes == null) {
                return SizedBox(
                  height: height > 0 ? height : 48,
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return Image.memory(
                bytes,
                height: height > 0 ? height : null,
                fit: BoxFit.contain,
              );
            },
          ),
        );

      case PluginUiRow(:final children):
        return Row(
          children: [
            for (final child in children)
              child is PluginUiSpacer
                  ? const Spacer()
                  : Flexible(child: _build(child, Axis.horizontal)),
          ],
        );

      case PluginUiColumn(:final children):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final child in children) _build(child, Axis.vertical),
          ],
        );

      // A spacer outside a row has no direction to expand in — a column here
      // is as tall as what is in it — so it is a gap rather than a stretch.
      case PluginUiSpacer():
        return within == Axis.horizontal
            ? const Spacer()
            : const SizedBox(height: 12);
    }
  }
}
