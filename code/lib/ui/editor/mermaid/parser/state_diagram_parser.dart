import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';
import 'identifier.dart';

/// Parser for Mermaid state diagrams (stateDiagram / stateDiagram-v2)
///
/// Supports:
/// - `[*] --> state` (start) and `state --> [*]` (end) special markers
/// - `state1 --> state2: label` transitions with optional labels
/// - Self-loops (`state --> state`)
/// - `state "description" as id`, which is how a state gets a readable name
/// - `state id <<choice>>` / `<<fork>>` / `<<join>>`
/// - `state name { … }` composite states, reported as subgraphs
/// - `direction LR`
///
/// Notes (`note right of A : …`) are read and discarded; drawing them is not
/// implemented.
class StateDiagramParser {
  static const _startId = '__start__';
  static const _endId = '__end__';

  final Map<String, MermaidNode> _nodes = {};
  final List<MermaidEdge> _edges = [];
  final List<Subgraph> _subgraphs = [];

  /// Nesting depth of each entry in [_subgraphs], used to order them.
  final List<int> _subgraphDepths = [];

  /// Composite states whose closing brace has not been read yet.
  final List<_OpenComposite> _open = [];

  DiagramDirection _direction = DiagramDirection.topToBottom;

  /// `state "Sitting still" as idle`
  static final _aliasRe =
      RegExp(r'^state\s+"([^"]*)"\s+as\s+(\S+)$', caseSensitive: false);

  /// `state choice_point <<choice>>`
  static final _stereotypeRe = RegExp(
    r'^state\s+(\S+)\s*<<\s*(choice|fork|join|end)\s*>>$',
    caseSensitive: false,
  );

  /// `state Composite {` — the brace may be on the same line.
  static final _compositeRe = RegExp(
    r'^state\s+(?:"([^"]*)"\s+as\s+(\S+)|(\S+))\s*\{$',
    caseSensitive: false,
  );

  /// `direction LR`
  static final _directionRe =
      RegExp(r'^direction\s+(TB|TD|BT|LR|RL)$', caseSensitive: false);

  MermaidDiagramData? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    _nodes.clear();
    _edges.clear();
    _subgraphs.clear();
    _subgraphDepths.clear();
    _open.clear();
    _direction = DiagramDirection.topToBottom;

    final contentLines = lines.length > 1 ? lines.sublist(1) : <String>[];

    for (final line in contentLines) {
      _parseLine(line.trim());
    }
    // A composite whose closing brace never arrived still groups what it got.
    while (_open.isNotEmpty) {
      _closeComposite();
    }
    _sortSubgraphsOutermostFirst();

    if (_nodes.isEmpty) return null;

    return MermaidDiagramData(
      type: DiagramType.flowchart,
      nodes: _nodes.values.toList(),
      edges: _edges,
      subgraphs: List.of(_subgraphs),
      direction: _direction,
    );
  }

  void _parseLine(String line) {
    if (line.isEmpty) return;
    if (line.startsWith('note ')) return;
    if (line.startsWith('%%')) return;
    // The separator between two concurrent regions of a composite state.
    if (line == '--') return;

    if (line == '}') {
      _closeComposite();
      return;
    }

    final direction = _directionRe.firstMatch(line);
    if (direction != null) {
      _direction = _directionFor(direction.group(1)!.toUpperCase());
      return;
    }

    final composite = _compositeRe.firstMatch(line);
    if (composite != null) {
      final id = composite.group(2) ?? composite.group(3)!;
      _open.add(
        _OpenComposite(id: _normalizeId(id), label: composite.group(1) ?? id),
      );
      return;
    }

    final stereotype = _stereotypeRe.firstMatch(line);
    if (stereotype != null) {
      final id = _normalizeId(stereotype.group(1)!);
      _nodes[id] = MermaidNode(
        id: id,
        label: '',
        shape: _shapeForStereotype(stereotype.group(2)!.toLowerCase()),
      );
      _claim(id);
      return;
    }

    final alias = _aliasRe.firstMatch(line);
    if (alias != null) {
      final id = _normalizeId(alias.group(2)!);
      // The description is the whole point of this form; keeping the alias as
      // the label threw it away.
      _nodes[id] = MermaidNode(
        id: id,
        label: alias.group(1)!,
        shape: NodeShape.stadium,
      );
      _claim(id);
      return;
    }

    final m =
        RegExp(r'^(.+?)\s*-->\s*([^:]+?)(?:\s*:\s*(.+))?$').firstMatch(line);
    if (m == null) return;

    final fromRaw = m.group(1)!.trim();
    final toRaw = m.group(2)!.trim();
    final label = m.group(3)?.trim();

    final fromId = _registerNode(fromRaw, isFrom: true);
    final toId = _registerNode(toRaw, isFrom: false);

    _edges.add(MermaidEdge(
      from: fromId,
      to: toId,
      label: label,
      arrowType: ArrowType.arrow,
    ));
  }

  /// Returns the unique node ID for the given raw token.
  /// All `[*]` as source share one start node; all `[*]` as target share one end node.
  String _registerNode(String raw, {required bool isFrom}) {
    if (raw == '[*]') {
      // Inside a composite, `[*]` is that composite's own entry or exit point,
      // so it gets an id of its own rather than joining the diagram's.
      final scope = _open.isEmpty ? '' : '_${_open.last.id}';
      final id = (isFrom ? _startId : _endId) + scope;
      _nodes.putIfAbsent(
        id,
        () => MermaidNode(id: id, label: '', shape: NodeShape.circle),
      );
      _claim(id);
      return id;
    }

    final id = _normalizeId(raw);
    _nodes.putIfAbsent(
      id,
      () => MermaidNode(id: id, label: raw, shape: NodeShape.stadium),
    );
    _claim(id);
    return id;
  }

  /// Records [id] as belonging to the composite currently open, if any.
  void _claim(String id) {
    if (_open.isEmpty) return;
    final open = _open.last;
    if (!open.nodeIds.contains(id)) open.nodeIds.add(id);
  }

  void _closeComposite() {
    if (_open.isEmpty) return;

    final closed = _open.removeLast();
    _subgraphs.add(
      Subgraph(
        id: closed.id,
        label: closed.label,
        nodeIds: List.of(closed.nodeIds),
      ),
    );
    // `_open.length` after the removal is how deep this one sat.
    _subgraphDepths.add(_open.length);
    // A composite nested in another belongs to it as well, so the outer box
    // stretches around the inner one.
    for (final id in closed.nodeIds) {
      _claim(id);
    }
  }

  /// Puts the outermost composites first.
  ///
  /// The subgraph box is drawn with an opaque fill, so an outer box painted
  /// after an inner one covers it completely — label and all. Composites close
  /// innermost-first, which is exactly the wrong order. A stable sort by depth
  /// fixes it while leaving siblings in the order they were written.
  void _sortSubgraphsOutermostFirst() {
    final indices = List<int>.generate(_subgraphs.length, (i) => i);
    indices.sort((a, b) {
      final byDepth = _subgraphDepths[a].compareTo(_subgraphDepths[b]);
      return byDepth != 0 ? byDepth : a.compareTo(b);
    });

    final ordered = [for (final i in indices) _subgraphs[i]];
    _subgraphs
      ..clear()
      ..addAll(ordered);
  }

  NodeShape _shapeForStereotype(String keyword) => switch (keyword) {
    'choice' => NodeShape.diamond,
    'end' => NodeShape.doubleCircle,
    // A fork or a join is a thick bar in mermaid; there is no bar shape here,
    // so it stays a rectangle rather than being drawn as something it is not.
    _ => NodeShape.rectangle,
  };

  DiagramDirection _directionFor(String keyword) => switch (keyword) {
    'BT' => DiagramDirection.bottomToTop,
    'LR' => DiagramDirection.leftToRight,
    'RL' => DiagramDirection.rightToLeft,
    _ => DiagramDirection.topToBottom,
  };

  String _normalizeId(String raw) {
    return normalizeMermaidId(raw.replaceAll(RegExp(r'[\s*]+$'), ''));
  }
}

/// A composite state whose closing brace has not been read yet.
class _OpenComposite {
  _OpenComposite({required this.id, required this.label});

  final String id;
  final String label;
  final List<String> nodeIds = [];
}
