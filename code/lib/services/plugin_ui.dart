/// What a plugin draws, as a tree the editor renders.
///
/// A plugin's answer used to be a string: the editor drew it as text in a
/// card, a pane or a drawer, and anything more — a form, a row of choices, a
/// button — was out of reach. This is the smallest thing that is not a string.
///
/// It is deliberately not HTML. A WebView costs a browser context in memory
/// and, on Linux, a system library the reader may not have; these nodes are
/// Flutter widgets, so they cost nothing at startup, follow the reader's
/// theme without the plugin knowing what the theme is, and cannot escape the
/// container they were put in. The escape hatch for what this cannot express
/// is written up in `docs/design/plugin-drawn-ui.md`.
library;

/// One node. Sealed, so a renderer that forgets a kind does not compile.
sealed class PluginUiNode {
  const PluginUiNode();
}

/// A run of text. The plugin has already translated it.
class PluginUiText extends PluginUiNode {
  const PluginUiText(this.text, {this.emphasis = false});

  final String text;

  /// Drawn as the container's title rather than its body.
  final bool emphasis;
}

/// A field the reader types into. [id] is what `on_event` is told.
class PluginUiInput extends PluginUiNode {
  const PluginUiInput({
    required this.id,
    this.value = '',
    this.placeholder = '',
    this.multiline = false,
  });

  final String id;
  final String value;
  final String placeholder;
  final bool multiline;
}

/// A row of one-tap choices. Choosing one sends it as [id]'s value.
class PluginUiChips extends PluginUiNode {
  const PluginUiChips({required this.id, required this.options});

  final String id;
  final List<String> options;
}

/// A button. Pressing it sends [id] with the value of every input beside it.
class PluginUiButton extends PluginUiNode {
  const PluginUiButton({
    required this.id,
    required this.label,
    this.primary = false,
  });

  final String id;
  final String label;
  final bool primary;
}

class PluginUiRow extends PluginUiNode {
  const PluginUiRow(this.children);

  final List<PluginUiNode> children;
}

class PluginUiColumn extends PluginUiNode {
  const PluginUiColumn(this.children);

  final List<PluginUiNode> children;
}

/// Blank space, for pushing what follows to the far end of a row.
class PluginUiSpacer extends PluginUiNode {
  const PluginUiSpacer();
}

/// What a tree may be, so that a plugin cannot hand over one that costs more
/// to draw than the editor has.
///
/// Both are generous for anything a person would design and far below what
/// would hurt: the deepest sensible layout is a column of rows of buttons,
/// and the widest is a list of choices.
class PluginUiLimits {
  const PluginUiLimits._();

  /// How deeply nodes may nest. A tree deeper than this is refused rather
  /// than truncated: the parser recurses, and a plugin should not be able to
  /// decide how much stack the editor uses.
  static const int maxDepth = 12;

  /// How many nodes a tree may hold in total.
  static const int maxNodes = 500;
}
