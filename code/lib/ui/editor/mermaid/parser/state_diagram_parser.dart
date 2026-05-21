import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';

class StateDiagramParser {
  final Map<String, MermaidNode> _nodes = {};
  final List<MermaidEdge> _edges = [];

  MermaidDiagramData? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    final contentLines = lines.length > 1 ? lines.sublist(1) : <String>[];

    for (final line in contentLines) {
      _parseLine(line.trim());
    }

    if (_nodes.isEmpty) return null;

    return MermaidDiagramData(
      type: DiagramType.stateDiagram,
      nodes: _nodes.values.toList(),
      edges: _edges,
      direction: DiagramDirection.topToBottom,
    );
  }

  void _parseLine(String line) {
    if (line.isEmpty) return;

    final transitionMatch = RegExp(
      r'^(.+?)\s*-->\s*(.+?)(?:\s*:\s*(.+))?$',
    ).firstMatch(line);

    if (transitionMatch != null) {
      final fromRaw = transitionMatch.group(1)!.trim();
      final toRaw = transitionMatch.group(2)!.trim();
      final label = transitionMatch.group(3)?.trim();

      final fromId = _normalizeId(fromRaw);
      final toId = _normalizeId(toRaw);

      _ensureNode(fromId, fromRaw);
      _ensureNode(toId, toRaw);

      _edges.add(MermaidEdge(
        from: fromId,
        to: toId,
        label: label,
      ));
    }
  }

  String _normalizeId(String raw) {
    if (raw == '[*]') return '__start_end__';
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  void _ensureNode(String id, String raw) {
    if (_nodes.containsKey(id)) return;
    final label = raw == '[*]' ? '●' : raw;
    final shape = raw == '[*]' ? NodeShape.circle : NodeShape.roundedRect;
    _nodes[id] = MermaidNode(id: id, label: label, shape: shape);
  }
}
