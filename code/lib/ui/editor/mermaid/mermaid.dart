/// Pure Dart Mermaid diagram renderer for Flutter
///
/// This library provides a complete implementation of Mermaid diagram
/// rendering using only Dart and Flutter's CustomPainter, without
/// any WebView or external API dependencies.
///
/// The diagram types this renderer draws are listed in
/// [MermaidParser.supportedTypes]. That list is the one the fence-language
/// check and the "unsupported type" message are both derived from, so it is
/// the only place worth keeping up to date — this comment used to carry a
/// second copy and had fallen eight types behind.
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
/// )
/// ```
///
/// Pie chart example:
/// ```dart
/// MermaidDiagram(
///   code: '''
///   pie
///     title Favorite Pets
///     "Dogs" : 386
///     "Cats" : 85
///     "Birds" : 15
///   ''',
/// )
/// ```
///
/// Timeline example:
/// ```dart
/// MermaidDiagram(
///   code: '''
///   timeline
///     title History of Social Media Platform
///     2002 : LinkedIn
///     2004 : Facebook
///          : Google
///     2005 : Youtube
///     2006 : Twitter
///   ''',
/// )
/// ```
library;

export 'config/responsive_config.dart';
export 'layout/architecture_layout.dart';
export 'layout/class_diagram_layout.dart';
export 'layout/dagre_layout.dart';
export 'layout/er_diagram_layout.dart';
export 'layout/layout_engine.dart';
export 'layout/mindmap_layout.dart';
export 'layout/requirement_diagram_layout.dart';
export 'layout/sequence_layout.dart';
export 'models/architecture.dart';
export 'models/block_diagram.dart';
export 'models/c4_diagram.dart';
export 'models/class_diagram.dart';
export 'models/diagram.dart';
export 'models/edge.dart';
export 'models/er_diagram.dart';
export 'models/gantt.dart';
export 'models/git_graph.dart';
export 'models/journey.dart';
export 'models/kanban.dart';
export 'models/mindmap.dart';
export 'models/node.dart';
export 'models/packet.dart';
export 'models/pie_chart.dart';
export 'models/quadrant_chart.dart';
export 'models/radar.dart';
export 'models/requirement_diagram.dart';
export 'models/sankey.dart';
export 'models/sequence.dart';
export 'models/style.dart';
export 'models/timeline.dart';
export 'models/xy_chart.dart';
export 'painter/architecture_painter.dart';
export 'painter/block_painter.dart';
export 'painter/box_edge_geometry.dart';
export 'painter/c4_painter.dart';
export 'painter/class_diagram_painter.dart';
export 'painter/er_diagram_painter.dart';
export 'painter/flowchart_painter.dart';
export 'painter/gantt_painter.dart';
export 'painter/git_graph_painter.dart';
export 'painter/journey_painter.dart';
export 'painter/kanban_painter.dart';
export 'painter/mermaid_painter.dart';
export 'painter/mindmap_painter.dart';
export 'painter/packet_painter.dart';
export 'painter/pie_chart_painter.dart';
export 'painter/quadrant_painter.dart';
export 'painter/radar_painter.dart';
export 'painter/requirement_painter.dart';
export 'painter/sankey_painter.dart';
export 'painter/sequence_painter.dart';
export 'painter/timeline_painter.dart';
export 'painter/xy_chart_painter.dart';
export 'parser/architecture_parser.dart';
export 'parser/block_parser.dart';
export 'parser/c4_parser.dart';
export 'parser/class_diagram_parser.dart';
export 'parser/er_diagram_parser.dart';
export 'parser/flowchart_parser.dart';
export 'parser/gantt_parser.dart';
export 'parser/git_graph_parser.dart';
export 'parser/identifier.dart';
export 'parser/indentation.dart';
export 'parser/journey_parser.dart';
export 'parser/kanban_parser.dart';
export 'parser/label.dart';
export 'parser/mermaid_parser.dart';
export 'parser/mindmap_parser.dart';
export 'parser/packet_parser.dart';
export 'parser/pie_chart_parser.dart';
export 'parser/quadrant_parser.dart';
export 'parser/radar_parser.dart';
export 'parser/requirement_parser.dart';
export 'parser/sankey_parser.dart';
export 'parser/sequence_parser.dart';
export 'parser/state_diagram_parser.dart';
export 'parser/timeline_parser.dart';
export 'parser/xy_chart_parser.dart';
export 'widgets/mermaid_diagram.dart';
