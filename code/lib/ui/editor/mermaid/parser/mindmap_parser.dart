import '../models/diagram.dart';
import '../models/mindmap.dart';
import 'indentation.dart';
import 'label.dart';

/// Parser for Mermaid mindmaps (`mindmap`).
///
/// Structure comes from indentation, so unlike the other parsers this one must
/// be given lines with their leading whitespace intact.
class MindmapParser {
  /// Creates a mindmap parser.
  const MindmapParser();

  /// A tab advances to the next multiple of this many columns.
  static const int tabWidth = 4;

  /// Shape wrappers, longest first so `((x))` is matched before `(x)`.
  static const _shapes = <(String, String, MindmapShape)>[
    ('))', '((', MindmapShape.bang),
    ('((', '))', MindmapShape.circle),
    ('{{', '}}', MindmapShape.hexagon),
    ('[', ']', MindmapShape.square),
    (')', '(', MindmapShape.cloud),
    ('(', ')', MindmapShape.rounded),
  ];

  /// Parses the lines of a mindmap.
  ///
  /// The first line is the `mindmap` header and is skipped.
  (MermaidDiagramData, MindmapData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    final body = lines.length > 1 ? lines.sublist(1) : const <String>[];

    MindmapNode? root;
    // Stack of (indent, node) for the path from the root to the last node.
    final stack = <(int, MindmapNode)>[];

    for (final raw in body) {
      if (raw.trim().isEmpty) continue;

      final indent = indentColumns(raw, tabWidth: tabWidth);
      final text = raw.trim();

      // Decorations that attach to the previous node rather than making one.
      if (text.startsWith('::icon(') || text.startsWith(':::')) continue;

      final parsed = _parseNode(text);
      if (parsed == null) continue;

      if (root == null) {
        root = MindmapNode(
          label: parsed.$1,
          shape: parsed.$2,
          cssClass: parsed.$3,
        );
        stack.add((indent, root));
        continue;
      }

      // Walk back out to the parent: the deepest entry still indented less
      // than this line.
      while (stack.length > 1 && stack.last.$1 >= indent) {
        stack.removeLast();
      }

      final parent = stack.last.$2;
      final node = MindmapNode(
        label: parsed.$1,
        shape: parsed.$2,
        cssClass: parsed.$3,
        depth: parent.depth + 1,
      );
      parent.children.add(node);
      stack.add((indent, node));
    }

    if (root == null) return null;

    return (
      MermaidDiagramData(
        type: DiagramType.mindmap,
        nodes: const [],
        edges: const [],
      ),
      MindmapData(root: root),
    );
  }

  /// Splits a line into label, shape and css class.
  (String, MindmapShape, String?)? _parseNode(String text) {
    var body = text;
    String? cssClass;

    final classIndex = body.indexOf(':::');
    if (classIndex != -1) {
      cssClass = body.substring(classIndex + 3).trim();
      body = body.substring(0, classIndex).trim();
    }

    if (body.isEmpty) return null;

    for (final (open, close, shape) in _shapes) {
      final start = body.indexOf(open);
      if (start == -1) continue;
      if (!body.endsWith(close)) continue;

      final label = body.substring(start + open.length,
          body.length - close.length);
      // An id may precede the wrapper (`id[Label]`); mermaid shows the label.
      return (cleanLabel(label).trim(), shape, cssClass);
    }

    return (body, MindmapShape.none, cssClass);
  }
}
