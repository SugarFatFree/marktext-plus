import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../models/timeline.dart';
import '../models/style.dart';

/// Painter for Timeline diagrams
class TimelinePainter extends CustomPainter {
  /// Creates a timeline painter
  const TimelinePainter({
    required this.timelineData,
    required this.style,
    this.deviceConfig,
  });

  /// The timeline data to render
  final TimelineChartData timelineData;

  /// Style configuration
  final MermaidStyle style;

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  @override
  void paint(Canvas canvas, Size size) {
    if (timelineData.sections.isEmpty) return;

    final padding = style.padding;
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final eventRadius = isMobile ? 6.0 : 8.0;

    // Calculate positions
    var currentY = padding;

    // Draw title if present
    if (timelineData.title != null) {
      _drawTitle(canvas, timelineData.title!, size.width / 2, currentY);
      currentY += 40.0;
    }

    // Calculate layout - keep sections evenly distributed for continuous timeline
    final totalSections = timelineData.sections.length;
    final availableWidth = size.width - padding * 2;
    final sectionWidth = availableWidth / totalSections;

    // Mermaid's `section` keyword bands several period columns together. The
    // band is drawn above the period titles, so it needs its own strip of
    // height — but only when the diagram uses sections at all, which keeps
    // every timeline written without them laid out exactly as before.
    final groups = _groupRuns();
    if (groups.isNotEmpty) {
      for (final run in groups) {
        _drawGroupBand(
          canvas,
          run,
          padding,
          sectionWidth,
          currentY,
        );
      }
      currentY += timelineGroupBandHeight;
    }

    // Adjust vertical spacing based on section density
    final verticalSpacing = isMobile ? 35.0 : 50.0;

    // Timeline Y position
    final timelineY = currentY + verticalSpacing + 20;

    // Draw timeline line (continuous from start to end)
    _drawTimelineLine(canvas, padding, size.width - padding, timelineY);

    // Calculate event box width dynamically to prevent overlap
    // Use progressively smaller ratios for denser timelines
    double widthRatio;
    if (sectionWidth < 60) {
      widthRatio = 0.50; // Very dense timeline
    } else if (sectionWidth < 80) {
      widthRatio = 0.55; // Dense timeline
    } else if (sectionWidth < 120) {
      widthRatio = 0.60; // Medium density
    } else {
      widthRatio = 0.65; // Sparse timeline
    }

    final eventBoxWidth = sectionWidth * widthRatio;

    // Draw sections and events
    for (var i = 0; i < totalSections; i++) {
      final section = timelineData.sections[i];
      final sectionX = padding + sectionWidth * i + sectionWidth / 2;
      // Columns in the same band share a colour, the way mermaid colours by
      // section; without bands each column keeps its own.
      final color = TimelineChartColors.getColorForSection(
        _colorIndexFor(i),
      );

      // Draw section marker (circle on timeline)
      _drawSectionMarker(canvas, sectionX, timelineY, eventRadius, color);

      // Draw section title ABOVE timeline
      _drawSectionTitle(
        canvas,
        section.title,
        sectionX,
        timelineY - verticalSpacing,
        color,
      );

      // Draw events BELOW timeline
      _drawEvents(
        canvas,
        section.events,
        sectionX,
        timelineY + verticalSpacing,
        eventBoxWidth,
        color,
      );

      // Draw connector line from timeline to title (upward)
      _drawConnectorLine(
        canvas,
        sectionX,
        timelineY - eventRadius,
        timelineY - verticalSpacing + 15,
        color,
      );
    }
  }

  /// Draws the title
  void _drawTitle(Canvas canvas, String title, double x, double y) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          fontSize: deviceConfig?.fontSize ?? 16.0,
          fontWeight: FontWeight.bold,
          color: Color(style.defaultNodeStyle.textColor ?? TimelineChartColors.textColor),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  /// Runs of consecutive columns that share a [TimelineSection.group].
  ///
  /// Returns `(group name, first column, last column)` for each run, and an
  /// empty list when the diagram uses no sections.
  List<(String, int, int)> _groupRuns() {
    final runs = <(String, int, int)>[];
    final sections = timelineData.sections;
    var start = 0;
    while (start < sections.length) {
      final name = sections[start].group;
      var end = start;
      while (end + 1 < sections.length && sections[end + 1].group == name) {
        end++;
      }
      if (name != null) runs.add((name, start, end));
      start = end + 1;
    }
    return runs;
  }

  /// Which colour a column takes: its band's ordinal, or its own when the
  /// diagram has no bands.
  int _colorIndexFor(int column) {
    final group = timelineData.sections[column].group;
    if (group == null) return column;
    // Ordinal by first appearance, so a band keeps one colour even if its
    // columns are not contiguous in the source.
    final seen = <String>{};
    for (final section in timelineData.sections) {
      final name = section.group;
      if (name == null) continue;
      if (name == group) break;
      seen.add(name);
    }
    return seen.length;
  }

  /// Draws one band above the period titles it covers.
  void _drawGroupBand(
    Canvas canvas,
    (String, int, int) run,
    double padding,
    double sectionWidth,
    double y,
  ) {
    final (name, first, last) = run;
    final left = padding + sectionWidth * first;
    final right = padding + sectionWidth * (last + 1);
    final color = Color(
      TimelineChartColors.getColorForSection(_colorIndexFor(first)),
    );

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 2, y, right - left - 4, timelineGroupBandHeight - 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontSize: deviceConfig?.fontSize ?? 12.0,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    textPainter.layout(maxWidth: (right - left - 12).clamp(0.0, double.infinity));
    textPainter.paint(
      canvas,
      Offset(
        (left + right) / 2 - textPainter.width / 2,
        y + (timelineGroupBandHeight - 8 - textPainter.height) / 2,
      ),
    );
  }

  /// Draws the horizontal timeline line
  void _drawTimelineLine(Canvas canvas, double startX, double endX, double y) {
    final paint = Paint()
      ..color = Color(TimelineChartColors.primaryColor)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
  }

  /// Draws a section marker on the timeline
  void _drawSectionMarker(
    Canvas canvas,
    double x,
    double y,
    double radius,
    int color,
  ) {
    // Draw outer circle
    final outerPaint = Paint()
      ..color = Color(color)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), radius, outerPaint);

    // Draw inner circle (white)
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), radius * 0.5, innerPaint);
  }

  /// Draws the section title
  void _drawSectionTitle(
    Canvas canvas,
    String title,
    double x,
    double y,
    int color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          fontSize: (deviceConfig?.fontSize ?? 12.0) + 2,
          fontWeight: FontWeight.bold,
          color: Color(color),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  /// Draws events for a section (below timeline)
  void _drawEvents(
    Canvas canvas,
    List<TimelineEvent> events,
    double centerX,
    double startY,
    double maxWidth,
    int color,
  ) {
    var currentY = startY;
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    // Increase event spacing to prevent vertical overlap
    final eventSpacing = isMobile ? 18.0 : 22.0;

    // Adjust font size and padding based on available width
    var baseFontSize = deviceConfig?.fontSize ?? 11.0;
    var fontSize = baseFontSize;
    double boxPadding;

    if (maxWidth < 50) {
      fontSize = baseFontSize - 2; // Smaller font for very tight spaces
      boxPadding = 4.0; // Minimal padding
    } else if (maxWidth < 80) {
      fontSize = baseFontSize - 1; // Slightly smaller for tight spaces
      boxPadding = 6.0; // Reduced padding
    } else {
      boxPadding = isMobile ? 6.0 : 10.0; // Normal padding
    }

    for (var i = 0; i < events.length; i++) {
      final event = events[i];

      // Draw event box background
      final titlePainter = TextPainter(
        text: TextSpan(
          text: event.title,
          style: TextStyle(
            fontSize: fontSize,
            color: Color(TimelineChartColors.textColor),
            fontWeight: FontWeight.w500,
            height: 1.2, // Line height for better readability
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 4, // Allow more lines for long titles
        textAlign: TextAlign.center,
      );
      titlePainter.layout(maxWidth: maxWidth);

      // Draw rounded rectangle background
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, currentY + titlePainter.height / 2),
          width: titlePainter.width + boxPadding * 2,
          height: titlePainter.height + boxPadding,
        ),
        const Radius.circular(6),
      );

      final boxPaint = Paint()
        ..color = Color(color).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(boxRect, boxPaint);

      // Draw border
      final borderPaint = Paint()
        ..color = Color(color).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(boxRect, borderPaint);

      // Draw event title
      titlePainter.paint(
        canvas,
        Offset(centerX - titlePainter.width / 2, currentY),
      );

      currentY += titlePainter.height + boxPadding + eventSpacing;

      // Draw event description if present
      if (event.description != null && event.description!.isNotEmpty) {
        final descPainter = TextPainter(
          text: TextSpan(
            text: event.description,
            style: TextStyle(
              fontSize: fontSize - 1,
              color: Color(TimelineChartColors.textColor).withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              height: 1.2, // Line height for better readability
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 3, // Allow more lines for descriptions
          textAlign: TextAlign.center,
        );
        descPainter.layout(maxWidth: maxWidth);
        descPainter.paint(
          canvas,
          Offset(centerX - descPainter.width / 2, currentY),
        );
        currentY += descPainter.height + 8; // Increase spacing after description
      }
    }
  }

  /// Draws a connector line from timeline to section title (upward)
  void _drawConnectorLine(
    Canvas canvas,
    double x,
    double startY,
    double endY,
    int color,
  ) {
    final paint = Paint()
      ..color = Color(color).withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, startY),
      Offset(x, endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(TimelinePainter oldDelegate) {
    return oldDelegate.timelineData != timelineData ||
        oldDelegate.style != style ||
        oldDelegate.deviceConfig != deviceConfig;
  }
}
