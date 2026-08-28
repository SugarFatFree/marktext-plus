/// Data models for treemap diagrams (`treemap-beta`).
library;

/// One box in the treemap.
///
/// A node with children is a section; a node with a value and no children is a
/// leaf. Mermaid's grammar distinguishes them by whether a value was written,
/// so a section that was given a value keeps it — the drawn area still comes
/// from what is underneath it.
class TreemapNode {
  /// Creates a treemap node.
  TreemapNode({
    required this.name,
    this.value,
    this.classSelector,
    List<TreemapNode>? children,
  }) : children = children ?? [];

  /// The label.
  final String name;

  /// The value written for a leaf, if any.
  final double? value;

  /// The `:::name` class this node was tagged with.
  final String? classSelector;

  /// Nodes nested under this one.
  final List<TreemapNode> children;

  /// Whether this node is drawn as a single box rather than a frame.
  bool get isLeaf => children.isEmpty;

  /// The area this node stands for.
  ///
  /// A section's own area is what its children add up to: writing a value on
  /// a section and a different set of values underneath it would otherwise
  /// draw a picture whose parts do not fill their whole.
  double get total {
    if (children.isEmpty) return value ?? 0;
    var sum = 0.0;
    for (final child in children) {
      sum += child.total;
    }
    return sum;
  }
}

/// A complete treemap.
class TreemapDiagramData {
  /// Creates treemap data.
  const TreemapDiagramData({
    required this.roots,
    this.title,
    this.classStyles = const {},
  });

  /// Optional title.
  final String? title;

  /// The top-level nodes.
  ///
  /// Mermaid allows only one, and says so; this keeps a list because refusing
  /// to draw anything at all is a worse answer to a second root than drawing
  /// both of them.
  final List<TreemapNode> roots;

  /// `classDef name style` declarations, by name.
  final Map<String, String> classStyles;

  /// Whether there is anything to draw.
  bool get isEmpty => roots.isEmpty;

  /// Everything the roots add up to.
  double get total {
    var sum = 0.0;
    for (final root in roots) {
      sum += root.total;
    }
    return sum;
  }
}
