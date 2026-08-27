import '../models/class_diagram.dart';
import '../models/diagram.dart';
import '../models/er_diagram.dart';
import '../models/gantt.dart';
import '../models/kanban.dart';
import '../models/pie_chart.dart';
import '../models/radar.dart';
import '../models/timeline.dart';
import '../models/xy_chart.dart';
import 'class_diagram_parser.dart';
import 'er_diagram_parser.dart';
import 'flowchart_parser.dart';
import 'gantt_parser.dart';
import 'kanban_parser.dart';
import 'pie_chart_parser.dart';
import 'radar_parser.dart';
import 'sequence_parser.dart';
import 'state_diagram_parser.dart';
import 'timeline_parser.dart';
import 'xy_chart_parser.dart';

/// Result of parsing a Mermaid diagram
class MermaidParseResult {
  /// Creates a parse result
  const MermaidParseResult({
    required this.diagram,
    this.pieChartData,
    this.ganttChartData,
    this.timelineChartData,
    this.kanbanChartData,
    this.radarChartData,
    this.xyChartData,
    this.classDiagramData,
    this.erDiagramData,
  });

  /// The parsed diagram data
  final MermaidDiagramData diagram;

  /// Pie chart specific data (only set for pie charts)
  final PieChartData? pieChartData;

  /// Gantt chart specific data (only set for Gantt charts)
  final GanttChartData? ganttChartData;

  /// Timeline chart specific data (only set for timeline charts)
  final TimelineChartData? timelineChartData;

  /// Kanban chart specific data (only set for Kanban charts)
  final KanbanChartData? kanbanChartData;

  /// Radar chart specific data (only set for Radar charts)
  final RadarChartData? radarChartData;

  /// XY chart specific data (only set for XY charts)
  final XYChartData? xyChartData;

  /// Class diagram specific data (only set for class diagrams)
  final ClassDiagramData? classDiagramData;

  /// ER diagram specific data (only set for ER diagrams)
  final ErDiagramData? erDiagramData;
}

/// Main parser for Mermaid diagrams
///
/// This parser detects the diagram type and delegates to the
/// appropriate specialized parser.
class MermaidParser {
  /// Creates a new Mermaid parser
  const MermaidParser();

  /// Parses a Mermaid diagram string
  ///
  /// Returns null if the diagram cannot be parsed
  MermaidDiagramData? parse(String source) {
    final result = parseWithData(source);
    return result?.diagram;
  }

  /// Parses a Mermaid diagram string and returns additional data
  ///
  /// Returns a [MermaidParseResult] containing the diagram and any
  /// type-specific data (like [PieChartData] for pie charts)
  MermaidParseResult? parseWithData(String source) {
    if (source.trim().isEmpty) return null;

    final lines = source.split('\n');
    final cleanedLines = _cleanLines(lines);

    if (cleanedLines.isEmpty) return null;

    final firstLine = _firstContentLine(cleanedLines);

    // Detect diagram type
    final type = _detectDiagramType(firstLine);

    switch (type) {
      case DiagramType.flowchart:
        final diagram = FlowchartParser().parse(cleanedLines);
        if (diagram != null) {
          return MermaidParseResult(diagram: diagram);
        }
        return null;
      case DiagramType.sequence:
        final diagram = SequenceParser().parse(cleanedLines);
        if (diagram != null) {
          return MermaidParseResult(diagram: diagram);
        }
        return null;
      case DiagramType.pieChart:
        final result = const PieChartParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            pieChartData: result.$2,
          );
        }
        return null;
      case DiagramType.ganttChart:
        final result = const GanttParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            ganttChartData: result.$2,
          );
        }
        return null;
      case DiagramType.timeline:
        final result = const TimelineParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            timelineChartData: result.$2,
          );
        }
        return null;
      case DiagramType.kanban:
        final result = const KanbanParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            kanbanChartData: result.$2,
          );
        }
        return null;
      case DiagramType.radar:
        final result = const RadarParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            radarChartData: result.$2,
          );
        }
        return null;
      case DiagramType.xyChart:
        final result = const XYChartParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            xyChartData: result.$2,
          );
        }
        return null;
      case DiagramType.classDiagram:
        final result = ClassDiagramParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            classDiagramData: result.$2,
          );
        }
        return null;
      case DiagramType.erDiagram:
        final result = ErDiagramParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            erDiagramData: result.$2,
          );
        }
        return null;
      case DiagramType.stateDiagram:
        final result = StateDiagramParser().parse(cleanedLines);
        if (result != null) {
          return MermaidParseResult(diagram: result);
        }
        return null;
      case DiagramType.unknown:
        return null;
    }
  }

  /// The header line, skipping YAML frontmatter (used by Kanban and others).
  String _firstContentLine(List<String> cleanedLines) {
    var first = cleanedLines.first.trim().toLowerCase();
    if (first != '---') return first;

    for (var i = 1; i < cleanedLines.length; i++) {
      if (cleanedLines[i].trim() == '---') {
        if (i + 1 < cleanedLines.length) {
          first = cleanedLines[i + 1].trim().toLowerCase();
        }
        break;
      }
    }
    return first;
  }

  /// Diagram types this renderer knows how to draw, in the spelling a header
  /// line uses.
  static const supportedTypes = <String>[
    'graph / flowchart',
    'sequenceDiagram',
    'classDiagram',
    'stateDiagram',
    'erDiagram',
    'pie',
    'gantt',
    'timeline',
    'kanban',
    'radar-beta',
    'xychart',
  ];

  /// Explains why [source] could not be rendered.
  ///
  /// Distinguishing "type not supported yet" from "syntax error in a type we
  /// do support" matters: a bare "unable to parse" leaves the author with no
  /// idea which of the two they are looking at.
  String describeParseFailure(String source) {
    final cleaned = _cleanLines(source.split('\n'));
    if (cleaned.isEmpty) return 'The diagram is empty.';

    final firstLine = _firstContentLine(cleaned);
    final type = _detectDiagramType(firstLine);

    if (type == DiagramType.unknown) {
      return 'Unrecognised diagram type: "$firstLine".\n'
          'Supported: ${supportedTypes.join(', ')}.';
    }

    return 'Could not parse this ${_typeLabel(type)}. '
        'The header is recognised, so check the syntax below it.';
  }

  String _typeLabel(DiagramType type) {
    switch (type) {
      case DiagramType.flowchart:
        return 'flowchart';
      case DiagramType.sequence:
        return 'sequence diagram';
      case DiagramType.classDiagram:
        return 'class diagram';
      case DiagramType.stateDiagram:
        return 'state diagram';
      case DiagramType.erDiagram:
        return 'ER diagram';
      case DiagramType.pieChart:
        return 'pie chart';
      case DiagramType.ganttChart:
        return 'Gantt chart';
      case DiagramType.timeline:
        return 'timeline';
      case DiagramType.kanban:
        return 'Kanban board';
      case DiagramType.radar:
        return 'radar chart';
      case DiagramType.xyChart:
        return 'XY chart';
      case DiagramType.unknown:
        return 'diagram';
    }
  }

  /// Detects the diagram type from the first line
  DiagramType _detectDiagramType(String firstLine) {
    // Flowchart patterns.
    //
    // The keyword may be followed by a space, a semicolon (`graph TD;`), or
    // nothing at all, and mermaid also accepts the `-elk` renderer suffix, so
    // this cannot be a prefix test against 'graph '.
    if (RegExp(r'^(graph|flowchart)(-elk)?\b').hasMatch(firstLine)) {
      return DiagramType.flowchart;
    }

    // Sequence diagram
    if (firstLine.startsWith('sequencediagram')) {
      return DiagramType.sequence;
    }

    // Pie chart
    if (firstLine.startsWith('pie')) {
      return DiagramType.pieChart;
    }

    // Gantt chart
    if (firstLine.startsWith('gantt')) {
      return DiagramType.ganttChart;
    }

    // Timeline
    if (firstLine.startsWith('timeline')) {
      return DiagramType.timeline;
    }

    // Kanban
    if (firstLine.startsWith('kanban')) {
      return DiagramType.kanban;
    }

    // Radar chart
    if (firstLine.startsWith('radar-beta')) {
      return DiagramType.radar;
    }

    // XY chart
    if (firstLine.startsWith('xychart')) {
      return DiagramType.xyChart;
    }

    // Class diagram
    if (firstLine.startsWith('classdiagram')) {
      return DiagramType.classDiagram;
    }

    // Entity-relationship diagram
    if (firstLine.startsWith('erdiagram')) {
      return DiagramType.erDiagram;
    }

    // State diagram
    if (firstLine.startsWith('statediagram') ||
        firstLine.startsWith('statediagram-v2')) {
      return DiagramType.stateDiagram;
    }

    return DiagramType.unknown;
  }

  /// Cleans and filters input lines
  List<String> _cleanLines(List<String> lines) {
    final result = <String>[];

    for (final raw in lines) {
      final trimmed = raw.trim();

      // `%%{init: {...}}%%` is a directive, not a comment. Dropped for now
      // rather than truncated at its leading `%%`, which would be the same
      // outcome today but hides the distinction from whoever implements it.
      if (trimmed.startsWith('%%{') && trimmed.endsWith('}%%')) {
        continue;
      }

      final line = _stripComment(raw);
      if (line.trim().isNotEmpty) {
        result.add(line);
      }
    }

    return result;
  }

  /// Truncates [line] at a `%%` comment marker.
  ///
  /// A bare `indexOf('%%')` would also cut inside node labels — `A["50%% off"]`
  /// or `B(100%% done)` — so brackets and quotes are tracked and only a marker
  /// outside both counts.
  String _stripComment(String line) {
    var inQuote = false;
    var depth = 0;

    for (var i = 0; i < line.length - 1; i++) {
      final c = line[i];

      if (c == '"') {
        inQuote = !inQuote;
        continue;
      }
      if (inQuote) continue;

      if (c == '[' || c == '(' || c == '{') {
        depth++;
      } else if (c == ']' || c == ')' || c == '}') {
        if (depth > 0) depth--;
      } else if (c == '%' && line[i + 1] == '%' && depth == 0) {
        return line.substring(0, i);
      }
    }

    return line;
  }
}

/// Result of parsing a token
class ParseToken {
  /// Creates a parse token
  const ParseToken({
    required this.type,
    required this.value,
    this.start = 0,
    this.end = 0,
  });

  /// Type of token
  final TokenType type;

  /// Token value
  final String value;

  /// Start position in source
  final int start;

  /// End position in source
  final int end;
}

/// Token types for lexical analysis
enum TokenType {
  /// Node identifier
  nodeId,

  /// Node label
  nodeLabel,

  /// Arrow/edge
  arrow,

  /// Edge label
  edgeLabel,

  /// Keyword (graph, subgraph, etc)
  keyword,

  /// Style definition
  style,

  /// Class definition
  classDef,

  /// Subgraph start
  subgraphStart,

  /// Subgraph end
  subgraphEnd,

  /// End of input
  eof,
}
