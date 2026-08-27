/// Data models for quadrant charts
library;

/// One plotted point.
class QuadrantPoint {
  /// Creates a quadrant chart point.
  const QuadrantPoint({
    required this.label,
    required this.x,
    required this.y,
    this.radius,
    this.color,
  });

  /// Text drawn next to the marker.
  final String label;

  /// Horizontal position, 0 at the left edge and 1 at the right.
  final double x;

  /// Vertical position, 0 at the *bottom* edge and 1 at the top — mermaid
  /// quotes these the way a reader thinks of a chart, not the way a canvas
  /// counts pixels.
  final double y;

  /// Marker radius in logical pixels, when the source overrode it.
  final double? radius;

  /// Marker colour as ARGB, when the source overrode it.
  final int? color;

  @override
  bool operator ==(Object other) =>
      other is QuadrantPoint &&
      other.label == label &&
      other.x == x &&
      other.y == y &&
      other.radius == radius &&
      other.color == color;

  @override
  int get hashCode => Object.hash(label, x, y, radius, color);
}

/// A complete quadrant chart.
class QuadrantChartData {
  /// Creates quadrant chart data.
  const QuadrantChartData({
    required this.points,
    this.title,
    this.xAxisLeft,
    this.xAxisRight,
    this.yAxisBottom,
    this.yAxisTop,
    this.quadrant1,
    this.quadrant2,
    this.quadrant3,
    this.quadrant4,
  });

  /// Optional chart title.
  final String? title;

  /// Label at the left end of the x axis.
  final String? xAxisLeft;

  /// Label at the right end of the x axis.
  final String? xAxisRight;

  /// Label at the bottom end of the y axis.
  final String? yAxisBottom;

  /// Label at the top end of the y axis.
  final String? yAxisTop;

  /// Top-right quadrant label. Mermaid numbers the quadrants anticlockwise
  /// from the top right, matching the mathematical convention.
  final String? quadrant1;

  /// Top-left quadrant label.
  final String? quadrant2;

  /// Bottom-left quadrant label.
  final String? quadrant3;

  /// Bottom-right quadrant label.
  final String? quadrant4;

  /// Plotted points.
  final List<QuadrantPoint> points;

  @override
  bool operator ==(Object other) =>
      other is QuadrantChartData &&
      other.title == title &&
      other.xAxisLeft == xAxisLeft &&
      other.xAxisRight == xAxisRight &&
      other.yAxisBottom == yAxisBottom &&
      other.yAxisTop == yAxisTop &&
      other.quadrant1 == quadrant1 &&
      other.quadrant2 == quadrant2 &&
      other.quadrant3 == quadrant3 &&
      other.quadrant4 == quadrant4;

  @override
  int get hashCode => Object.hash(title, xAxisLeft, xAxisRight, yAxisBottom,
      yAxisTop, quadrant1, quadrant2, quadrant3, quadrant4);
}

/// Colours used when drawing a quadrant chart.
class QuadrantChartColors {
  QuadrantChartColors._();

  /// Fill for each quadrant, in order 1 to 4 (top-right first, anticlockwise).
  static const List<int> quadrantFills = [
    0xFFE8F0FE, // top right
    0xFFF3E8FD, // top left
    0xFFE9F7EF, // bottom left
    0xFFFDF3E8, // bottom right
  ];

  /// Default marker colour.
  static const int pointColor = 0xFF1A73E8;

  /// Axis and border colour.
  static const int axisColor = 0xFF9E9E9E;

  /// Text colour.
  static const int textColor = 0xFF212121;

  /// Quadrant label colour, lighter than body text.
  static const int quadrantLabelColor = 0xFF5F6368;
}
