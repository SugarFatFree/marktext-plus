import 'dart:math' as math;
import 'dart:ui';

import '../config/responsive_config.dart';
import '../models/git_graph.dart';
import '../models/journey.dart';
import '../models/diagram.dart';
import '../models/kanban.dart';
import '../models/node.dart';
import '../models/quadrant_chart.dart';
import '../models/radar.dart';
import '../models/timeline.dart';
import '../models/block_diagram.dart';
import '../models/c4_diagram.dart';
import '../models/sankey.dart';
import '../models/style.dart';
import '../models/xy_chart.dart';

/// Abstract base class for layout engines
abstract class LayoutEngine {
  /// Creates a layout engine
  const LayoutEngine();

  /// Computes layout for the given diagram
  ///
  /// Returns the total size required to render the diagram
  Size computeLayout(
    MermaidDiagramData diagram,
    MermaidStyle style,
    Size availableSize,
  );

  /// Measures the size of a node
  Size measureNode(MermaidNode node, MermaidStyle style) {
    final nodeStyle = style.getNodeStyle(node.className);

    // Calculate text size. A label can hold line breaks: `<br/>` in the
    // source is how mermaid wraps text inside a box, so the widest line sets
    // the width and the count sets the height.
    final fontSize = nodeStyle.fontSize;
    final lines = node.label.split('\n');
    final textWidth = lines
        .map((line) => line.length * fontSize * 0.6)
        .fold<double>(0, math.max);
    final textHeight = fontSize * 1.4 * lines.length;

    // Add padding based on shape
    double horizontalPadding = 24.0;
    double verticalPadding = 16.0;

    switch (node.shape) {
      case NodeShape.circle:
      case NodeShape.doubleCircle:
        // Circle needs equal dimensions
        final diameter = math.max(textWidth, textHeight) + 32;
        return Size(diameter, diameter);

      case NodeShape.diamond:
      case NodeShape.hexagon:
        // These shapes need more horizontal space
        horizontalPadding = 40.0;
        verticalPadding = 24.0;
        break;

      case NodeShape.stadium:
        // Stadium is wider
        horizontalPadding = 32.0;
        break;

      case NodeShape.cylinder:
        // Cylinder needs extra height for the 3D effect
        verticalPadding = 28.0;
        break;

      default:
        break;
    }

    return Size(
      textWidth + horizontalPadding,
      textHeight + verticalPadding,
    );
  }
}

/// Simple layout engine that arranges nodes in a grid-like pattern
///
/// This is a basic fallback layout when more sophisticated algorithms
/// aren't needed or available.
class SimpleLayoutEngine extends LayoutEngine {
  /// Creates a simple layout engine
  const SimpleLayoutEngine();

  @override
  Size computeLayout(
    MermaidDiagramData diagram,
    MermaidStyle style,
    Size availableSize,
  ) {
    if (diagram.nodes.isEmpty) return Size.zero;

    // Measure all nodes first
    for (final node in diagram.nodes) {
      final size = measureNode(node, style);
      node.width = size.width;
      node.height = size.height;
    }

    final isHorizontal = diagram.direction == DiagramDirection.leftToRight ||
        diagram.direction == DiagramDirection.rightToLeft;

    // Simple row/column layout
    double x = style.padding;
    double y = style.padding;
    double maxRowHeight = 0;
    double maxWidth = 0;
    double maxHeight = 0;

    final nodesPerRow = isHorizontal
        ? diagram.nodes.length
        : math.sqrt(diagram.nodes.length).ceil();

    for (var i = 0; i < diagram.nodes.length; i++) {
      final node = diagram.nodes[i];

      if (!isHorizontal && i > 0 && i % nodesPerRow == 0) {
        // Move to next row
        x = style.padding;
        y += maxRowHeight + style.nodeSpacingY;
        maxRowHeight = 0;
      }

      node.x = x;
      node.y = y;

      x += node.width + style.nodeSpacingX;
      maxRowHeight = math.max(maxRowHeight, node.height);
      maxWidth = math.max(maxWidth, x);
      maxHeight = math.max(maxHeight, y + node.height);
    }

    return Size(
      maxWidth + style.padding,
      maxHeight + style.padding,
    );
  }
}

/// Layout engine for timeline diagrams
class TimelineChartLayout {
  /// Creates a timeline chart layout engine
  const TimelineChartLayout({this.deviceConfig});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Computes the layout size for a timeline chart
  Size computeLayout(
    TimelineChartData timelineData,
    MermaidStyle style,
    Size availableSize,
  ) {
    if (timelineData.sections.isEmpty) return Size.zero;

    final padding = style.padding;
    final titleHeight = timelineData.title != null ? 60.0 : 20.0;

    // Calculate maximum events in any section
    var maxEvents = 0;
    for (final section in timelineData.sections) {
      if (section.events.length > maxEvents) {
        maxEvents = section.events.length;
      }
    }

    // Layout constants
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final eventHeight = isMobile ? 50.0 : 60.0;
    final verticalSpacing = isMobile ? 30.0 : 40.0;
    final timelineMargin = 20.0;

    // A `section` band is drawn above the period labels, so it needs its own
    // strip — and only when the diagram uses sections, which leaves every
    // timeline written without them exactly the height it was.
    final hasGroups =
        timelineData.sections.any((section) => section.group != null);
    final groupBandHeight = hasGroups ? timelineGroupBandHeight : 0.0;

    // Calculate total height
    // Structure: padding + title + bands + spacing + period labels + timeline + spacing + events + padding
    final totalHeight = padding +
        titleHeight +
        groupBandHeight +
        verticalSpacing +  // Space for period labels above timeline
        timelineMargin +   // Space around timeline
        verticalSpacing +  // Space before events
        (maxEvents * eventHeight) +
        padding;

    // Width should be based on available space
    final totalWidth = availableSize.width;

    return Size(totalWidth, totalHeight);
  }
}

/// Layout engine for Kanban diagrams
class KanbanChartLayout {
  /// Creates a Kanban chart layout engine
  const KanbanChartLayout({this.deviceConfig});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Computes layout size for Kanban chart
  Size computeLayout(
    KanbanChartData kanbanData,
    MermaidStyle style,
    Size availableSize,
  ) {
    if (kanbanData.columns.isEmpty) return Size.zero;

    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final isTablet = deviceConfig?.deviceType == DeviceType.tablet;

    // Responsive constants
    final padding = style.padding;
    final titleHeight = kanbanData.title != null ? 60.0 : 20.0;
    final columnHeaderHeight = isMobile ? 50.0 : 60.0;
    final columnSpacing = isMobile ? 12.0 : 16.0;
    final cardHeight = isMobile ? 90.0 : 110.0; // Base card height
    final cardSpacing = isMobile ? 8.0 : 12.0;

    // Calculate column width strategy
    final totalColumns = kanbanData.columns.length;
    double columnWidth;

    if (isMobile) {
      // Mobile: Single column visible, horizontal scroll
      columnWidth = availableSize.width - (padding * 2) - columnSpacing;
      columnWidth = columnWidth.clamp(250.0, 350.0);
    } else if (isTablet && totalColumns > 3) {
      // Tablet: Max 3 columns, scroll if more
      columnWidth = (availableSize.width - padding * 2 - columnSpacing * 2) / 3;
    } else {
      // Desktop: Fit all columns if possible
      final availableWidth = availableSize.width - padding * 2;
      columnWidth = (availableWidth - columnSpacing * (totalColumns - 1)) / totalColumns;
      columnWidth = columnWidth.clamp(200.0, 350.0);
    }

    // Calculate maximum cards in any column
    var maxCards = 0;
    for (final column in kanbanData.columns) {
      if (column.tasks.length > maxCards) {
        maxCards = column.tasks.length;
      }
    }

    // Calculate total height
    final cardsAreaHeight = (maxCards * cardHeight) + ((maxCards + 1) * cardSpacing);

    final totalHeight = padding +
        titleHeight +
        columnHeaderHeight +
        cardsAreaHeight +
        padding;

    // Calculate total width
    final totalWidth = isMobile
        ? (columnWidth + columnSpacing) * totalColumns + padding * 2
        : availableSize.width;

    return Size(totalWidth, totalHeight);
  }
}

/// Layout engine for Radar charts
class RadarChartLayout {
  /// Creates a Radar chart layout engine
  const RadarChartLayout({this.deviceConfig});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Computes layout size for Radar chart
  Size computeLayout(
    RadarChartData radarData,
    MermaidStyle style,
    Size availableSize,
  ) {
    if (radarData.axes.isEmpty) return Size.zero;

    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final padding = style.padding;
    final titleHeight = radarData.title != null ? (isMobile ? 40.0 : 50.0) : 0.0;
    final legendHeight = radarData.showLegend && radarData.curves.length > 1 ? 60.0 : 0.0;

    // Calculate chart size based on available space
    final availableChartWidth = availableSize.width - padding * 2;
    final availableChartHeight = availableSize.height - titleHeight - legendHeight - padding * 2;

    // Use square aspect ratio, fitting within available space
    final chartSize = math.min(
      math.min(availableChartWidth, availableChartHeight),
      isMobile ? 350.0 : 500.0,
    );

    final totalWidth = chartSize + padding * 2;
    final totalHeight = titleHeight + chartSize + legendHeight + padding * 2;

    return Size(totalWidth, totalHeight);
  }
}

/// Layout engine for quadrant charts
class QuadrantChartLayout {
  /// Creates a quadrant chart layout engine
  const QuadrantChartLayout({this.deviceConfig});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Computes layout size for a quadrant chart.
  ///
  /// The plot is square; the extra height is the title plus the axis captions
  /// drawn outside it on all four sides.
  Size computeLayout(
    QuadrantChartData quadrantData,
    MermaidStyle style,
    Size availableSize,
  ) {
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final padding = style.padding;
    final titleHeight =
        quadrantData.title != null ? (isMobile ? 32.0 : 40.0) : 0.0;
    const axisGutter = 26.0;

    final availableWidth = availableSize.width - padding * 2 - axisGutter * 2;
    final availableHeight =
        availableSize.height - padding * 2 - titleHeight - axisGutter * 2;

    final side = math.min(
      math.min(availableWidth, availableHeight),
      isMobile ? 320.0 : 460.0,
    );
    if (side <= 0) return Size.zero;

    return Size(
      side + padding * 2 + axisGutter * 2,
      side + padding * 2 + titleHeight + axisGutter * 2,
    );
  }
}

/// Layout engine for C4 diagrams
class C4DiagramLayout {
  /// Creates a C4 layout engine
  const C4DiagramLayout({this.deviceConfig});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Computes the size a C4 diagram needs.
  ///
  /// Delegates to [C4Layout], the same code the painter runs, so the box
  /// reserved here always matches what gets drawn into it.
  Size computeLayout(
    C4DiagramData c4Data,
    MermaidStyle style,
    Size availableSize,
  ) {
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final titleHeight = c4Data.title == null ? 0.0 : (isMobile ? 30.0 : 38.0);

    final layout = C4Layout.compute(
      c4Data,
      availableWidth: availableSize.width,
      padding: style.padding,
      titleHeight: titleHeight,
    );
    if (layout.elements.isEmpty && layout.boundaries.isEmpty) return Size.zero;
    return Size(math.max(layout.width, availableSize.width), layout.height);
  }
}

/// Layout engine for block diagrams
class BlockDiagramLayout {
  /// Creates a block diagram layout engine
  const BlockDiagramLayout({this.deviceConfig});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Computes the size a block diagram needs.
  ///
  /// Delegates to [BlockLayout], the same code the painter runs, so the box
  /// reserved here always matches what gets drawn into it.
  Size computeLayout(
    BlockDiagramData blockData,
    MermaidStyle style,
    Size availableSize,
  ) {
    final layout = BlockLayout.compute(
      blockData,
      availableWidth: availableSize.width,
      padding: style.padding,
    );
    if (layout.blocks.isEmpty) return Size.zero;
    return Size(math.max(layout.width, availableSize.width), layout.height);
  }
}

/// Layout engine for Sankey diagrams
class SankeyChartLayout {
  /// Creates a Sankey layout engine
  const SankeyChartLayout({this.deviceConfig});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Computes the size a Sankey diagram needs.
  ///
  /// Delegates to [SankeyLayout], the same code the painter runs, so the box
  /// reserved here always matches what gets drawn into it.
  Size computeLayout(
    SankeyChartData sankeyData,
    MermaidStyle style,
    Size availableSize,
  ) {
    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final titleHeight =
        sankeyData.title == null ? 0.0 : (isMobile ? 30.0 : 38.0);

    final layout = SankeyLayout.compute(
      sankeyData,
      availableWidth: availableSize.width,
      bandHeight: isMobile ? 260 : 360,
      padding: style.padding,
      titleHeight: titleHeight,
      labelGutter: isMobile ? 72 : 96,
    );

    if (layout.nodes.isEmpty) return Size.zero;
    return Size(
      math.max(layout.width, availableSize.width),
      layout.height,
    );
  }
}

/// Layout engine for XY charts
class XYChartLayout {
  /// Creates an XY chart layout engine
  const XYChartLayout({this.deviceConfig});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Computes layout size for XY chart
  Size computeLayout(
    XYChartData xyData,
    MermaidStyle style,
    Size availableSize,
  ) {
    if (xyData.series.isEmpty) return Size.zero;

    final isMobile = deviceConfig?.deviceType == DeviceType.mobile;
    final padding = style.padding;
    final titleHeight = xyData.title != null ? (isMobile ? 35.0 : 45.0) : 0.0;
    final xAxisLabelHeight = isMobile ? 40.0 : 50.0;

    final totalWidth = math.min(availableSize.width, isMobile ? 400.0 : 700.0);
    final totalHeight = titleHeight + (isMobile ? 280.0 : 400.0) + xAxisLabelHeight + padding * 2;

    return Size(totalWidth, totalHeight);
  }
}


/// Layout engine for user journey diagrams.
///
/// A journey is a satisfaction line: tasks run left to right on a fixed
/// column pitch, and the score puts each marker on one of five rows.
class JourneyChartLayout {
  /// Creates a journey layout engine.
  const JourneyChartLayout({this.deviceConfig});

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// Width of one task column.
  static const double taskWidth = 110.0;

  /// Height of the plotted score band.
  static const double chartHeight = 190.0;

  /// Height of the section header strip.
  static const double sectionBarHeight = 34.0;

  /// Height reserved under the chart for task labels.
  static const double labelHeight = 54.0;

  /// Height reserved for the actor legend; zero when nobody is named.
  static const double legendHeight = 30.0;

  /// Computes the layout size for a journey diagram.
  Size computeLayout(
    JourneyData journeyData,
    MermaidStyle style,
    Size availableSize,
  ) {
    final taskCount = journeyData.allTasks.length;
    if (taskCount == 0) return Size.zero;

    final padding = style.padding;
    final titleHeight = journeyData.title != null ? 44.0 : 12.0;
    final legend = journeyData.actors.isEmpty ? 0.0 : legendHeight;

    final width = padding * 2 + taskCount * taskWidth;
    final height = padding * 2 +
        titleHeight +
        sectionBarHeight +
        chartHeight +
        labelHeight +
        legend;

    return Size(width, height);
  }
}

/// Layout engine for git graphs.
///
/// One row per branch, one column per commit in source order.
class GitGraphLayout {
  /// Creates a git graph layout engine.
  const GitGraphLayout({this.deviceConfig});

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// Horizontal distance between commits.
  static const double columnWidth = 70.0;

  /// Vertical distance between branch rows.
  static const double rowHeight = 62.0;

  /// Space on the left for branch name labels.
  static const double labelGutter = 96.0;

  /// Computes the layout size for a git graph.
  Size computeLayout(
    GitGraphData gitData,
    MermaidStyle style,
    Size availableSize,
  ) {
    if (gitData.commits.isEmpty) return Size.zero;

    final padding = style.padding;
    final titleHeight = gitData.title != null ? 44.0 : 8.0;

    // A trailing half column keeps a tag on the last commit inside the canvas.
    final width = padding * 2 +
        labelGutter +
        (gitData.lastColumn + 1.5) * columnWidth;
    final height =
        padding * 2 + titleHeight + gitData.branches.length * rowHeight;

    return Size(width, height);
  }
}
