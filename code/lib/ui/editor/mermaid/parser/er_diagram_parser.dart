import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/er_diagram.dart';
import '../models/node.dart';
import 'identifier.dart';
import 'label.dart';

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

  /// The words mermaid accepts in place of the cardinality symbols.
  ///
  /// `PERSON one or more to ADDRESS : has` is as valid as `PERSON }|--|{
  /// ADDRESS : has`, and reading only the symbols meant a diagram written in
  /// words did not fail one relation — it failed to parse at all, and the
  /// whole thing fell back to a grey code block.
  ///
  /// Longest first: `zero or one` has to be tried before `one`, or the
  /// leading `zero or` is left behind as part of the entity's name.
  static const _cardinalityWords = <(String, String, String)>[
    // (words, left symbol, right symbol)
    ('zero or one', '|o', 'o|'),
    ('one or zero', '|o', 'o|'),
    ('zero or more', '}o', 'o{'),
    ('zero or many', '}o', 'o{'),
    ('one or more', '}|', '|{'),
    ('one or many', '}|', '|{'),
    ('only one', '||', '||'),
    ('one', '||', '||'),
  ];

  /// Rewrites the spelled-out form of a relation into the symbolic one.
  ///
  /// Normalising rather than parsing twice: the symbol path already reads all
  /// thirty-two combinations correctly, and a second implementation of the
  /// same grammar is how the two come apart later.
  static String? _fromWords(String line) {
    final match = RegExp(
      r'^(.+?)\s+(' +
          _cardinalityWords.map((c) => c.$1).join('|') +
          r')\s+(optionally to|to)\s+(' +
          _cardinalityWords.map((c) => c.$1).join('|') +
          r')\s+(.+?)\s*(:\s*.*)?$',
      caseSensitive: false,
    ).firstMatch(line);
    if (match == null) return null;

    String? left;
    String? right;
    for (final entry in _cardinalityWords) {
      if (entry.$1 == match.group(2)!.toLowerCase()) left = entry.$2;
      if (entry.$1 == match.group(4)!.toLowerCase()) right = entry.$3;
    }
    if (left == null || right == null) return null;

    // `to` identifies, `optionally to` does not — the same distinction the
    // `--` and `..` connectors carry.
    final connector =
        match.group(3)!.toLowerCase() == 'to' ? '--' : '..';
    return '${match.group(1)} $left$connector$right '
        '${match.group(5)}${match.group(6) ?? ''}';
  }

  bool _parseRelation(String line) {
    final match = _relationRe.firstMatch(_fromWords(line) ?? line);
    if (match == null) return false;

    final left = _declare(match.group(1)!);
    final leftToken = match.group(2)!;
    final connector = match.group(3)!;
    final rightToken = match.group(4)!;
    final right = _declare(match.group(5)!);
    final label = cleanLabel(match.group(6)).trim();

    _edges.add(MermaidEdge(
      from: left.id,
      to: right.id,
      // Empty rather than null: the painter draws a label background
      // wherever there is one, and an empty label left a box on the line.
      label: label.isEmpty ? null : label,
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

    // Neither part may hold a bracket. With `(.+?)` and `(.*?)` the two lazy
    // runs grew against each other, and a line of 30,000 `[` took
    // twenty-seven seconds to reject.
    final aliasMatch =
        RegExp(r'^([^\[\]]+)\[\s*"?([^\]]*?)"?\s*\]$').firstMatch(name);
    if (aliasMatch != null) {
      name = cleanLabel(aliasMatch.group(1)!).trim();
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

  String _normalizeId(String raw) {
    return normalizeMermaidId(raw, keepDash: true);
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
