/// Parser for C4 diagrams
library;

import '../models/c4_diagram.dart';
import '../models/diagram.dart';

/// Parser for Mermaid C4 diagrams (`C4Context` and its siblings).
///
/// The syntax is a sequence of function calls — `Person(alias, "name", "…")`,
/// `Rel(a, b, "uses")` — with boundaries wrapping their contents in braces.
class C4Parser {
  /// Creates a C4 parser.
  const C4Parser();

  /// `Person(alias, "label", "description")`, with the arguments left whole
  /// so quotes and commas inside them survive.
  static final _callRe = RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)\s*\((.*)$');

  /// `title Some words`
  static final _titleRe = RegExp(r'^title\s+(.+)$', caseSensitive: false);

  /// `UpdateLayoutConfig($c4ShapeInRow="3")`
  static final _shapesPerRowRe = RegExp(
    r'c4ShapeInRow"?\s*=\s*"?(\d+)',
    caseSensitive: false,
  );

  /// Element keywords, mapped to what they draw.
  static const _elementKinds = <String, C4ElementKind>{
    'person': C4ElementKind.person,
    'system': C4ElementKind.system,
    'systemdb': C4ElementKind.database,
    'systemqueue': C4ElementKind.queue,
    'container': C4ElementKind.container,
    'containerdb': C4ElementKind.database,
    'containerqueue': C4ElementKind.queue,
    'component': C4ElementKind.component,
    'componentdb': C4ElementKind.database,
    'componentqueue': C4ElementKind.queue,
    'node': C4ElementKind.node,
    'node_l': C4ElementKind.node,
    'node_r': C4ElementKind.node,
    'deployment_node': C4ElementKind.node,
  };

  /// Parses a C4 diagram from cleaned lines.
  ///
  /// Returns null when nothing was found, so the renderer can fall back to
  /// showing the source rather than an empty box.
  (MermaidDiagramData, C4DiagramData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    String? title;
    var shapesPerRow = 4;
    final roots = <C4Node>[];
    final relations = <C4Relation>[];
    // The innermost boundary being filled; the root list when empty.
    final open = <_OpenBoundary>[];

    void add(C4Node node) {
      if (open.isEmpty) {
        roots.add(node);
      } else {
        open.last.children.add(node);
      }
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase().startsWith('c4')) continue;

      if (line == '}' || line == '{') {
        if (line == '}' && open.isNotEmpty) {
          final closed = open.removeLast();
          add(
            C4Boundary(
              alias: closed.alias,
              label: closed.label,
              type: closed.type,
              children: List.of(closed.children),
            ),
          );
        }
        continue;
      }

      final titleMatch = _titleRe.firstMatch(line);
      if (titleMatch != null) {
        title = titleMatch.group(1)!.trim();
        continue;
      }

      final call = _callRe.firstMatch(line);
      if (call == null) continue;

      final keyword = call.group(1)!;
      final lower = keyword.toLowerCase();
      final args = _splitArguments(call.group(2)!);

      if (lower == 'updatelayoutconfig') {
        final match = _shapesPerRowRe.firstMatch(line);
        if (match != null) {
          shapesPerRow = int.tryParse(match.group(1)!) ?? shapesPerRow;
        }
        continue;
      }
      if (lower == 'updaterelstyle' || lower == 'updateelementstyle') continue;

      if (lower.endsWith('boundary')) {
        if (args.isEmpty) continue;
        open.add(
          _OpenBoundary(
            alias: args[0],
            label: args.length > 1 ? args[1] : args[0],
            type: args.length > 2 ? args[2] : _boundaryType(lower),
          ),
        );
        continue;
      }

      if (lower.startsWith('rel') || lower.startsWith('birel')) {
        if (args.length < 2) continue;
        relations.add(
          C4Relation(
            from: args[0],
            to: args[1],
            label: args.length > 2 ? args[2] : null,
            technology: args.length > 3 ? args[3] : null,
            bidirectional: lower.startsWith('birel'),
            direction: _directionOf(lower),
          ),
        );
        continue;
      }

      final external = lower.endsWith('_ext');
      final kindKey = external ? lower.substring(0, lower.length - 4) : lower;
      final kind = _elementKinds[kindKey];
      if (kind == null || args.isEmpty) continue;

      // `Person` and `System` take (alias, label, description); `Container`,
      // `Component` and `Node` take (alias, label, technology, description).
      // Reading them the same way put the technology in the description.
      final takesTechnology =
          kindKey.startsWith('container') ||
          kindKey.startsWith('component') ||
          kindKey.contains('node');
      final third = args.length > 2 ? args[2] : null;
      final fourth = args.length > 3 ? args[3] : null;

      add(
        C4Element(
          alias: args[0],
          label: args.length > 1 ? args[1] : args[0],
          kind: kind,
          description: takesTechnology ? fourth : third,
          technology: takesTechnology ? third : null,
          isExternal: external,
        ),
      );
    }

    // A boundary whose closing brace never arrived still holds its contents.
    while (open.isNotEmpty) {
      final closed = open.removeLast();
      add(
        C4Boundary(
          alias: closed.alias,
          label: closed.label,
          type: closed.type,
          children: List.of(closed.children),
        ),
      );
    }

    if (roots.isEmpty) return null;

    return (
      MermaidDiagramData(
        type: DiagramType.c4Diagram,
        nodes: const [],
        edges: const [],
        title: title,
      ),
      C4DiagramData(
        nodes: roots,
        relations: relations,
        title: title,
        shapesPerRow: shapesPerRow,
      ),
    );
  }

  String? _boundaryType(String keyword) {
    if (keyword.startsWith('enterprise')) return 'Enterprise';
    if (keyword.startsWith('system')) return 'System';
    if (keyword.startsWith('container')) return 'Container';
    return null;
  }

  C4RelationDirection _directionOf(String keyword) {
    if (keyword.endsWith('_u') || keyword.endsWith('_up')) {
      return C4RelationDirection.up;
    }
    if (keyword.endsWith('_d') || keyword.endsWith('_down')) {
      return C4RelationDirection.down;
    }
    if (keyword.endsWith('_l') || keyword.endsWith('_left')) {
      return C4RelationDirection.left;
    }
    if (keyword.endsWith('_r') || keyword.endsWith('_right')) {
      return C4RelationDirection.right;
    }
    return C4RelationDirection.unspecified;
  }

  /// Splits the arguments of a call, dropping the trailing `)` and any `{`.
  ///
  /// Not `split(',')`: a description routinely contains commas, and they sit
  /// inside quotes.
  List<String> _splitArguments(String text) {
    final args = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    var depth = 0;

    for (var i = 0; i < text.length; i++) {
      final c = text[i];

      if (c == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (inQuotes) {
        buffer.write(c);
        continue;
      }
      if (c == '(') {
        depth++;
        buffer.write(c);
        continue;
      }
      if (c == ')') {
        if (depth == 0) break;
        depth--;
        buffer.write(c);
        continue;
      }
      if (c == ',' && depth == 0) {
        args.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }
      buffer.write(c);
    }

    final last = buffer.toString().trim();
    if (last.isNotEmpty) args.add(last);
    return args.where((a) => a.isNotEmpty).toList();
  }
}

/// A boundary whose closing brace has not been read yet.
class _OpenBoundary {
  _OpenBoundary({required this.alias, required this.label, this.type});

  final String alias;
  final String label;
  final String? type;
  final List<C4Node> children = [];
}
