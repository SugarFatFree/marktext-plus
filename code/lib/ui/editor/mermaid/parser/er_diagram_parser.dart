import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/er_diagram.dart';
import '../models/node.dart';

/// Parser for Mermaid entity-relationship diagrams (`erDiagram`).
///
/// Supports:
/// - `A ||--o{ B : label` relationships in all sixteen cardinality
///   combinations, with `--` (identifying) or `..` (non-identifying) lines
/// - `ENTITY { type name PK "comment" }` attribute blocks
/// - `ENTITY["Display name"]` aliases
class ErDiagramParser {
  /// Creates an ER diagram parser.
  ErDiagramParser();

  /// `LEFT lcard(--|..)rcard RIGHT : label`
  ///
  /// Left tokens are `|o || }o }|`; right tokens mirror them as `o| || o{ |{`.
  ///
  /// An entity is an identifier optionally followed by a bracketed alias, and
  /// that alias may contain spaces — `\S+` would stop at the first one and
  /// fail the whole line.
  static final _relationRe = RegExp(
    r'^([^\s\[\]]+(?:\[[^\]]*\])?)'
    r'\s+([|}][o|])(--|\.\.)([o|][|{])\s+'
    r'([^\s\[\]]+(?:\[[^\]]*\])?)'
    r'\s*(?::\s*(.*))?$',
  );

  /// `type name [PK[,FK]] ["comment"]`
  static final _attributeRe = RegExp(
    r'^(\S+)\s+(\S+)'
    r'(?:\s+((?:PK|FK|UK)(?:\s*,\s*(?:PK|FK|UK))*))?'
    r'\s*(?:"([^"]*)")?\s*$',
  );

  final Map<String, _EntityBuilder> _entities = {};
  final List<MermaidEdge> _edges = [];
  String? _title;

  /// Parses the cleaned lines of an ER diagram.
  ///
  /// The first line is the `erDiagram` header and is skipped.
  (MermaidDiagramData, ErDiagramData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    final body = lines.length > 1 ? lines.sublist(1) : const <String>[];
    String? openEntityId;

    for (final raw in body) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (openEntityId != null) {
        if (line.startsWith('}')) {
          openEntityId = null;
          continue;
        }
        _parseAttribute(openEntityId, line);
        continue;
      }

      if (line.toLowerCase().startsWith('title ')) {
        _title = line.substring('title '.length).trim();
        continue;
      }

      if (_parseRelation(line)) continue;

      // `ENTITY {` opens an attribute block; `ENTITY` alone just declares it.
      if (line.endsWith('{')) {
        final declaration = line.substring(0, line.length - 1).trim();
        if (declaration.isEmpty) continue;
        openEntityId = _declare(declaration).id;
        continue;
      }

      if (!line.contains(' ')) _declare(line);
    }

    if (_entities.isEmpty) return null;

    final entities = _entities.values.map((b) => b.build()).toList();

    final nodes = entities
        .map((e) => MermaidNode(
              id: e.id,
              label: e.displayName,
              shape: NodeShape.rectangle,
            ))
        .toList();

    return (
      MermaidDiagramData(
        type: DiagramType.erDiagram,
        nodes: nodes,
        edges: _edges,
        title: _title,
      ),
      ErDiagramData(entities: entities, title: _title),
    );
  }

  bool _parseRelation(String line) {
    final match = _relationRe.firstMatch(line);
    if (match == null) return false;

    final left = _declare(match.group(1)!);
    final leftToken = match.group(2)!;
    final connector = match.group(3)!;
    final rightToken = match.group(4)!;
    final right = _declare(match.group(5)!);
    final label = match.group(6)?.trim();

    _edges.add(MermaidEdge(
      from: left.id,
      to: right.id,
      label: (label == null || label.isEmpty) ? null : _unquote(label),
      startArrowType: _headForLeft(leftToken),
      arrowType: _headForRight(rightToken),
      lineType: connector == '..' ? LineType.dotted : LineType.solid,
    ));
    return true;
  }

  /// Left-hand tokens read outward from the entity: `|o || }o }|`.
  ArrowType _headForLeft(String token) {
    switch (token) {
      case '|o':
        return ArrowType.erZeroOrOne;
      case '||':
        return ArrowType.erExactlyOne;
      case '}o':
        return ArrowType.erZeroOrMore;
      case '}|':
        return ArrowType.erOneOrMore;
      default:
        return ArrowType.none;
    }
  }

  /// Right-hand tokens are the mirror image: `o| || o{ |{`.
  ArrowType _headForRight(String token) {
    switch (token) {
      case 'o|':
        return ArrowType.erZeroOrOne;
      case '||':
        return ArrowType.erExactlyOne;
      case 'o{':
        return ArrowType.erZeroOrMore;
      case '|{':
        return ArrowType.erOneOrMore;
      default:
        return ArrowType.none;
    }
  }

  void _parseAttribute(String entityId, String line) {
    var text = line;
    if (text.endsWith(',')) text = text.substring(0, text.length - 1).trim();
    if (text.isEmpty) return;

    final match = _attributeRe.firstMatch(text);
    if (match == null) return;

    final keys = match.group(3);
    _entities[entityId]?.attributes.add(ErAttribute(
          type: match.group(1)!,
          name: match.group(2)!,
          keys: keys == null
              ? const []
              : keys.split(',').map((k) => k.trim()).toList(),
          comment: match.group(4),
        ));
  }

  /// Registers an entity, handling the `NAME["Alias"]` form.
  _EntityBuilder _declare(String raw) {
    var name = raw.trim();
    String? alias;

    final aliasMatch = RegExp(r'^(.+?)\[\s*"?(.*?)"?\s*\]$').firstMatch(name);
    if (aliasMatch != null) {
      name = aliasMatch.group(1)!.trim();
      alias = aliasMatch.group(2);
    }

    final id = _normalizeId(name);
    final builder = _entities.putIfAbsent(
      id,
      () => _EntityBuilder(id: id, name: name),
    );
    if (alias != null && alias.isNotEmpty) builder.alias = alias;
    return builder;
  }

  String _unquote(String text) {
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  String _normalizeId(String raw) {
    return raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-一-龥]'), '_');
  }
}

/// Mutable accumulator turned into an immutable [ErEntity] at the end.
class _EntityBuilder {
  _EntityBuilder({required this.id, required this.name});

  final String id;
  final String name;
  String? alias;
  final List<ErAttribute> attributes = [];

  ErEntity build() {
    return ErEntity(
      id: id,
      name: name,
      attributes: List.unmodifiable(attributes),
      alias: alias,
    );
  }
}
