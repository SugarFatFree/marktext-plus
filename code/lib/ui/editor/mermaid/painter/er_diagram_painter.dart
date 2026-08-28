import 'box_edge_geometry.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/er_diagram_layout.dart';
import '../models/edge.dart';
import '../models/er_diagram.dart';
import '../models/node.dart';
import '../models/style.dart';
import 'mermaid_painter.dart';

/// Paints entity-relationship diagrams.
///
/// Entities are two compartments — name and attribute table — measured with
/// the same [ErBoxMetrics] the layout used. Relationship ends carry crow's
/// foot notation rather than arrow heads.
class ErDiagramPainter extends MermaidPainter {
  /// Creates an ER diagram painter.
  ErDiagramPainter({
    required super.diagram,
    required super.style,
    required this.erData,
    this.deviceConfig,
  });

  /// Parsed entities keyed by node id.
  final ErDiagramData erData;

  /// Responsive configuration, when the diagram is size-adaptive.
  final MermaidDeviceConfig? deviceConfig;

  @override
  void paint(Canvas canvas, Size size) {
    // Relationships first: crow's feet sit against an entity's border, and
    // drawing boxes afterwards would clip them.
    for (final edge in diagram.edges) {
      _drawRelationship(canvas, edge);
    }
    for (final node in diagram.nodes) {
      _drawEntity(canvas, node);
    }
  }

  @override
  bool shouldRepaint(covariant MermaidPainter oldDelegate) {
    if (oldDelegate is! ErDiagramPainter) return true;
    return super.shouldRepaint(oldDelegate) || erData != oldDelegate.erData;
  }

  void _drawEntity(Canvas canvas, MermaidNode node) {
    final entity = erData.byId(node.id);
    if (entity == null) return;

    final metrics = ErBoxMetrics.measure(entity, style);
    final nodeStyle = style.defaultNodeStyle;
    final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);

    final fill = Paint()
      ..color = Color(nodeStyle.fillColor ?? MermaidColors.defaultNodeFill)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = Color(nodeStyle.strokeColor ?? MermaidColors.defaultNodeStroke)
      ..strokeWidth = nodeStyle.strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(nodeStyle.borderRadius),
    );
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);

    final textColor =
        Color(nodeStyle.textColor ?? MermaidColors.defaultTextColor);

    // Name compartment, centred.
    _drawLine(
      canvas,
      entity.displayName,
      Offset(node.x + node.width / 2, node.y + ErBoxMetrics.verticalPadding),
      TextStyle(
        fontSize: nodeStyle.fontSize,
        fontFamily: style.fontFamily,
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      centred: true,
    );

    if (!metrics.hasAttributes) return;

    final separatorY = node.y + metrics.headerHeight;
    canvas.drawLine(
      Offset(node.x, separatorY),
      Offset(node.x + node.width, separatorY),
      stroke,
    );

    final attributeStyle = TextStyle(
      fontSize: nodeStyle.fontSize,
      fontFamily: style.fontFamily,
      color: textColor,
    );

    var y = separatorY + ErBoxMetrics.verticalPadding;
    for (final line in metrics.attributeLines) {
      _drawLine(
        canvas,
        line,
        Offset(node.x + ErBoxMetrics.horizontalPadding, y),
        attributeStyle,
        centred: false,
      );
      y += metrics.lineHeight;
    }
  }

  void _drawRelationship(Canvas canvas, MermaidEdge edge) {
    final fromNode = diagram.getNode(edge.from);
    final toNode = diagram.getNode(edge.to);
    if (fromNode == null || toNode == null) return;

    final fromRect =
        Rect.fromLTWH(fromNode.x, fromNode.y, fromNode.width, fromNode.height);
    final toRect =
        Rect.fromLTWH(toNode.x, toNode.y, toNode.width, toNode.height);

    final start = rectEdgePoint(fromRect, toRect.center);
    final end = rectEdgePoint(toRect, fromRect.center);

    final paint = createEdgePaint(edge);

    if (edge.lineType == LineType.dotted) {
      drawDashedLine(canvas, start, end, paint);
    } else {
      canvas.drawLine(start, end, paint);
    }

    final forward = math.atan2(end.dy - start.dy, end.dx - start.dx);
    if (edge.arrowType != ArrowType.none) {
      drawArrowHead(canvas, end, forward, edge.arrowType, paint);
    }
    if (edge.startArrowType != ArrowType.none) {
      drawArrowHead(
        canvas,
        start,
        forward + math.pi,
        edge.startArrowType,
        paint,
      );
    }

    final label = edge.label;
    if (label == null || label.isEmpty) return;

    final edgeStyle = edge.style ?? style.defaultEdgeStyle;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: edgeStyle.labelFontSize,
          fontFamily: style.fontFamily,
          color: Color(
            edgeStyle.labelColor ?? MermaidColors.defaultTextColor,
          ),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final centre = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    // Knock out the line behind the label so it stays readable.
    canvas.drawRect(
      Rect.fromCenter(
        center: centre,
        width: painter.width + 8,
        height: painter.height + 2,
      ),
      Paint()
        ..color = Color(style.backgroundColor)
        ..style = PaintingStyle.fill,
    );
    painter.paint(
      canvas,
      Offset(centre.dx - painter.width / 2, centre.dy - painter.height / 2),
    );
  }

  void _drawLine(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle textStyle, {
    required bool centred,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final dx = centred ? position.dx - painter.width / 2 : position.dx;
    painter.paint(canvas, Offset(dx, position.dy));
  }
}
