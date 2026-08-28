import '../models/block_diagram.dart';
import '../models/c4_diagram.dart';
import '../models/class_diagram.dart';
import '../models/diagram.dart';
import '../models/architecture.dart';
import '../models/packet.dart';
import '../models/er_diagram.dart';
import '../models/gantt.dart';
import '../models/git_graph.dart';
import '../models/journey.dart';
import '../models/kanban.dart';
import '../models/mindmap.dart';
import '../models/pie_chart.dart';
import '../models/quadrant_chart.dart';
import '../models/requirement_diagram.dart';
import '../models/sankey.dart';
import '../models/sequence.dart';
import '../models/radar.dart';
import '../models/timeline.dart';
import '../models/xy_chart.dart';
import 'block_parser.dart';
import 'c4_parser.dart';
import 'class_diagram_parser.dart';
import 'er_diagram_parser.dart';
import 'flowchart_parser.dart';
import 'gantt_parser.dart';
import 'git_graph_parser.dart';
import 'journey_parser.dart';
import 'kanban_parser.dart';
import 'mindmap_parser.dart';
import 'pie_chart_parser.dart';
import 'quadrant_parser.dart';
import 'requirement_parser.dart';
import 'sankey_parser.dart';
import 'architecture_parser.dart';
import 'packet_parser.dart';
import 'radar_parser.dart';
import 'sequence_parser.dart';
import 'state_diagram_parser.dart';
import 'timeline_parser.dart';
import 'xy_chart_parser.dart';
import 'label.dart';

/// Result of parsing a Mermaid diagram
/// Why a diagram could not be parsed. See [MermaidParser.describeFailure].
enum MermaidFailureKind {
  /// Nothing but blank lines and comments.
  empty,

  /// The first line names no diagram type this package implements.
  unknownType,

  /// The header is understood and there is nothing after it.
  headerOnly,

  /// The header is understood but nothing below it could be read.
  unparsedBody,
}

/// A parse failure and the one piece of text worth quoting back.
///
/// [detail] is the offending first line for [MermaidFailureKind.unknownType],
/// and the diagram's own name — "flowchart", "sequence diagram" — otherwise.
/// Both are left untranslated on purpose: one is the reader's own text and the
/// other is Mermaid's vocabulary.
class MermaidFailure {
  const MermaidFailure(this.kind, this.detail);

  final MermaidFailureKind kind;
  final String detail;
}

class MermaidParseResult {
  /// Creates a parse result
  const MermaidParseResult({
    required this.diagram,
    this.pieChartData,
    this.ganttChartData,
    this.timelineChartData,
    this.kanbanChartData,
    this.quadrantChartData,
    this.requirementDiagramData,
    this.sankeyChartData,
    this.blockDiagramData,
    this.c4DiagramData,
    this.architectureData,
    this.packetData,
    this.radarChartData,
    this.xyChartData,
    this.classDiagramData,
    this.erDiagramData,
    this.journeyData,
    this.gitGraphData,
    this.mindmapData,
    this.sequenceData,
  });

  /// The parsed diagram data
  final MermaidDiagramData diagram;

  /// Whether anything at all came out of the parse.
  ///
  /// A diagram whose header is understood but whose body is not — one mistyped
  /// arrow is enough — used to reach the painter with nothing in it and draw a
  /// blank box. A blank box is indistinguishable from a broken renderer, which
  /// is how "mermaid 渲染有问题" gets reported. Upstream MarkText rejects the
  /// same input outright and shows an error node in its place.
  ///
  /// Types that keep their content in a payload rather than in nodes and edges
  /// — a pie chart has neither — count as long as the payload is there.
  bool get hasContent =>
      diagram.nodes.isNotEmpty ||
      diagram.edges.isNotEmpty ||
      pieChartData != null ||
      ganttChartData != null ||
      timelineChartData != null ||
      kanbanChartData != null ||
      quadrantChartData != null ||
      requirementDiagramData != null ||
      sankeyChartData != null ||
      blockDiagramData != null ||
      c4DiagramData != null ||
      architectureData != null ||
      packetData != null ||
      radarChartData != null ||
      xyChartData != null ||
      classDiagramData != null ||
      erDiagramData != null ||
      journeyData != null ||
      gitGraphData != null ||
      mindmapData != null ||
      sequenceData != null;


  /// Pie chart specific data (only set for pie charts)
  final PieChartData? pieChartData;

  /// Gantt chart specific data (only set for Gantt charts)
  final GanttChartData? ganttChartData;

  /// Timeline chart specific data (only set for timeline charts)
  final TimelineChartData? timelineChartData;

  /// Kanban chart specific data (only set for Kanban charts)
  final KanbanChartData? kanbanChartData;

  /// Quadrant chart specific data (only set for quadrant charts)
  final QuadrantChartData? quadrantChartData;

  /// Requirement diagram specific data (only set for requirement diagrams)
  final RequirementDiagramData? requirementDiagramData;

  /// Sankey specific data (only set for Sankey diagrams)
  final SankeyChartData? sankeyChartData;

  /// Block diagram specific data (only set for block diagrams)
  final BlockDiagramData? blockDiagramData;

  /// C4 specific data (only set for C4 diagrams)
  final C4DiagramData? c4DiagramData;

  /// Architecture diagram specific data (only set for architecture diagrams)
  final ArchitectureDiagramData? architectureData;

  /// Packet diagram specific data (only set for packet diagrams)
  final PacketDiagramData? packetData;

  /// Radar chart specific data (only set for Radar charts)
  final RadarChartData? radarChartData;

  /// XY chart specific data (only set for XY charts)
  final XYChartData? xyChartData;

  /// Class diagram specific data (only set for class diagrams)
  final ClassDiagramData? classDiagramData;

  /// ER diagram specific data (only set for ER diagrams)
  final ErDiagramData? erDiagramData;

  /// Journey specific data (only set for user journey diagrams)
  final JourneyData? journeyData;

  /// Git graph specific data (only set for git graphs)
  final GitGraphData? gitGraphData;

  /// Mindmap specific data (only set for mindmaps)
  final MindmapData? mindmapData;

  /// Sequence specific data (only set for sequence diagrams)
  final SequenceDiagramData? sequenceData;
  /// Whether the diagram's own syntax already gave it a title.
  ///
  /// Checked before a frontmatter title is applied: a chart that draws the
  /// title it parsed would otherwise show two, one from its painter and one
  /// from the widget.
  bool get hasOwnTitle =>
      diagram.title != null ||
      pieChartData?.title != null ||
      ganttChartData?.title != null ||
      timelineChartData?.title != null ||
      kanbanChartData?.title != null ||
      quadrantChartData?.title != null ||
      sankeyChartData?.title != null ||
      c4DiagramData?.title != null ||
      architectureData?.title != null ||
      packetData?.title != null ||
      radarChartData?.title != null ||
      xyChartData?.title != null ||
      journeyData?.title != null ||
      gitGraphData?.title != null;

  /// The same result, carrying a diagram title it did not have.
  ///
  /// Only the diagram changes; every payload is passed through untouched, so
  /// a type that draws its own title keeps the one it parsed.
  MermaidParseResult withDiagramTitle(String title) => MermaidParseResult(
        diagram: diagram.copyWith(title: title),
        pieChartData: pieChartData,
        ganttChartData: ganttChartData,
        timelineChartData: timelineChartData,
        kanbanChartData: kanbanChartData,
        quadrantChartData: quadrantChartData,
        requirementDiagramData: requirementDiagramData,
        sankeyChartData: sankeyChartData,
        blockDiagramData: blockDiagramData,
        c4DiagramData: c4DiagramData,
        architectureData: architectureData,
        packetData: packetData,
        radarChartData: radarChartData,
        xyChartData: xyChartData,
        classDiagramData: classDiagramData,
        erDiagramData: erDiagramData,
        journeyData: journeyData,
        gitGraphData: gitGraphData,
        mindmapData: mindmapData,
        sequenceData: sequenceData,
      );

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
  /// type-specific data (like [PieChartData] for pie charts), or null when
  /// nothing usable came out of it — see [MermaidParseResult.hasContent].
  /// Every caller already treats null as "show the reader why", so an empty
  /// result reaching the painter and drawing a blank box was the one failure
  /// that said nothing.
  MermaidParseResult? parseWithData(String source) {
    final result = _parseWithData(source);
    if (result == null || !result.hasContent) return null;

    // A frontmatter title applies to whatever came out, and only when the
    // diagram's own syntax did not already give one.
    final title = _frontMatterTitle(source.split('\n'));
    if (title == null || result.hasOwnTitle) return result;
    return result.withDiagramTitle(title);
  }

  MermaidParseResult? _parseWithData(String source) {
    if (source.trim().isEmpty) return null;

    final lines = source.split('\n');
    final cleanedLines = _cleanLines(lines);

    if (cleanedLines.isEmpty) return null;

    final firstLine = _firstContentLine(cleanedLines);
    // The frontmatter block is read here and does not go any further: handed
    // on, it made every type parser step over YAML it has no grammar for, and
    // `pie title X` on the header line stopped being found at all because the
    // first line was `---` rather than the header.
    final body = _withoutFrontMatter(cleanedLines);

    // Detect diagram type
    final type = _detectDiagramType(firstLine);

    switch (type) {
      case DiagramType.flowchart:
        final diagram = FlowchartParser().parse(body);
        if (diagram != null) {
          return MermaidParseResult(diagram: diagram);
        }
        return null;
      case DiagramType.sequence:
        final result = SequenceParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            sequenceData: result.$2,
          );
        }
        return null;
      case DiagramType.pieChart:
        final result = const PieChartParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            pieChartData: result.$2,
          );
        }
        return null;
      case DiagramType.ganttChart:
        final result = const GanttParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            ganttChartData: result.$2,
          );
        }
        return null;
      case DiagramType.timeline:
        final result = const TimelineParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            timelineChartData: result.$2,
          );
        }
        return null;
      case DiagramType.kanban:
        final result = const KanbanParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            kanbanChartData: result.$2,
          );
        }
        return null;
      case DiagramType.requirementDiagram:
        final result = const RequirementParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            requirementDiagramData: result.$2,
          );
        }
        return null;
      case DiagramType.quadrantChart:
        final result = const QuadrantParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            quadrantChartData: result.$2,
          );
        }
        return null;
      case DiagramType.sankey:
        final result = const SankeyParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            sankeyChartData: result.$2,
          );
        }
        return null;
      case DiagramType.blockDiagram:
        final result = const BlockParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            blockDiagramData: result.$2,
          );
        }
        return null;
      case DiagramType.c4Diagram:
        final result = const C4Parser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            c4DiagramData: result.$2,
          );
        }
        return null;
      case DiagramType.architecture:
        final result = const ArchitectureParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            architectureData: result.$2,
          );
        }
        return null;
      case DiagramType.packet:
        final result = const PacketParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            packetData: result.$2,
          );
        }
        return null;
      case DiagramType.radar:
        final result = const RadarParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            radarChartData: result.$2,
          );
        }
        return null;
      case DiagramType.xyChart:
        final result = const XYChartParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            xyChartData: result.$2,
          );
        }
        return null;
      case DiagramType.classDiagram:
        final result = ClassDiagramParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            classDiagramData: result.$2,
          );
        }
        return null;
      case DiagramType.mindmap:
        // Mindmaps are structured by indentation, so this parser gets the
        // lines with their leading whitespace intact.
        final result = const MindmapParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            mindmapData: result.$2,
          );
        }
        return null;
      case DiagramType.gitGraph:
        final result = const GitGraphParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            gitGraphData: result.$2,
          );
        }
        return null;
      case DiagramType.journey:
        final result = const JourneyParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            journeyData: result.$2,
          );
        }
        return null;
      case DiagramType.erDiagram:
        final result = ErDiagramParser().parse(body);
        if (result != null) {
          return MermaidParseResult(
            diagram: result.$1,
            erDiagramData: result.$2,
          );
        }
        return null;
      case DiagramType.stateDiagram:
        final result = StateDiagramParser().parse(body);
        if (result != null) {
          return MermaidParseResult(diagram: result);
        }
        return null;
      case DiagramType.unknown:
        return null;
    }
  }

  /// The lines after a YAML frontmatter block, or all of them if there is none.
  List<String> _withoutFrontMatter(List<String> cleanedLines) {
    if (cleanedLines.isEmpty || cleanedLines.first.trim() != '---') {
      return cleanedLines;
    }
    for (var i = 1; i < cleanedLines.length; i++) {
      if (cleanedLines[i].trim() == '---') {
        return cleanedLines.sublist(i + 1);
      }
    }
    // An unterminated block is not frontmatter; leave the lines alone.
    return cleanedLines;
  }

  /// The `title:` a YAML frontmatter block gives the diagram.
  ///
  /// Mermaid's documented way to title any diagram, including the ones whose
  /// own syntax has no `title` line — a flowchart is titled this way and no
  /// other. The block was being skipped to find the header line and never
  /// read, so the title silently disappeared for every diagram type.
  String? _frontMatterTitle(List<String> cleanedLines) {
    if (cleanedLines.isEmpty || cleanedLines.first.trim() != '---') return null;

    for (var i = 1; i < cleanedLines.length; i++) {
      final line = cleanedLines[i].trim();
      if (line == '---') return null;
      if (!line.startsWith('title:')) continue;

      var value = line.substring('title:'.length).trim();
      // YAML lets the value be quoted; the quotes are not part of it.
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }
      return value.isEmpty ? null : cleanLabel(value);
    }
    return null;
  }

  /// The header line, skipping YAML frontmatter (used by Kanban and others).
  String _firstContentLine(List<String> cleanedLines) {
    // Reads whatever _withoutFrontMatter hands the type parsers, so the two
    // cannot disagree about where the diagram starts. They did: a block that
    // never closed was frontmatter to one and ordinary text to the other, and
    // the header line came back as `---`, so the whole diagram was dropped.
    final body = _withoutFrontMatter(cleanedLines);
    return body.isEmpty ? '' : body.first.trim().toLowerCase();
  }

  /// Diagram types this renderer knows how to draw, in the spelling a header
  /// line uses.
  static const supportedTypes = <String>[
    'graph / flowchart',
    'sequenceDiagram',
    'classDiagram',
    'stateDiagram',
    'erDiagram',
    'journey',
    'gitGraph',
    'mindmap',
    'pie',
    'gantt',
    'timeline',
    'kanban',
    'radar-beta',
    'xychart',
    'quadrantChart',
    'requirementDiagram',
    'sankey-beta',
    'block-beta',
    'C4Context / C4Container / C4Component / C4Dynamic / C4Deployment',
  ];

  /// Whether a fenced code block tagged [language] should be handed to the
  /// diagram renderer.
  ///
  /// Derived from [supportedTypes] rather than kept as a second hard-coded
  /// list, so implementing a type cannot leave the two disagreeing. The
  /// canonical tag is ```mermaid, with the bare type names accepted as a
  /// convenience.
  static bool handlesLanguage(String language) {
    final lang = language.trim().toLowerCase();
    if (lang.isEmpty) return false;
    if (lang == 'mermaid') return true;

    for (final supported in supportedTypes) {
      for (final name in supported.split(' / ')) {
        if (lang == name.trim().toLowerCase()) return true;
      }
    }
    return false;
  }

  /// Explains why [source] could not be rendered.
  ///
  /// Distinguishing "type not supported yet" from "syntax error in a type we
  /// do support" matters: a bare "unable to parse" leaves the author with no
  /// idea which of the two they are looking at.
  String describeParseFailure(String source) {
    final failure = describeFailure(source);
    switch (failure.kind) {
      case MermaidFailureKind.empty:
        return 'The diagram is empty.';
      case MermaidFailureKind.unknownType:
        return 'Unrecognised diagram type: "${failure.detail}".\n'
            'Supported: ${supportedTypes.join(', ')}.';
      case MermaidFailureKind.headerOnly:
        return 'This ${failure.detail} has a header but no content.';
      case MermaidFailureKind.unparsedBody:
        return 'Could not parse this ${failure.detail}. '
            'The header is recognised, so check the syntax below it.';
    }
  }

  /// Why [source] could not be turned into a diagram, without wording it.
  ///
  /// The wording belongs to whoever is showing it: this package deliberately
  /// depends on nothing but Flutter, so it cannot reach the app's translations,
  /// and [describeParseFailure] can only ever answer in English. That left a
  /// reader working in any of the other eleven languages with an English
  /// sentence in the middle of their document.
  MermaidFailure describeFailure(String source) {
    final cleaned = _cleanLines(source.split('\n'));
    if (cleaned.isEmpty) {
      return const MermaidFailure(MermaidFailureKind.empty, '');
    }

    final firstLine = _firstContentLine(cleaned);
    final type = _detectDiagramType(firstLine);

    if (type == DiagramType.unknown) {
      return MermaidFailure(MermaidFailureKind.unknownType, firstLine);
    }

    if (cleaned.length <= 1) {
      return MermaidFailure(MermaidFailureKind.headerOnly, _typeLabel(type));
    }

    return MermaidFailure(MermaidFailureKind.unparsedBody, _typeLabel(type));
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
      case DiagramType.journey:
        return 'user journey';
      case DiagramType.gitGraph:
        return 'git graph';
      case DiagramType.mindmap:
        return 'mindmap';
      case DiagramType.pieChart:
        return 'pie chart';
      case DiagramType.ganttChart:
        return 'Gantt chart';
      case DiagramType.timeline:
        return 'timeline';
      case DiagramType.kanban:
        return 'Kanban board';
      case DiagramType.quadrantChart:
        return 'quadrant chart';
      case DiagramType.requirementDiagram:
        return 'requirement diagram';
      case DiagramType.sankey:
        return 'Sankey diagram';
      case DiagramType.blockDiagram:
        return 'block diagram';
      case DiagramType.c4Diagram:
        return 'C4 diagram';
      case DiagramType.architecture:
        return 'architecture diagram';
      case DiagramType.packet:
        return 'packet diagram';
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

    // Packet diagram. `packet` on its own is accepted alongside the beta
    // spelling: mermaid dropped the suffix, and documents written either way
    // are in the wild.
    if (RegExp(r'^packet(-beta)?\b').hasMatch(firstLine)) {
      return DiagramType.packet;
    }

    // Architecture diagram
    if (RegExp(r'^architecture(-beta)?\b').hasMatch(firstLine)) {
      return DiagramType.architecture;
    }

    // XY chart
    if (firstLine.startsWith('xychart')) {
      return DiagramType.xyChart;
    }

    // Quadrant chart
    if (firstLine.startsWith('quadrantchart')) {
      return DiagramType.quadrantChart;
    }

    // Requirement diagram
    if (firstLine.startsWith('requirementdiagram')) {
      return DiagramType.requirementDiagram;
    }

    // Sankey
    if (firstLine.startsWith('sankey')) {
      return DiagramType.sankey;
    }

    // Block diagram
    if (firstLine.startsWith('block-beta') || firstLine.startsWith('block ')) {
      return DiagramType.blockDiagram;
    }

    // C4 model
    if (firstLine.startsWith('c4context') ||
        firstLine.startsWith('c4container') ||
        firstLine.startsWith('c4component') ||
        firstLine.startsWith('c4dynamic') ||
        firstLine.startsWith('c4deployment')) {
      return DiagramType.c4Diagram;
    }

    // Class diagram
    if (firstLine.startsWith('classdiagram')) {
      return DiagramType.classDiagram;
    }

    // Entity-relationship diagram
    if (firstLine.startsWith('erdiagram')) {
      return DiagramType.erDiagram;
    }

    // User journey
    if (firstLine.startsWith('journey')) {
      return DiagramType.journey;
    }

    // Git graph
    if (firstLine.startsWith('gitgraph')) {
      return DiagramType.gitGraph;
    }

    // Mindmap
    if (firstLine.startsWith('mindmap')) {
      return DiagramType.mindmap;
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
