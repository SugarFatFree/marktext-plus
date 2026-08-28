import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/mindmap_layout.dart';
import '../models/mindmap.dart';
import '../models/style.dart';

/// Paints mindmaps laid out by [MindmapLayout].
class MindmapPainter extends CustomPainter {
  /// Creates a mindmap painter.
  const MindmapPainter({
    required this.mindmapData,
    required this.style,
    this.deviceConfig,
  });

  /// The mindmap to render.
  final MindmapData mindmapData;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// Branch colours, chosen by the index of the root child a node descends
  /// from so a whole subtree shares one colour.
  static const _branchColors = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFE53935),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final root = mindmapData.root;

    // Edges first so node fills cover their ends.
    for (var i = 0; i < root.children.length; i++) {
      _drawSubtreeEdges(
        canvas,
        root,
        root.children[i],
        _branchColors[i % _branchColors.length],
      );
    }

    for (var i = 0; i < root.children.length; i++) {
      final colour = _branchColors[i % _branchColors.length];
      for (final node in root.children[i].descendants) {
        _drawNode(canvas, node, colour);
      }
    }

    _drawNode(canvas, root, Color(MermaidColors.defaultNodeStroke));
  }

  @override
  bool shouldRepaint(covariant MindmapPainter oldDelegate) {
    return mindmapData != oldDelegate.mindmapData || style != oldDelegate.style;
  }

  void _drawSubtreeEdges(
    Canvas canvas,
    MindmapNode parent,
    MindmapNode node,
    Color colour,
  ) {
    _drawEdge(canvas, parent, node, colour);
    for (final child in node.children) {
      _drawSubtreeEdges(canvas, node, child, colour);
    }
  }

  /// A horizontal-tangent curve, so branches leave and arrive flat rather than
  /// meeting the box at an angle.
  void _drawEdge(
    Canvas canvas,
    MindmapNode parent,
    MindmapNode child,
    Color colour,
  ) {
    final goingRight = child.x >= parent.x;
    final start = Offset(
      parent.x + (goingRight ? parent.width / 2 : -parent.width / 2),
      parent.y,
    );
    final end = Offset(
      child.x + (goingRight ? -child.width / 2 : child.width / 2),
      child.y,
    );

    final controlOffset = (end.dx - start.dx).abs() * 0.5;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + (goingRight ? controlOffset : -controlOffset),
        start.dy,
        end.dx + (goingRight ? -controlOffset : controlOffset),
        end.dy,
        end.dx,
        end.dy,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = colour.withValues(alpha: 0.55)
        ..strokeWidth = child.depth <= 1 ? 2.4 : 1.6
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawNode(Canvas canvas, MindmapNode node, Color colour) {
    final rect = Rect.fromCenter(
      center: Offset(node.x, node.y),
      width: node.width,
      height: node.height,
    );

    final fill = Paint()
      ..color = colour.withValues(alpha: node.depth == 0 ? 0.18 : 0.10)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = colour
      ..strokeWidth = node.depth == 0 ? 2.0 : 1.4
      ..style = PaintingStyle.stroke;

    switch (node.shape) {
      case MindmapShape.circle:
      case MindmapShape.bang:
        final radius = rect.longestSide / 2;
        canvas.drawCircle(rect.center, radius, fill);
        canvas.drawCircle(rect.center, radius, stroke);
      case MindmapShape.cloud:
      case MindmapShape.rounded:
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(rect.height / 2),
        );
        canvas.drawRRect(rrect, fill);
        canvas.drawRRect(rrect, stroke);
      case MindmapShape.hexagon:
        final path = _hexagonPath(rect);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case MindmapShape.square:
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      case MindmapShape.none:
        // Undecorated nodes get an underline instead of a box, so deeper
        // levels stay light and the branch structure keeps the emphasis.
        canvas.drawLine(
          Offset(rect.left, rect.bottom),
          Offset(rect.right, rect.bottom),
          Paint()
            ..color = colour.withValues(alpha: 0.5)
            ..strokeWidth = 1.4,
        );
    }

    final painter = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          fontSize: MindmapLayout.fontSizeForDepth(node.depth, style),
          fontWeight: node.depth <= 1 ? FontWeight.w600 : FontWeight.w400,
          fontFamily: style.fontFamily,
          color: Color(
            style.defaultNodeStyle.textColor ?? MermaidColors.defaultTextColor,
          ),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        node.x - painter.width / 2,
        node.y - painter.height / 2,
      ),
    );
  }

  Path _hexagonPath(Rect rect) {
    final inset = rect.height * 0.35;
    return Path()
      ..moveTo(rect.left + inset, rect.top)
      ..lineTo(rect.right - inset, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.right - inset, rect.bottom)
      ..lineTo(rect.left + inset, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
  }
}
