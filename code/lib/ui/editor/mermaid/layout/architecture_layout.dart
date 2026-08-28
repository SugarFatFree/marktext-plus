import 'dart:math' as math;
import 'dart:ui';

import '../models/architecture.dart';

/// Where one node was placed.
class ArchPlacement {
  /// Creates a placement.
  const ArchPlacement({required this.node, required this.rect});

  /// The node this describes.
  final ArchNode node;

  /// Its box in diagram coordinates.
  final Rect rect;
}

/// Where one group's frame was placed.
class ArchGroupBox {
  /// Creates a group box.
  const ArchGroupBox({required this.group, required this.rect});

  /// The group this describes.
  final ArchGroup group;

  /// The frame, already covering every member with room for the title.
  final Rect rect;
}

/// The result of laying an architecture diagram out.
class ArchitectureLayoutResult {
  /// Creates a layout result.
  const ArchitectureLayoutResult({
    required this.placements,
    required this.groupBoxes,
    required this.size,
  });

  /// Every service and junction, placed.
  final List<ArchPlacement> placements;

  /// Every group frame, placed.
  final List<ArchGroupBox> groupBoxes;

  /// The size the whole drawing needs.
  final Size size;

  /// Looks a placement up by node id.
  ArchPlacement? placementOf(String id) {
    for (final placement in placements) {
      if (placement.node.id == id) return placement;
    }
    return null;
  }

  /// Looks a group frame up by group id.
  ArchGroupBox? groupBoxOf(String id) {
    for (final box in groupBoxes) {
      if (box.group.id == id) return box;
    }
    return null;
  }
}

/// Places the boxes of an architecture diagram on a grid.
///
/// Mermaid derives the arrangement from the edges rather than from the order
/// things were written: `db:L -- R:server` does not merely connect the two, it
/// says the server sits to the *left* of the db. Laying the nodes out in
/// source order instead would draw a picture that contradicts its own arrows.
///
/// Nodes are placed group by group. Doing it in one pass over the whole
/// diagram lets two groups' members interleave on the grid, and the frames
/// drawn round them then overlap — which reads as a nesting that the source
/// never described.
class ArchitectureLayout {
  /// Creates an architecture layout engine.
  const ArchitectureLayout();

  /// Width of one service box.
  static const cellWidth = 96.0;

  /// Height of one service box.
  static const cellHeight = 84.0;

  /// Gap between adjacent cells.
  static const cellGap = 44.0;

  /// Padding between a group's frame and the boxes inside it.
  static const groupPadding = 22.0;

  /// Height of the strip at the top of a group frame that holds its title.
  static const groupTitleHeight = 26.0;

  /// Gap between two group frames.
  static const groupGap = 36.0;

  /// Padding around the whole drawing.
  static const diagramPadding = 20.0;

  /// Space above the drawing when the diagram carries a title.
  static const titleHeight = 40.0;

  /// Lays [data] out.
  ArchitectureLayoutResult layout(ArchitectureDiagramData data) {
    // Every node belongs to a group; the ones written without an `in` clause
    // share a nameless one so that they are laid out together rather than each
    // starting its own grid.
    final byGroup = <String?, List<ArchNode>>{};
    for (final node in data.nodes) {
      byGroup.putIfAbsent(node.parent, () => []).add(node);
    }
    for (final group in data.groups) {
      byGroup.putIfAbsent(group.id, () => []);
    }

    final cells = <String, (int, int)>{};
    final blockSize = <String?, (int, int)>{};
    for (final entry in byGroup.entries) {
      final placed = _placeWithinGroup(entry.value, data.edges);
      cells.addAll(placed.$1);
      blockSize[entry.key] = placed.$2;
    }

    // The groups themselves are arranged with the same rule, using the edges
    // that cross between them.
    final groupOrder = byGroup.keys.toList();
    final groupCells = _placeGroups(groupOrder, blockSize, data, byGroup);

    final placements = <ArchPlacement>[];
    final groupBoxes = <ArchGroupBox>[];
    final groupById = {for (final g in data.groups) g.id: g};
    var right = 0.0;
    var bottom = 0.0;
    final top = data.title != null ? titleHeight : 0.0;

    for (final key in groupOrder) {
      final origin = groupCells[key] ?? const Offset(0, 0);
      final named = key != null && groupById.containsKey(key);
      final innerX = origin.dx + (named ? groupPadding : 0);
      final innerY = origin.dy + (named ? groupPadding + groupTitleHeight : 0);

      var maxX = innerX;
      var maxY = innerY;
      for (final node in byGroup[key]!) {
        final cell = cells[node.id] ?? (0, 0);
        final rect = Rect.fromLTWH(
          innerX + cell.$1 * (cellWidth + cellGap),
          innerY + cell.$2 * (cellHeight + cellGap),
          cellWidth,
          cellHeight,
        );
        placements.add(ArchPlacement(node: node, rect: rect));
        maxX = math.max(maxX, rect.right);
        maxY = math.max(maxY, rect.bottom);
      }

      if (named) {
        final frame = Rect.fromLTRB(
          origin.dx,
          origin.dy,
          maxX + groupPadding,
          maxY + groupPadding,
        );
        groupBoxes.add(ArchGroupBox(group: groupById[key]!, rect: frame));
        right = math.max(right, frame.right);
        bottom = math.max(bottom, frame.bottom);
      } else {
        right = math.max(right, maxX);
        bottom = math.max(bottom, maxY);
      }
    }

    // Everything was laid out from the origin; shift it down for the title and
    // out for the padding in one go.
    final shifted = [
      for (final p in placements)
        ArchPlacement(
          node: p.node,
          rect: p.rect.translate(diagramPadding, diagramPadding + top),
        ),
    ];
    final shiftedGroups = [
      for (final g in groupBoxes)
        ArchGroupBox(
          group: g.group,
          rect: g.rect.translate(diagramPadding, diagramPadding + top),
        ),
    ];

    return ArchitectureLayoutResult(
      placements: shifted,
      groupBoxes: shiftedGroups,
      size: Size(
        right + diagramPadding * 2,
        bottom + diagramPadding * 2 + top,
      ),
    );
  }

  /// Places one group's nodes relative to each other.
  ///
  /// Returns the cell of every node and how many columns and rows the group
  /// ended up needing.
  (Map<String, (int, int)>, (int, int)) _placeWithinGroup(
    List<ArchNode> nodes,
    List<ArchEdge> edges,
  ) {
    final ids = {for (final node in nodes) node.id};
    final cells = <String, (int, int)>{};
    final taken = <(int, int)>{};

    // Only the edges wholly inside this group say anything about where its
    // members sit relative to one another.
    final inside = edges
        .where((e) =>
            !e.fromIsGroup &&
            !e.toIsGroup &&
            ids.contains(e.fromId) &&
            ids.contains(e.toId))
        .toList();

    final neighbours = <String, List<(String, ArchSide)>>{};
    for (final edge in inside) {
      neighbours.putIfAbsent(edge.fromId, () => []).add(
            (edge.toId, edge.fromSide),
          );
      // Seen from the other end the step is the opposite one, and the side
      // that describes it is the one written on that end.
      neighbours.putIfAbsent(edge.toId, () => []).add(
            (edge.fromId, edge.toSide),
          );
    }

    for (final node in nodes) {
      if (cells.containsKey(node.id)) continue;
      // A fresh component starts under everything placed so far, so two
      // unconnected islands do not land on top of each other.
      var seedRow = 0;
      for (final cell in taken) {
        seedRow = math.max(seedRow, cell.$2 + 1);
      }
      _claim(cells, taken, node.id, (0, seedRow));

      final queue = <String>[node.id];
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        final here = cells[current]!;
        for (final (otherId, side)
            in neighbours[current] ?? const <(String, ArchSide)>[]) {
          if (cells.containsKey(otherId)) continue;
          final step = side.step;
          var candidate = (here.$1 + step.$1, here.$2 + step.$2);
          // The direction is honoured even when the obvious cell is taken:
          // keep stepping the same way rather than dropping the constraint.
          var guard = 0;
          while (taken.contains(candidate) && guard < 64) {
            candidate = (candidate.$1 + step.$1, candidate.$2 + step.$2);
            guard++;
          }
          _claim(cells, taken, otherId, candidate);
          queue.add(otherId);
        }
      }
    }

    if (cells.isEmpty) return (cells, (0, 0));

    // Shift to non-negative coordinates: an edge pointing left or up puts
    // nodes at negative cells, which would draw off the top-left corner.
    var minX = 0, minY = 0, maxX = 0, maxY = 0;
    for (final cell in cells.values) {
      minX = math.min(minX, cell.$1);
      minY = math.min(minY, cell.$2);
      maxX = math.max(maxX, cell.$1);
      maxY = math.max(maxY, cell.$2);
    }
    final normalised = {
      for (final entry in cells.entries)
        entry.key: (entry.value.$1 - minX, entry.value.$2 - minY),
    };
    return (normalised, (maxX - minX + 1, maxY - minY + 1));
  }

  void _claim(
    Map<String, (int, int)> cells,
    Set<(int, int)> taken,
    String id,
    (int, int) cell,
  ) {
    cells[id] = cell;
    taken.add(cell);
  }

  /// Arranges the group blocks themselves.
  ///
  /// Uses the edges that cross between groups where there are any, and falls
  /// back to a left-to-right row where there are none.
  Map<String?, Offset> _placeGroups(
    List<String?> order,
    Map<String?, (int, int)> blockSize,
    ArchitectureDiagramData data,
    Map<String?, List<ArchNode>> byGroup,
  ) {
    final groupIds = {for (final g in data.groups) g.id};
    final groupOf = <String, String?>{};
    for (final entry in byGroup.entries) {
      for (final node in entry.value) {
        groupOf[node.id] = entry.key;
      }
    }

    final crossing = <(String?, String?, ArchSide)>[];
    for (final edge in data.edges) {
      final from =
          edge.fromIsGroup ? edge.fromId : groupOf[edge.fromId] ?? edge.fromId;
      final to = edge.toIsGroup ? edge.toId : groupOf[edge.toId] ?? edge.toId;
      if (from == to) continue;
      if (!order.contains(from) || !order.contains(to)) continue;
      crossing.add((from, to, edge.fromSide));
    }

    final cells = <String?, (int, int)>{};
    final taken = <(int, int)>{};
    final neighbours = <String?, List<(String?, ArchSide)>>{};
    for (final (from, to, side) in crossing) {
      neighbours.putIfAbsent(from, () => []).add((to, side));
      neighbours.putIfAbsent(to, () => []).add((from, _opposite(side)));
    }

    var nextColumn = 0;
    for (final key in order) {
      if (cells.containsKey(key)) continue;
      var cell = (nextColumn, 0);
      while (taken.contains(cell)) {
        cell = (cell.$1 + 1, cell.$2);
      }
      cells[key] = cell;
      taken.add(cell);
      nextColumn = cell.$1 + 1;

      final queue = <String?>[key];
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        final here = cells[current]!;
        for (final (other, side)
            in neighbours[current] ?? const <(String?, ArchSide)>[]) {
          if (cells.containsKey(other)) continue;
          final step = side.step;
          var candidate = (here.$1 + step.$1, here.$2 + step.$2);
          var guard = 0;
          while (taken.contains(candidate) && guard < 64) {
            candidate = (candidate.$1 + step.$1, candidate.$2 + step.$2);
            guard++;
          }
          cells[other] = candidate;
          taken.add(candidate);
          nextColumn = math.max(nextColumn, candidate.$1 + 1);
          queue.add(other);
        }
      }
    }

    // Turn cells into pixels. Column widths and row heights follow the widest
    // and tallest block in them, so a large group does not overlap its
    // neighbour.
    var minX = 0, minY = 0;
    for (final cell in cells.values) {
      minX = math.min(minX, cell.$1);
      minY = math.min(minY, cell.$2);
    }
    final columnWidth = <int, double>{};
    final rowHeight = <int, double>{};
    for (final entry in cells.entries) {
      final size = blockSize[entry.key] ?? (0, 0);
      final named = entry.key != null && groupIds.contains(entry.key);
      final frame = named ? groupPadding * 2 : 0.0;
      final titleRoom = named ? groupTitleHeight : 0.0;
      final width = size.$1 == 0
          ? 0.0
          : size.$1 * cellWidth + (size.$1 - 1) * cellGap + frame;
      final height = size.$2 == 0
          ? 0.0
          : size.$2 * cellHeight + (size.$2 - 1) * cellGap + frame + titleRoom;
      final column = entry.value.$1 - minX;
      final row = entry.value.$2 - minY;
      columnWidth[column] = math.max(columnWidth[column] ?? 0, width);
      rowHeight[row] = math.max(rowHeight[row] ?? 0, height);
    }

    final columnX = <int, double>{};
    var x = 0.0;
    final lastColumn = columnWidth.keys.fold<int>(0, math.max);
    for (var c = 0; c <= lastColumn; c++) {
      columnX[c] = x;
      final width = columnWidth[c] ?? 0;
      if (width > 0) x += width + groupGap;
    }
    final rowY = <int, double>{};
    var y = 0.0;
    final lastRow = rowHeight.keys.fold<int>(0, math.max);
    for (var r = 0; r <= lastRow; r++) {
      rowY[r] = y;
      final height = rowHeight[r] ?? 0;
      if (height > 0) y += height + groupGap;
    }

    return {
      for (final entry in cells.entries)
        entry.key: Offset(
          columnX[entry.value.$1 - minX] ?? 0,
          rowY[entry.value.$2 - minY] ?? 0,
        ),
    };
  }

  ArchSide _opposite(ArchSide side) => switch (side) {
        ArchSide.left => ArchSide.right,
        ArchSide.right => ArchSide.left,
        ArchSide.top => ArchSide.bottom,
        ArchSide.bottom => ArchSide.top,
      };
}
