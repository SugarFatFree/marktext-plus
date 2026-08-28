import '../models/diagram.dart';
import '../models/pie_chart.dart';
import 'label.dart';

/// Parser for Mermaid pie chart diagrams
///
/// Parses pie chart syntax like:
/// ```
/// pie
///     title My Pie Chart
///     "Dogs" : 386
///     "Cats" : 85
///     "Rats" : 15
/// ```
///
/// Or with showData:
/// ```
/// pie showData
///     title My Pie Chart
///     "Dogs" : 386
///     "Cats" : 85
/// ```
class PieChartParser {
  /// Creates a pie chart parser
  const PieChartParser();

  /// Parses pie chart diagram from cleaned lines
  ///
  /// Returns a tuple of (MermaidDiagramData, PieChartData) or null if parsing fails
  (MermaidDiagramData, PieChartData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    String? title;
    final slices = <PieSlice>[];
    var showValuesInLegend = false;

    // Parse the first line for options and for a title written on it.
    //
    // Mermaid's own documentation opens with `pie title Pets adopted by
    // volunteers`; only `showData` was read off this line, so that title —
    // the spelling most people copy — was silently dropped.
    var header = lines.first.trim();
    if (header.toLowerCase().startsWith('pie')) {
      header = header.substring(3).trimLeft();
    }
    if (header.toLowerCase().startsWith('showdata')) {
      showValuesInLegend = true;
      header = header.substring(8).trimLeft();
    }
    if (header.toLowerCase().startsWith('title ')) {
      final headerTitle = header.substring(6).trim();
      if (headerTitle.isNotEmpty) title = headerTitle;
    }

    // Parse remaining lines
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Parse title
      if (line.toLowerCase().startsWith('title ')) {
        title = cleanLabel(line.substring(6)).trim();
        continue;
      }

      // Parse slice: "Label" : value
      final slice = _parseSlice(line);
      if (slice != null) {
        slices.add(slice);
      }
    }

    if (slices.isEmpty) return null;

    final pieData = PieChartData(
      title: title,
      slices: slices,
      showValuesInLegend: showValuesInLegend,
    );

    // Create a minimal diagram data for compatibility
    final diagramData = MermaidDiagramData(
      type: DiagramType.pieChart,
      nodes: const [],
      edges: const [],
      title: title,
    );

    return (diagramData, pieData);
  }

  /// Parses a single slice line
  ///
  /// Format: "Label" : value
  /// or: "Label": value
  /// or: Label : value
  PieSlice? _parseSlice(String line) {
    // Try quoted label first: "Label" : value
    final quotedPattern = RegExp(r'"([^"]+)"\s*:\s*([\d.]+)');
    var match = quotedPattern.firstMatch(line);

    if (match != null) {
      final label = match.group(1)!;
      final value = double.tryParse(match.group(2)!);
      if (value != null && value > 0) {
        return PieSlice(label: cleanLabel(label), value: value);
      }
    }

    // Try single-quoted label: 'Label' : value
    final singleQuotedPattern = RegExp(r"'([^']+)'\s*:\s*([\d.]+)");
    match = singleQuotedPattern.firstMatch(line);

    if (match != null) {
      final label = match.group(1)!;
      final value = double.tryParse(match.group(2)!);
      if (value != null && value > 0) {
        return PieSlice(label: cleanLabel(label), value: value);
      }
    }

    // Try unquoted label: Label : value
    //
    // Anchored at the start: a slice is the whole line. Without the anchor the
    // engine tried every position on a line with no colon, handing `[^:]+`
    // back one character at a time from each — a 30,000-character line inside
    // a `pie` block took fourteen seconds.
    final unquotedPattern = RegExp(r'^([^:]+):\s*([\d.]+)');
    match = unquotedPattern.firstMatch(line);

    if (match != null) {
      final label = match.group(1)!.trim();
      final value = double.tryParse(match.group(2)!);
      if (value != null && value > 0 && label.isNotEmpty) {
        return PieSlice(label: cleanLabel(label), value: value);
      }
    }

    return null;
  }
}
