import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/style.dart';

/// Base class for Mermaid diagram painters
abstract class MermaidPainter extends CustomPainter {
  /// Creates a Mermaid painter
  const MermaidPainter({
    required this.diagram,
    required this.style,
  });

  /// The diagram data to render
  final MermaidDiagramData diagram;

  /// Style configuration
  final MermaidStyle style;

  @override
  bool shouldRepaint(covariant MermaidPainter oldDelegate) {
    return diagram != oldDelegate.diagram || style != oldDelegate.style;
  }

  /// Draws an arrow head at the given position and angle
  void drawArrowHead(
    Canvas canvas,
    Offset position,
    double angle,
    ArrowType type,
    Paint paint,
  ) {
    const arrowSize = 10.0;

    switch (type) {
      case ArrowType.arrow:
        final path = Path();
        path.moveTo(position.dx, position.dy);
        path.lineTo(
          position.dx - arrowSize * math.cos(angle - 0.4),
          position.dy - arrowSize * math.sin(angle - 0.4),
        );
        path.moveTo(position.dx, position.dy);
        path.lineTo(
          position.dx - arrowSize * math.cos(angle + 0.4),
          position.dy - arrowSize * math.sin(angle + 0.4),
        );
        canvas.drawPath(path, paint);
        break;

      case ArrowType.circle:
        canvas.drawCircle(
          Offset(
            position.dx - 5 * math.cos(angle),
            position.dy - 5 * math.sin(angle),
          ),
          5,
          paint..style = PaintingStyle.stroke,
        );
        break;

      case ArrowType.cross:
        const crossSize = 8.0;
        final centerX = position.dx - crossSize * math.cos(angle);
        final centerY = position.dy - crossSize * math.sin(angle);
        canvas.drawLine(
          Offset(centerX - crossSize / 2, centerY - crossSize / 2),
          Offset(centerX + crossSize / 2, centerY + crossSize / 2),
          paint,
        );
        canvas.drawLine(
          Offset(centerX + crossSize / 2, centerY - crossSize / 2),
          Offset(centerX - crossSize / 2, centerY + crossSize / 2),
          paint,
        );
        break;

      case ArrowType.none:
      case ArrowType.doubleArrow:
        break;
    }
  }

  /// Draws text with optional background
  void drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle textStyle, {
    TextAlign align = TextAlign.center,
    Color? backgroundColor,
    double? maxWidth,
  }) {
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    textPainter.layout(maxWidth: maxWidth ?? double.infinity);

    // Draw background if specified
    if (backgroundColor != null) {
      final bgRect = Rect.fromCenter(
        center: position,
        width: textPainter.width + 8,
        height: textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
        Paint()..color = backgroundColor,
      );
    }

    // Center text
    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  /// Creates a Paint from edge style
  Paint createEdgePaint(MermaidEdge edge) {
    final edgeStyle = edge.style ?? style.defaultEdgeStyle;
    final paint = Paint()
      ..color = Color(edgeStyle.strokeColor ?? MermaidColors.defaultEdgeColor)
      ..strokeWidth = edgeStyle.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Apply dash pattern for dotted lines
    if (edge.lineType == LineType.dotted) {
      // We'll handle this in the draw method
    }

    return paint;
  }

  /// Draws a line with optional dash pattern
  void drawLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    LineType lineType,
  ) {
    if (lineType == LineType.dotted) {
      _drawDashedLine(canvas, start, end, paint, [5, 5]);
    } else if (lineType == LineType.thick) {
      paint.strokeWidth = paint.strokeWidth * 2;
      canvas.drawLine(start, end, paint);
    } else {
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> dashPattern,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / length;
    final unitDy = dy / length;

    var currentLength = 0.0;
    var drawSegment = true;
    var patternIndex = 0;

    while (currentLength < length) {
      final segmentLength =
          math.min(dashPattern[patternIndex], length - currentLength);

      if (drawSegment) {
        final segmentStart = Offset(
          start.dx + unitDx * currentLength,
          start.dy + unitDy * currentLength,
        );
        final segmentEnd = Offset(
          start.dx + unitDx * (currentLength + segmentLength),
          start.dy + unitDy * (currentLength + segmentLength),
        );
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentLength += segmentLength;
      drawSegment = !drawSegment;
      patternIndex = (patternIndex + 1) % dashPattern.length;
    }
  }
}
