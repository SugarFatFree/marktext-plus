import '../models/class_diagram.dart';
import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';
import 'identifier.dart';

/// Parser for Mermaid class diagrams (`classDiagram`).
///
/// Supports:
/// - `class Name { ... }` blocks and the single-line `Name : +member` form
/// - Visibility sigils `+ - # ~`, plus the `*` (abstract) and `$` (static)
///   classifiers
/// - `<<interface>>` / `<<abstract>>` / `<<enumeration>>` annotations, both
///   inside a class body and as a standalone `<<interface>> Name` line
/// - All eight relationship kinds, written in either direction
/// - Cardinality labels (`Student "1" --> "1..*" Course`) and relation labels
/// - `note "text"` and `note for Class "text"`
/// - `direction TB|BT|LR|RL`
/// - Generics written with mermaid's tilde syntax (`List~int~` -> `List<int>`)
class ClassDiagramParser {
  /// Creates a class diagram parser.
  ClassDiagramParser();

  final Map<String, _ClassBuilder> _classes = {};
  final List<MermaidEdge> _edges = [];
  final List<String> _floatingNotes = [];
  DiagramDirection _direction = DiagramDirection.topToBottom;
  String? _title;

  /// Relationship tokens, longest first so that `<|--` is matched before `--`.
  static final List<_RelationPattern> _relationPatterns = [
    // Bidirectional / two-headed forms.
    _RelationPattern('<|--|>', ClassRelationType.inheritance,
        startHead: ArrowType.hollowTriangle, endHead: ArrowType.hollowTriangle),
    _RelationPattern('<-->', ClassRelationType.association,
        startHead: ArrowType.arrow, endHead: ArrowType.arrow),
    // Head on the left-hand side.
    _RelationPattern('<|..', ClassRelationType.realization,
        startHead: ArrowType.hollowTriangle, dashed: true),
    _RelationPattern('<|--', ClassRelationType.inheritance,
        startHead: ArrowType.hollowTriangle),
    _RelationPattern('<..', ClassRelationType.dependency,
        startHead: ArrowType.openArrow, dashed: true),
    _RelationPattern('<--', ClassRelationType.association,
        startHead: ArrowType.arrow),
    _RelationPattern('*--', ClassRelationType.composition,
        startHead: ArrowType.filledDiamond),
    _RelationPattern('o--', ClassRelationType.aggregation,
        startHead: ArrowType.hollowDiamond),
    // Head on the right-hand side.
    _RelationPattern('..|>', ClassRelationType.realization,
        endHead: ArrowType.hollowTriangle, dashed: true),
    _RelationPattern('--|>', ClassRelationType.inheritance,
        endHead: ArrowType.hollowTriangle),
    _RelationPattern('--*', ClassRelationType.composition,
        endHead: ArrowType.filledDiamond),
    _RelationPattern('--o', ClassRelationType.aggregation,
        endHead: ArrowType.hollowDiamond),
    _RelationPattern('..>', ClassRelationType.dependency,
        endHead: ArrowType.openArrow, dashed: true),
    _RelationPattern('-->', ClassRelationType.association,
        endHead: ArrowType.arrow),
    // Plain links, matched last.
    _RelationPattern('--', ClassRelationType.link),
    _RelationPattern('..', ClassRelationType.dashedLink, dashed: true),
  ];

  /// Parses the cleaned lines of a class diagram.
  ///
  /// The first line is the `classDiagram` header and is skipped.
  (MermaidDiagramData, ClassDiagramData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    final body = lines.length > 1 ? lines.sublist(1) : const <String>[];

    // Current `class X {` block being filled, if any.
    String? openClassId;

    for (final raw in body) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (openClassId != null) {
        if (line == '}' || line.startsWith('}')) {
          openClassId = null;
          continue;
        }
        _parseMemberLine(openClassId, line);
        continue;
      }

      if (_parseDirective(line)) continue;
      if (_parseNote(line)) continue;
      if (_parseStandaloneAnnotation(line)) continue;

      final opened = _parseClassDeclaration(line);
      if (opened != null) {
        // A non-null result means the declaration opened a `{` block.
        openClassId = opened.isEmpty ? null : opened;
        continue;
      }

      if (_parseRelation(line)) continue;

      // `Name : +member` shorthand.
      final colon = line.indexOf(':');
      if (colon > 0) {
        final target = _normalizeId(line.substring(0, colon).trim());
        if (target.isNotEmpty) {
          _ensureClass(target, line.substring(0, colon).trim());
          _parseMemberLine(target, line.substring(colon + 1).trim());
        }
      }
    }

    if (_classes.isEmpty) return null;

    final boxes = _classes.values.map((b) => b.build()).toList();

    final nodes = boxes
        .map((box) => MermaidNode(
              id: box.id,
              label: box.displayName,
              shape: NodeShape.rectangle,
              className: box.cssClass,
            ))
        .toList();

    final diagram = MermaidDiagramData(
      type: DiagramType.classDiagram,
      nodes: nodes,
      edges: _edges,
      direction: _direction,
      title: _title,
    );

    final classData = ClassDiagramData(
      classes: boxes,
      title: _title,
      notes: _floatingNotes,
    );

    return (diagram, classData);
  }

  // ---------------------------------------------------------------- directives

  bool _parseDirective(String line) {
    final lower = line.toLowerCase();

    if (lower.startsWith('direction ')) {
      switch (line.substring('direction '.length).trim().toUpperCase()) {
        case 'LR':
          _direction = DiagramDirection.leftToRight;
        case 'RL':
          _direction = DiagramDirection.rightToLeft;
        case 'BT':
          _direction = DiagramDirection.bottomToTop;
        default:
          _direction = DiagramDirection.topToBottom;
      }
      return true;
    }

    if (lower.startsWith('title ')) {
      _title = line.substring('title '.length).trim();
      return true;
    }

    // Interaction and styling directives we do not render yet, but which must
    // not fall through to the relationship/member parsers.
    for (final keyword in const [
      'click ',
      'link ',
      'callback ',
      'style ',
      'classdef ',
      'cssclass ',
      'namespace ',
    ]) {
      if (lower.startsWith(keyword)) return true;
    }

    return false;
  }

  bool _parseNote(String line) {
    final forMatch =
        RegExp(r'^note\s+for\s+(\S+)\s+"(.*)"$').firstMatch(line);
    if (forMatch != null) {
      final id = _normalizeId(forMatch.group(1)!);
      _ensureClass(id, forMatch.group(1)!).note = forMatch.group(2);
      return true;
    }

    final plain = RegExp(r'^note\s+"(.*)"$').firstMatch(line);
    if (plain != null) {
      _floatingNotes.add(plain.group(1)!);
      return true;
    }

    return false;
  }

  /// Handles the standalone `<<interface>> Shape` form.
  bool _parseStandaloneAnnotation(String line) {
    final match = RegExp(r'^<<\s*(.+?)\s*>>\s+(\S+)$').firstMatch(line);
    if (match == null) return false;
    final id = _normalizeId(match.group(2)!);
    _ensureClass(id, match.group(2)!).stereotype = match.group(1);
    return true;
  }

  // ------------------------------------------------------------------ classes

  /// Parses a `class Name`, `class Name {`, or `class Name["Label"] {` line.
  ///
  /// Returns the class id when the line opened a `{` block, an empty string
  /// when it declared a class without a block, and null when the line is not a
  /// class declaration at all.
  String? _parseClassDeclaration(String line) {
    if (!RegExp(r'^class\s').hasMatch(line)) return null;

    var rest = line.substring('class'.length).trim();
    final opensBlock = rest.endsWith('{');
    if (opensBlock) {
      rest = rest.substring(0, rest.length - 1).trim();
    }

    String? label;
    // `class A["Custom Label"]`
    final labelMatch = RegExp(r'^(.+?)\[\s*"(.*)"\s*\]$').firstMatch(rest);
    if (labelMatch != null) {
      rest = labelMatch.group(1)!.trim();
      label = labelMatch.group(2);
    }

    // `class A:::cssClass`
    String? cssClass;
    final cssIndex = rest.indexOf(':::');
    if (cssIndex != -1) {
      cssClass = rest.substring(cssIndex + 3).trim();
      rest = rest.substring(0, cssIndex).trim();
    }

    if (rest.isEmpty) return null;

    final id = _normalizeId(rest);
    final builder = _ensureClass(id, rest);
    if (label != null) builder.label = label;
    if (cssClass != null && cssClass.isNotEmpty) builder.cssClass = cssClass;

    return opensBlock ? id : '';
  }

  void _parseMemberLine(String classId, String line) {
    if (line.isEmpty) return;

    // Annotation inside a class body.
    final annotation = RegExp(r'^<<\s*(.+?)\s*>>$').firstMatch(line);
    if (annotation != null) {
      _classes[classId]?.stereotype = annotation.group(1);
      return;
    }

    var text = line;
    if (text.endsWith(';')) text = text.substring(0, text.length - 1).trim();
    if (text.isEmpty) return;

    var visibility = ClassMemberVisibility.none;
    if (text.isNotEmpty) {
      switch (text[0]) {
        case '+':
          visibility = ClassMemberVisibility.public;
          text = text.substring(1).trim();
        case '-':
          visibility = ClassMemberVisibility.private;
          text = text.substring(1).trim();
        case '#':
          visibility = ClassMemberVisibility.protected;
          text = text.substring(1).trim();
        case '~':
          visibility = ClassMemberVisibility.package;
          text = text.substring(1).trim();
      }
    }

    // Trailing classifiers: `$` static, `*` abstract.
    var isStatic = false;
    var isAbstract = false;
    while (text.isNotEmpty) {
      final last = text[text.length - 1];
      if (last == r'$') {
        isStatic = true;
        text = text.substring(0, text.length - 1).trim();
      } else if (last == '*') {
        isAbstract = true;
        text = text.substring(0, text.length - 1).trim();
      } else {
        break;
      }
    }

    if (text.isEmpty) return;

    final isMethod = text.contains('(');
    String name;
    String? type;

    if (isMethod) {
      final close = text.lastIndexOf(')');
      if (close == -1) {
        name = text;
      } else {
        name = text.substring(0, close + 1).trim();
        final tail = text.substring(close + 1).trim();
        if (tail.isNotEmpty) type = tail;
      }
    } else {
      // Either `name : Type` or the UML-ish `Type name`.
      final colon = text.indexOf(':');
      if (colon != -1) {
        name = text.substring(0, colon).trim();
        type = text.substring(colon + 1).trim();
      } else {
        final space = text.indexOf(' ');
        if (space != -1) {
          type = text.substring(0, space).trim();
          name = text.substring(space + 1).trim();
        } else {
          name = text;
        }
      }
    }

    final member = ClassMember(
      name: _expandGenerics(name),
      visibility: visibility,
      type: type == null ? null : _expandGenerics(type),
      isMethod: isMethod,
      isStatic: isStatic,
      isAbstract: isAbstract,
    );

    final builder = _classes[classId];
    if (builder == null) return;
    if (isMethod) {
      builder.methods.add(member);
    } else {
      builder.attributes.add(member);
    }
  }

  // ------------------------------------------------------------- relationships

  bool _parseRelation(String line) {
    var text = line;
    String? label;

    // Relation label follows the final colon: `A --> B : uses`.
    final colon = text.indexOf(':');
    if (colon != -1) {
      label = text.substring(colon + 1).trim();
      text = text.substring(0, colon).trim();
    }

    for (final pattern in _relationPatterns) {
      final index = text.indexOf(pattern.token);
      if (index <= 0) continue;

      final leftRaw = text.substring(0, index).trim();
      final rightRaw = text.substring(index + pattern.token.length).trim();
      if (leftRaw.isEmpty || rightRaw.isEmpty) continue;

      final left = _splitCardinality(leftRaw, cardinalityTrails: true);
      final right = _splitCardinality(rightRaw, cardinalityTrails: false);
      if (left.name.isEmpty || right.name.isEmpty) continue;

      final fromId = _normalizeId(left.name);
      final toId = _normalizeId(right.name);
      _ensureClass(fromId, left.name);
      _ensureClass(toId, right.name);

      _edges.add(MermaidEdge(
        from: fromId,
        to: toId,
        label: (label != null && label.isNotEmpty) ? label : null,
        arrowType: pattern.endHead,
        startArrowType: pattern.startHead,
        lineType: pattern.dashed ? LineType.dotted : LineType.solid,
        startLabel: left.cardinality,
        endLabel: right.cardinality,
      ));
      return true;
    }

    return false;
  }

  /// Splits `Student "1"` / `"1..*" Course` into a name and a cardinality.
  _Endpoint _splitCardinality(String raw, {required bool cardinalityTrails}) {
    final match = cardinalityTrails
        ? RegExp(r'^(.*?)\s*"([^"]*)"\s*$').firstMatch(raw)
        : RegExp(r'^\s*"([^"]*)"\s*(.*)$').firstMatch(raw);

    if (match == null) return _Endpoint(raw.trim(), null);

    final name = cardinalityTrails ? match.group(1)! : match.group(2)!;
    final cardinality = cardinalityTrails ? match.group(2)! : match.group(1)!;
    return _Endpoint(name.trim(), cardinality.trim());
  }

  // ------------------------------------------------------------------ helpers

  _ClassBuilder _ensureClass(String id, String rawName) {
    return _classes.putIfAbsent(
      id,
      () => _ClassBuilder(id: id, name: _expandGenerics(_stripGenerics(rawName))),
    );
  }

  /// Mermaid writes generics with tildes: `List~int~` renders as `List<int>`.
  String _expandGenerics(String text) {
    if (!text.contains('~')) return text;
    return text.replaceAllMapped(
      RegExp(r'~([^~]+)~'),
      (m) => '<${m.group(1)}>',
    );
  }

  /// Removes a generic suffix so `Class01~T~` and `Class01` share an id.
  String _stripGenerics(String text) {
    return text.replaceAll(RegExp(r'~[^~]*~'), '').trim();
  }

  String _normalizeId(String raw) {
    return normalizeMermaidId(_stripGenerics(raw));
  }
}

/// A relationship token and the arrow heads it implies.
class _RelationPattern {
  const _RelationPattern(
    this.token,
    this.type, {
    this.startHead = ArrowType.none,
    this.endHead = ArrowType.none,
    this.dashed = false,
  });

  final String token;
  final ClassRelationType type;
  final ArrowType startHead;
  final ArrowType endHead;
  final bool dashed;
}

/// One side of a relationship line.
class _Endpoint {
  const _Endpoint(this.name, this.cardinality);

  final String name;
  final String? cardinality;
}

/// Mutable accumulator turned into an immutable [ClassBox] at the end.
class _ClassBuilder {
  _ClassBuilder({required this.id, required this.name});

  final String id;
  final String name;
  String? stereotype;
  String? note;
  String? cssClass;
  String? label;
  final List<ClassMember> attributes = [];
  final List<ClassMember> methods = [];

  ClassBox build() {
    return ClassBox(
      id: id,
      name: name,
      stereotype: stereotype,
      attributes: List.unmodifiable(attributes),
      methods: List.unmodifiable(methods),
      note: note,
      cssClass: cssClass,
      label: label,
    );
  }
}
