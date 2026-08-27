import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../models/class_diagram.dart';
import '../models/node.dart';
import '../models/style.dart';
import 'dagre_layout.dart';

/// Measured geometry of a single class box.
///
/// Layout and painting must agree on these numbers exactly, otherwise text
/// overflows the box it was measured for. Both sides call [measure], which is
/// a pure function of the box and the style.
class ClassBoxMetrics {
  /// Creates measured geometry.
  const ClassBoxMetrics({
    required this.size,
    required this.headerLines,
    required this.attributeLines,
    required this.methodLines,
    required this.lineHeight,
    required this.headerHeight,
    required this.attributesHeight,
    required this.methodsHeight,
  });

  /// Horizontal padding inside a compartment.
  static const double horizontalPadding = 14.0;

  /// Vertical padding inside a compartment.
  static const double verticalPadding = 8.0;

  /// Narrowest a class box may render.
  static const double minWidth = 100.0;

  /// Line height as a multiple of the font size.
  static const double lineHeightFactor = 1.5;

  /// Overall box size.
  final Size size;

  /// Header lines: the stereotype (when present) followed by the class name.
  final List<String> headerLines;

  /// Rendered text of each attribute.
  final List<String> attributeLines;

  /// Rendered text of each method.
  final List<String> methodLines;

  /// Height of one text line.
  final double lineHeight;

  /// Height of the name compartment.
  final double headerHeight;

  /// Height of the attribute compartment, 0 when the box has no compartments.
  final double attributesHeight;

  /// Height of the method compartment, 0 when the box has no compartments.
  final double methodsHeight;

  /// Whether this box renders the attribute/method compartments at all.
  ///
  /// Mermaid draws a bare box for a class declared without members.
  bool get hasCompartments => attributesHeight > 0 || methodsHeight > 0;

  /// Measures [box] under [style].
  static ClassBoxMetrics measure(ClassBox box, MermaidStyle style) {
    final nodeStyle = style.getNodeStyle(box.cssClass);
    final fontSize = nodeStyle.fontSize;
    final lineHeight = fontSize * lineHeightFactor;

    final headerLines = <String>[];
    if (box.stereotype != null && box.stereotype!.isNotEmpty) {
      headerLines.add('«${box.stereotype}»');
    }
    headerLines.add(box.displayName);

    final attributeLines = box.attributes.map((m) => m.displayText).toList();
    final methodLines = box.methods.map((m) => m.displayText).toList();

    var maxWidth = minWidth - horizontalPadding * 2;
    for (final line in headerLines) {
      maxWidth = math.max(
        maxWidth,
        _measureLine(line, fontSize, style.fontFamily, FontWeight.w600),
      );
    }
    for (final line in [...attributeLines, ...methodLines]) {
      maxWidth = math.max(
        maxWidth,
        _measureLine(line, fontSize, style.fontFamily, null),
      );
    }

    final headerHeight = verticalPadding * 2 + headerLines.length * lineHeight;

    final hasMembers = attributeLines.isNotEmpty || methodLines.isNotEmpty;
    final attributesHeight = hasMembers
        ? verticalPadding * 2 + attributeLines.length * lineHeight
        : 0.0;
    final methodsHeight =
        hasMembers ? verticalPadding * 2 + methodLines.length * lineHeight : 0.0;

    return ClassBoxMetrics(
      size: Size(
        maxWidth + horizontalPadding * 2,
        headerHeight + attributesHeight + methodsHeight,
      ),
      headerLines: headerLines,
      attributeLines: attributeLines,
      methodLines: methodLines,
      lineHeight: lineHeight,
      headerHeight: headerHeight,
      attributesHeight: attributesHeight,
      methodsHeight: methodsHeight,
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

/// Hierarchical layout for class diagrams.
///
/// Reuses Dagre's ranking and crossing reduction, replacing only node
/// measurement: [DagreLayout.measureNodeWithShape] sizes a node from a single
/// label line, which cannot describe a three-compartment class box.
class ClassDiagramLayout extends DagreLayout {
  /// Creates a class diagram layout for [classData].
  ClassDiagramLayout({required this.classData, super.deviceConfig});

  /// The parsed class boxes, keyed by node id through [ClassDiagramData.byId].
  final ClassDiagramData classData;

  final Map<String, ClassBoxMetrics> _cache = {};

  /// Measured geometry for the class with [id], or null when [id] is not a
  /// class in this diagram.
  ClassBoxMetrics? metricsFor(String id, MermaidStyle style) {
    final cached = _cache[id];
    if (cached != null) return cached;
    final box = classData.byId(id);
    if (box == null) return null;
    final metrics = ClassBoxMetrics.measure(box, style);
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
