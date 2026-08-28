/// Data models for architecture diagrams (`architecture-beta`).
library;

/// Which face of a box an edge leaves from or arrives at.
enum ArchSide {
  /// Left face.
  left,

  /// Right face.
  right,

  /// Top face.
  top,

  /// Bottom face.
  bottom;

  /// Reads mermaid's one-letter side names.
  static ArchSide? parse(String text) => switch (text.toUpperCase()) {
        'L' => ArchSide.left,
        'R' => ArchSide.right,
        'T' => ArchSide.top,
        'B' => ArchSide.bottom,
        _ => null,
      };

  /// The step this side takes on the placement grid.
  ///
  /// The side named on an endpoint says where the *other* endpoint lies: in
  /// `db:R -- L:server`, the server is one column to the right of the db.
  (int, int) get step => switch (this) {
        ArchSide.left => (-1, 0),
        ArchSide.right => (1, 0),
        ArchSide.top => (0, -1),
        ArchSide.bottom => (0, 1),
      };
}

/// A service, junction, or group in an architecture diagram.
class ArchNode {
  /// Creates an architecture node.
  const ArchNode({
    required this.id,
    required this.label,
    this.icon,
    this.parent,
    this.isJunction = false,
  });

  /// The identifier edges refer to.
  final String id;

  /// The text drawn under the icon. Falls back to the id when unwritten.
  final String label;

  /// The icon name mermaid was given — `cloud`, `database`, `disk`, `server`,
  /// `internet`, or a name from an icon pack this app does not carry.
  final String? icon;

  /// The group this node sits in, if any.
  final String? parent;

  /// A junction is an unlabelled corner used to route edges.
  final bool isJunction;
}

/// A group box drawn around the nodes it holds.
class ArchGroup {
  /// Creates an architecture group.
  const ArchGroup({
    required this.id,
    required this.label,
    this.icon,
    this.parent,
  });

  /// The identifier `in` clauses refer to.
  final String id;

  /// The title drawn on the group's frame.
  final String label;

  /// The icon drawn beside the title.
  final String? icon;

  /// The enclosing group, when groups are nested.
  final String? parent;
}

/// One connection between two nodes.
class ArchEdge {
  /// Creates an architecture edge.
  const ArchEdge({
    required this.fromId,
    required this.fromSide,
    required this.toId,
    required this.toSide,
    this.arrowAtFrom = false,
    this.arrowAtTo = false,
    this.fromIsGroup = false,
    this.toIsGroup = false,
  });

  /// Identifier of the endpoint written first.
  final String fromId;

  /// The face of [fromId] the edge leaves from.
  final ArchSide fromSide;

  /// Identifier of the endpoint written second.
  final String toId;

  /// The face of [toId] the edge arrives at.
  final ArchSide toSide;

  /// Whether an arrowhead is drawn at the first endpoint.
  final bool arrowAtFrom;

  /// Whether an arrowhead is drawn at the second endpoint.
  final bool arrowAtTo;

  /// Whether the first endpoint named a group rather than a service.
  final bool fromIsGroup;

  /// Whether the second endpoint named a group rather than a service.
  final bool toIsGroup;
}

/// A complete architecture diagram.
class ArchitectureDiagramData {
  /// Creates architecture diagram data.
  const ArchitectureDiagramData({
    required this.nodes,
    required this.groups,
    required this.edges,
    this.title,
  });

  /// Optional title.
  final String? title;

  /// Services and junctions, in the order they were written.
  final List<ArchNode> nodes;

  /// Group boxes, in the order they were written.
  final List<ArchGroup> groups;

  /// Connections between nodes.
  final List<ArchEdge> edges;

  /// Whether there is anything at all to draw.
  bool get isEmpty => nodes.isEmpty && groups.isEmpty;
}
