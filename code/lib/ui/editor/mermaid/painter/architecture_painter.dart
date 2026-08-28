import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/architecture_layout.dart';
import '../models/architecture.dart';
import '../models/style.dart';

/// Draws an `architecture-beta` diagram.
class ArchitecturePainter extends CustomPainter {
  /// Creates an architecture painter.
  const ArchitecturePainter({
    required this.architectureData,
    required this.layout,
    required this.style,
    this.deviceConfig,
  });

  /// The diagram to render.
  final ArchitectureDiagramData architectureData;

  /// Where everything was placed.
  final ArchitectureLayoutResult layout;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// The icons mermaid ships with its architecture diagrams.
  ///
  /// Anything else — a name from one of the iconify packs mermaid can be
  /// configured with — falls back to a generic box rather than to nothing, so
  /// an unfamiliar icon costs the picture its glyph and not its node.
  static const _icons = <String, IconData>{
    'cloud': Icons.cloud_outlined,
    'database': Icons.storage_outlined,
    'disk': Icons.save_outlined,
    'server': Icons.dns_outlined,
    'internet': Icons.public_outlined,
  };

  static const _fallbackIcon = Icons.widgets_outlined;

  @override
  void paint(Canvas canvas, Size size) {
    if (architectureData.isEmpty) return;

    final stroke = Color(style.defaultNodeStyle.strokeColor ?? 0xFF64B5F6);
    final fill = Color(style.defaultNodeStyle.fillColor ?? 0xFFECEFF1);
    final text = Color(style.defaultNodeStyle.textColor ?? 0xFF212121);
    final edgeColor = Color(style.defaultEdgeStyle.strokeColor ?? 0xFF9E9E9E);

    if (architectureData.title != null) {
      _text(
        canvas,
        architectureData.title!,
        Rect.fromLTWH(0, ArchitectureLayout.diagramPadding, size.width,
            ArchitectureLayout.titleHeight),
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(style.onBackgroundTextColor),
          fontFamily: style.fontFamily,
        ),
      );
    }

    // Group frames first: they sit behind everything they hold.
    final framePaint = Paint()
      ..color = Color(style.onBackgroundTextColor).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final box in layout.groupBoxes) {
      final rounded = RRect.fromRectAndRadius(box.rect, const Radius.circular(8));
      _dashedRRect(canvas, rounded, framePaint);
      _text(
        canvas,
        box.group.label,
        Rect.fromLTWH(
          box.rect.left + 10,
          box.rect.top + 4,
          box.rect.width - 20,
          ArchitectureLayout.groupTitleHeight,
        ),
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(style.onBackgroundTextColor),
          fontFamily: style.fontFamily,
        ),
        align: TextAlign.left,
      );
    }

    // Edges under the boxes, so a line that runs behind a node is hidden by it
    // rather than drawn across its label.
    final edgePaint = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final edge in architectureData.edges) {
      final from = _anchor(edge.fromId, edge.fromIsGroup, edge.fromSide);
      final to = _anchor(edge.toId, edge.toIsGroup, edge.toSide);
      if (from == null || to == null) continue;
      _orthogonal(canvas, from, to, edge, edgePaint);
    }

    for (final placement in layout.placements) {
      if (placement.node.isJunction) {
        // A junction is a routing corner, not a box: mermaid draws nothing
        // but the meeting of the lines.
        canvas.drawCircle(placement.rect.center, 4, Paint()..color = edgeColor);
        continue;
      }
      final rect = RRect.fromRectAndRadius(
        placement.rect,
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, Paint()..color = fill);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final icon = _icons[placement.node.icon] ??
          (placement.node.icon == null ? null : _fallbackIcon);
      final labelTop = placement.rect.top + (icon == null ? 0 : 34);
      if (icon != null) {
        _icon(canvas, icon, placement.rect.topCenter + const Offset(0, 12), text);
      }
      _text(
        canvas,
        placement.node.label,
        Rect.fromLTRB(
          placement.rect.left + 4,
          labelTop,
          placement.rect.right - 4,
          placement.rect.bottom - 4,
        ),
        TextStyle(fontSize: 12, color: text, fontFamily: style.fontFamily),
      );
    }
  }

  /// The point on a node's or group's frame that an edge attaches to.
  Offset? _anchor(String id, bool isGroup, ArchSide side) {
    final rect = isGroup
        ? layout.groupBoxOf(id)?.rect
        : layout.placementOf(id)?.rect ?? layout.groupBoxOf(id)?.rect;
    if (rect == null) return null;
    return switch (side) {
      ArchSide.left => Offset(rect.left, rect.center.dy),
      ArchSide.right => Offset(rect.right, rect.center.dy),
      ArchSide.top => Offset(rect.center.dx, rect.top),
      ArchSide.bottom => Offset(rect.center.dx, rect.bottom),
    };
  }

  /// Draws the connection as two straight runs meeting at a right angle.
  ///
  /// Architecture diagrams are drawn on a grid and mermaid routes them
  /// orthogonally; a straight diagonal between two boxes cuts across the cells
  /// between them and reads as a different picture.
  void _orthogonal(
    Canvas canvas,
    Offset from,
    Offset to,
    ArchEdge edge,
    Paint paint,
  ) {
    final horizontalFirst =
        edge.fromSide == ArchSide.left || edge.fromSide == ArchSide.right;
    final corner =
        horizontalFirst ? Offset(to.dx, from.dy) : Offset(from.dx, to.dy);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(corner.dx, corner.dy)
      ..lineTo(to.dx, to.dy);
    canvas.drawPath(path, paint);

    if (edge.arrowAtTo) {
      _arrowHead(canvas, to, corner == to ? from : corner, paint.color);
    }
    if (edge.arrowAtFrom) {
      _arrowHead(canvas, from, corner == from ? to : corner, paint.color);
    }
  }

  void _arrowHead(Canvas canvas, Offset tip, Offset from, Color color) {
    final direction = tip - from;
    if (direction.distance == 0) return;
    final angle = direction.direction;
    const length = 9.0;
    const spread = 0.45;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - length * _cos(angle - spread),
        tip.dy - length * _sin(angle - spread),
      )
      ..lineTo(
        tip.dx - length * _cos(angle + spread),
        tip.dy - length * _sin(angle + spread),
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static double _cos(double radians) => Offset.fromDirection(radians).dx;
  static double _sin(double radians) => Offset.fromDirection(radians).dy;

  void _dashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  void _icon(Canvas canvas, IconData icon, Offset center, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, 0));
  }

  void _text(
    Canvas canvas,
    String text,
    Rect box,
    TextStyle textStyle, {
    TextAlign align = TextAlign.center,
  }) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: box.width < 0 ? 0 : box.width);
    final dx = align == TextAlign.left
        ? box.left
        : box.left + (box.width - painter.width) / 2;
    painter.paint(canvas, Offset(dx, box.top));
  }

  @override
  bool shouldRepaint(covariant ArchitecturePainter oldDelegate) =>
      architectureData != oldDelegate.architectureData ||
      layout != oldDelegate.layout ||
      style != oldDelegate.style;
}
