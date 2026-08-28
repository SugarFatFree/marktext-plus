import 'dart:math' as math;
import 'dart:ui';

import '../models/treemap.dart';

/// One node, placed.
class TreemapTile {
  /// Creates a tile.
  const TreemapTile({
    required this.node,
    required this.rect,
    required this.depth,
  });

  /// The node this draws.
  final TreemapNode node;

  /// Where it goes.
  final Rect rect;

  /// How deep it sits, the roots being zero.
  final int depth;
}

/// The result of laying a treemap out.
class TreemapLayoutResult {
  /// Creates a layout result.
  const TreemapLayoutResult({required this.tiles, required this.size});

  /// Every node, outermost first, so a painter drawing in order puts children
  /// over their parents.
  final List<TreemapTile> tiles;

  /// The area the drawing occupies.
  final Size size;
}

/// Places treemap nodes by the squarified algorithm.
///
/// Slicing the space alternately by row and column — the obvious approach —
/// gives long thin slivers whose areas cannot be compared by eye, which is
/// the one thing a treemap is for. Squarified keeps each box as close to
/// square as it can, which is what mermaid, d3 and every other treemap does.
class TreemapLayout {
  /// Creates a treemap layout engine.
  const TreemapLayout();

  /// Space between a section's frame and what it holds.
  static const padding = 4.0;

  /// Height of the strip at the top of a section that carries its label.
  static const headerHeight = 18.0;

  /// Space above the drawing when the diagram has a title.
  static const titleHeight = 32.0;

  /// Lays [data] out inside [size].
  TreemapLayoutResult layout(TreemapDiagramData data, Size size) {
    final tiles = <TreemapTile>[];
    if (data.isEmpty) {
      return TreemapLayoutResult(tiles: tiles, size: size);
    }

    final top = data.title != null ? titleHeight : 0.0;
    final area = Rect.fromLTWH(
      padding,
      top + padding,
      math.max(1, size.width - padding * 2),
      math.max(1, size.height - top - padding * 2),
    );

    _place(data.roots, area, 0, tiles);
    return TreemapLayoutResult(tiles: tiles, size: size);
  }

  void _place(
    List<TreemapNode> nodes,
    Rect area,
    int depth,
    List<TreemapTile> tiles,
  ) {
    if (nodes.isEmpty || area.width <= 0 || area.height <= 0) return;

    final weighted = [
      for (final node in nodes)
        if (node.total > 0) node,
    ];
    // Nodes with nothing underneath them still have a name worth showing, so
    // they share what is left equally rather than vanishing.
    final drawn = weighted.isEmpty ? nodes : weighted;
    final values = [
      for (final node in drawn) weighted.isEmpty ? 1.0 : node.total,
    ];

    final rects = _squarify(values, area);
    for (var i = 0; i < drawn.length; i++) {
      final node = drawn[i];
      final rect = rects[i];
      tiles.add(TreemapTile(node: node, rect: rect, depth: depth));

      if (node.children.isEmpty) continue;
      final inner = Rect.fromLTRB(
        rect.left + padding,
        rect.top + headerHeight,
        rect.right - padding,
        rect.bottom - padding,
      );
      if (inner.width <= 2 || inner.height <= 2) continue;
      _place(node.children, inner, depth + 1, tiles);
    }
  }

  /// The squarified treemap of [values] inside [area].
  ///
  /// Rows are grown one value at a time for as long as adding the next value
  /// makes the row's worst aspect ratio better, then laid out and the
  /// remaining space carried forward.
  List<Rect> _squarify(List<double> values, Rect area) {
    final result = List<Rect>.filled(values.length, Rect.zero);
    var remaining = area;
    var index = 0;
    var left = values.fold<double>(0, (a, b) => a + b);

    while (index < values.length) {
      final shorter = math.min(remaining.width, remaining.height);
      final row = <double>[];
      var rowSum = 0.0;
      var worst = double.infinity;
      var next = index;

      while (next < values.length) {
        final candidate = [...row, values[next]];
        final candidateSum = rowSum + values[next];
        final candidateWorst = _worstRatio(
          candidate,
          candidateSum,
          shorter,
          left,
          remaining,
        );
        if (row.isNotEmpty && candidateWorst > worst) break;
        row.add(values[next]);
        rowSum = candidateSum;
        worst = candidateWorst;
        next++;
      }

      final horizontal = remaining.width >= remaining.height;
      // The share of the remaining area this row takes.
      final fraction = left <= 0 ? 0.0 : rowSum / left;
      final thickness = horizontal
          ? remaining.width * fraction
          : remaining.height * fraction;

      var offset = horizontal ? remaining.top : remaining.left;
      for (var i = 0; i < row.length; i++) {
        final share = rowSum <= 0 ? 1.0 / row.length : row[i] / rowSum;
        if (horizontal) {
          final height = remaining.height * share;
          result[index + i] =
              Rect.fromLTWH(remaining.left, offset, thickness, height);
          offset += height;
        } else {
          final width = remaining.width * share;
          result[index + i] =
              Rect.fromLTWH(offset, remaining.top, width, thickness);
          offset += width;
        }
      }

      remaining = horizontal
          ? Rect.fromLTRB(
              remaining.left + thickness,
              remaining.top,
              remaining.right,
              remaining.bottom,
            )
          : Rect.fromLTRB(
              remaining.left,
              remaining.top + thickness,
              remaining.right,
              remaining.bottom,
            );
      left -= rowSum;
      index += row.length;
    }

    return result;
  }

  /// The worst aspect ratio a row of [values] would have.
  double _worstRatio(
    List<double> values,
    double sum,
    double shorter,
    double left,
    Rect remaining,
  ) {
    if (sum <= 0 || left <= 0 || shorter <= 0) return double.infinity;
    final areaOfRow = remaining.width * remaining.height * (sum / left);
    final side = areaOfRow / shorter;
    if (side <= 0) return double.infinity;

    var worst = 0.0;
    for (final value in values) {
      final height = areaOfRow <= 0 ? 0.0 : (value / sum) * shorter;
      if (height <= 0) return double.infinity;
      final ratio = math.max(side / height, height / side);
      if (ratio > worst) worst = ratio;
    }
    return worst;
  }
}
