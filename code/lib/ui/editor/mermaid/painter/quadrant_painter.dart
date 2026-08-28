/// Painter for quadrant charts
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../models/quadrant_chart.dart';
import '../models/style.dart';

/// Draws a quadrant chart: a square plot split into four labelled regions.
class QuadrantPainter extends CustomPainter {
  /// Creates a quadrant chart painter.
  const QuadrantPainter({
    required this.quadrantData,
    required this.style,
    this.deviceConfig,
  });

  /// The chart to draw.
  final QuadrantChartData quadrantData;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  @override
  void paint(Canvas canvas, Size size) {
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final padding = style.padding;
    final titleHeight = quadrantData.title == null ? 0.0 : (isMobile ? 32.0 : 40.0);
    // Room for the axis captions drawn outside the plot on all four sides.
    const axisGutter = 26.0;

    if (quadrantData.title != null) {
      _drawText(
        canvas,
        quadrantData.title!,
        Offset(size.width / 2, padding + titleHeight / 2),
        fontSize: isMobile ? 15 : 17,
        weight: FontWeight.w600,
        color: QuadrantChartColors.textColor,
      );
    }

    final left = padding + axisGutter;
    final top = padding + titleHeight + axisGutter;
    final side = math.min(
      size.width - left - padding - axisGutter,
      size.height - top - padding - axisGutter,
    );
    if (side <= 0) return;

    final plot = Rect.fromLTWH(left, top, side, side);
    _drawQuadrants(canvas, plot, isMobile);
    _drawAxes(canvas, plot, isMobile);
    _drawPoints(canvas, plot, isMobile);
  }

  void _drawQuadrants(Canvas canvas, Rect plot, bool isMobile) {
    final half = plot.width / 2;
    // Anticlockwise from the top right, which is how mermaid numbers them.
    final rects = [
      Rect.fromLTWH(plot.left + half, plot.top, half, half),
      Rect.fromLTWH(plot.left, plot.top, half, half),
      Rect.fromLTWH(plot.left, plot.top + half, half, half),
      Rect.fromLTWH(plot.left + half, plot.top + half, half, half),
    ];
    final labels = [
      quadrantData.quadrant1,
      quadrantData.quadrant2,
      quadrantData.quadrant3,
      quadrantData.quadrant4,
    ];

    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
        rects[i],
        Paint()..color = Color(QuadrantChartColors.quadrantFills[i]),
      );
      final label = labels[i];
      if (label == null || label.isEmpty) continue;
      _drawText(
        canvas,
        label,
        rects[i].center,
        fontSize: isMobile ? 11 : 13,
        weight: FontWeight.w500,
        color: QuadrantChartColors.quadrantLabelColor,
        maxWidth: half - 12,
      );
    }
  }

  void _drawAxes(Canvas canvas, Rect plot, bool isMobile) {
    final line = Paint()
      ..color = Color(QuadrantChartColors.axisColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(plot, line);
    canvas.drawLine(
      Offset(plot.center.dx, plot.top),
      Offset(plot.center.dx, plot.bottom),
      line,
    );
    canvas.drawLine(
      Offset(plot.left, plot.center.dy),
      Offset(plot.right, plot.center.dy),
      line,
    );

    final fontSize = isMobile ? 10.0 : 12.0;
    const gap = 14.0;

    void caption(String? text, Offset at, {double rotation = 0}) {
      if (text == null || text.isEmpty) return;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      if (rotation != 0) canvas.rotate(rotation);
      _drawText(
        canvas,
        text,
        Offset.zero,
        fontSize: fontSize,
        weight: FontWeight.w400,
        color: QuadrantChartColors.quadrantLabelColor,
        maxWidth: plot.width / 2 - 8,
      );
      canvas.restore();
    }

    caption(quadrantData.xAxisLeft,
        Offset(plot.left + plot.width / 4, plot.bottom + gap));
    caption(quadrantData.xAxisRight,
        Offset(plot.right - plot.width / 4, plot.bottom + gap));
    // Rotated so a long caption runs along the axis rather than off the side.
    caption(quadrantData.yAxisBottom,
        Offset(plot.left - gap, plot.bottom - plot.height / 4),
        rotation: -math.pi / 2);
    caption(quadrantData.yAxisTop,
        Offset(plot.left - gap, plot.top + plot.height / 4),
        rotation: -math.pi / 2);
  }

  void _drawPoints(Canvas canvas, Rect plot, bool isMobile) {
    final defaultRadius = isMobile ? 4.0 : 5.0;

    for (final point in quadrantData.points) {
      // y runs bottom-up in the source and top-down on the canvas.
      final center = Offset(
        plot.left + point.x * plot.width,
        plot.bottom - point.y * plot.height,
      );
      final radius = point.radius ?? defaultRadius;
      final color = Color(point.color ?? QuadrantChartColors.pointColor);

      canvas.drawCircle(center, radius, Paint()..color = color);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      if (point.label.isEmpty) continue;
      _drawText(
        canvas,
        point.label,
        Offset(center.dx, center.dy - radius - (isMobile ? 8 : 9)),
        fontSize: isMobile ? 10 : 11,
        weight: FontWeight.w400,
        color: QuadrantChartColors.textColor,
      );
    }
  }

  /// Draws [text] centred on [center].
  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required FontWeight weight,
    required int color,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: Color(color),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant QuadrantPainter oldDelegate) =>
      oldDelegate.quadrantData != quadrantData || oldDelegate.style != style;
}
