/// Data models and layout for Sankey diagrams
library;

import 'dart:math' as math;

/// One flow, carrying [value] units from [source] to [target].
class SankeyLink {
  /// Creates a Sankey link.
  const SankeyLink({
    required this.source,
    required this.target,
    required this.value,
  });

  /// Name of the node the flow leaves.
  final String source;

  /// Name of the node the flow enters.
  final String target;

  /// Magnitude of the flow, which sets the ribbon thickness.
  final double value;

  @override
  bool operator ==(Object other) =>
      other is SankeyLink &&
      other.source == source &&
      other.target == target &&
      other.value == value;

  @override
  int get hashCode => Object.hash(source, target, value);
}

/// A complete Sankey diagram.
class SankeyChartData {
  /// Creates Sankey diagram data.
  const SankeyChartData({required this.nodes, required this.links, this.title});

  /// Node names, in the order they first appear in the source.
  ///
  /// Sankey source has no node declarations — every name is introduced by the
  /// flow that mentions it — so this order is the only stable one available.
  final List<String> nodes;

  /// The flows.
  final List<SankeyLink> links;

  /// Optional title, taken from YAML frontmatter.
  final String? title;

  @override
  bool operator ==(Object other) =>
      other is SankeyChartData &&
      other.title == title &&
      _listEquals(other.nodes, nodes) &&
      _listEquals(other.links, links);

  @override
  int get hashCode =>
      Object.hash(title, Object.hashAll(nodes), Object.hashAll(links));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A placed node.
class SankeyNodeLayout {
  /// Creates a placed node.
  const SankeyNodeLayout({
    required this.id,
    required this.index,
    required this.layer,
    required this.value,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Node name.
  final String id;

  /// Position in [SankeyChartData.nodes], used to pick a stable colour.
  final int index;

  /// Column the node sits in, counting from zero at the left.
  final int layer;

  /// Total flow through the node.
  final double value;

  /// Left edge in logical pixels.
  final double left;

  /// Top edge in logical pixels.
  final double top;

  /// Bar width.
  final double width;

  /// Bar height, proportional to [value].
  final double height;

  /// Right edge.
  double get right => left + width;

  /// Bottom edge.
  double get bottom => top + height;
}

/// A placed ribbon.
class SankeyLinkLayout {
  /// Creates a placed ribbon.
  const SankeyLinkLayout({
    required this.link,
    required this.colorIndex,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.thickness,
  });

  /// The flow this ribbon draws.
  final SankeyLink link;

  /// Index of the source node, so the ribbon can take its colour.
  final int colorIndex;

  /// Where the ribbon leaves the source bar.
  final double x0;

  /// Vertical *centre* of the ribbon at the source end.
  final double y0;

  /// Where the ribbon meets the target bar.
  final double x1;

  /// Vertical *centre* of the ribbon at the target end.
  final double y1;

  /// Ribbon thickness, proportional to the flow value.
  final double thickness;
}

/// The result of laying out a Sankey diagram.
class SankeyLayoutResult {
  /// Creates a layout result.
  const SankeyLayoutResult({
    required this.width,
    required this.height,
    required this.nodes,
    required this.links,
    required this.labelGutter,
  });

  /// Total width needed.
  final double width;

  /// Total height needed.
  final double height;

  /// Placed nodes.
  final List<SankeyNodeLayout> nodes;

  /// Placed ribbons.
  final List<SankeyLinkLayout> links;

  /// Horizontal room reserved for the labels outside the outermost bars.
  final double labelGutter;
}

/// Turns [SankeyChartData] into placed bars and ribbons.
///
/// The painter and the size calculation both go through this one function, so
/// the box the widget reserves and the drawing that lands in it cannot drift
/// apart. It is deliberately free of Flutter types so it can be exercised
/// without a widget test.
class SankeyLayout {
  const SankeyLayout._();

  /// Bar width in logical pixels.
  static const double nodeWidth = 18;

  /// Vertical gap between two bars in the same column.
  static const double nodePadding = 14;

  /// Computes the layout.
  ///
  /// [bandHeight] is the height the busiest column is scaled to; every other
  /// column is drawn at the same scale, which is what makes ribbon thickness
  /// comparable across the whole diagram.
  static SankeyLayoutResult compute(
    SankeyChartData data, {
    required double availableWidth,
    double bandHeight = 360,
    double padding = 16,
    double titleHeight = 0,
    double labelGutter = 96,
  }) {
    final ids = data.nodes;
    if (ids.isEmpty || data.links.isEmpty) {
      return const SankeyLayoutResult(
        width: 0,
        height: 0,
        nodes: [],
        links: [],
        labelGutter: 0,
      );
    }

    final indexOf = <String, int>{};
    for (var i = 0; i < ids.length; i++) {
      indexOf[ids[i]] = i;
    }

    final links = data.links;
    final ends = <(int, int)>[];
    final outgoing = List.generate(ids.length, (_) => <int>[]);
    final incoming = List.generate(ids.length, (_) => <int>[]);
    for (var i = 0; i < links.length; i++) {
      final s = indexOf[links[i].source];
      final t = indexOf[links[i].target];
      ends.add((s ?? -1, t ?? -1));
      if (s == null || t == null || s == t) continue;
      outgoing[s].add(i);
      incoming[t].add(i);
    }

    // Column assignment: longest path from a source. The pass count is capped
    // at the node count so a cyclic diagram — which a Sankey should not have,
    // but nothing stops an author writing — terminates instead of spinning.
    final depth = List<int>.filled(ids.length, 0);
    for (var pass = 0; pass < ids.length; pass++) {
      var changed = false;
      for (var i = 0; i < links.length; i++) {
        final (s, t) = ends[i];
        if (s < 0 || t < 0 || s == t) continue;
        if (depth[t] < depth[s] + 1) {
          depth[t] = depth[s] + 1;
          changed = true;
        }
      }
      if (!changed) break;
    }

    // A cycle keeps the relaxation above raising depths until the pass cap
    // stops it, which scatters three nodes across ten columns. Renumbering the
    // depths that are actually occupied to 0, 1, 2 … closes those gaps, and
    // does no harm to an acyclic diagram, which has none.
    final occupied = depth.toSet().toList()..sort();
    final rank = <int, int>{};
    for (var i = 0; i < occupied.length; i++) {
      rank[occupied[i]] = i;
    }
    for (var i = 0; i < depth.length; i++) {
      depth[i] = rank[depth[i]]!;
    }

    var maxDepth = 0;
    for (final d in depth) {
      maxDepth = math.max(maxDepth, d);
    }
    // Anything with nothing flowing out of it is a sink, and sinks line up on
    // the right edge — d3-sankey calls this "justify" alignment and it is what
    // mermaid renders.
    for (var i = 0; i < ids.length; i++) {
      if (outgoing[i].isEmpty) depth[i] = maxDepth;
    }

    final value = List<double>.filled(ids.length, 0);
    for (var i = 0; i < ids.length; i++) {
      var out = 0.0;
      for (final li in outgoing[i]) {
        out += links[li].value;
      }
      var into = 0.0;
      for (final li in incoming[i]) {
        into += links[li].value;
      }
      value[i] = math.max(out, into);
    }

    final layers = List.generate(maxDepth + 1, (_) => <int>[]);
    for (var i = 0; i < ids.length; i++) {
      layers[depth[i]].add(i);
    }

    var maxLayerValue = 0.0;
    var maxLayerCount = 1;
    for (final layer in layers) {
      var sum = 0.0;
      for (final n in layer) {
        sum += value[n];
      }
      maxLayerValue = math.max(maxLayerValue, sum);
      maxLayerCount = math.max(maxLayerCount, layer.length);
    }

    final usable = math.max(
      bandHeight - nodePadding * (maxLayerCount - 1),
      40.0,
    );
    final scale = maxLayerValue > 0 ? usable / maxLayerValue : 1.0;

    _orderLayers(layers, links, ends, incoming, outgoing, ids.length, maxDepth);

    // Column heights differ; centring them reads far better than hanging every
    // column from the top.
    final layerHeights = <double>[];
    for (final layer in layers) {
      var h = 0.0;
      for (var k = 0; k < layer.length; k++) {
        h += math.max(value[layer[k]] * scale, 2.0);
        if (k > 0) h += nodePadding;
      }
      layerHeights.add(h);
    }
    var bandUsed = 0.0;
    for (final h in layerHeights) {
      bandUsed = math.max(bandUsed, h);
    }

    final gutter = labelGutter;
    final firstLeft = padding + gutter;
    final span = availableWidth - padding * 2 - gutter * 2 - nodeWidth;
    final layerGap = maxDepth > 0 ? math.max(span / maxDepth, 70.0) : 0.0;

    final byIndex = List<SankeyNodeLayout?>.filled(ids.length, null);
    final nodeLayouts = <SankeyNodeLayout>[];
    final bandTop = padding + titleHeight;
    for (var d = 0; d <= maxDepth; d++) {
      var y = bandTop + (bandUsed - layerHeights[d]) / 2;
      for (final n in layers[d]) {
        final h = math.max(value[n] * scale, 2.0);
        final placed = SankeyNodeLayout(
          id: ids[n],
          index: n,
          layer: d,
          value: value[n],
          left: firstLeft + layerGap * d,
          top: y,
          width: nodeWidth,
          height: h,
        );
        byIndex[n] = placed;
        nodeLayouts.add(placed);
        y += h + nodePadding;
      }
    }

    final linkLayouts = _placeLinks(
      links,
      ends,
      incoming,
      outgoing,
      byIndex,
      scale,
    );

    return SankeyLayoutResult(
      width: firstLeft + layerGap * maxDepth + nodeWidth + gutter + padding,
      height: bandTop + bandUsed + padding,
      nodes: nodeLayouts,
      links: linkLayouts,
      labelGutter: gutter,
    );
  }

  /// Reduces ribbon crossings by repeatedly sorting each column on the average
  /// position of the nodes it connects to in the column before (or after).
  static void _orderLayers(
    List<List<int>> layers,
    List<SankeyLink> links,
    List<(int, int)> ends,
    List<List<int>> incoming,
    List<List<int>> outgoing,
    int nodeCount,
    int maxDepth,
  ) {
    final position = List<int>.filled(nodeCount, 0);
    void reindex() {
      for (final layer in layers) {
        for (var k = 0; k < layer.length; k++) {
          position[layer[k]] = k;
        }
      }
    }

    reindex();
    for (var sweep = 0; sweep < 4; sweep++) {
      final forward = sweep.isEven;
      for (var step = 0; step <= maxDepth; step++) {
        final d = forward ? step : maxDepth - step;
        if (forward && d == 0) continue;
        if (!forward && d == maxDepth) continue;

        final layer = layers[d];
        final bary = <int, double>{};
        for (final n in layer) {
          final related = forward ? incoming[n] : outgoing[n];
          if (related.isEmpty) {
            bary[n] = position[n].toDouble();
            continue;
          }
          var sum = 0.0;
          var weight = 0.0;
          for (final li in related) {
            final other = forward ? ends[li].$1 : ends[li].$2;
            if (other < 0) continue;
            final w = math.max(links[li].value, 0.0001);
            sum += position[other] * w;
            weight += w;
          }
          bary[n] = weight > 0 ? sum / weight : position[n].toDouble();
        }
        layer.sort((a, b) => bary[a]!.compareTo(bary[b]!));
        reindex();
      }
    }
  }

  static List<SankeyLinkLayout> _placeLinks(
    List<SankeyLink> links,
    List<(int, int)> ends,
    List<List<int>> incoming,
    List<List<int>> outgoing,
    List<SankeyNodeLayout?> byIndex,
    double scale,
  ) {
    double topOf(int node) => byIndex[node]?.top ?? 0;

    final y0 = List<double>.filled(links.length, 0);
    final y1 = List<double>.filled(links.length, 0);
    final thickness = List<double>.filled(links.length, 0);

    for (var i = 0; i < byIndex.length; i++) {
      final node = byIndex[i];
      if (node == null) continue;

      // Ribbons leave a bar in the vertical order of where they land, and
      // arrive in the order of where they came from; that is what keeps the
      // bundle from folding over itself.
      outgoing[i].sort(
        (a, b) => topOf(ends[a].$2).compareTo(topOf(ends[b].$2)),
      );
      incoming[i].sort(
        (a, b) => topOf(ends[a].$1).compareTo(topOf(ends[b].$1)),
      );

      var offset = node.top;
      for (final li in outgoing[i]) {
        final t = math.max(links[li].value * scale, 1.0);
        thickness[li] = t;
        y0[li] = offset + t / 2;
        offset += t;
      }
      offset = node.top;
      for (final li in incoming[i]) {
        final t = math.max(links[li].value * scale, 1.0);
        y1[li] = offset + t / 2;
        offset += t;
      }
    }

    final result = <SankeyLinkLayout>[];
    for (var i = 0; i < links.length; i++) {
      final (s, t) = ends[i];
      if (s < 0 || t < 0 || s == t) continue;
      final from = byIndex[s];
      final to = byIndex[t];
      if (from == null || to == null) continue;
      result.add(
        SankeyLinkLayout(
          link: links[i],
          colorIndex: s,
          x0: from.right,
          y0: y0[i],
          x1: to.left,
          y1: y1[i],
          thickness: thickness[i],
        ),
      );
    }
    // Thick ribbons first so the thin ones stay visible on top of them.
    result.sort((a, b) => b.thickness.compareTo(a.thickness));
    return result;
  }
}

/// Colours used when drawing a Sankey diagram.
class SankeyColors {
  SankeyColors._();

  /// Bar colours, cycled by node order.
  static const List<int> palette = [
    0xFF4E79A7,
    0xFFF28E2B,
    0xFFE15759,
    0xFF76B7B2,
    0xFF59A14F,
    0xFFEDC948,
    0xFFB07AA1,
    0xFFFF9DA7,
    0xFF9C755F,
    0xFFBAB0AC,
  ];

  /// Label colour.
  static const int textColor = 0xFF212121;

  /// Colour of the number printed under a label.
  static const int valueColor = 0xFF6B6B6B;

  /// Colour for a node whose index falls outside [palette].
  static int forIndex(int index) => palette[index % palette.length];
}
