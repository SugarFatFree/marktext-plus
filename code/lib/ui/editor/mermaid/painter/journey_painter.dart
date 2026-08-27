import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/layout_engine.dart';
import '../models/journey.dart';
import '../models/style.dart';

/// Paints user journey diagrams as a satisfaction line.
///
/// Tasks run left to right on a fixed column pitch; the score puts each marker
/// on one of five rows and colours it, so the shape of the line reads as the
/// shape of the experience.
class JourneyPainter extends CustomPainter {
  /// Creates a journey painter.
  const JourneyPainter({
    required this.journeyData,
    required this.style,
    this.deviceConfig,
  });

  /// The journey to render.
  final JourneyData journeyData;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// Marker colours for scores 1..5, worst to best.
  static const _scoreColors = <Color>[
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFFFFD54F),
    Color(0xFFAED581),
    Color(0xFF66BB6A),
  ];

  /// Backgrounds cycled through for section headers.
  static const _sectionColors = <Color>[
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFE0F7FA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final tasks = journeyData.allTasks;
    if (tasks.isEmpty) return;

    final padding = style.padding;
    final textColor = Color(
      style.defaultNodeStyle.textColor ?? MermaidColors.defaultTextColor,
    );

    var top = padding;

    if (journeyData.title != null) {
      _drawText(
        canvas,
        journeyData.title!,
        Offset(size.width / 2, top),
        TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: style.fontFamily,
          color: textColor,
        ),
        centred: true,
      );
      top += 44.0;
    } else {
      top += 12.0;
    }

    final sectionTop = top;
    final chartTop = sectionTop + JourneyChartLayout.sectionBarHeight;
    final chartBottom = chartTop + JourneyChartLayout.chartHeight;

    _drawSectionBar(canvas, sectionTop, padding, textColor);
    _drawScoreGuides(canvas, size, chartTop, chartBottom, padding);
    _drawJourneyLine(canvas, tasks, chartTop, chartBottom, padding);
    _drawTaskMarkers(canvas, tasks, chartTop, chartBottom, padding, textColor);

    if (journeyData.actors.isNotEmpty) {
      _drawLegend(
        canvas,
        Offset(padding, chartBottom + JourneyChartLayout.labelHeight),
        textColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant JourneyPainter oldDelegate) {
    return journeyData != oldDelegate.journeyData || style != oldDelegate.style;
  }

  /// Header strip, each section spanning as many columns as it has tasks.
  void _drawSectionBar(
    Canvas canvas,
    double top,
    double padding,
    Color textColor,
  ) {
    var x = padding;
    var colorIndex = 0;

    for (final section in journeyData.sections) {
      if (section.tasks.isEmpty) continue;
      final width = section.tasks.length * JourneyChartLayout.taskWidth;
      final rect = Rect.fromLTWH(
        x + 2,
        top,
        width - 4,
        JourneyChartLayout.sectionBarHeight - 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..color = _sectionColors[colorIndex % _sectionColors.length]
          ..style = PaintingStyle.fill,
      );

      _drawText(
        canvas,
        section.name,
        rect.center,
        TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: style.fontFamily,
          color: textColor,
        ),
        centred: true,
        verticallyCentred: true,
        maxWidth: width - 12,
      );

      x += width;
      colorIndex++;
    }
  }

  /// Five faint rows, one per score.
  void _drawScoreGuides(
    Canvas canvas,
    Size size,
    double chartTop,
    double chartBottom,
    double padding,
  ) {
    final guide = Paint()
      ..color = Color(MermaidColors.defaultEdgeColor).withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (var score = 1; score <= 5; score++) {
      final y = _yForScore(score, chartTop, chartBottom);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        guide,
      );
    }
  }

  void _drawJourneyLine(
    Canvas canvas,
    List<JourneyTask> tasks,
    double chartTop,
    double chartBottom,
    double padding,
  ) {
    if (tasks.length < 2) return;

    final path = Path();
    for (var i = 0; i < tasks.length; i++) {
      final point = Offset(
        _xForIndex(i, padding),
        _yForScore(tasks[i].clampedScore, chartTop, chartBottom),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Color(MermaidColors.defaultEdgeColor).withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawTaskMarkers(
    Canvas canvas,
    List<JourneyTask> tasks,
    double chartTop,
    double chartBottom,
    double padding,
    Color textColor,
  ) {
    const radius = 13.0;

    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final centre = Offset(
        _xForIndex(i, padding),
        _yForScore(task.clampedScore, chartTop, chartBottom),
      );

      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..color = _scoreColors[task.clampedScore - 1]
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..color = Color(MermaidColors.defaultNodeStroke)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );

      // The score doubles as the marker's label; mermaid draws a face here.
      _drawText(
        canvas,
        '${task.clampedScore}',
        centre,
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: style.fontFamily,
          color: const Color(0xFF37474F),
        ),
        centred: true,
        verticallyCentred: true,
      );

      _drawText(
        canvas,
        task.name,
        Offset(centre.dx, chartBottom + 10),
        TextStyle(
          fontSize: 12,
          fontFamily: style.fontFamily,
          color: textColor,
        ),
        centred: true,
        maxWidth: JourneyChartLayout.taskWidth - 8,
      );

      if (task.actors.isNotEmpty) {
        _drawText(
          canvas,
          task.actors.join(', '),
          Offset(centre.dx, chartBottom + 28),
          TextStyle(
            fontSize: 11,
            fontFamily: style.fontFamily,
            color: textColor.withValues(alpha: 0.7),
          ),
          centred: true,
          maxWidth: JourneyChartLayout.taskWidth - 8,
        );
      }
    }
  }

  void _drawLegend(Canvas canvas, Offset origin, Color textColor) {
    _drawText(
      canvas,
      journeyData.actors.join(' · '),
      origin,
      TextStyle(
        fontSize: 11,
        fontFamily: style.fontFamily,
        color: textColor.withValues(alpha: 0.75),
      ),
      centred: false,
    );
  }

  double _xForIndex(int index, double padding) =>
      padding + index * JourneyChartLayout.taskWidth +
      JourneyChartLayout.taskWidth / 2;

  /// Score 5 sits at the top of the band, score 1 at the bottom.
  double _yForScore(int score, double chartTop, double chartBottom) {
    final usable = chartBottom - chartTop - 40;
    final fraction = (score - 1) / 4.0;
    return chartBottom - 20 - usable * fraction;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle textStyle, {
    required bool centred,
    bool verticallyCentred = false,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);

    final dx = centred ? position.dx - painter.width / 2 : position.dx;
    final dy =
        verticallyCentred ? position.dy - painter.height / 2 : position.dy;
    painter.paint(canvas, Offset(dx, dy));
  }
}
