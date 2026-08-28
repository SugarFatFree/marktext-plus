import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../config/responsive_config.dart';
import '../models/mindmap.dart';
import '../models/style.dart';

/// Two-sided layout for mindmaps.
///
/// The root sits in the middle and its subtrees alternate right and left, which
/// keeps the map compact and reads closer to mermaid's radial arrangement than
/// a plain left-to-right tree would.
class MindmapLayout {
  /// Creates a mindmap layout engine.
  const MindmapLayout({this.deviceConfig});

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// Horizontal gap between a node and its children.
  static const double levelGap = 46.0;

  /// Vertical gap between siblings.
  static const double siblingGap = 14.0;

  /// Padding inside a node box.
  static const double horizontalPadding = 14.0;

  /// Padding above and below a node's text.
  static const double verticalPadding = 8.0;

  /// Font size for a node at [depth].
  static double fontSizeForDepth(int depth, MermaidStyle style) {
    final base = style.defaultNodeStyle.fontSize;
    if (depth == 0) return base + 4;
    if (depth == 1) return base + 1;
    return base - 1;
  }

  /// Positions every node and returns the size needed to draw them.
  Size computeLayout(
    MindmapData data,
    MermaidStyle style,
    Size availableSize,
  ) {
    final root = data.root;

    for (final node in data.allNodes) {
      final fontSize = fontSizeForDepth(node.depth, style);
      final textWidth = _measureText(node.label, fontSize, style.fontFamily);
      node.width = textWidth + horizontalPadding * 2;
      node.height = fontSize * 1.4 + verticalPadding * 2;
    }

    // Alternate whole subtrees between the two sides.
    for (var i = 0; i < root.children.length; i++) {
      final side = i.isEven ? MindmapSide.right : MindmapSide.left;
      for (final node in root.children[i].descendants) {
        node.side = side;
      }
    }
    root.side = MindmapSide.centre;

    final right = root.children
        .where((c) => c.side == MindmapSide.right)
        .toList();
    final left =
        root.children.where((c) => c.side == MindmapSide.left).toList();

    for (final child in root.children) {
      _computeSubtreeHeight(child);
    }

    final rightHeight = _stackHeight(right);
    final leftHeight = _stackHeight(left);
    final contentHeight =
        math.max(math.max(rightHeight, leftHeight), root.height);

    root.x = 0;
    root.y = contentHeight / 2;

    _placeSide(right, root, 1, contentHeight, rightHeight);
    _placeSide(left, root, -1, contentHeight, leftHeight);

    // Shift everything into positive coordinates and add the outer padding.
    final padding = style.padding;
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;

    for (final node in data.allNodes) {
      minX = math.min(minX, node.x - node.width / 2);
      maxX = math.max(maxX, node.x + node.width / 2);
      minY = math.min(minY, node.y - node.height / 2);
      maxY = math.max(maxY, node.y + node.height / 2);
    }

    if (minX == double.infinity) return Size.zero;

    final dx = padding - minX;
    final dy = padding - minY;
    for (final node in data.allNodes) {
      node.x += dx;
      node.y += dy;
    }

    return Size(maxX - minX + padding * 2, maxY - minY + padding * 2);
  }

  /// Total height a list of sibling subtrees occupies, gaps included.
  double _stackHeight(List<MindmapNode> siblings) {
    if (siblings.isEmpty) return 0;
    var total = 0.0;
    for (final node in siblings) {
      total += node.subtreeHeight;
    }
    return total + siblingGap * (siblings.length - 1);
  }

  double _computeSubtreeHeight(MindmapNode node) {
    if (node.children.isEmpty) {
      node.subtreeHeight = node.height;
      return node.subtreeHeight;
    }
    var total = 0.0;
    for (final child in node.children) {
      total += _computeSubtreeHeight(child);
    }
    total += siblingGap * (node.children.length - 1);
    node.subtreeHeight = math.max(node.height, total);
    return node.subtreeHeight;
  }

  void _placeSide(
    List<MindmapNode> siblings,
    MindmapNode root,
    int direction,
    double contentHeight,
    double sideHeight,
  ) {
    if (siblings.isEmpty) return;

    var y = (contentHeight - sideHeight) / 2;
    for (final child in siblings) {
      final x = root.x +
          direction * (root.width / 2 + levelGap + child.width / 2);
      _place(child, x, y, direction);
      y += child.subtreeHeight + siblingGap;
    }
  }

  void _place(MindmapNode node, double x, double top, int direction) {
    node.x = x;
    node.y = top + node.subtreeHeight / 2;

    var childTop = top;
    for (final child in node.children) {
      final childX = node.x +
          direction * (node.width / 2 + levelGap + child.width / 2);
      _place(child, childX, childTop, direction);
      childTop += child.subtreeHeight + siblingGap;
    }
  }

  double _measureText(String text, double fontSize, String? fontFamily) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}
