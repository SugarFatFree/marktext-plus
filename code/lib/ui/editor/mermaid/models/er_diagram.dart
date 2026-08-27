/// Cardinality at one end of an entity-relationship line.
///
/// Mermaid writes these as a two-character token per side — `|o`, `||`, `}o`,
/// `}|` on the left and their mirrors `o|`, `||`, `o{`, `|{` on the right.
enum ErCardinality {
  /// `|o` / `o|` — zero or one.
  zeroOrOne,

  /// `||` — exactly one.
  exactlyOne,

  /// `}o` / `o{` — zero or more.
  zeroOrMore,

  /// `}|` / `|{` — one or more.
  oneOrMore,
}

/// One attribute row inside an entity box.
class ErAttribute {
  /// Creates an attribute.
  const ErAttribute({
    required this.type,
    required this.name,
    this.keys = const [],
    this.comment,
  });

  /// Declared type, e.g. `string`.
  final String type;

  /// Attribute name.
  final String name;

  /// Key markers: `PK`, `FK`, `UK`. Mermaid allows several, comma separated.
  final List<String> keys;

  /// Quoted trailing comment, if any.
  final String? comment;

  /// The row as it should be painted.
  String get displayText {
    final buffer = StringBuffer('$type $name');
    if (keys.isNotEmpty) buffer.write(' ${keys.join(',')}');
    return buffer.toString();
  }
}

/// One entity box in an ER diagram.
class ErEntity {
  /// Creates an entity.
  const ErEntity({
    required this.id,
    required this.name,
    this.attributes = const [],
    this.alias,
  });

  /// Identifier used by relationship lines and the layout engine.
  final String id;

  /// Entity name as written.
  final String name;

  /// Attribute rows, in declaration order.
  final List<ErAttribute> attributes;

  /// Display alias from `ENTITY["Label"]`.
  final String? alias;

  /// Header text: the alias when present, otherwise the name.
  String get displayName => (alias != null && alias!.isNotEmpty) ? alias! : name;
}

/// Everything an ER painter needs beyond the generic node/edge graph.
class ErDiagramData {
  /// Creates ER diagram data.
  const ErDiagramData({required this.entities, this.title});

  /// All entities, in declaration order.
  final List<ErEntity> entities;

  /// Optional diagram title.
  final String? title;

  /// Looks up an entity by identifier.
  ErEntity? byId(String id) {
    for (final entity in entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }
}
