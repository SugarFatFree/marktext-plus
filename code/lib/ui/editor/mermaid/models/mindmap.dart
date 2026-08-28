/// Data models for Mindmap diagrams
library;

/// Outline shape of a mindmap node.
enum MindmapShape {
  /// No decoration — bare text.
  none,

  /// `[text]` — square.
  square,

  /// `(text)` — rounded.
  rounded,

  /// `((text))` — circle.
  circle,

  /// `))text((` — bang.
  bang,

  /// `)text(` — cloud.
  cloud,

  /// `{{text}}` — hexagon.
  hexagon,
}

/// Which half of the map a subtree was placed on.
enum MindmapSide {
  /// The root itself, which belongs to neither side.
  centre,

  /// Laid out to the right of the root.
  right,

  /// Laid out to the left of the root.
  left,
}

/// One node in a mindmap tree.
///
/// Layout fields are mutable because the layout pass fills them in, matching
/// how [MermaidNode] works for graph diagrams.
class MindmapNode {
  /// Creates a node.
  MindmapNode({
    required this.label,
    this.shape = MindmapShape.none,
    this.cssClass,
    this.depth = 0,
    List<MindmapNode>? children,
  }) : children = children ?? <MindmapNode>[];

  /// Display text.
  final String label;

  /// Outline shape.
  final MindmapShape shape;

  /// Class applied via `:::name`.
  final String? cssClass;

  /// Distance from the root, which drives font size and colour.
  final int depth;

  /// Child nodes, in source order.
  final List<MindmapNode> children;

  /// Centre X after layout.
  double x = 0;

  /// Centre Y after layout.
  double y = 0;

  /// Width after measurement.
  double width = 0;

  /// Height after measurement.
  double height = 0;

  /// Which half of the map this node sits on.
  MindmapSide side = MindmapSide.centre;

  /// Total vertical space this subtree needs; set during layout.
  double subtreeHeight = 0;

  /// Every node in this subtree, including itself.
  Iterable<MindmapNode> get descendants sync* {
    yield this;
    for (final child in children) {
      yield* child.descendants;
    }
  }
}

/// A parsed mindmap.
class MindmapData {
  /// Creates mindmap data.
  const MindmapData({required this.root});

  /// Root of the tree.
  final MindmapNode root;

  /// Every node, root first.
  Iterable<MindmapNode> get allNodes => root.descendants;
}
