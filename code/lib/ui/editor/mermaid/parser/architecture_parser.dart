import '../models/architecture.dart';
import '../models/diagram.dart';

/// Parses mermaid `architecture-beta` diagrams.
///
/// ```
/// architecture-beta
///     group api(cloud)[API]
///
///     service db(database)[Database] in api
///     service server(server)[Server] in api
///     junction j1 in api
///
///     db:L -- R:server
///     server:T --> B:j1
/// ```
class ArchitectureParser {
  /// Creates an architecture parser.
  const ArchitectureParser();

  // `group id(icon)[Label] in parent` — the icon, the label, and the `in`
  // clause are each optional.
  static final _groupRe = RegExp(
    r'^group\s+([A-Za-z0-9_-]+)'
    r'(?:\(([^)]*)\))?'
    r'(?:\[([^\]]*)\])?'
    r'(?:\s+in\s+([A-Za-z0-9_-]+))?\s*$',
  );
  static final _serviceRe = RegExp(
    r'^service\s+([A-Za-z0-9_-]+)'
    r'(?:\(([^)]*)\))?'
    r'(?:\[([^\]]*)\])?'
    r'(?:\s+in\s+([A-Za-z0-9_-]+))?\s*$',
  );
  static final _junctionRe = RegExp(
    r'^junction\s+([A-Za-z0-9_-]+)'
    r'(?:\s+in\s+([A-Za-z0-9_-]+))?\s*$',
  );
  // `db:L -- R:server`, with `-->`, `<--`, `<-->` for the arrowed forms and an
  // optional `{group}` on either id.
  static final _edgeRe = RegExp(
    r'^([A-Za-z0-9_-]+)(\{group\})?\s*:\s*([LRTB])'
    r'\s*(<?-{1,2}>?)\s*'
    r'([LRTB])\s*:\s*([A-Za-z0-9_-]+)(\{group\})?\s*$',
    caseSensitive: false,
  );

  /// Returns the diagram and its data, or null if nothing could be read.
  (MermaidDiagramData, ArchitectureDiagramData)? parse(List<String> lines) {
    String? title;
    final nodes = <ArchNode>[];
    final groups = <ArchGroup>[];
    final edges = <ArchEdge>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('%%')) continue;
      if (line.startsWith('architecture')) continue;

      if (line.toLowerCase().startsWith('title ')) {
        title = line.substring(6).trim();
        continue;
      }

      final group = _groupRe.firstMatch(line);
      if (group != null) {
        final id = group.group(1)!;
        groups.add(ArchGroup(
          id: id,
          label: _orId(group.group(3), id),
          icon: _blankToNull(group.group(2)),
          parent: group.group(4),
        ));
        continue;
      }

      final service = _serviceRe.firstMatch(line);
      if (service != null) {
        final id = service.group(1)!;
        nodes.add(ArchNode(
          id: id,
          label: _orId(service.group(3), id),
          icon: _blankToNull(service.group(2)),
          parent: service.group(4),
        ));
        continue;
      }

      final junction = _junctionRe.firstMatch(line);
      if (junction != null) {
        final id = junction.group(1)!;
        nodes.add(ArchNode(
          id: id,
          label: '',
          parent: junction.group(2),
          isJunction: true,
        ));
        continue;
      }

      final edge = _edgeRe.firstMatch(line);
      if (edge != null) {
        final arrow = edge.group(4)!;
        edges.add(ArchEdge(
          fromId: edge.group(1)!,
          fromIsGroup: edge.group(2) != null,
          fromSide: ArchSide.parse(edge.group(3)!)!,
          toSide: ArchSide.parse(edge.group(5)!)!,
          toId: edge.group(6)!,
          toIsGroup: edge.group(7) != null,
          arrowAtFrom: arrow.startsWith('<'),
          arrowAtTo: arrow.endsWith('>'),
        ));
      }
    }

    if (nodes.isEmpty && groups.isEmpty) return null;

    return (
      MermaidDiagramData(
        type: DiagramType.architecture,
        nodes: const [],
        edges: const [],
        title: title,
      ),
      ArchitectureDiagramData(
        nodes: nodes,
        groups: groups,
        edges: edges,
        title: title,
      ),
    );
  }

  static String? _blankToNull(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// An element written without a label is drawn with its id, which is what
  /// mermaid does — an unlabelled box is worse than a terse one.
  static String _orId(String? label, String id) {
    final trimmed = label?.trim();
    return trimmed == null || trimmed.isEmpty ? id : trimmed;
  }
}
