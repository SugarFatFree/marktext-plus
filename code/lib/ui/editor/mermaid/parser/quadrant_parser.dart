/// Parser for quadrant charts
library;

import '../models/diagram.dart';
import '../models/quadrant_chart.dart';

/// Parser for Mermaid quadrant charts (`quadrantChart`).
class QuadrantParser {
  /// Creates a quadrant chart parser.
  const QuadrantParser();

  /// `x-axis Low Reach --> High Reach`, where the second half is optional.
  static final _axisRe = RegExp(
    r'^(x-axis|y-axis)\s+(.+)$',
    caseSensitive: false,
  );

  /// `quadrant-1 We should expand`
  static final _quadrantRe = RegExp(
    r'^quadrant-([1-4])\s+(.+)$',
    caseSensitive: false,
  );

  /// `Campaign A: [0.3, 0.6] radius: 10, color: #ff0000`
  static final _pointRe = RegExp(
    r'^(.+?)\s*:\s*\[\s*([0-9.+-]+)\s*,\s*([0-9.+-]+)\s*\](.*)$',
  );

  static final _radiusRe =
      RegExp(r'radius\s*:\s*([0-9.]+)', caseSensitive: false);
  static final _colorRe =
      RegExp(r'(?:color|fill)\s*:\s*(#[0-9a-fA-F]{3,8})', caseSensitive: false);

  /// Parses a quadrant chart from cleaned lines.
  ///
  /// Returns null when there is nothing to draw, so the renderer can fall back
  /// to showing the source rather than an empty box.
  (MermaidDiagramData, QuadrantChartData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    String? title;
    String? xLeft;
    String? xRight;
    String? yBottom;
    String? yTop;
    final quadrants = <int, String>{};
    final points = <QuadrantPoint>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase() == 'quadrantchart') continue;

      if (line.toLowerCase().startsWith('title ')) {
        title = line.substring(6).trim();
        continue;
      }

      final axis = _axisRe.firstMatch(line);
      if (axis != null) {
        final (start, end) = _splitAxis(axis.group(2)!);
        if (axis.group(1)!.toLowerCase() == 'x-axis') {
          xLeft = start;
          xRight = end;
        } else {
          yBottom = start;
          yTop = end;
        }
        continue;
      }

      final quadrant = _quadrantRe.firstMatch(line);
      if (quadrant != null) {
        quadrants[int.parse(quadrant.group(1)!)] = quadrant.group(2)!.trim();
        continue;
      }

      final point = _parsePoint(line);
      if (point != null) points.add(point);
    }

    // Axis and quadrant labels alone still draw a usable chart, but an empty
    // one is not worth replacing the source with.
    if (points.isEmpty &&
        quadrants.isEmpty &&
        xLeft == null &&
        yBottom == null) {
      return null;
    }

    final chart = QuadrantChartData(
      title: title,
      xAxisLeft: xLeft,
      xAxisRight: xRight,
      yAxisBottom: yBottom,
      yAxisTop: yTop,
      quadrant1: quadrants[1],
      quadrant2: quadrants[2],
      quadrant3: quadrants[3],
      quadrant4: quadrants[4],
      points: points,
    );

    return (
      MermaidDiagramData(
        type: DiagramType.quadrantChart,
        nodes: const [],
        edges: const [],
        title: title,
      ),
      chart,
    );
  }

  /// Splits `Low Reach --> High Reach` into its two ends.
  ///
  /// A single label without an arrow names the low end only, which is what
  /// mermaid does.
  (String, String?) _splitAxis(String text) {
    final arrow = text.indexOf('-->');
    if (arrow == -1) return (_unquote(text.trim()), null);
    return (
      _unquote(text.substring(0, arrow).trim()),
      _unquote(text.substring(arrow + 3).trim()),
    );
  }

  QuadrantPoint? _parsePoint(String line) {
    final match = _pointRe.firstMatch(line);
    if (match == null) return null;

    final x = double.tryParse(match.group(2)!);
    final y = double.tryParse(match.group(3)!);
    if (x == null || y == null) return null;

    final trailing = match.group(4) ?? '';
    final radius = _radiusRe.firstMatch(trailing);
    final color = _colorRe.firstMatch(trailing);

    return QuadrantPoint(
      label: _unquote(match.group(1)!.trim()),
      // Out-of-range coordinates would be drawn outside the chart box.
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      radius: radius == null ? null : double.tryParse(radius.group(1)!),
      color: color == null ? null : parseHexColor(color.group(1)!),
    );
  }

  static String _unquote(String text) {
    if (text.length >= 2 &&
        ((text.startsWith('"') && text.endsWith('"')) ||
            (text.startsWith("'") && text.endsWith("'")))) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  /// Turns `#rgb`, `#rrggbb` or `#aarrggbb` into an ARGB value.
  ///
  /// Returns null for anything else rather than guessing, so a typo shows the
  /// default colour instead of an arbitrary one.
  static int? parseHexColor(String hex) {
    var value = hex.startsWith('#') ? hex.substring(1) : hex;

    if (value.length == 3) {
      value = value.split('').map((c) => '$c$c').join();
    }
    if (value.length == 6) {
      value = 'ff$value';
    }
    if (value.length != 8) return null;

    return int.tryParse(value, radix: 16);
  }
}
