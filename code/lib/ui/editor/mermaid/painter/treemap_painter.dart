import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/treemap_layout.dart';
import '../models/style.dart';
import '../models/treemap.dart';

/// Draws a `treemap-beta` diagram.
class TreemapPainter extends CustomPainter {
  /// Creates a treemap painter.
  const TreemapPainter({
    required this.treemapData,
    required this.layout,
    required this.style,
    this.deviceConfig,
  });

  /// The treemap to render.
  final TreemapDiagramData treemapData;

  /// Where every box was placed.
  final TreemapLayoutResult layout;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// Fills for successive depths.
  ///
  /// Depth rather than index: a treemap's nesting is the thing being read, so
  /// colouring siblings alike and generations differently is what makes the
  /// structure visible. Leaves get the accent of their own depth.
  static const _fills = <int>[
    0xFF90CAF9,
    0xFFA5D6A7,
    0xFFFFCC80,
    0xFFCE93D8,
    0xFF80DEEA,
    0xFFEF9A9A,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (treemapData.isEmpty) return;

    final border = Paint()
      ..color = Color(style.defaultNodeStyle.strokeColor ?? 0xFF546E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (treemapData.title != null) {
      _text(
        canvas,
        treemapData.title!,
        Rect.fromLTWH(0, 4, size.width, TreemapLayout.titleHeight),
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(style.onBackgroundTextColor),
          fontFamily: style.fontFamily,
        ),
      );
    }

    for (final tile in layout.tiles) {
      final fill = Color(_fills[tile.depth % _fills.length]);
      // A section is a frame around its children, so it is drawn faintly; a
      // leaf is the thing being compared, so it is drawn solid.
      canvas.drawRect(
        tile.rect,
        Paint()..color = fill.withValues(alpha: tile.node.isLeaf ? 0.85 : 0.28),
      );
      canvas.drawRect(tile.rect, border);

      final labelBox = tile.node.isLeaf
          ? tile.rect.deflate(3)
          : Rect.fromLTWH(
              tile.rect.left + 4,
              tile.rect.top + 1,
              tile.rect.width - 8,
              TreemapLayout.headerHeight - 2,
            );
      if (labelBox.width < 12 || labelBox.height < 8) continue;

      final label = tile.node.isLeaf && tile.node.value != null
          ? '${tile.node.name}\n${_number(tile.node.value!)}'
          : tile.node.name;

      _text(
        canvas,
        label,
        labelBox,
        TextStyle(
          fontSize: tile.node.isLeaf ? 11 : 12,
          fontWeight: tile.node.isLeaf ? FontWeight.normal : FontWeight.w600,
          color: Color(style.defaultNodeStyle.textColor ?? 0xFF212121),
          fontFamily: style.fontFamily,
        ),
        align: tile.node.isLeaf ? TextAlign.center : TextAlign.left,
      );
    }
  }

  /// A value without a trailing `.0` on the whole numbers most of them are.
  static String _number(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  void _text(
    Canvas canvas,
    String text,
    Rect box,
    TextStyle textStyle, {
    TextAlign align = TextAlign.center,
  }) {
    if (text.isEmpty || box.width <= 0) return;
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: box.width);
    if (painter.height > box.height) return;
    final dx = align == TextAlign.left
        ? box.left
        : box.left + (box.width - painter.width) / 2;
    painter.paint(canvas, Offset(dx, box.top + (box.height - painter.height) / 2));
  }

  @override
  bool shouldRepaint(covariant TreemapPainter oldDelegate) =>
      treemapData != oldDelegate.treemapData ||
      layout != oldDelegate.layout ||
      style != oldDelegate.style;
}
