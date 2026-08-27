import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../models/edge.dart';
import '../models/node.dart';
import '../models/sequence.dart';
import '../models/style.dart';
import 'mermaid_painter.dart';

/// Helper class for participant colors
class _ParticipantColors {
  const _ParticipantColors(this.fill, this.stroke);
  final int fill;
  final int stroke;
}

/// Painter for sequence diagrams
class SequencePainter extends MermaidPainter {
  /// Creates a sequence painter
  const SequencePainter({
    required super.diagram,
    required super.style,
    this.deviceConfig,
    this.sequenceData,
  });

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Activation bars, when the source declared any.
  final SequenceDiagramData? sequenceData;

  /// Width of an activation bar.
  static const double _activationWidth = 10;

  /// How far each nested bar steps to the right of the one enclosing it.
  static const double _activationNestOffset = 5;

  /// Widest a note box gets before its text wraps.
  static const double _noteMaxWidth = 220;

  /// Narrowest a note box gets, so a one-word note still reads as a box.
  static const double _noteMinWidth = 60;

  /// Gap between a note box and the lifeline it hangs off.
  static const double _noteGap = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (diagram.nodes.isEmpty) return;

    // Get responsive values
    final messageSpacing = deviceConfig?.messageSpacing ?? 50.0;
    final messageStartOffset = messageSpacing * 0.8;

    final firstNode = diagram.nodes.first;
    final messageStartY = firstNode.y + firstNode.height + messageStartOffset;
    // A note takes a row of its own; counting only messages drew it on top of
    // the message beside it.
    final steps = sequenceData?.steps;
    final rowCount = steps?.length ?? diagram.edges.length;
    final totalMessagesHeight = rowCount * messageSpacing;
    final bottomY = messageStartY + totalMessagesHeight + 20;

    // Draw participant lifelines (dashed vertical lines)
    for (final node in diagram.nodes) {
      _drawLifeline(canvas, node, messageStartY - 10, bottomY);
    }

    // Draw participant boxes at top
    for (final node in diagram.nodes) {
      _drawParticipant(canvas, node);
    }

    // Activation bars sit under the messages: a message arrow has to land on
    // top of the bar it starts, not behind it.
    _drawActivations(canvas, messageStartY, messageSpacing);

    // Draw messages and notes, one row each
    var rowY = messageStartY;
    if (steps == null) {
      for (final edge in diagram.edges) {
        _drawMessage(canvas, edge, rowY);
        rowY += messageSpacing;
      }
    } else {
      for (final step in steps) {
        final note = step.note;
        if (note != null) {
          _drawNote(canvas, note, rowY);
        } else if (step.messageIndex >= 0 &&
            step.messageIndex < diagram.edges.length) {
          _drawMessage(canvas, diagram.edges[step.messageIndex], rowY);
        }
        rowY += messageSpacing;
      }
    }

    // Draw participant boxes at bottom
    for (final node in diagram.nodes) {
      _drawParticipantBottom(canvas, node, bottomY);
    }
  }

  /// Draws the bars showing when each participant is busy.
  void _drawActivations(
    Canvas canvas,
    double messageStartY,
    double messageSpacing,
  ) {
    final activations = sequenceData?.activations;
    if (activations == null || activations.isEmpty) return;

    final fill = Paint()..color = const Color(0xFFE8EAF6);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF5C6BC0);

    for (final bar in activations) {
      final node = diagram.getNode(bar.participantId);
      if (node == null) continue;

      final centerX = node.x + node.width / 2;
      final left =
          centerX - _activationWidth / 2 + bar.depth * _activationNestOffset;

      final top = messageStartY + bar.startIndex * messageSpacing;
      // A bar that opens and closes on the same message would be a hairline,
      // so it is given a readable minimum instead.
      final bottom = math.max(
        messageStartY + bar.endIndex * messageSpacing,
        top + messageSpacing * 0.4,
      );

      final rect = Rect.fromLTRB(left, top, left + _activationWidth, bottom);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
    }
  }

  /// Draws a note box on the row at [y].
  void _drawNote(Canvas canvas, SequenceNote note, double y) {
    final anchors = <MermaidNode>[];
    for (final id in note.participantIds) {
      final node = diagram.getNode(id);
      if (node != null) anchors.add(node);
    }
    if (anchors.isEmpty) return;

    final textStyle = TextStyle(
      color: const Color(0xFF3E2723),
      fontSize: (deviceConfig?.fontSize ?? 14.0) - 2,
    );
    final text = TextPainter(
      text: TextSpan(text: note.text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: _noteMaxWidth);

    const hPad = 10.0;
    const vPad = 6.0;
    final boxWidth = math.max(text.width + hPad * 2, _noteMinWidth);
    final boxHeight = text.height + vPad * 2;

    final firstX = anchors.first.x + anchors.first.width / 2;
    final lastX = anchors.last.x + anchors.last.width / 2;
    final (left, width) = switch (note.placement) {
      SequenceNotePlacement.leftOf => (firstX - _noteGap - boxWidth, boxWidth),
      SequenceNotePlacement.rightOf => (firstX + _noteGap, boxWidth),
      // `Note over A,B` stretches between the two lifelines, and has to be at
      // least wide enough for its own text either way.
      SequenceNotePlacement.over when anchors.length > 1 => _spanBox(
        firstX,
        lastX,
        boxWidth,
      ),
      SequenceNotePlacement.over => (firstX - boxWidth / 2, boxWidth),
    };

    final rect = Rect.fromLTWH(left, y - boxHeight / 2, width, boxHeight);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFF5AD));
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFAAAA33),
    );

    text.paint(
      canvas,
      Offset(rect.left + (width - text.width) / 2, rect.top + vPad),
    );
  }

  /// Left edge and width of a note stretched between two lifelines.
  (double, double) _spanBox(double firstX, double lastX, double minWidth) {
    final gapBetween = (lastX - firstX).abs();
    final width = math.max(gapBetween + _noteGap * 2, minWidth);
    return (math.min(firstX, lastX) - (width - gapBetween) / 2, width);
  }

  void _drawLifeline(
    Canvas canvas,
    MermaidNode node,
    double startY,
    double endY,
  ) {
    final centerX = node.x + node.width / 2;

    final paint = Paint()
      ..color = Color(
        style.defaultEdgeStyle.strokeColor ?? MermaidColors.defaultEdgeColor,
      )
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw dashed lifeline
    const dashLength = 8.0;
    const gapLength = 5.0;
    var currentY = startY;

    while (currentY < endY) {
      final segmentEnd = math.min(currentY + dashLength, endY);
      canvas.drawLine(
        Offset(centerX, currentY),
        Offset(centerX, segmentEnd),
        paint,
      );
      currentY = segmentEnd + gapLength;
    }
  }

  // Predefined colors for participants (similar to reference image)
  static const List<_ParticipantColors> _participantColorPalette = [
    _ParticipantColors(0xFFF3E5F5, 0xFFCE93D8), // Purple/Lavender
    _ParticipantColors(0xFFE0F2F1, 0xFF80CBC4), // Teal/Mint
    _ParticipantColors(0xFFFFF3E0, 0xFFFFCC80), // Orange/Peach
    _ParticipantColors(0xFFE8F5E9, 0xFFA5D6A7), // Green
    _ParticipantColors(0xFFE3F2FD, 0xFF90CAF9), // Blue
    _ParticipantColors(0xFFFCE4EC, 0xFFF48FB1), // Pink
  ];

  _ParticipantColors _getParticipantColors(int index) {
    return _participantColorPalette[index % _participantColorPalette.length];
  }

  void _drawParticipant(Canvas canvas, MermaidNode node) {
    final nodeIndex = diagram.nodes.indexOf(node);
    final colors = _getParticipantColors(nodeIndex);
    final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);

    final fillPaint = Paint()
      ..color = Color(colors.fill)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Color(colors.stroke)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Check if it's an actor
    if (node is SequenceParticipant &&
        node.participantType == ParticipantType.actor) {
      final nodeStyle = style.getNodeStyle(node.className);
      _drawActor(canvas, rect.center, nodeStyle);
    } else {
      // Regular participant box with rounded corners
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
    }

    // Draw label
    final textStyle = TextStyle(
      color: const Color(0xFF37474F), // Dark blue-gray text
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
    );
    drawText(canvas, node.label, rect.center, textStyle);
  }

  void _drawParticipantBottom(Canvas canvas, MermaidNode node, double y) {
    final nodeIndex = diagram.nodes.indexOf(node);
    final colors = _getParticipantColors(nodeIndex);
    final rect = Rect.fromLTWH(node.x, y, node.width, node.height);

    final fillPaint = Paint()
      ..color = Color(colors.fill)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Color(colors.stroke)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (node is SequenceParticipant &&
        node.participantType == ParticipantType.actor) {
      final nodeStyle = style.getNodeStyle(node.className);
      _drawActor(canvas, rect.center, nodeStyle);
    } else {
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
    }

    final textStyle = TextStyle(
      color: const Color(0xFF37474F),
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
    );
    drawText(canvas, node.label, rect.center, textStyle);
  }

  void _drawActor(Canvas canvas, Offset center, NodeStyle nodeStyle) {
    final strokePaint = Paint()
      ..color = Color(nodeStyle.strokeColor ?? MermaidColors.defaultNodeStroke)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const headRadius = 10.0;
    const bodyHeight = 20.0;
    const armSpan = 15.0;
    const legSpan = 12.0;

    // Head
    canvas.drawCircle(
      Offset(center.dx, center.dy - bodyHeight - headRadius),
      headRadius,
      strokePaint,
    );

    // Body
    canvas.drawLine(
      Offset(center.dx, center.dy - bodyHeight),
      Offset(center.dx, center.dy),
      strokePaint,
    );

    // Arms
    canvas.drawLine(
      Offset(center.dx - armSpan, center.dy - bodyHeight + 5),
      Offset(center.dx + armSpan, center.dy - bodyHeight + 5),
      strokePaint,
    );

    // Legs
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx - legSpan, center.dy + 15),
      strokePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + legSpan, center.dy + 15),
      strokePaint,
    );
  }

  void _drawMessage(Canvas canvas, MermaidEdge edge, double y) {
    final fromNode = diagram.getNode(edge.from);
    final toNode = diagram.getNode(edge.to);

    if (fromNode == null || toNode == null) return;

    final fromX = fromNode.x + fromNode.width / 2;
    final toX = toNode.x + toNode.width / 2;

    final paint = createEdgePaint(edge);

    // Self-referential message
    if (edge.from == edge.to) {
      _drawSelfMessage(canvas, fromX, y, edge, paint);
      return;
    }

    // Draw the line
    drawLine(canvas, Offset(fromX, y), Offset(toX, y), paint, edge.lineType);

    // Draw arrow head
    if (edge.arrowType != ArrowType.none) {
      final angle = toX > fromX ? 0.0 : math.pi;
      drawArrowHead(canvas, Offset(toX, y), angle, edge.arrowType, paint);
    }

    // Draw label
    if (edge.label != null && edge.label!.isNotEmpty) {
      final midX = (fromX + toX) / 2;
      final edgeStyle = edge.style ?? style.defaultEdgeStyle;
      final textStyle = TextStyle(
        color: Color(edgeStyle.labelColor ?? MermaidColors.defaultTextColor),
        fontSize: edgeStyle.labelFontSize,
      );
      drawText(
        canvas,
        edge.label!,
        Offset(midX, y - 12),
        textStyle,
        backgroundColor: Color(
          edgeStyle.labelBackgroundColor ?? style.backgroundColor,
        ),
      );
    }
  }

  void _drawSelfMessage(
    Canvas canvas,
    double x,
    double y,
    MermaidEdge edge,
    Paint paint,
  ) {
    const loopWidth = 30.0;
    const loopHeight = 20.0;

    final path = Path()
      ..moveTo(x, y)
      ..lineTo(x + loopWidth, y)
      ..lineTo(x + loopWidth, y + loopHeight)
      ..lineTo(x, y + loopHeight);

    if (edge.lineType == LineType.dotted) {
      // Draw dashed path
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        var distance = 0.0;
        while (distance < metric.length) {
          final segmentLength = math.min(5.0, metric.length - distance);
          final extractedPath = metric.extractPath(
            distance,
            distance + segmentLength,
          );
          canvas.drawPath(extractedPath, paint);
          distance += 10.0; // 5 dash + 5 gap
        }
      }
    } else {
      canvas.drawPath(path, paint);
    }

    // Arrow head pointing down-left
    if (edge.arrowType != ArrowType.none) {
      drawArrowHead(
        canvas,
        Offset(x, y + loopHeight),
        math.pi, // Pointing left
        edge.arrowType,
        paint,
      );
    }

    // Label
    if (edge.label != null && edge.label!.isNotEmpty) {
      final edgeStyle = edge.style ?? style.defaultEdgeStyle;
      final textStyle = TextStyle(
        color: Color(edgeStyle.labelColor ?? MermaidColors.defaultTextColor),
        fontSize: edgeStyle.labelFontSize,
      );
      drawText(
        canvas,
        edge.label!,
        Offset(x + loopWidth + 5, y + loopHeight / 2),
        textStyle,
        align: TextAlign.left,
      );
    }
  }
}
