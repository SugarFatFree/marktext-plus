/// Data models and layout for block diagrams (`block-beta`)
library;

import 'dart:math' as math;

import 'node.dart';

/// One cell of a block diagram.
class BlockItem {
  /// Creates a block.
  const BlockItem({
    required this.id,
    required this.label,
    this.shape = NodeShape.rectangle,
    this.span = 1,
    this.isSpace = false,
  });

  /// Identifier, used as the target of an arrow.
  final String id;

  /// Text drawn in the block.
  final String label;

  /// Outline to draw.
  final NodeShape shape;

  /// How many columns the block occupies.
  final int span;

  /// Whether this is a `space` placeholder, which reserves cells and draws
  /// nothing.
  final bool isSpace;

  @override
  bool operator ==(Object other) =>
      other is BlockItem &&
      other.id == id &&
      other.label == label &&
      other.shape == shape &&
      other.span == span &&
      other.isSpace == isSpace;

  @override
  int get hashCode => Object.hash(id, label, shape, span, isSpace);
}

/// An arrow between two blocks.
class BlockArrow {
  /// Creates an arrow.
  const BlockArrow({required this.from, required this.to, this.label});

  /// Id of the block the arrow leaves.
  final String from;

  /// Id of the block the arrow enters.
  final String to;

  /// Optional text drawn at the middle of the arrow.
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is BlockArrow &&
      other.from == from &&
      other.to == to &&
      other.label == label;

  @override
  int get hashCode => Object.hash(from, to, label);
}

/// A complete block diagram.
class BlockDiagramData {
  /// Creates block diagram data.
  const BlockDiagramData({
    required this.columns,
    required this.items,
    required this.arrows,
  });

  /// Grid width in columns.
  final int columns;

  /// Blocks in the order they were written; the grid is filled from them.
  final List<BlockItem> items;

  /// Arrows between blocks.
  final List<BlockArrow> arrows;

  @override
  bool operator ==(Object other) =>
      other is BlockDiagramData &&
      other.columns == columns &&
      _sameList(other.items, items) &&
      _sameList(other.arrows, arrows);

  @override
  int get hashCode =>
      Object.hash(columns, Object.hashAll(items), Object.hashAll(arrows));

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A placed block.
class BlockPlacement {
  /// Creates a placement.
  const BlockPlacement({
    required this.item,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// The block placed here.
  final BlockItem item;

  /// Left edge in logical pixels.
  final double left;

  /// Top edge in logical pixels.
  final double top;

  /// Width, which grows with the block's span.
  final double width;

  /// Height of a single row.
  final double height;

  /// Centre of the block, where an arrow points.
  (double, double) get center => (left + width / 2, top + height / 2);
}

/// The result of laying out a block diagram.
class BlockLayoutResult {
  /// Creates a layout result.
  const BlockLayoutResult({
    required this.width,
    required this.height,
    required this.blocks,
  });

  /// Total width needed.
  final double width;

  /// Total height needed.
  final double height;

  /// Placed blocks, `space` placeholders excluded.
  final List<BlockPlacement> blocks;

  /// The placement of [id], or null when nothing was placed under that name.
  BlockPlacement? find(String id) {
    for (final block in blocks) {
      if (block.item.id == id) return block;
    }
    return null;
  }
}

/// Turns [BlockDiagramData] into placed rectangles.
///
/// The painter and the size calculation both go through this one function, so
/// the box the widget reserves and the drawing that lands in it cannot drift
/// apart. Free of Flutter types, so it can be exercised without a widget test.
class BlockLayout {
  const BlockLayout._();

  /// Gap between neighbouring cells.
  static const double gap = 12;

  /// Height of one row.
  static const double rowHeight = 52;

  /// Computes the layout.
  static BlockLayoutResult compute(
    BlockDiagramData data, {
    required double availableWidth,
    double padding = 16,
    double titleHeight = 0,
    double minCellWidth = 96,
  }) {
    if (data.items.isEmpty) {
      return const BlockLayoutResult(width: 0, height: 0, blocks: []);
    }

    final columns = math.max(data.columns, 1);
    final usable = math.max(availableWidth - padding * 2, minCellWidth);
    final cellWidth =
        math.max((usable - gap * (columns - 1)) / columns, minCellWidth);

    final blocks = <BlockPlacement>[];
    var row = 0;
    var column = 0;

    for (final item in data.items) {
      final span = math.min(math.max(item.span, 1), columns);
      // A block that no longer fits on this row starts the next one, which is
      // how a grid wraps and how `columns 3` produces three per row.
      if (column + span > columns) {
        row++;
        column = 0;
      }

      if (!item.isSpace) {
        blocks.add(
          BlockPlacement(
            item: item,
            left: padding + column * (cellWidth + gap),
            top: padding + titleHeight + row * (rowHeight + gap),
            width: cellWidth * span + gap * (span - 1),
            height: rowHeight,
          ),
        );
      }

      column += span;
      if (column >= columns) {
        row++;
        column = 0;
      }
    }

    final rows = column == 0 ? row : row + 1;
    return BlockLayoutResult(
      width: padding * 2 + cellWidth * columns + gap * (columns - 1),
      height: padding * 2 +
          titleHeight +
          math.max(rows, 1) * rowHeight +
          math.max(rows - 1, 0) * gap,
      blocks: blocks,
    );
  }
}

/// Colours used when drawing a block diagram.
class BlockDiagramColors {
  BlockDiagramColors._();

  /// Block fill.
  static const int fill = 0xFFECEFF1;

  /// Block outline.
  static const int stroke = 0xFF78909C;

  /// Label colour.
  static const int textColor = 0xFF263238;

  /// Arrow colour.
  static const int arrowColor = 0xFF546E7A;
}
