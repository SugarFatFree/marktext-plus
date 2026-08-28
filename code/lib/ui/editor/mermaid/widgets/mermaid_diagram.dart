import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/class_diagram_layout.dart';
import '../layout/requirement_diagram_layout.dart';
import '../layout/er_diagram_layout.dart';
import '../layout/mindmap_layout.dart';
import '../layout/dagre_layout.dart';
import '../layout/layout_engine.dart';
import '../layout/sugiyama_layout.dart';
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

        // For mobile, wrap in horizontal scroll if needed
        Widget diagramWidget = Container(
          width: displayWidth,
          height: displayHeight,
          color: Color(_style.backgroundColor),
          child: CustomPaint(painter: painter, size: _computedSize),
        );

        // Enable horizontal scrolling on mobile if diagram is wider than screen
        if (_deviceConfig?.deviceType == DeviceType.mobile &&
            _computedSize.width > availableWidth) {
          diagramWidget = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: diagramWidget,
          );
        }

        return GestureDetector(
          onTapDown: widget.onNodeTap != null ? _handleTap : null,
          child: diagramWidget,
        );
      },
    );
  }

  void _handleTap(TapDownDetails details) {
    if (_diagram == null || widget.onNodeTap == null) return;

    final localPosition = details.localPosition;

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

/// An interactive Mermaid diagram with pan and zoom support
class InteractiveMermaidDiagram extends StatefulWidget {
  /// Creates an interactive Mermaid diagram
  const InteractiveMermaidDiagram({
    super.key,
    required this.code,
    this.style,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.onNodeTap,
  });

  /// The Mermaid diagram code
  final String code;

  /// Style configuration
  final MermaidStyle? style;

  /// Minimum zoom scale
  final double minScale;

  /// Maximum zoom scale
  final double maxScale;

  /// Callback when a node is tapped
  final void Function(String nodeId)? onNodeTap;

  @override
  State<InteractiveMermaidDiagram> createState() =>
      _InteractiveMermaidDiagramState();
}

class _InteractiveMermaidDiagramState extends State<InteractiveMermaidDiagram> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _diagramKey = GlobalKey();
  Size? _lastDiagramSize;
  Size? _lastViewportSize;
  bool _hasCentered = false;

  @override
  void didUpdateWidget(InteractiveMermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code || oldWidget.style != widget.style) {
      // Reset centering when code changes
      _hasCentered = false;
      _lastDiagramSize = null;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _centerDiagram(Size viewportSize, Size diagramSize) {
    // Only center if size changed or first time
    if (_hasCentered &&
        _lastDiagramSize == diagramSize &&
        _lastViewportSize == viewportSize) {
      return;
    }

    _lastDiagramSize = diagramSize;
    _lastViewportSize = viewportSize;
    _hasCentered = true;

    // Calculate scale to fit diagram in viewport with padding
    const padding = 40.0; // Padding around diagram
    final availableWidth = viewportSize.width - padding * 2;
    final availableHeight = viewportSize.height - padding * 2;

    // Calculate scale factors for width and height
    final scaleX = availableWidth / diagramSize.width;
    final scaleY = availableHeight / diagramSize.height;

    // Use the smaller scale to ensure the entire diagram fits
    // But don't scale up beyond 1.0 (100%)
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(
      widget.minScale,
      1.0,
    );

    // Calculate the scaled diagram size
    final scaledWidth = diagramSize.width * scale;
    final scaledHeight = diagramSize.height * scale;

    // Calculate offset to center the scaled diagram
    final offsetX = (viewportSize.width - scaledWidth) / 2;
    final offsetY = (viewportSize.height - scaledHeight) / 2;

    // Set the transformation matrix
    // Matrix4 applies transformations in reverse order when using cascade
    // So we build: translate then scale (which applies as scale first, then translate)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Create matrix that scales at origin then translates to center
        final matrix = Matrix4.identity();
        // Apply translation
        matrix.setEntry(0, 3, offsetX);
        matrix.setEntry(1, 3, offsetY);
        // Apply scale
        matrix.setEntry(0, 0, scale);
        matrix.setEntry(1, 1, scale);
        _transformationController.value = matrix;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lay out against the space actually available
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 800.0;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 600.0;

        final viewportSize = Size(availableWidth, availableHeight);

        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          child: _CenteringMermaidDiagram(
            key: _diagramKey,
            code: widget.code,
            style: widget.style,
            viewportSize: viewportSize,
            onNodeTap: widget.onNodeTap,
            onSizeComputed: (diagramSize) {
              _centerDiagram(viewportSize, diagramSize);
            },
          ),
        );
      },
    );
  }
}

/// Internal widget that reports its computed size for centering
class _CenteringMermaidDiagram extends StatefulWidget {
  const _CenteringMermaidDiagram({
    super.key,
    required this.code,
    required this.viewportSize,
    required this.onSizeComputed,
    this.style,
    this.onNodeTap,
  });

  final String code;
  final MermaidStyle? style;
  final Size viewportSize;
  final void Function(String nodeId)? onNodeTap;
  final void Function(Size size) onSizeComputed;

  @override
  State<_CenteringMermaidDiagram> createState() =>
      _CenteringMermaidDiagramState();
}

class _CenteringMermaidDiagramState extends State<_CenteringMermaidDiagram> {
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

  late MermaidStyle _style;

  @override
  void initState() {
    super.initState();
    _style = widget.style ?? const MermaidStyle();
    _parseDiagram();
  }

  @override
  void didUpdateWidget(_CenteringMermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code || oldWidget.style != widget.style) {
      _style = widget.style ?? const MermaidStyle();
      _parseDiagram();
    }
  }

  void _parseDiagram() {
    try {
      const parser = MermaidParser();
      final result = parser.parseWithData(widget.code);

      if (result == null) {
        throw Exception(parser.describeParseFailure(widget.code));
      }

      final diagram = result.diagram;
      Size size;

      // Compute layout based on diagram type
      if (diagram.type == DiagramType.pieChart && result.pieChartData != null) {
        final pieLayout = PieChartLayout(deviceConfig: _deviceConfig);
        size = pieLayout.computeLayout(
          result.pieChartData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.ganttChart &&
          result.ganttChartData != null) {
        final ganttLayout = GanttChartLayout(deviceConfig: _deviceConfig);
        size = ganttLayout.computeLayout(
          result.ganttChartData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.timeline &&
          result.timelineChartData != null) {
        final timelineLayout = TimelineChartLayout(deviceConfig: _deviceConfig);
        size = timelineLayout.computeLayout(
          result.timelineChartData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.kanban &&
          result.kanbanChartData != null) {
        final kanbanLayout = KanbanChartLayout(deviceConfig: _deviceConfig);
        size = kanbanLayout.computeLayout(
          result.kanbanChartData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.quadrantChart &&
          result.quadrantChartData != null) {
        final quadrantLayout = QuadrantChartLayout(deviceConfig: _deviceConfig);
        size = quadrantLayout.computeLayout(
          result.quadrantChartData!,
          _style,
          widget.viewportSize,
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
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.c4Diagram &&
          result.c4DiagramData != null) {
        final c4Layout = C4DiagramLayout(deviceConfig: _deviceConfig);
        size = c4Layout.computeLayout(
          result.c4DiagramData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.blockDiagram &&
          result.blockDiagramData != null) {
        final blockLayout = BlockDiagramLayout(deviceConfig: _deviceConfig);
        size = blockLayout.computeLayout(
          result.blockDiagramData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.sankey &&
          result.sankeyChartData != null) {
        final sankeyLayout = SankeyChartLayout(deviceConfig: _deviceConfig);
        size = sankeyLayout.computeLayout(
          result.sankeyChartData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.radar &&
          result.radarChartData != null) {
        final radarLayout = RadarChartLayout(deviceConfig: _deviceConfig);
        size = radarLayout.computeLayout(
          result.radarChartData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.xyChart &&
          result.xyChartData != null) {
        final xyLayout = XYChartLayout(deviceConfig: _deviceConfig);
        size = xyLayout.computeLayout(
          result.xyChartData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.mindmap &&
          result.mindmapData != null) {
        final mindmapLayout = MindmapLayout(deviceConfig: _deviceConfig);
        size = mindmapLayout.computeLayout(
          result.mindmapData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.gitGraph &&
          result.gitGraphData != null) {
        final gitLayout = GitGraphLayout(deviceConfig: _deviceConfig);
        size = gitLayout.computeLayout(
          result.gitGraphData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.journey &&
          result.journeyData != null) {
        final journeyLayout = JourneyChartLayout(deviceConfig: _deviceConfig);
        size = journeyLayout.computeLayout(
          result.journeyData!,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.erDiagram &&
          result.erDiagramData != null) {
        // Entity boxes carry a table of attributes, which the generic
        // single-label node measurement cannot describe.
        final erLayout = ErDiagramLayout(
          erData: result.erDiagramData!,
          deviceConfig: _deviceConfig,
        );
        size = erLayout.computeLayout(diagram, _style, widget.viewportSize);
      } else if (diagram.type == DiagramType.requirementDiagram &&
          result.requirementDiagramData != null) {
        final requirementLayout = RequirementDiagramLayout(
          requirementData: result.requirementDiagramData!,
          deviceConfig: _deviceConfig,
        );
        size = requirementLayout.computeLayout(
          diagram,
          _style,
          widget.viewportSize,
        );
      } else if (diagram.type == DiagramType.classDiagram &&
          result.classDiagramData != null) {
        // Class boxes are three compartments tall, which the generic
        // single-label node measurement cannot describe.
        final classLayout = ClassDiagramLayout(
          classData: result.classDiagramData!,
          deviceConfig: _deviceConfig,
        );
        size = classLayout.computeLayout(diagram, _style, widget.viewportSize);
      } else {
        final layoutEngine = _getLayoutEngine(diagram.type);
        size = layoutEngine.computeLayout(diagram, _style, widget.viewportSize);
      }

      setState(() {
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
      });

      // Notify parent of computed size for centering
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSizeComputed(size);
      });
    } catch (e) {
      setState(() {
        _error = _readableError(e);
        _isLoading = false;
      });
    }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _MermaidErrorBox(error: _error!, code: widget.code);
    }

    if (_diagram == null) {
      return const SizedBox.shrink();
    }

    final painter = _getPainter(_diagram!);

    return Container(
      width: _computedSize.width,
      height: _computedSize.height,
      color: Color(_style.backgroundColor),
      child: GestureDetector(
        onTapDown: widget.onNodeTap != null ? _handleTap : null,
        child: CustomPaint(painter: painter, size: _computedSize),
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    if (_diagram == null || widget.onNodeTap == null) return;

    final localPosition = details.localPosition;

    for (final node in _diagram!.nodes) {
      final nodeRect = Rect.fromLTWH(node.x, node.y, node.width, node.height);

      if (nodeRect.contains(localPosition)) {
        widget.onNodeTap!(node.id);
        break;
      }
    }
  }

}
