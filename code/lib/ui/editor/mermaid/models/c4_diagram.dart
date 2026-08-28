/// Data models and layout for C4 diagrams
library;

import 'dart:math' as math;

/// What a C4 element stands for.
enum C4ElementKind {
  /// A human actor.
  person,

  /// A software system.
  system,

  /// A system that stores data.
  database,

  /// A system that queues messages.
  queue,

  /// A container — an application or a data store inside a system.
  container,

  /// A component inside a container.
  component,

  /// A deployment node.
  node,
}

/// Anything that takes up space in the diagram.
abstract class C4Node {
  const C4Node();

  /// The name relations refer to it by.
  String get alias;
}

/// One box: a person, a system, a container, a component.
class C4Element extends C4Node {
  /// Creates an element.
  const C4Element({
    required this.alias,
    required this.label,
    required this.kind,
    this.description,
    this.technology,
    this.isExternal = false,
  });

  @override
  final String alias;

  /// Name drawn in the box.
  final String label;

  /// What the box stands for, which sets its outline.
  final C4ElementKind kind;

  /// Optional sentence under the name.
  final String? description;

  /// Optional technology note, drawn in brackets.
  final String? technology;

  /// Whether this sits outside the system being described, which mermaid
  /// draws in grey.
  final bool isExternal;

  @override
  bool operator ==(Object other) =>
      other is C4Element &&
      other.alias == alias &&
      other.label == label &&
      other.kind == kind &&
      other.description == description &&
      other.technology == technology &&
      other.isExternal == isExternal;

  @override
  int get hashCode =>
      Object.hash(alias, label, kind, description, technology, isExternal);
}

/// A labelled dashed box drawn around the things inside it.
class C4Boundary extends C4Node {
  /// Creates a boundary.
  const C4Boundary({
    required this.alias,
    required this.label,
    required this.children,
    this.type,
  });

  @override
  final String alias;

  /// Name drawn at the top of the box.
  final String label;

  /// What kind of boundary it is — "Enterprise", "System", "Container".
  final String? type;

  /// What the boundary encloses. Boundaries may nest.
  final List<C4Node> children;

  @override
  bool operator ==(Object other) =>
      other is C4Boundary &&
      other.alias == alias &&
      other.label == label &&
      other.type == type &&
      _sameList(other.children, children);

  @override
  int get hashCode => Object.hash(alias, label, type, Object.hashAll(children));

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Which way a relation is drawn, when the source asked for one.
enum C4RelationDirection {
  /// Wherever the two boxes happen to be.
  unspecified,

  /// `Rel_U` — the target sits above.
  up,

  /// `Rel_D` — the target sits below.
  down,

  /// `Rel_L` — the target sits to the left.
  left,

  /// `Rel_R` — the target sits to the right.
  right,
}

/// An arrow between two elements.
class C4Relation {
  /// Creates a relation.
  const C4Relation({
    required this.from,
    required this.to,
    this.label,
    this.technology,
    this.bidirectional = false,
    this.direction = C4RelationDirection.unspecified,
  });

  /// Alias of the element the arrow leaves.
  final String from;

  /// Alias of the element the arrow enters.
  final String to;

  /// Text drawn beside the arrow.
  final String? label;

  /// Optional technology note.
  final String? technology;

  /// Whether the arrow has a head at both ends.
  final bool bidirectional;

  /// The direction the source asked for, if any.
  final C4RelationDirection direction;

  @override
  bool operator ==(Object other) =>
      other is C4Relation &&
      other.from == from &&
      other.to == to &&
      other.label == label &&
      other.technology == technology &&
      other.bidirectional == bidirectional &&
      other.direction == direction;

  @override
  int get hashCode =>
      Object.hash(from, to, label, technology, bidirectional, direction);
}

/// A complete C4 diagram.
class C4DiagramData {
  /// Creates C4 diagram data.
  const C4DiagramData({
    required this.nodes,
    required this.relations,
    this.title,
    this.shapesPerRow = 4,
  });

  /// Top-level elements and boundaries, in the order they were written.
  final List<C4Node> nodes;

  /// Arrows between elements.
  final List<C4Relation> relations;

  /// Optional title.
  final String? title;

  /// How many boxes fit on one row, which mermaid calls `c4ShapeInRow`.
  final int shapesPerRow;

  @override
  bool operator ==(Object other) =>
      other is C4DiagramData &&
      other.title == title &&
      other.shapesPerRow == shapesPerRow &&
      C4Boundary._sameList(other.nodes, nodes) &&
      C4Boundary._sameList(other.relations, relations);

  @override
  int get hashCode => Object.hash(
    title,
    shapesPerRow,
    Object.hashAll(nodes),
    Object.hashAll(relations),
  );
}

/// A placed element.
class C4Placement {
  /// Creates a placement.
  const C4Placement({
    required this.element,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// The element placed here.
  final C4Element element;

  /// Left edge in logical pixels.
  final double left;

  /// Top edge in logical pixels.
  final double top;

  /// Box width.
  final double width;

  /// Box height.
  final double height;

  /// Centre of the box, where a relation points.
  (double, double) get center => (left + width / 2, top + height / 2);
}

/// A placed boundary.
class C4BoundaryPlacement {
  /// Creates a boundary placement.
  const C4BoundaryPlacement({
    required this.boundary,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// The boundary drawn here.
  final C4Boundary boundary;

  /// Left edge in logical pixels.
  final double left;

  /// Top edge in logical pixels.
  final double top;

  /// Box width.
  final double width;

  /// Box height, covering everything inside.
  final double height;
}

/// The result of laying out a C4 diagram.
class C4LayoutResult {
  /// Creates a layout result.
  const C4LayoutResult({
    required this.width,
    required this.height,
    required this.elements,
    required this.boundaries,
  });

  /// Total width needed.
  final double width;

  /// Total height needed.
  final double height;

  /// Placed elements.
  final List<C4Placement> elements;

  /// Placed boundaries, outermost first so an inner one draws on top.
  final List<C4BoundaryPlacement> boundaries;

  /// The placement of [alias], or null when nothing was placed under it.
  C4Placement? find(String alias) {
    for (final element in elements) {
      if (element.element.alias == alias) return element;
    }
    return null;
  }
}

/// Turns [C4DiagramData] into placed boxes.
///
/// The painter and the size calculation both go through this one function, so
/// the box the widget reserves and the drawing that lands in it cannot drift
/// apart. Free of Flutter types, so it can be exercised without a widget test.
class C4Layout {
  const C4Layout._();

  /// Width of one element box.
  static const double boxWidth = 168;

  /// Height of one element box.
  static const double boxHeight = 96;

  /// Gap between neighbouring boxes.
  static const double gap = 20;

  /// Room at the top of a boundary for its name.
  static const double boundaryHeader = 26;

  /// Padding between a boundary's edge and what it contains.
  static const double boundaryPadding = 14;

  /// Computes the layout.
  static C4LayoutResult compute(
    C4DiagramData data, {
    required double availableWidth,
    double padding = 16,
    double titleHeight = 0,
  }) {
    final elements = <C4Placement>[];
    final boundaries = <C4BoundaryPlacement>[];

    final bottom = _placeRow(
      data.nodes,
      left: padding,
      top: padding + titleHeight,
      perRow: math.max(data.shapesPerRow, 1),
      elements: elements,
      boundaries: boundaries,
    );

    var right = padding;
    for (final element in elements) {
      right = math.max(right, element.left + element.width);
    }
    for (final boundary in boundaries) {
      right = math.max(right, boundary.left + boundary.width);
    }

    return C4LayoutResult(
      width: math.max(right + padding, availableWidth),
      height: bottom + padding,
      elements: elements,
      boundaries: boundaries,
    );
  }

  /// Places [nodes] starting at ([left], [top]) and returns the bottom edge.
  ///
  /// A boundary takes a block of its own rather than a cell: it has to be wide
  /// enough for what it holds, and what it holds is laid out by the same
  /// function one level down.
  static double _placeRow(
    List<C4Node> nodes, {
    required double left,
    required double top,
    required int perRow,
    required List<C4Placement> elements,
    required List<C4BoundaryPlacement> boundaries,
  }) {
    var x = left;
    var y = top;
    var column = 0;
    var rowBottom = top;

    void endRow() {
      if (column == 0) return;
      x = left;
      y = rowBottom + gap;
      column = 0;
    }

    for (final node in nodes) {
      if (node is C4Element) {
        if (column >= perRow) endRow();
        elements.add(
          C4Placement(
            element: node,
            left: x,
            top: y,
            width: boxWidth,
            height: boxHeight,
          ),
        );
        x += boxWidth + gap;
        column++;
        rowBottom = math.max(rowBottom, y + boxHeight);
        continue;
      }

      if (node is C4Boundary) {
        // A boundary starts on a line of its own.
        endRow();
        // What the recursion adds lands at the end of these lists, so the
        // slice from here on is exactly this boundary's contents — no need to
        // search for them afterwards.
        final firstElement = elements.length;
        final firstBoundary = boundaries.length;

        final innerBottom = _placeRow(
          node.children,
          left: left + boundaryPadding,
          top: y + boundaryHeader + boundaryPadding,
          perRow: perRow,
          elements: elements,
          boundaries: boundaries,
        );

        var innerRight = left + boundaryPadding + boxWidth;
        for (var k = firstElement; k < elements.length; k++) {
          innerRight = math.max(
            innerRight,
            elements[k].left + elements[k].width,
          );
        }
        for (var k = firstBoundary; k < boundaries.length; k++) {
          innerRight = math.max(
            innerRight,
            boundaries[k].left + boundaries[k].width,
          );
        }

        // Inserted at its own index rather than appended: a boundary has to be
        // drawn before the boundaries nested inside it.
        boundaries.insert(
          firstBoundary,
          C4BoundaryPlacement(
            boundary: node,
            left: left,
            top: y,
            width: innerRight + boundaryPadding - left,
            height: innerBottom + boundaryPadding - y,
          ),
        );

        y = innerBottom + boundaryPadding + gap;
        rowBottom = math.max(rowBottom, y - gap);
        x = left;
        column = 0;
      }
    }

    return rowBottom;
  }
}

/// Colours used when drawing a C4 diagram.
class C4Colors {
  C4Colors._();

  /// Fill for a person.
  static const int personFill = 0xFF08427B;

  /// Fill for a system inside the boundary being described.
  static const int systemFill = 0xFF1168BD;

  /// Fill for anything marked external.
  static const int externalFill = 0xFF999999;

  /// Text drawn inside a filled box.
  static const int boxText = 0xFFFFFFFF;

  /// Boundary outline and label.
  static const int boundaryStroke = 0xFF666666;

  /// Relation arrows and their labels.
  static const int relation = 0xFF707070;
}
