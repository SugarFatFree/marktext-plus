import 'dart:math' as math;
import '../../../../utils/text_width.dart';
import 'dart:ui';

import '../config/responsive_config.dart';
import '../models/diagram.dart';
import '../models/style.dart';
import 'layout_engine.dart';

class SequenceLayout extends LayoutEngine {
  /// Creates a sequence layout engine
  const SequenceLayout({this.deviceConfig, this.rowCount});

  /// Responsive device configuration
  final MermaidDeviceConfig? deviceConfig;

  /// Number of rows to reserve height for.
  ///
  /// Notes take a row of their own, so the message count alone leaves the
  /// diagram short by one row per note. Null falls back to the message count,
  /// which is right for a diagram with no notes.
  final int? rowCount;

  @override
  Size computeLayout(
    MermaidDiagramData diagram,
    MermaidStyle style,
    Size availableSize,
  ) {
    if (diagram.nodes.isEmpty) return Size.zero;

    // Get responsive values
    final participantSpacingBase = deviceConfig?.participantSpacing ?? 150.0;
    final messageSpacing = deviceConfig?.messageSpacing ?? 50.0;
    final fontSize = deviceConfig?.fontSize ?? 14.0;

    // Measure all nodes first
    for (final node in diagram.nodes) {
      final size = measureNode(node, style);
      node.width = size.width;
      node.height = size.height;
    }

    // Sequence diagrams arrange participants horizontally
    const topY = 30.0; // Fixed Y for participant headers at top

    // Calculate width needed based on participant count and message labels
    final participantCount = diagram.nodes.length;

    // Calculate max label length to determine spacing
    var maxLabelLength = 0.0;
    for (final edge in diagram.edges) {
      if (edge.label != null) {
        // Through the shared table. At half the font size per character this
        // was short for Latin and less than half of what a CJK message needs,
        // and this width is what sets the gap between two participants — so a
        // Chinese message ran across the lifeline beside it.
        final labelWidth = estimatedTextWidth(edge.label!, fontSize);
        if (labelWidth > maxLabelLength) {
          maxLabelLength = labelWidth;
        }
      }
    }

    // Minimum spacing based on label length, with responsive bounds
    final minSpacing = math.max(
      participantSpacingBase * 0.6,
      maxLabelLength + 30,
    );
    final maxSpacing = participantSpacingBase; // Use responsive max spacing

    // Calculate optimal spacing
    final participantSpacing = math.min(minSpacing, maxSpacing);

    // Calculate total nodes width
    var totalNodesWidth = 0.0;
    for (final node in diagram.nodes) {
      totalNodesWidth += node.width;
    }

    // Total width is based on actual content
    final totalWidth =
        style.padding * 2 +
        totalNodesWidth +
        (participantCount > 1
            ? (participantCount - 1) * participantSpacing
            : 0);

    // Position participants with calculated spacing
    var currentX = style.padding;
    for (var i = 0; i < diagram.nodes.length; i++) {
      final node = diagram.nodes[i];
      node.x = currentX;
      node.y = topY;
      currentX += node.width + participantSpacing;
    }

    // Calculate height based on number of messages with responsive spacing
    final messageStartOffset = messageSpacing * 0.8;
    final bottomParticipantHeight = messageSpacing;

    final nodeHeight = diagram.nodes.first.height;
    final messagesHeight = (rowCount ?? diagram.edges.length) * messageSpacing;
    final totalHeight =
        topY +
        nodeHeight +
        messageStartOffset +
        messagesHeight +
        bottomParticipantHeight +
        style.padding;

    return Size(totalWidth, totalHeight);
  }
}
