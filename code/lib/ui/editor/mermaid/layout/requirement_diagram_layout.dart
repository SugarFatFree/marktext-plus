import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../models/node.dart';
import '../models/requirement_diagram.dart';
import '../models/style.dart';
import 'dagre_layout.dart';

/// Measured geometry of a single requirement box.
///
/// Layout and painting have to agree on these numbers exactly, or the text
/// overflows the box it was measured for, so both call [measure].
class RequirementBoxMetrics {
  const RequirementBoxMetrics({
    required this.size,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.lineHeight,
    required this.headerHeight,
    required this.labelWidth,
  });

  static const double horizontalPadding = 12.0;
  static const double verticalPadding = 8.0;
  static const double minWidth = 140.0;
  static const double maxWidth = 320.0;
  static const double lineHeightFactor = 1.5;

  /// Gap between a row's label and its value.
  static const double labelGap = 10.0;

  final Size size;

  /// The box's name.
  final String title;

  /// What kind of thing it is, drawn under the name.
  final String subtitle;

  /// Label and value for each row under the header.
  final List<(String, String)> rows;

  final double lineHeight;

  /// Height of the name-and-kind header.
  final double headerHeight;

  /// Width reserved for the row labels, so the values line up.
  final double labelWidth;

  static RequirementBoxMetrics? measure(
    String name,
    RequirementDiagramData data,
    MermaidStyle style,
  ) {
    final box = data.boxFor(name);
    if (box == null) return null;

    final fontSize = style.getNodeStyle(null).fontSize;
    final lineHeight = fontSize * lineHeightFactor;

    var labelWidth = 0.0;
    for (final row in box.rows) {
      labelWidth = math.max(
        labelWidth,
        _measure(row.$1, fontSize, style.fontFamily, FontWeight.w600),
      );
    }

    var contentWidth = math.max(
      _measure(box.title, fontSize, style.fontFamily, FontWeight.w600),
      _measure(box.subtitle ?? '', fontSize * 0.85, style.fontFamily, null),
    );
    for (final row in box.rows) {
      contentWidth = math.max(
        contentWidth,
        labelWidth +
            labelGap +
            _measure(row.$2, fontSize, style.fontFamily, null),
      );
    }

    final width = contentWidth
        .clamp(minWidth - horizontalPadding * 2, maxWidth - horizontalPadding * 2)
        .toDouble();

    // Two header lines: the name, then the kind.
    final headerHeight = verticalPadding * 2 + lineHeight * 2;
    final bodyHeight = box.rows.isEmpty
        ? 0.0
        : verticalPadding * 2 + box.rows.length * lineHeight;

    return RequirementBoxMetrics(
      size: Size(width + horizontalPadding * 2, headerHeight + bodyHeight),
      title: box.title,
      subtitle: box.subtitle ?? '',
      rows: box.rows,
      lineHeight: lineHeight,
      headerHeight: headerHeight,
      labelWidth: labelWidth,
    );
  }

  static double _measure(
    String text,
    double fontSize,
    String? fontFamily,
    FontWeight? fontWeight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

/// Hierarchical layout for requirement diagrams.
///
/// Reuses Dagre's ranking and crossing reduction, replacing only how a node is
/// measured: a requirement box is a header plus a table of rows, which a
/// single label line cannot describe.
class RequirementDiagramLayout extends DagreLayout {
  RequirementDiagramLayout({required this.requirementData, super.deviceConfig});

  final RequirementDiagramData requirementData;

  final Map<String, RequirementBoxMetrics?> _cache = {};

  RequirementBoxMetrics? metricsFor(String id, MermaidStyle style) {
    return _cache.putIfAbsent(
      id,
      () => RequirementBoxMetrics.measure(id, requirementData, style),
    );
  }

  @override
  Size measureNodeWithShape(MermaidNode node, MermaidStyle style) {
    final metrics = metricsFor(node.id, style);
    if (metrics == null) return super.measureNodeWithShape(node, style);
    return metrics.size;
  }
}
