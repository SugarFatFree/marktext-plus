import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/requirement_diagram_layout.dart';
import '../models/edge.dart';
import '../models/node.dart';
import '../models/requirement_diagram.dart';
import '../models/style.dart';
import 'mermaid_painter.dart';

/// Paints requirement diagrams.
///
/// Each box is a header — the name over what kind of thing it is — above a
/// table of the fields the source gave. Boxes are sized with the same
/// [RequirementBoxMetrics] the layout used, so text cannot overflow the box
/// that was measured for it.
class RequirementPainter extends MermaidPainter {
  RequirementPainter({
    required super.diagram,
    required super.style,
    required this.requirementData,
    this.deviceConfig,
  });

  final RequirementDiagramData requirementData;

  final MermaidDeviceConfig? deviceConfig;

  @override
  void paint(Canvas canvas, Size size) {
    // Relations first so arrow heads, which end just outside a border, cannot
    // be clipped by a box drawn afterwards.
    for (final edge in diagram.edges) {
      _drawRelation(canvas, edge);
    }
    for (final node in diagram.nodes) {
      _drawBox(canvas, node);
    }
  }

  @override
  bool shouldRepaint(covariant MermaidPainter oldDelegate) {
    if (oldDelegate is! RequirementPainter) return true;
    return super.shouldRepaint(oldDelegate) ||
        requirementData != oldDelegate.requirementData;
  }

  void _drawBox(Canvas canvas, MermaidNode node) {
    final metrics =
        RequirementBoxMetrics.measure(node.id, requirementData, style);
    if (metrics == null) return;

    final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(
      rrect,
      Paint()..color = Color(RequirementDiagramColors.boxFill),
    );

    // The header is tinted, so the name reads as a title rather than as the
    // first row of the table.
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, metrics.headerHeight),
      Paint()..color = Color(RequirementDiagramColors.headerFill),
    );
    canvas.restore();

    final border = Paint()
      ..color = Color(RequirementDiagramColors.boxBorder)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawRRect(rrect, border);

    if (metrics.rows.isNotEmpty) {
      final y = rect.top + metrics.headerHeight;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), border);
    }

    final fontSize = style.getNodeStyle(null).fontSize;
    final left = rect.left + RequirementBoxMetrics.horizontalPadding;

    var y = rect.top + RequirementBoxMetrics.verticalPadding;
    _drawText(
      canvas,
      metrics.title,
      Offset(rect.center.dx, y + metrics.lineHeight / 2),
      fontSize: fontSize,
      weight: FontWeight.w600,
      color: RequirementDiagramColors.textColor,
      centred: true,
      maxWidth: rect.width - RequirementBoxMetrics.horizontalPadding * 2,
    );
    y += metrics.lineHeight;
    _drawText(
      canvas,
      metrics.subtitle,
      Offset(rect.center.dx, y + metrics.lineHeight / 2),
      fontSize: fontSize * 0.85,
      weight: FontWeight.w400,
      color: RequirementDiagramColors.labelColor,
      centred: true,
      maxWidth: rect.width - RequirementBoxMetrics.horizontalPadding * 2,
    );

    y = rect.top +
        metrics.headerHeight +
        RequirementBoxMetrics.verticalPadding;
    for (final row in metrics.rows) {
      final centre = y + metrics.lineHeight / 2;
      _drawText(
        canvas,
        row.$1,
        Offset(left, centre),
        fontSize: fontSize,
        weight: FontWeight.w600,
        color: RequirementDiagramColors.labelColor,
      );
      _drawText(
        canvas,
        row.$2,
        Offset(left + metrics.labelWidth + RequirementBoxMetrics.labelGap,
            centre),
        fontSize: fontSize,
        weight: FontWeight.w400,
        color: RequirementDiagramColors.textColor,
        maxWidth: rect.right -
            RequirementBoxMetrics.horizontalPadding -
            (left + metrics.labelWidth + RequirementBoxMetrics.labelGap),
      );
      y += metrics.lineHeight;
    }
  }

  void _drawRelation(Canvas canvas, MermaidEdge edge) {
    final fromNode = diagram.getNode(edge.from);
    final toNode = diagram.getNode(edge.to);
    if (fromNode == null || toNode == null) return;

    final fromRect =
        Rect.fromLTWH(fromNode.x, fromNode.y, fromNode.width, fromNode.height);
    final toRect =
        Rect.fromLTWH(toNode.x, toNode.y, toNode.width, toNode.height);

    final start = _edgePoint(fromRect, toRect.center);
    final end = _edgePoint(toRect, fromRect.center);

    final paint = Paint()
      ..color = Color(RequirementDiagramColors.edgeColor)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawLine(start, end, paint);
    drawArrowHead(
      canvas,
      end,
      math.atan2(end.dy - start.dy, end.dx - start.dx),
      ArrowType.arrow,
      paint,
    );

    final label = edge.label;
    if (label == null || label.isEmpty) return;

    final centre = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final painter = _layout(
      label,
      fontSize: style.defaultEdgeStyle.labelFontSize,
      weight: FontWeight.w400,
      color: RequirementDiagramColors.labelColor,
    );
    // A pill behind the label so the line does not run through the text.
    final box = Rect.fromCenter(
      center: centre,
      width: painter.width + 8,
      height: painter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(3)),
      Paint()..color = Color(RequirementDiagramColors.boxFill),
    );
    painter.paint(
      canvas,
      Offset(centre.dx - painter.width / 2, centre.dy - painter.height / 2),
    );
  }

  /// Where the line from [rect]'s centre towards [towards] leaves the box.
  Offset _edgePoint(Rect rect, Offset towards) {
    final centre = rect.center;
    final dx = towards.dx - centre.dx;
    final dy = towards.dy - centre.dy;
    if (dx == 0 && dy == 0) return centre;

    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;
    // Scale the direction until it touches whichever side it reaches first.
    final scale = math.min(
      dx == 0 ? double.infinity : halfWidth / dx.abs(),
      dy == 0 ? double.infinity : halfHeight / dy.abs(),
    );
    return Offset(centre.dx + dx * scale, centre.dy + dy * scale);
  }

  TextPainter _layout(
    String text, {
    required double fontSize,
    required FontWeight weight,
    required int color,
    double? maxWidth,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: style.fontFamily,
          fontWeight: weight,
          color: Color(color),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
  }

  /// Draws [text] with [at] as its left edge and vertical centre, or as its
  /// centre when [centred].
  void _drawText(
    Canvas canvas,
    String text,
    Offset at, {
    required double fontSize,
    required FontWeight weight,
    required int color,
    bool centred = false,
    double? maxWidth,
  }) {
    if (text.isEmpty) return;
    final painter = _layout(
      text,
      fontSize: fontSize,
      weight: weight,
      color: color,
      maxWidth: maxWidth,
    );
    painter.paint(
      canvas,
      Offset(
        centred ? at.dx - painter.width / 2 : at.dx,
        at.dy - painter.height / 2,
      ),
    );
  }
}
