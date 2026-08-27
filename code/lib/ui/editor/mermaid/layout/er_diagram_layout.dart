import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../models/er_diagram.dart';
import '../models/node.dart';
import '../models/style.dart';
import 'dagre_layout.dart';

/// Measured geometry of a single entity box.
///
/// Layout and painting call the same pure [measure], so an attribute row can
/// never be wider than the box that was sized for it.
class ErBoxMetrics {
  /// Creates measured geometry.
  const ErBoxMetrics({
    required this.size,
    required this.attributeLines,
    required this.lineHeight,
    required this.headerHeight,
    required this.attributesHeight,
  });

  /// Horizontal padding inside the box.
  static const double horizontalPadding = 14.0;

  /// Vertical padding inside a compartment.
  static const double verticalPadding = 8.0;

  /// Narrowest an entity box may render.
  static const double minWidth = 120.0;

  /// Line height as a multiple of the font size.
  static const double lineHeightFactor = 1.5;

  /// Overall box size.
  final Size size;

  /// Rendered text of each attribute row.
  final List<String> attributeLines;

  /// Height of one text line.
  final double lineHeight;

  /// Height of the name compartment.
  final double headerHeight;

  /// Height of the attribute compartment; 0 when the entity has no attributes.
  final double attributesHeight;

  /// Whether this entity renders an attribute compartment at all.
  bool get hasAttributes => attributesHeight > 0;

  /// Measures [entity] under [style].
  static ErBoxMetrics measure(ErEntity entity, MermaidStyle style) {
    final nodeStyle = style.defaultNodeStyle;
    final fontSize = nodeStyle.fontSize;
    final lineHeight = fontSize * lineHeightFactor;

    final attributeLines = entity.attributes.map((a) => a.displayText).toList();

    var maxWidth = math.max(
      minWidth - horizontalPadding * 2,
      _measureLine(entity.displayName, fontSize, style.fontFamily,
          FontWeight.w600),
    );
    for (final line in attributeLines) {
      maxWidth = math.max(
        maxWidth,
        _measureLine(line, fontSize, style.fontFamily, null),
      );
    }

    final headerHeight = verticalPadding * 2 + lineHeight;
    final attributesHeight = attributeLines.isEmpty
        ? 0.0
        : verticalPadding * 2 + attributeLines.length * lineHeight;

    return ErBoxMetrics(
      size: Size(
        maxWidth + horizontalPadding * 2,
        headerHeight + attributesHeight,
      ),
      attributeLines: attributeLines,
      lineHeight: lineHeight,
      headerHeight: headerHeight,
      attributesHeight: attributesHeight,
    );
  }

  static double _measureLine(
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

/// Hierarchical layout for ER diagrams.
///
/// Reuses Dagre's ranking and crossing reduction, replacing only node
/// measurement — the inherited version sizes a node from one label line, which
/// cannot describe an entity box carrying a table of attributes.
class ErDiagramLayout extends DagreLayout {
  /// Creates an ER layout for [erData].
  ErDiagramLayout({required this.erData, super.deviceConfig});

  /// The parsed entities, keyed by node id through [ErDiagramData.byId].
  final ErDiagramData erData;

  final Map<String, ErBoxMetrics> _cache = {};

  /// Measured geometry for the entity with [id], or null when [id] is not an
  /// entity in this diagram.
  ErBoxMetrics? metricsFor(String id, MermaidStyle style) {
    final cached = _cache[id];
    if (cached != null) return cached;
    final entity = erData.byId(id);
    if (entity == null) return null;
    final metrics = ErBoxMetrics.measure(entity, style);
    _cache[id] = metrics;
    return metrics;
  }

  @override
  Size measureNodeWithShape(MermaidNode node, MermaidStyle style) {
    final metrics = metricsFor(node.id, style);
    if (metrics == null) return super.measureNodeWithShape(node, style);
    return metrics.size;
  }
}
