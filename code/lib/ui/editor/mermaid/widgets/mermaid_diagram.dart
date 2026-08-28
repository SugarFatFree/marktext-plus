import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/class_diagram_layout.dart';
import '../layout/requirement_diagram_layout.dart';
import '../layout/er_diagram_layout.dart';
import '../layout/mindmap_layout.dart';
import '../layout/dagre_layout.dart';
import '../layout/layout_engine.dart';
import '../layout/sequence_layout.dart';
import '../models/class_diagram.dart';
import '../models/er_diagram.dart';
import '../models/diagram.dart';
import '../models/gantt.dart';
import '../models/git_graph.dart';
import '../models/journey.dart';
import '../models/kanban.dart';
import '../models/mindmap.dart';
import '../models/pie_chart.dart';
import '../models/quadrant_chart.dart';
import '../models/requirement_diagram.dart';
import '../models/block_diagram.dart';
import '../models/c4_diagram.dart';
import '../models/sankey.dart';
import '../models/sequence.dart';
import '../layout/architecture_layout.dart';
import '../models/architecture.dart';
import '../models/packet.dart';
import '../models/radar.dart';
import '../models/timeline.dart';
import '../models/style.dart';
import '../models/xy_chart.dart';
import '../painter/class_diagram_painter.dart';
import '../painter/er_diagram_painter.dart';
import '../painter/flowchart_painter.dart';
import '../painter/gantt_painter.dart';
import '../painter/git_graph_painter.dart';
import '../painter/journey_painter.dart';
import '../painter/kanban_painter.dart';
import '../painter/mindmap_painter.dart';
import '../painter/pie_chart_painter.dart';
import '../painter/quadrant_painter.dart';
import '../painter/requirement_painter.dart';
import '../painter/block_painter.dart';
import '../painter/c4_painter.dart';
import '../painter/sankey_painter.dart';
import '../painter/architecture_painter.dart';
import '../painter/packet_painter.dart';
import '../painter/radar_painter.dart';
import '../painter/sequence_painter.dart';
import '../painter/timeline_painter.dart';
import '../painter/xy_chart_painter.dart';
import '../parser/mermaid_parser.dart';

/// A widget that renders Mermaid diagrams using pure Dart/Flutter
///
/// This widget parses Mermaid diagram syntax and renders it using
/// Flutter's CustomPainter, without any WebView or external dependencies.
///
/// Example usage:
/// ```dart
/// MermaidDiagram(
///   code: '''
///   graph TD
///     A[Start] --> B{Decision}
///     B -->|Yes| C[OK]
///     B -->|No| D[Cancel]
///   ''',
///   style: MermaidStyle.dark(),
/// )
/// ```
class MermaidDiagram extends StatefulWidget {
  /// Creates a Mermaid diagram widget
  const MermaidDiagram({
    super.key,
    required this.code,
    this.style,
    this.width,
    this.height,
    this.onNodeTap,
    this.onError,
    this.errorBuilder,
    this.loadingBuilder,
    this.responsiveConfig,
    this.enableResponsive = true,
  });

  /// The Mermaid diagram code
  final String code;

  /// Style configuration (defaults to light theme)
  final MermaidStyle? style;

  /// Fixed width (if not provided, uses available space)
  final double? width;

  /// Fixed height (if not provided, uses computed size)
  final double? height;

  /// Callback when a node is tapped
  final void Function(String nodeId)? onNodeTap;

  /// Callback when parsing fails
  final void Function(String error)? onError;

  /// Builder for error state
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Builder for loading state
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Responsive configuration for different screen sizes
  final MermaidResponsiveConfig? responsiveConfig;

  /// Whether to enable responsive layout (defaults to true)
  final bool enableResponsive;

  @override
  State<MermaidDiagram> createState() => _MermaidDiagramState();
}

class _MermaidDiagramState extends State<MermaidDiagram> {
  MermaidDiagramData? _diagram;
  PieChartData? _pieChartData;
  GanttChartData? _ganttChartData;
  TimelineChartData? _timelineChartData;
  KanbanChartData? _kanbanChartData;
  QuadrantChartData? _quadrantChartData;
  SankeyChartData? _sankeyChartData;
  BlockDiagramData? _blockDiagramData;
  C4DiagramData? _c4DiagramData;
  SequenceDiagramData? _sequenceData;
  RequirementDiagramData? _requirementDiagramData;
  ArchitectureDiagramData? _architectureData;
  ArchitectureLayoutResult? _architectureLayout;
  PacketDiagramData? _packetData;
  RadarChartData? _radarChartData;
  XYChartData? _xyChartData;
  ClassDiagramData? _classDiagramData;
  ErDiagramData? _erDiagramData;
  JourneyData? _journeyData;
  GitGraphData? _gitGraphData;
  MindmapData? _mindmapData;
  Size _computedSize = Size.zero;
  String? _error;
  bool _isLoading = true;
  MermaidDeviceConfig? _deviceConfig;
  double? _lastWidth;

  late MermaidStyle _style;

  @override
  void initState() {
    super.initState();
    _style = widget.style ?? const MermaidStyle();
  }

  @override
  void didUpdateWidget(MermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code || oldWidget.style != widget.style) {
      _style = widget.style ?? const MermaidStyle();
      _lastWidth = null; // Force re-layout
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initial parse will happen in build when we have context
  }

  void _parseDiagram(double availableWidth) {
    // Get responsive config
    if (widget.enableResponsive) {
      final responsiveConfig =
          widget.responsiveConfig ?? const MermaidResponsiveConfig();
      _deviceConfig = responsiveConfig.getConfigForWidth(availableWidth);

      // Apply responsive settings to style
      _style = _applyResponsiveStyle(_style, _deviceConfig!);
    }

    try {
      final parser = const MermaidParser();
      final result = parser.parseWithData(widget.code);

      if (result == null) {
        throw Exception(parser.describeParseFailure(widget.code));
      }

      final diagram = result.diagram;
      Size size;

      // Compute layout based on diagram type
      if (diagram.type == DiagramType.pieChart && result.pieChartData != null) {
        // Use pie chart layout with responsive config
        final pieLayout = PieChartLayout(deviceConfig: _deviceConfig);
        size = pieLayout.computeLayout(
          result.pieChartData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.ganttChart &&
          result.ganttChartData != null) {
        // Use Gantt chart layout with responsive config
        final ganttLayout = GanttChartLayout(deviceConfig: _deviceConfig);
        size = ganttLayout.computeLayout(
          result.ganttChartData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.timeline &&
          result.timelineChartData != null) {
        // Use Timeline chart layout with responsive config
        final timelineLayout = TimelineChartLayout(deviceConfig: _deviceConfig);
        size = timelineLayout.computeLayout(
          result.timelineChartData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.kanban &&
          result.kanbanChartData != null) {
        // Use Kanban chart layout with responsive config
        final kanbanLayout = KanbanChartLayout(deviceConfig: _deviceConfig);
        size = kanbanLayout.computeLayout(
          result.kanbanChartData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.quadrantChart &&
          result.quadrantChartData != null) {
        final quadrantLayout = QuadrantChartLayout(deviceConfig: _deviceConfig);
        size = quadrantLayout.computeLayout(
          result.quadrantChartData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.sequence &&
          result.sequenceData != null) {
        final sequenceLayout = SequenceLayout(
          deviceConfig: _deviceConfig,
          rowCount: result.sequenceData!.steps.length,
        );
        size = sequenceLayout.computeLayout(
          diagram,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.c4Diagram &&
          result.c4DiagramData != null) {
        final c4Layout = C4DiagramLayout(deviceConfig: _deviceConfig);
        size = c4Layout.computeLayout(
          result.c4DiagramData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.blockDiagram &&
          result.blockDiagramData != null) {
        final blockLayout = BlockDiagramLayout(deviceConfig: _deviceConfig);
        size = blockLayout.computeLayout(
          result.blockDiagramData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.sankey &&
          result.sankeyChartData != null) {
        final sankeyLayout = SankeyChartLayout(deviceConfig: _deviceConfig);
        size = sankeyLayout.computeLayout(
          result.sankeyChartData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.architecture &&
          result.architectureData != null) {
        // The layout is kept, not recomputed in the painter: it is the same
        // work either way, and a painter that lays out on every frame repeats
        // it for every repaint.
        final archLayout =
            const ArchitectureLayout().layout(result.architectureData!);
        _architectureLayout = archLayout;
        size = archLayout.size;
      } else if (diagram.type == DiagramType.packet &&
          result.packetData != null) {
        // A packet's height follows straight from how many rows of bits it
        // needs, and its width is whatever it is given: no layout to run.
        final packet = result.packetData!;
        size = Size(
          widget.width ?? availableWidth,
          _style.padding * 2 +
              (packet.title != null ? PacketPainter.titleHeight : 0) +
              packet.rowCount *
                  (PacketPainter.rowHeight + PacketPainter.rulerHeight),
        );
      } else if (diagram.type == DiagramType.radar &&
          result.radarChartData != null) {
        // Use Radar chart layout with responsive config
        final radarLayout = RadarChartLayout(deviceConfig: _deviceConfig);
        size = radarLayout.computeLayout(
          result.radarChartData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.xyChart &&
          result.xyChartData != null) {
        // Use XY chart layout with responsive config
        final xyLayout = XYChartLayout(deviceConfig: _deviceConfig);
        size = xyLayout.computeLayout(
          result.xyChartData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.mindmap &&
          result.mindmapData != null) {
        final mindmapLayout = MindmapLayout(deviceConfig: _deviceConfig);
        size = mindmapLayout.computeLayout(
          result.mindmapData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.gitGraph &&
          result.gitGraphData != null) {
        final gitLayout = GitGraphLayout(deviceConfig: _deviceConfig);
        size = gitLayout.computeLayout(
          result.gitGraphData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.journey &&
          result.journeyData != null) {
        final journeyLayout = JourneyChartLayout(deviceConfig: _deviceConfig);
        size = journeyLayout.computeLayout(
          result.journeyData!,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.erDiagram &&
          result.erDiagramData != null) {
        // Entity boxes carry a table of attributes, which the generic
        // single-label node measurement cannot describe.
        final erLayout = ErDiagramLayout(
          erData: result.erDiagramData!,
          deviceConfig: _deviceConfig,
        );
        size = erLayout.computeLayout(
          diagram,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.requirementDiagram &&
          result.requirementDiagramData != null) {
        // A requirement box is a header over a table of fields, so it needs
        // measuring the same way a class box does.
        final requirementLayout = RequirementDiagramLayout(
          requirementData: result.requirementDiagramData!,
          deviceConfig: _deviceConfig,
        );
        size = requirementLayout.computeLayout(
          diagram,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else if (diagram.type == DiagramType.classDiagram &&
          result.classDiagramData != null) {
        // Class boxes are three compartments tall, which the generic
        // single-label node measurement cannot describe.
        final classLayout = ClassDiagramLayout(
          classData: result.classDiagramData!,
          deviceConfig: _deviceConfig,
        );
        size = classLayout.computeLayout(
          diagram,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      } else {
        final layoutEngine = _getLayoutEngine(diagram.type);
        size = layoutEngine.computeLayout(
          diagram,
          _style,
          Size(widget.width ?? availableWidth, widget.height ?? 600),
        );
      }

      _diagram = diagram;
      _pieChartData = result.pieChartData;
      _ganttChartData = result.ganttChartData;
      _timelineChartData = result.timelineChartData;
      _kanbanChartData = result.kanbanChartData;
      _requirementDiagramData = result.requirementDiagramData;
      _quadrantChartData = result.quadrantChartData;
      _sankeyChartData = result.sankeyChartData;
      _blockDiagramData = result.blockDiagramData;
      _c4DiagramData = result.c4DiagramData;
      _sequenceData = result.sequenceData;
      _packetData = result.packetData;
      _architectureData = result.architectureData;
      _radarChartData = result.radarChartData;
      _xyChartData = result.xyChartData;
      _classDiagramData = result.classDiagramData;
      _erDiagramData = result.erDiagramData;
      _journeyData = result.journeyData;
      _gitGraphData = result.gitGraphData;
      _mindmapData = result.mindmapData;
      _computedSize = size;
      _error = null;
      _isLoading = false;
    } catch (e) {
      final errorMsg = _readableError(e);
      _error = errorMsg;
      _isLoading = false;
      widget.onError?.call(errorMsg);
    }
  }

  MermaidStyle _applyResponsiveStyle(
    MermaidStyle style,
    MermaidDeviceConfig config,
  ) {
    return style.copyWith(
      padding: config.padding,
      nodeSpacingX: config.nodeSpacingX,
      nodeSpacingY: config.nodeSpacingY,
      defaultNodeStyle: style.defaultNodeStyle.copyWith(
        fontSize: config.fontSize,
      ),
    );
  }

  LayoutEngine _getLayoutEngine(DiagramType type) {
    switch (type) {
      case DiagramType.flowchart:
        return DagreLayout(deviceConfig: _deviceConfig);
      case DiagramType.sequence:
        return SequenceLayout(deviceConfig: _deviceConfig);
      default:
        return const SimpleLayoutEngine();
    }
  }

  CustomPainter _getPainter(MermaidDiagramData diagram) {
    switch (diagram.type) {
      case DiagramType.flowchart:
        return FlowchartPainter(
          diagram: diagram,
          style: _style,
          deviceConfig: _deviceConfig,
        );
      case DiagramType.sequence:
        return SequencePainter(
          diagram: diagram,
          style: _style,
          deviceConfig: _deviceConfig,
          sequenceData: _sequenceData,
        );
      case DiagramType.pieChart:
        if (_pieChartData != null) {
          return PieChartPainter(
            pieData: _pieChartData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.ganttChart:
        if (_ganttChartData != null) {
          return GanttPainter(
            ganttData: _ganttChartData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.timeline:
        if (_timelineChartData != null) {
          return TimelinePainter(
            timelineData: _timelineChartData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.kanban:
        if (_kanbanChartData != null) {
          return KanbanPainter(
            kanbanData: _kanbanChartData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.requirementDiagram:
        if (_requirementDiagramData != null) {
          return RequirementPainter(
            diagram: diagram,
            style: _style,
            requirementData: _requirementDiagramData!,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.quadrantChart:
        if (_quadrantChartData != null) {
          return QuadrantPainter(
            quadrantData: _quadrantChartData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.c4Diagram:
        if (_c4DiagramData != null) {
          return C4Painter(
            c4Data: _c4DiagramData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.blockDiagram:
        if (_blockDiagramData != null) {
          return BlockPainter(
            blockData: _blockDiagramData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.sankey:
        if (_sankeyChartData != null) {
          return SankeyPainter(
            sankeyData: _sankeyChartData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.architecture:
        if (_architectureData != null && _architectureLayout != null) {
          return ArchitecturePainter(
            architectureData: _architectureData!,
            layout: _architectureLayout!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.packet:
        if (_packetData != null) {
          return PacketPainter(
            packetData: _packetData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.radar:
        if (_radarChartData != null) {
          return RadarPainter(
            radarData: _radarChartData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.xyChart:
        if (_xyChartData != null) {
          return XYChartPainter(
            xyData: _xyChartData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.mindmap:
        if (_mindmapData != null) {
          return MindmapPainter(
            mindmapData: _mindmapData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.gitGraph:
        if (_gitGraphData != null) {
          return GitGraphPainter(
            gitData: _gitGraphData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.journey:
        if (_journeyData != null) {
          return JourneyPainter(
            journeyData: _journeyData!,
            style: _style,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.erDiagram:
        if (_erDiagramData != null) {
          return ErDiagramPainter(
            diagram: diagram,
            style: _style,
            erData: _erDiagramData!,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      case DiagramType.classDiagram:
        if (_classDiagramData != null) {
          return ClassDiagramPainter(
            diagram: diagram,
            style: _style,
            classData: _classDiagramData!,
            deviceConfig: _deviceConfig,
          );
        }
        return FlowchartPainter(diagram: diagram, style: _style);
      default:
        return FlowchartPainter(diagram: diagram, style: _style);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        // Re-parse if width changed significantly or first time
        if (_lastWidth == null ||
            (availableWidth - _lastWidth!).abs() > 50 ||
            _isLoading) {
          _lastWidth = availableWidth;
          _parseDiagram(availableWidth);
        }

        if (_isLoading) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return widget.errorBuilder?.call(context, _error!) ??
              _MermaidErrorBox(error: _error!, code: widget.code);
        }

        if (_diagram == null) {
          return const SizedBox.shrink();
        }

        final painter = _getPainter(_diagram!);

        // Calculate display size with responsive constraints
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _computedSize.width;

        final displayWidth = widget.width != null
            ? (_computedSize.width > widget.width!
                  ? _computedSize.width
                  : widget.width!)
            : _computedSize.width.clamp(0.0, maxWidth);

        final displayHeight = widget.height != null
            ? (_computedSize.height > widget.height!
                  ? _computedSize.height
                  : widget.height!)
            : _computedSize.height;

        // A small screen scrolls a wide diagram rather than shrinking it: a
        // flowchart squeezed into a phone's width is a picture of nothing.
        final scrolls = _deviceConfig?.deviceType == DeviceType.mobile &&
            _computedSize.width > availableWidth;

        // Everywhere else it is scaled down to fit. The box used to be clamped
        // to the available width while the painting inside kept its full size,
        // so a diagram wider than the editor simply had its right-hand side
        // cut off — with nothing to say so, and no way to see the rest.
        // Upstream MarkText fixed the same fault by scaling (#3560).
        _paintScale = (!scrolls && _computedSize.width > displayWidth)
            ? displayWidth / _computedSize.width
            : 1.0;

        Widget diagramWidget = Container(
          width: displayWidth,
          height: _paintScale < 1.0
              ? _computedSize.height * _paintScale
              : displayHeight,
          color: Color(_style.backgroundColor),
          child: _paintScale < 1.0
              ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _computedSize.width,
                    height: _computedSize.height,
                    child: CustomPaint(painter: painter, size: _computedSize),
                  ),
                )
              : CustomPaint(painter: painter, size: _computedSize),
        );

        if (scrolls) {
          diagramWidget = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: diagramWidget,
          );
        }

        // A diagram-level title, which nothing drew. The charts paint the
        // title their own syntax gives them, but `---\ntitle: …\n---` — the
        // only way a flowchart can be titled, and the way mermaid documents
        // for every type — reached the widget and stopped there. Class and
        // entity-relationship diagrams parsed a `title` line all along and
        // had nowhere to put it either.
        // Skipped when a chart drew the title itself: the pie parser records
        // its title in both places, and drawing both put it on screen twice.
        final paintsOwnTitle = _pieChartData?.title != null ||
            _ganttChartData?.title != null ||
            _timelineChartData?.title != null ||
            _kanbanChartData?.title != null ||
            _quadrantChartData?.title != null ||
            _sankeyChartData?.title != null ||
            _c4DiagramData?.title != null ||
            _architectureData?.title != null ||
            _packetData?.title != null ||
            _radarChartData?.title != null ||
            _xyChartData?.title != null ||
            _journeyData?.title != null ||
            _gitGraphData?.title != null;
        final title = paintsOwnTitle ? null : _diagram?.title;
        if (title != null && title.isNotEmpty) {
          diagramWidget = Container(
            width: displayWidth,
            color: Color(_style.backgroundColor),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (_deviceConfig?.fontSize ?? 14) + 3,
                      fontWeight: FontWeight.w600,
                      color: Color(
                        _style.defaultNodeStyle.textColor ??
                            MermaidColors.defaultTextColor,
                      ),
                    ),
                  ),
                ),
                diagramWidget,
              ],
            ),
          );
        }

        return GestureDetector(
          onTapDown: widget.onNodeTap != null ? _handleTap : null,
          child: diagramWidget,
        );
      },
    );
  }

  /// How much the painting is shrunk to fit the space it was given.
  ///
  /// Kept because a tap arrives in the widget's coordinates and the nodes are
  /// in the diagram's: without dividing by this, tapping a node in a scaled
  /// diagram selects whichever node happens to sit at the unscaled position —
  /// further and further off towards the right of the picture.
  double _paintScale = 1.0;

  void _handleTap(TapDownDetails details) {
    if (_diagram == null || widget.onNodeTap == null) return;

    final localPosition = _paintScale == 1.0
        ? details.localPosition
        : details.localPosition / _paintScale;

    for (final node in _diagram!.nodes) {
      final nodeRect = Rect.fromLTWH(node.x, node.y, node.width, node.height);

      if (nodeRect.contains(localPosition)) {
        widget.onNodeTap!(node.id);
        break;
      }
    }
  }

}

/// The message shown in a diagram's place when it cannot be parsed.
///
/// One widget rather than the three near-copies this file used to carry: the
/// fixed red-on-white was fixed in one of them and left in the others, which is
/// how a dark theme ended up with a bright panel in the middle of the document
/// in some places and not others.
///
/// The app supplies its own `errorBuilder` and words the failure in the
/// reader's language. This is what an export captures — it renders off screen
/// with no builder — so the wording here stays English: this package depends on
/// nothing but Flutter, and reaching the app's translations would end that.
class _MermaidErrorBox extends StatelessWidget {
  const _MermaidErrorBox({required this.error, this.code});

  final String error;

  /// The diagram source, quoted below the message where there is room for it.
  final String? code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        border: Border.all(color: scheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Mermaid parse error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
          ),
          if (code != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                code!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Strips Dart's `Exception: ` prefix so the message reads as prose.
///
/// The parser's failure descriptions are written for whoever wrote the
/// diagram, not for a stack trace.
String _readableError(Object error) {
  final text = error.toString();
  const prefix = 'Exception: ';
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}
