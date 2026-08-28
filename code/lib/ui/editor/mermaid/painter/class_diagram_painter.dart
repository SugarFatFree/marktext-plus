import 'box_edge_geometry.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/class_diagram_layout.dart';
import '../models/class_diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';
import '../models/style.dart';
import 'mermaid_painter.dart';

/// Paints UML class diagrams.
///
/// Boxes are drawn as the familiar three compartments — name, attributes,
/// methods — using the same [ClassBoxMetrics] the layout measured with, so
/// text can never overflow the box that was sized for it.
class ClassDiagramPainter extends MermaidPainter {
  /// Creates a class diagram painter.
  ClassDiagramPainter({
    required super.diagram,
    required super.style,
    required this.classData,
    this.deviceConfig,
  });

  /// Parsed class boxes keyed by node id.
  final ClassDiagramData classData;

  /// Responsive configuration, when the diagram is size-adaptive.
  final MermaidDeviceConfig? deviceConfig;

  @override
  void paint(Canvas canvas, Size size) {
    // Relations first: arrow heads sit just outside a box's border, so drawing
    // boxes afterwards cannot clip them.
    for (final edge in diagram.edges) {
      _drawRelation(canvas, edge);
    }
    for (final node in diagram.nodes) {
      _drawClassBox(canvas, node);
    }
  }

  @override
  bool shouldRepaint(covariant MermaidPainter oldDelegate) {
    if (oldDelegate is! ClassDiagramPainter) return true;
    return super.shouldRepaint(oldDelegate) ||
        classData != oldDelegate.classData;
  }

  // --------------------------------------------------------------- class boxes

  void _drawClassBox(Canvas canvas, MermaidNode node) {
    final box = classData.byId(node.id);
    if (box == null) return;

    final metrics = ClassBoxMetrics.measure(box, style);
    final nodeStyle = style.getNodeStyle(box.cssClass);
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
    var y = node.y + ClassBoxMetrics.verticalPadding;
    for (var i = 0; i < metrics.headerLines.length; i++) {
      final isStereotype =
          i == 0 && metrics.headerLines.length > 1;
      _drawLine(
        canvas,
        metrics.headerLines[i],
        Offset(node.x + node.width / 2, y),
        TextStyle(
          fontSize: nodeStyle.fontSize,
          fontFamily: style.fontFamily,
          color: textColor,
          fontWeight: isStereotype ? FontWeight.w400 : FontWeight.w600,
          fontStyle: (!isStereotype && box.isAbstract)
              ? FontStyle.italic
              : FontStyle.normal,
        ),
        centred: true,
      );
      y += metrics.lineHeight;
    }

    if (!metrics.hasCompartments) return;

    final memberStyle = TextStyle(
      fontSize: nodeStyle.fontSize,
      fontFamily: style.fontFamily,
      color: textColor,
    );

    // Attribute compartment.
    var separatorY = node.y + metrics.headerHeight;
    _drawSeparator(canvas, node, separatorY, stroke);

    y = separatorY + ClassBoxMetrics.verticalPadding;
    for (final line in metrics.attributeLines) {
      _drawLine(
        canvas,
        line,
        Offset(node.x + ClassBoxMetrics.horizontalPadding, y),
        memberStyle,
        centred: false,
      );
      y += metrics.lineHeight;
    }

    // Method compartment.
    separatorY = node.y + metrics.headerHeight + metrics.attributesHeight;
    _drawSeparator(canvas, node, separatorY, stroke);

    y = separatorY + ClassBoxMetrics.verticalPadding;
    for (final line in metrics.methodLines) {
      _drawLine(
        canvas,
        line,
        Offset(node.x + ClassBoxMetrics.horizontalPadding, y),
        memberStyle,
        centred: false,
      );
      y += metrics.lineHeight;
    }
  }

  void _drawSeparator(Canvas canvas, MermaidNode node, double y, Paint stroke) {
    canvas.drawLine(
      Offset(node.x, y),
      Offset(node.x + node.width, y),
      stroke,
    );
  }

  /// Draws one line of text with its top edge at [position].
  ///
  /// When [centred], [position] gives the horizontal centre; otherwise it is
  /// the left edge.
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

  // ---------------------------------------------------------------- relations

  void _drawRelation(Canvas canvas, MermaidEdge edge) {
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

    // Arrow heads point away from the box they touch.
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

    final labelStyle = TextStyle(
      fontSize: (edge.style ?? style.defaultEdgeStyle).labelFontSize,
      fontFamily: style.fontFamily,
      color: Color(
        (edge.style ?? style.defaultEdgeStyle).labelColor ??
            MermaidColors.defaultTextColor,
      ),
    );

    if (edge.label != null && edge.label!.isNotEmpty) {
      _drawRelationLabel(
        canvas,
        edge.label!,
        Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
        labelStyle,
      );
    }

    // Cardinalities sit just inside each endpoint, offset off the line.
    if (edge.startLabel != null && edge.startLabel!.isNotEmpty) {
      _drawRelationLabel(
        canvas,
        edge.startLabel!,
        _cardinalityAnchor(start, end),
        labelStyle,
      );
    }
    if (edge.endLabel != null && edge.endLabel!.isNotEmpty) {
      _drawRelationLabel(
        canvas,
        edge.endLabel!,
        _cardinalityAnchor(end, start),
        labelStyle,
      );
    }
  }

  /// A point a short way along the line from [anchor] towards [towards],
  /// nudged perpendicular so the text does not sit on the line.
  Offset _cardinalityAnchor(Offset anchor, Offset towards) {
    final dx = towards.dx - anchor.dx;
    final dy = towards.dy - anchor.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return anchor;
    const along = 22.0;
    const perpendicular = 10.0;
    return Offset(
      anchor.dx + dx / length * along - dy / length * perpendicular,
      anchor.dy + dy / length * along + dx / length * perpendicular,
    );
  }

  void _drawRelationLabel(
    Canvas canvas,
    String text,
    Offset centre,
    TextStyle textStyle,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final rect = Rect.fromCenter(
      center: centre,
      width: painter.width + 8,
      height: painter.height + 2,
    );
    // Knock out the line behind the text so it stays readable.
    canvas.drawRect(
      rect,
      Paint()
        ..color = Color(style.backgroundColor)
        ..style = PaintingStyle.fill,
    );
    painter.paint(
      canvas,
      Offset(centre.dx - painter.width / 2, centre.dy - painter.height / 2),
    );
  }
}
