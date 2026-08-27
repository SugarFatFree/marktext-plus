/// Painter for block diagrams
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../models/block_diagram.dart';
import '../models/node.dart';
import '../models/style.dart';

/// Draws a block diagram: a grid of labelled blocks with arrows between them.
class BlockPainter extends CustomPainter {
  /// Creates a block diagram painter.
  const BlockPainter({
    required this.blockData,
    required this.style,
    this.deviceConfig,
  });

  /// The diagram to draw.
  final BlockDiagramData blockData;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = BlockLayout.compute(
      blockData,
      availableWidth: size.width,
      padding: style.padding,
    );
    if (layout.blocks.isEmpty) return;

    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;

    // Arrows first, so a block covers the end of the line rather than the line
    // crossing the block's label.
    _drawArrows(canvas, layout);

    for (final block in layout.blocks) {
      _drawBlock(canvas, block, isMobile);
    }
  }

  void _drawBlock(Canvas canvas, BlockPlacement block, bool isMobile) {
    final rect = Rect.fromLTWH(
      block.left,
      block.top,
      block.width,
      block.height,
    );

    final fill = Paint()..color = const Color(BlockDiagramColors.fill);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(BlockDiagramColors.stroke);

    switch (block.item.shape) {
      case NodeShape.roundedRect:
        final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rounded, fill);
        canvas.drawRRect(rounded, stroke);
      case NodeShape.stadium:
        final pill = RRect.fromRectAndRadius(
          rect,
          Radius.circular(rect.height / 2),
        );
        canvas.drawRRect(pill, fill);
        canvas.drawRRect(pill, stroke);
      case NodeShape.circle:
        final radius = math.min(rect.width, rect.height) / 2;
        canvas.drawCircle(rect.center, radius, fill);
        canvas.drawCircle(rect.center, radius, stroke);
      case NodeShape.diamond:
        final path = Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case NodeShape.hexagon:
        final inset = math.min(rect.width / 4, rect.height / 2);
        final path = Path()
          ..moveTo(rect.left + inset, rect.top)
          ..lineTo(rect.right - inset, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.right - inset, rect.bottom)
          ..lineTo(rect.left + inset, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case NodeShape.cylinder:
        // A database: a rectangle capped with an ellipse at each end.
        final lid = math.min(rect.height / 5, 10.0);
        final body = Path()
          ..moveTo(rect.left, rect.top + lid)
          ..lineTo(rect.left, rect.bottom - lid)
          ..arcToPoint(
            Offset(rect.right, rect.bottom - lid),
            radius: Radius.elliptical(rect.width / 2, lid),
            clockwise: false,
          )
          ..lineTo(rect.right, rect.top + lid)
          ..arcToPoint(
            Offset(rect.left, rect.top + lid),
            radius: Radius.elliptical(rect.width / 2, lid),
            clockwise: false,
          )
          ..close();
        canvas.drawPath(body, fill);
        canvas.drawPath(body, stroke);
        canvas.drawArc(
          Rect.fromLTWH(rect.left, rect.top, rect.width, lid * 2),
          0,
          math.pi * 2,
          false,
          stroke,
        );
      case NodeShape.subroutine:
        // A rectangle with a vertical rule inside each end.
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
        for (final dx in [8.0, rect.width - 8.0]) {
          canvas.drawLine(
            Offset(rect.left + dx, rect.top),
            Offset(rect.left + dx, rect.bottom),
            stroke,
          );
        }
      case NodeShape.parallelogram:
        final slant = math.min(rect.width / 5, rect.height);
        final path = Path()
          ..moveTo(rect.left + slant, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right - slant, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      default:
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
    }

    _drawLabel(canvas, block.item.label, rect, fontSize: isMobile ? 11 : 12.5);
  }

  void _drawArrows(Canvas canvas, BlockLayoutResult layout) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(BlockDiagramColors.arrowColor);

    for (final arrow in blockData.arrows) {
      final from = layout.find(arrow.from);
      final to = layout.find(arrow.to);
      if (from == null || to == null || from == to) continue;

      final (fx, fy) = from.center;
      final (tx, ty) = to.center;
      final start = _edgePoint(from, tx, ty);
      final end = _edgePoint(to, fx, fy);

      canvas.drawLine(start, end, paint);
      _drawArrowHead(canvas, start, end, paint);

      final label = arrow.label;
      if (label != null && label.isNotEmpty) {
        _drawLabel(
          canvas,
          label,
          Rect.fromCenter(
            center: Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
            width: 90,
            height: 18,
          ),
          fontSize: 11,
          background: true,
        );
      }
    }
  }

  /// Where a line aimed at ([towardsX], [towardsY]) leaves [block]'s outline.
  ///
  /// Meeting the edge rather than the centre is what keeps the arrowhead from
  /// disappearing under the block it points at.
  Offset _edgePoint(BlockPlacement block, double towardsX, double towardsY) {
    final (cx, cy) = block.center;
    final dx = towardsX - cx;
    final dy = towardsY - cy;
    if (dx == 0 && dy == 0) return Offset(cx, cy);

    final halfWidth = block.width / 2;
    final halfHeight = block.height / 2;
    // Scale the direction until it touches whichever side it reaches first.
    final scale = math.min(
      dx == 0 ? double.infinity : halfWidth / dx.abs(),
      dy == 0 ? double.infinity : halfHeight / dy.abs(),
    );
    return Offset(cx + dx * scale, cy + dy * scale);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const length = 9.0;
    const spread = 0.4;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - length * math.cos(angle - spread),
        end.dy - length * math.sin(angle - spread),
      )
      ..lineTo(
        end.dx - length * math.cos(angle + spread),
        end.dy - length * math.sin(angle + spread),
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(BlockDiagramColors.arrowColor),
    );
  }

  /// Draws [text] centred in [rect].
  void _drawLabel(
    Canvas canvas,
    String text,
    Rect rect, {
    required double fontSize,
    bool background = false,
  }) {
    if (text.isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(BlockDiagramColors.textColor),
          fontFamily: style.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: math.max(rect.width - 10, 20));

    final origin = Offset(
      rect.center.dx - painter.width / 2,
      rect.center.dy - painter.height / 2,
    );

    if (background) {
      // An arrow label sits on top of its own line; without something behind
      // it the line runs straight through the text.
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx - 3,
          origin.dy - 1,
          painter.width + 6,
          painter.height + 2,
        ),
        Paint()..color = Color(style.backgroundColor),
      );
    }

    painter.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(covariant BlockPainter oldDelegate) =>
      oldDelegate.blockData != blockData || oldDelegate.style != style;
}
