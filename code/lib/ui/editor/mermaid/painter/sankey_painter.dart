/// Painter for Sankey diagrams
library;

import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../models/sankey.dart';
import '../models/style.dart';

/// Draws a Sankey diagram: bars joined by ribbons whose thickness is the flow.
class SankeyPainter extends CustomPainter {
  /// Creates a Sankey painter.
  const SankeyPainter({
    required this.sankeyData,
    required this.style,
    this.deviceConfig,
  });

  /// The diagram to draw.
  final SankeyChartData sankeyData;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  @override
  void paint(Canvas canvas, Size size) {
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final titleHeight = sankeyData.title == null
        ? 0.0
        : (isMobile ? 30.0 : 38.0);

    final layout = SankeyLayout.compute(
      sankeyData,
      availableWidth: size.width,
      bandHeight: isMobile ? 260 : 360,
      padding: style.padding,
      titleHeight: titleHeight,
      labelGutter: isMobile ? 72 : 96,
    );
    if (layout.nodes.isEmpty) return;

    if (sankeyData.title != null) {
      _drawText(
        canvas,
        sankeyData.title!,
        Offset(size.width / 2, style.padding + titleHeight / 2),
        fontSize: isMobile ? 14 : 16,
        weight: FontWeight.w600,
        color: SankeyColors.textColor,
        align: TextAlign.center,
        maxWidth: size.width - style.padding * 2,
      );
    }

    _drawLinks(canvas, layout);
    _drawNodes(canvas, layout, isMobile);
  }

  void _drawLinks(Canvas canvas, SankeyLayoutResult layout) {
    for (final ribbon in layout.links) {
      final half = ribbon.thickness / 2;
      // A pair of cubics with control points halfway across gives the S-curve
      // mermaid draws; a straight ribbon reads as a bar chart, not a flow.
      final midX = (ribbon.x0 + ribbon.x1) / 2;

      final path = Path()
        ..moveTo(ribbon.x0, ribbon.y0 - half)
        ..cubicTo(
          midX,
          ribbon.y0 - half,
          midX,
          ribbon.y1 - half,
          ribbon.x1,
          ribbon.y1 - half,
        )
        ..lineTo(ribbon.x1, ribbon.y1 + half)
        ..cubicTo(
          midX,
          ribbon.y1 + half,
          midX,
          ribbon.y0 + half,
          ribbon.x0,
          ribbon.y0 + half,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Color(SankeyColors.forIndex(ribbon.colorIndex))
              .withValues(alpha: 0.42),
      );
    }
  }

  void _drawNodes(Canvas canvas, SankeyLayoutResult layout, bool isMobile) {
    var lastLayer = 0;
    for (final node in layout.nodes) {
      if (node.layer > lastLayer) lastLayer = node.layer;
    }

    for (final node in layout.nodes) {
      canvas.drawRect(
        Rect.fromLTWH(node.left, node.top, node.width, node.height),
        Paint()..color = Color(SankeyColors.forIndex(node.index)),
      );

      // Labels sit outside the diagram on the side the bar is nearest, so they
      // never land on top of a ribbon.
      final onLeft = node.layer * 2 >= lastLayer && lastLayer > 0;
      final gap = isMobile ? 5.0 : 7.0;
      _drawText(
        canvas,
        node.id,
        Offset(
          onLeft ? node.left - gap : node.right + gap,
          node.top + node.height / 2,
        ),
        fontSize: isMobile ? 10 : 11.5,
        weight: FontWeight.w500,
        color: SankeyColors.textColor,
        align: onLeft ? TextAlign.right : TextAlign.left,
        maxWidth: layout.labelGutter - gap,
        anchorRight: onLeft,
      );
    }
  }

  /// Draws [text] vertically centred on [anchor].
  ///
  /// [anchorRight] puts the right edge of the text on [anchor] instead of the
  /// left, which is what a label hanging off the left of a bar needs.
  void _drawText(
    Canvas canvas,
    String text,
    Offset anchor, {
    required double fontSize,
    required FontWeight weight,
    required int color,
    required TextAlign align,
    required double maxWidth,
    bool anchorRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: Color(color),
          fontFamily: style.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth <= 0 ? double.infinity : maxWidth);

    final dx = align == TextAlign.center
        ? anchor.dx - painter.width / 2
        : anchorRight
        ? anchor.dx - painter.width
        : anchor.dx;

    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant SankeyPainter oldDelegate) =>
      oldDelegate.sankeyData != sankeyData || oldDelegate.style != style;
}
