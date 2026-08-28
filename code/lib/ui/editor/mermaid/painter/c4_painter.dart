/// Painter for C4 diagrams
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../models/c4_diagram.dart';
import '../models/style.dart';

/// Draws a C4 diagram: labelled boxes inside dashed boundaries, with arrows.
class C4Painter extends CustomPainter {
  /// Creates a C4 painter.
  const C4Painter({
    required this.c4Data,
    required this.style,
    this.deviceConfig,
  });

  /// The diagram to draw.
  final C4DiagramData c4Data;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  @override
  void paint(Canvas canvas, Size size) {
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final titleHeight = c4Data.title == null ? 0.0 : (isMobile ? 30.0 : 38.0);

    final layout = C4Layout.compute(
      c4Data,
      availableWidth: size.width,
      padding: style.padding,
      titleHeight: titleHeight,
    );
    if (layout.elements.isEmpty && layout.boundaries.isEmpty) return;

    if (c4Data.title != null) {
      _drawText(
        canvas,
        c4Data.title!,
        Rect.fromLTWH(0, style.padding, size.width, titleHeight),
        fontSize: isMobile ? 14 : 16,
        color: const Color(0xFF212121),
        weight: FontWeight.w600,
      );
    }

    // Boundaries first, and outermost first within that, so a nested one and
    // the boxes inside both land on top of their parent.
    for (final boundary in layout.boundaries) {
      _drawBoundary(canvas, boundary);
    }
    _drawRelations(canvas, layout);
    for (final element in layout.elements) {
      _drawElement(canvas, element, isMobile);
    }
  }

  void _drawBoundary(Canvas canvas, C4BoundaryPlacement placed) {
    final rect = Rect.fromLTWH(
      placed.left,
      placed.top,
      placed.width,
      placed.height,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(C4Colors.boundaryStroke);

    _drawDashedRect(canvas, rect, stroke);

    final type = placed.boundary.type;
    final label = type == null
        ? placed.boundary.label
        : '${placed.boundary.label} [$type]';
    _drawText(
      canvas,
      label,
      Rect.fromLTWH(placed.left + 10, placed.top + 4, placed.width - 20, 18),
      fontSize: 11.5,
      color: const Color(C4Colors.boundaryStroke),
      weight: FontWeight.w600,
      align: TextAlign.left,
    );
  }

  void _drawElement(Canvas canvas, C4Placement placed, bool isMobile) {
    final rect = Rect.fromLTWH(
      placed.left,
      placed.top,
      placed.width,
      placed.height,
    );
    final element = placed.element;
    final fill = Paint()..color = Color(_fillFor(element));

    switch (element.kind) {
      case C4ElementKind.person:
        // A head above a rounded body, which is how C4 draws an actor.
        final headRadius = math.min(rect.width, rect.height) / 9;
        final body = Rect.fromLTWH(
          rect.left,
          rect.top + headRadius,
          rect.width,
          rect.height - headRadius,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(body, const Radius.circular(8)),
          fill,
        );
        canvas.drawCircle(
          Offset(rect.center.dx, rect.top + headRadius),
          headRadius,
          fill,
        );
      case C4ElementKind.database:
        final lid = math.min(rect.height / 6, 10.0);
        final path = Path()
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
        canvas.drawPath(path, fill);
      case C4ElementKind.queue:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
          fill,
        );
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          fill,
        );
    }

    _drawElementText(canvas, placed, isMobile);
  }

  void _drawElementText(Canvas canvas, C4Placement placed, bool isMobile) {
    final element = placed.element;
    final parts = <String>[
      element.label,
      if (element.technology != null && element.technology!.isNotEmpty)
        '[${element.technology}]',
      if (element.description != null && element.description!.isNotEmpty)
        element.description!,
    ];

    final painter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: parts.first,
            style: TextStyle(
              fontSize: isMobile ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(C4Colors.boxText),
              fontFamily: style.fontFamily,
            ),
          ),
          for (final part in parts.skip(1))
            TextSpan(
              text: '\n$part',
              style: TextStyle(
                fontSize: isMobile ? 9.5 : 10.5,
                color: const Color(C4Colors.boxText),
                fontFamily: style.fontFamily,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 5,
      ellipsis: '…',
    )..layout(maxWidth: placed.width - 16);

    painter.paint(
      canvas,
      Offset(
        placed.left + (placed.width - painter.width) / 2,
        placed.top + (placed.height - painter.height) / 2 + 4,
      ),
    );
  }

  void _drawRelations(Canvas canvas, C4LayoutResult layout) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(C4Colors.relation);

    for (final relation in c4Data.relations) {
      final from = layout.find(relation.from);
      final to = layout.find(relation.to);
      if (from == null || to == null || from == to) continue;

      final (fx, fy) = from.center;
      final (tx, ty) = to.center;
      final start = _edgePoint(from, tx, ty);
      final end = _edgePoint(to, fx, fy);

      canvas.drawLine(start, end, paint);
      _drawArrowHead(canvas, start, end);
      if (relation.bidirectional) _drawArrowHead(canvas, end, start);

      final parts = <String>[
        if (relation.label != null && relation.label!.isNotEmpty)
          relation.label!,
        if (relation.technology != null && relation.technology!.isNotEmpty)
          '[${relation.technology}]',
      ];
      if (parts.isEmpty) continue;

      _drawText(
        canvas,
        parts.join('\n'),
        Rect.fromCenter(
          center: Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
          width: 130,
          height: 30,
        ),
        fontSize: 10.5,
        color: const Color(C4Colors.relation),
        weight: FontWeight.w400,
        background: true,
      );
    }
  }

  /// Where a line aimed at ([towardsX], [towardsY]) leaves [placed]'s outline.
  ///
  /// Meeting the edge rather than the centre is what keeps the arrowhead from
  /// disappearing under the box it points at.
  Offset _edgePoint(C4Placement placed, double towardsX, double towardsY) {
    final (cx, cy) = placed.center;
    final dx = towardsX - cx;
    final dy = towardsY - cy;
    if (dx == 0 && dy == 0) return Offset(cx, cy);

    final scale = math.min(
      dx == 0 ? double.infinity : (placed.width / 2) / dx.abs(),
      dy == 0 ? double.infinity : (placed.height / 2) / dy.abs(),
    );
    return Offset(cx + dx * scale, cy + dy * scale);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end) {
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

    canvas.drawPath(path, Paint()..color = const Color(C4Colors.relation));
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dash = 7.0;
    const gap = 5.0;

    void run(Offset from, Offset to) {
      final total = (to - from).distance;
      if (total == 0) return;
      final step = (to - from) / total;
      var travelled = 0.0;
      while (travelled < total) {
        final end = math.min(travelled + dash, total);
        canvas.drawLine(from + step * travelled, from + step * end, paint);
        travelled = end + gap;
      }
    }

    run(rect.topLeft, rect.topRight);
    run(rect.topRight, rect.bottomRight);
    run(rect.bottomRight, rect.bottomLeft);
    run(rect.bottomLeft, rect.topLeft);
  }

  int _fillFor(C4Element element) {
    if (element.isExternal) return C4Colors.externalFill;
    return element.kind == C4ElementKind.person
        ? C4Colors.personFill
        : C4Colors.systemFill;
  }

  /// Draws [text] inside [rect].
  void _drawText(
    Canvas canvas,
    String text,
    Rect rect, {
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w400,
    TextAlign align = TextAlign.center,
    bool background = false,
  }) {
    if (text.isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          fontFamily: style.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: math.max(rect.width, 20));

    final dx = align == TextAlign.left
        ? rect.left
        : rect.left + (rect.width - painter.width) / 2;
    final origin = Offset(dx, rect.top + (rect.height - painter.height) / 2);

    if (background) {
      // A relation label sits on its own line; without something behind it the
      // line runs straight through the text.
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
  bool shouldRepaint(covariant C4Painter oldDelegate) =>
      oldDelegate.c4Data != c4Data || oldDelegate.style != style;
}
