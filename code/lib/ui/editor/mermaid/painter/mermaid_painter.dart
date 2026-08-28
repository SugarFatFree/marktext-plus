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
    Paint paint, {
    Color? fillColor,
  }) {
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

      case ArrowType.openArrow:
        {
          // Same open V as ArrowType.arrow; kept distinct so class diagrams
          // can express "dependency" independently of flowchart arrows.
          final openPath = Path();
          openPath.moveTo(position.dx, position.dy);
          openPath.lineTo(
            position.dx - arrowSize * math.cos(angle - 0.4),
            position.dy - arrowSize * math.sin(angle - 0.4),
          );
          openPath.moveTo(position.dx, position.dy);
          openPath.lineTo(
            position.dx - arrowSize * math.cos(angle + 0.4),
            position.dy - arrowSize * math.sin(angle + 0.4),
          );
          canvas.drawPath(openPath, _strokeOf(paint));
        }
        break;

      case ArrowType.hollowTriangle:
        {
          const triangleSize = 15.0;
          const spread = 0.36;
          final trianglePath = Path();
          trianglePath.moveTo(position.dx, position.dy);
          trianglePath.lineTo(
            position.dx - triangleSize * math.cos(angle - spread),
            position.dy - triangleSize * math.sin(angle - spread),
          );
          trianglePath.lineTo(
            position.dx - triangleSize * math.cos(angle + spread),
            position.dy - triangleSize * math.sin(angle + spread),
          );
          trianglePath.close();
          canvas.drawPath(trianglePath, _fillOf(fillColor));
          canvas.drawPath(trianglePath, _strokeOf(paint));
        }
        break;

      case ArrowType.filledDiamond:
      case ArrowType.hollowDiamond:
        {
          const diamondLength = 18.0;
          const diamondHalfWidth = 6.5;
          final dirX = math.cos(angle);
          final dirY = math.sin(angle);
          // Perpendicular unit vector.
          final normalX = -dirY;
          final normalY = dirX;
          final midX = position.dx - (diamondLength / 2) * dirX;
          final midY = position.dy - (diamondLength / 2) * dirY;

          final diamondPath = Path();
          diamondPath.moveTo(position.dx, position.dy);
          diamondPath.lineTo(
            midX + diamondHalfWidth * normalX,
            midY + diamondHalfWidth * normalY,
          );
          diamondPath.lineTo(
            position.dx - diamondLength * dirX,
            position.dy - diamondLength * dirY,
          );
          diamondPath.lineTo(
            midX - diamondHalfWidth * normalX,
            midY - diamondHalfWidth * normalY,
          );
          diamondPath.close();

          if (type == ArrowType.filledDiamond) {
            canvas.drawPath(diamondPath, _fillOf(paint.color));
          } else {
            canvas.drawPath(diamondPath, _fillOf(fillColor));
          }
          canvas.drawPath(diamondPath, _strokeOf(paint));
        }
        break;

      case ArrowType.erExactlyOne:
        _erBar(canvas, position, angle, paint, 9);
        _erBar(canvas, position, angle, paint, 15);
        break;

      case ArrowType.erZeroOrOne:
        _erCircle(canvas, position, angle, paint, 8);
        _erBar(canvas, position, angle, paint, 17);
        break;

      case ArrowType.erZeroOrMore:
        _erCrowFoot(canvas, position, angle, paint);
        _erCircle(canvas, position, angle, paint, 20);
        break;

      case ArrowType.erOneOrMore:
        _erCrowFoot(canvas, position, angle, paint);
        _erBar(canvas, position, angle, paint, 20);
        break;

      case ArrowType.none:
      case ArrowType.doubleArrow:
        break;
    }
  }

  /// A short stroke across the line, [distance] back from its end.
  void _erBar(
    Canvas canvas,
    Offset end,
    double angle,
    Paint paint,
    double distance,
  ) {
    const halfWidth = 6.0;
    final dirX = math.cos(angle);
    final dirY = math.sin(angle);
    final centreX = end.dx - distance * dirX;
    final centreY = end.dy - distance * dirY;

    canvas.drawLine(
      Offset(centreX - halfWidth * -dirY, centreY - halfWidth * dirX),
      Offset(centreX + halfWidth * -dirY, centreY + halfWidth * dirX),
      _strokeOf(paint),
    );
  }

  /// The "zero" ring, [distance] back from the line's end.
  void _erCircle(
    Canvas canvas,
    Offset end,
    double angle,
    Paint paint,
    double distance,
  ) {
    const radius = 4.5;
    final centre = Offset(
      end.dx - distance * math.cos(angle),
      end.dy - distance * math.sin(angle),
    );
    canvas.drawCircle(centre, radius, _fillOf(null));
    canvas.drawCircle(centre, radius, _strokeOf(paint));
  }

  /// The "many" fork: three strokes meeting at the entity's edge and opening
  /// back along the line.
  void _erCrowFoot(Canvas canvas, Offset end, double angle, Paint paint) {
    const length = 13.0;
    const halfSpread = 6.0;

    final dirX = math.cos(angle);
    final dirY = math.sin(angle);
    final baseX = end.dx - length * dirX;
    final baseY = end.dy - length * dirY;
    final stroke = _strokeOf(paint);

    canvas.drawLine(end, Offset(baseX, baseY), stroke);
    canvas.drawLine(
      end,
      Offset(baseX - halfSpread * -dirY, baseY - halfSpread * dirX),
      stroke,
    );
    canvas.drawLine(
      end,
      Offset(baseX + halfSpread * -dirY, baseY + halfSpread * dirX),
      stroke,
    );
  }

  /// Stroke paint mirroring [source]'s colour and width.
  ///
  /// Built fresh rather than mutating [source] so callers can keep reusing the
  /// same Paint across an edge without inheriting a style flipped here.
  Paint _strokeOf(Paint source) {
    return Paint()
      ..color = source.color
      ..strokeWidth = source.strokeWidth
      ..strokeCap = source.strokeCap
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
  }

  /// Solid fill paint, defaulting to the diagram background so "hollow" heads
  /// hide the line running underneath them.
  Paint _fillOf(Color? color) {
    return Paint()
      ..color = color ?? Color(style.backgroundColor)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
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
    // Two coincident points — a self-loop, or a node that laid out on top of
    // its neighbour — leave nothing to divide by. The loop below happens not
    // to run in that case, so the NaN never reaches the canvas today; the
    // guard is here so that stays true if the loop ever changes.
    if (length == 0) return;
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
