import '../models/diagram.dart';
import '../models/treemap.dart';

/// Parses mermaid `treemap-beta` diagrams.
///
/// The grammar is indentation-based, and taken from mermaid 11.16's own
/// definition rather than guessed at:
///
/// ```
/// treemap-beta
///     "Root"
///         "Section A"
///             "Leaf A1": 10
///             "Leaf A2": 20
///         "Section B": 15
///         "Tagged": 5:::important
///     classDef important fill:#f9f
/// ```
///
/// * `INDENTATION` is `[ \t]+`, and its *length* is what nests a row.
/// * `STRING2` is `"…"` or `'…'`.
/// * `NUMBER2` is `[0-9_.,]+`, read with the commas taken out, so `1,024`
///   means one thousand and twenty four rather than failing to parse.
class TreemapParser {
  /// Creates a treemap parser.
  const TreemapParser();

  static final _classDefRe =
      RegExp(r'^classDef\s+([A-Za-z_]\w*)(?:\s+([^\n\r;]*))?;?$');
  static final _itemRe = RegExp(
    r'''^(?:"([^"]*)"|'([^']*)')'''
    r'''(?:\s*:\s*([0-9_.,]+))?'''
    r'''(?:\s*:::\s*([A-Za-z_]\w*))?\s*$''',
  );
  // A name written without quotes. Mermaid's grammar requires them; accepting
  // the bare form costs nothing and a document that leaves them off would
  // otherwise render as an empty box with no hint as to why.
  static final _bareItemRe = RegExp(
    r'''^([^:"']+?)'''
    r'''(?:\s*:\s*([0-9_.,]+))?'''
    r'''(?:\s*:::\s*([A-Za-z_]\w*))?\s*$''',
  );

  /// Returns the diagram and its data, or null if nothing could be read.
  (MermaidDiagramData, TreemapDiagramData)? parse(List<String> lines) {
    String? title;
    final classStyles = <String, String>{};
    final roots = <TreemapNode>[];
    // Nodes still open, innermost last, with the indent each was written at.
    final stack = <({int indent, TreemapNode node})>[];

    for (final raw in lines) {
      if (raw.trim().isEmpty || raw.trim().startsWith('%%')) continue;
      final line = raw.trim();
      if (line.startsWith('treemap')) continue;

      if (line.toLowerCase().startsWith('title ')) {
        title = line.substring(6).trim();
        continue;
      }

      final classDef = _classDefRe.firstMatch(line);
      if (classDef != null) {
        classStyles[classDef.group(1)!] = classDef.group(2)?.trim() ?? '';
        continue;
      }

      final indent = _indentOf(raw);
      final quoted = _itemRe.firstMatch(line);
      final bare = quoted == null ? _bareItemRe.firstMatch(line) : null;
      if (quoted == null && bare == null) continue;

      final name = quoted != null
          ? (quoted.group(1) ?? quoted.group(2) ?? '')
          : bare!.group(1)!.trim();
      final rawValue = quoted != null ? quoted.group(3) : bare!.group(2);
      final selector = quoted != null ? quoted.group(4) : bare!.group(3);

      final node = TreemapNode(
        name: name,
        value: _number(rawValue),
        classSelector: selector,
      );

      while (stack.isNotEmpty && stack.last.indent >= indent) {
        stack.removeLast();
      }
      if (stack.isEmpty) {
        roots.add(node);
      } else {
        stack.last.node.children.add(node);
      }
      stack.add((indent: indent, node: node));
    }

    if (roots.isEmpty) return null;

    return (
      MermaidDiagramData(
        type: DiagramType.treemap,
        nodes: const [],
        edges: const [],
        title: title,
      ),
      TreemapDiagramData(
        roots: roots,
        title: title,
        classStyles: classStyles,
      ),
    );
  }

  /// The width of [line]'s leading whitespace, a tab counting as one.
  ///
  /// Mermaid's `INDENTATION` token is `[ \t]+` and what nests a row is the
  /// token's length, so a tab is one unit there too.
  static int _indentOf(String line) {
    var i = 0;
    while (i < line.length &&
        (line.codeUnitAt(i) == 0x20 || line.codeUnitAt(i) == 0x09)) {
      i++;
    }
    return i;
  }

  static double? _number(String? text) {
    if (text == null) return null;
    return double.tryParse(text.replaceAll(',', '').replaceAll('_', ''));
  }
}
