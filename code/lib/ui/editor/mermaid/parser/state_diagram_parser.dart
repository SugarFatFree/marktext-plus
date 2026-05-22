import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';

/// Parser for Mermaid state diagrams (stateDiagram / stateDiagram-v2)
///
/// Supports:
/// - `[*] --> state` (start) and `state --> [*]` (end) special markers
/// - `state1 --> state2: label` transitions with optional labels
/// - Self-loops (`state --> state`)
/// - Multiple [*] occurrences are treated as separate start/end nodes
class StateDiagramParser {
  final Map<String, MermaidNode> _nodes = {};
  final List<MermaidEdge> _edges = [];
  int _startCount = 0;
  int _endCount = 0;

  MermaidDiagramData? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    final contentLines = lines.length > 1 ? lines.sublist(1) : <String>[];

    for (final line in contentLines) {
      _parseLine(line.trim());
    }

    if (_nodes.isEmpty) return null;

    return MermaidDiagramData(
      type: DiagramType.flowchart,
      nodes: _nodes.values.toList(),
      edges: _edges,
      direction: DiagramDirection.topToBottom,
    );
  }

  void _parseLine(String line) {
    if (line.isEmpty) return;
    if (line.startsWith('note ')) return; // Skip notes for now
    if (line.startsWith('%%')) return; // Skip comments

    // Parse: state1 --> state2: optional label
    final m = RegExp(r'^(.+?)\s*-->\s*([^:]+?)(?:\s*:\s*(.+))?$').firstMatch(line);
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
  /// Each `[*]` instance becomes a separate start/end node.
  String _registerNode(String raw, {required bool isFrom}) {
    if (raw == '[*]') {
      // Start state when used as source, end state when used as target
      final id = isFrom ? '__start_${_startCount++}__' : '__end_${_endCount++}__';
      _nodes[id] = MermaidNode(
        id: id,
        label: '',
        shape: NodeShape.circle,
      );
      return id;
    }

    final id = _normalizeId(raw);
    _nodes.putIfAbsent(
      id,
      () => MermaidNode(id: id, label: raw, shape: NodeShape.stadium),
    );
    return id;
  }

  String _normalizeId(String raw) {
    // Strip trailing modifier markers like '*' that Mermaid uses for emphasis
    final cleaned = raw.replaceAll(RegExp(r'[\s*]+$'), '').trim();
    return cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9_一-龥]'), '_');
  }
}
