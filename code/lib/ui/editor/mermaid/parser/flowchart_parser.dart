import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';
import '../models/style.dart';

/// Helper class for arrow information
class _ArrowInfo {
  const _ArrowInfo({
    required this.line,
    required this.head,
    required this.bidirectional,
    this.label,
  });

  /// The dashes, equals signs or dots that make up the line.
  final String line;

  /// What sits at the far end: `>`, `o`, `x`, or empty for a plain line.
  final String head;

  /// Whether the near end carries an arrow head as well, as in `A <--> B`.
  final bool bidirectional;

  final String? label;
}

/// Parser for Mermaid flowchart diagrams
///
/// Supports syntax like:
/// ```
/// graph TD
///   A[Start] --> B{Decision}
///   B -->|Yes| C[OK]
///   B -->|No| D[Cancel]
/// ```
class FlowchartParser {
  final Map<String, MermaidNode> _nodes = {};
  final List<MermaidEdge> _edges = [];
  final List<Subgraph> _subgraphs = [];
  final Map<String, NodeStyle> _classDefs = {};
  final Map<String, String> _nodeClasses = {};

  // Subgraph parsing state
  String? _currentSubgraphId;
  String? _currentSubgraphLabel;
  final List<String> _currentSubgraphNodes = [];
  final List<_SubgraphState> _subgraphStack = [];
  final Set<String> _subgraphIds = {}; // Track all subgraph IDs

  DiagramDirection _direction = DiagramDirection.topToBottom;

  /// Parses flowchart lines into diagram data
  MermaidDiagramData? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    _nodes.clear();
    _edges.clear();
    _subgraphs.clear();
    _classDefs.clear();
    _nodeClasses.clear();
    _currentSubgraphId = null;
    _currentSubgraphLabel = null;
    _currentSubgraphNodes.clear();
    _subgraphStack.clear();
    _subgraphIds.clear();

    // Parse first line for direction
    final firstLine = lines.first.trim().toLowerCase();
    _parseDirection(firstLine);

    // Parse remaining lines
    for (var i = 1; i < lines.length; i++) {
      _parseLine(lines[i]);
    }

    // Apply class styles to nodes
    _applyClassStyles();

    return MermaidDiagramData(
      type: DiagramType.flowchart,
      nodes: _nodes.values.toList(),
      edges: _edges,
      direction: _direction,
      subgraphs: _subgraphs,
      style: MermaidStyle(classDefs: _classDefs),
    );
  }

  void _parseDirection(String line) {
    if (line.contains(' td') || line.contains(' tb')) {
      _direction = DiagramDirection.topToBottom;
    } else if (line.contains(' bt')) {
      _direction = DiagramDirection.bottomToTop;
    } else if (line.contains(' lr')) {
      _direction = DiagramDirection.leftToRight;
    } else if (line.contains(' rl')) {
      _direction = DiagramDirection.rightToLeft;
    }
  }

  void _parseLine(String line) {
    // A statement may end with a semicolon. Now that a node id accepts any
    // character that is not a delimiter, `A-->B;` would otherwise name the
    // target "B;".
    final trimmed = line.trim().replaceFirst(RegExp(r';\s*$'), '');
    if (trimmed.isEmpty) return;

    // Parse classDef
    if (trimmed.startsWith('classDef ')) {
      _parseClassDef(trimmed);
      return;
    }

    // Parse class assignment
    if (trimmed.startsWith('class ')) {
      _parseClassAssignment(trimmed);
      return;
    }

    // Parse style
    if (trimmed.startsWith('style ')) {
      _parseStyle(trimmed);
      return;
    }

    // Parse subgraph
    if (trimmed.startsWith('subgraph ')) {
      _parseSubgraphStart(trimmed);
      return;
    }

    if (trimmed == 'end') {
      _parseSubgraphEnd();
      return;
    }

    // Parse node and edge definitions
    _parseNodeOrEdge(trimmed);
  }

  void _parseSubgraphStart(String line) {
    // Parse: "subgraph id [label]" or "subgraph label"
    final trimmed = line.substring(9).trim(); // Remove "subgraph "

    // Save current subgraph state if we're in one (nested subgraph)
    if (_currentSubgraphId != null) {
      _subgraphStack.add(_SubgraphState(
        id: _currentSubgraphId!,
        label: _currentSubgraphLabel ?? _currentSubgraphId!,
        nodeIds: List.from(_currentSubgraphNodes),
      ));
    }

    // Parse id and label
    // Format can be: "subgraph id" or "subgraph id [label]" or "subgraph label"
    final bracketMatch = RegExp(r'^([^\s\[\](){}<>|]+)\s*\[(.+)\]$').firstMatch(trimmed);
    if (bracketMatch != null) {
      _currentSubgraphId = bracketMatch.group(1);
      _currentSubgraphLabel = bracketMatch.group(2);
    } else {
      // Use the text as both id and label
      final parts = trimmed.split(RegExp(r'\s+'));
      _currentSubgraphId = parts.isNotEmpty ? parts[0] : 'subgraph_${_subgraphs.length}';
      _currentSubgraphLabel = trimmed;
    }

    // Record subgraph ID
    if (_currentSubgraphId != null) {
      _subgraphIds.add(_currentSubgraphId!);
    }

    _currentSubgraphNodes.clear();
  }

  void _parseSubgraphEnd() {
    if (_currentSubgraphId != null) {
      // Create the subgraph
      _subgraphs.add(Subgraph(
        id: _currentSubgraphId!,
        label: _currentSubgraphLabel ?? _currentSubgraphId!,
        nodeIds: List.from(_currentSubgraphNodes),
      ));

      // Restore parent subgraph state if any
      if (_subgraphStack.isNotEmpty) {
        final parent = _subgraphStack.removeLast();
        // Add this subgraph's nodes to parent
        parent.nodeIds.addAll(_currentSubgraphNodes);
        _currentSubgraphId = parent.id;
        _currentSubgraphLabel = parent.label;
        _currentSubgraphNodes
          ..clear()
          ..addAll(parent.nodeIds);
      } else {
        _currentSubgraphId = null;
        _currentSubgraphLabel = null;
        _currentSubgraphNodes.clear();
      }
    }
  }

  /// Tracks a node ID for the current subgraph
  void _trackNodeForSubgraph(String nodeId) {
    if (_currentSubgraphId != null && !_currentSubgraphNodes.contains(nodeId)) {
      _currentSubgraphNodes.add(nodeId);
    }
  }

  void _parseNodeOrEdge(String line) {
    // Split line by arrows to get individual node-edge pairs
    // Arrows: -->, ==>, ---, -.->
    // An arrow is: an optional head at the near end, a line, an optional
    // label sitting between two line segments, a head, and an optional
    // piped label.
    //
    // The old alternation listed `---` before `---->`, and alternation
    // prefers the first branch that matches, so a long arrow was read as a
    // short one and the rest — `-> B` — became the target's name. It also had
    // no form for `A -- label --> B` at all, which lost the source node, and
    // an unescaped dot that matched any single character between dashes.
    final arrowRegex = RegExp(
      r'\s*(<)?(-{2,}|={2,}|-\.+-|-\.)'
      r'(?:\s*([^|>ox\-=.][^|]*?)\s*(-{2,}|={2,}|-\.+-|\.-))?'
      r'([>ox])?\s*(?:\|([^|]*)\|)?\s*',
    );

    final parts = <String>[];
    final arrows = <_ArrowInfo>[];

    var lastEnd = 0;
    for (final match in arrowRegex.allMatches(line)) {
      if (match.start > lastEnd) {
        parts.add(line.substring(lastEnd, match.start).trim());
      }
      arrows.add(_ArrowInfo(
        line: match.group(2)!,
        head: match.group(5) ?? '',
        bidirectional: match.group(1) != null,
        // Either spelling of the label; only one can be present.
        label: match.group(3) ?? match.group(6),
      ));
      lastEnd = match.end;
    }
    // Add the last part
    if (lastEnd < line.length) {
      parts.add(line.substring(lastEnd).trim());
    }

    if (parts.length < 2 || arrows.isEmpty) {
      // Not an edge definition, try parsing as single node
      final node = _parseNode(line);
      if (node != null && !_subgraphIds.contains(node.id)) {
        _nodes[node.id] = node;
        _trackNodeForSubgraph(node.id);
      }
      return;
    }

    // One position may name several nodes: `A --> B & C` links A to both, and
    // `A & B --> C` links both to C. Splitting only on arrows dropped
    // everything after the ampersand.
    final groups = parts.map(_splitOnAmpersand).toList();

    // Process all nodes and edges
    for (var i = 0; i < groups.length; i++) {
      for (final part in groups[i]) {
        final nodeId = _extractId(part);

        // Skip if this is a subgraph ID (don't create node for subgraph reference)
        if (_subgraphIds.contains(nodeId)) continue;
        final node = _parseNode(part);
        if (node == null) continue;
        // Only add node if not exists, or update if new one has shape/label info
        if (!_nodes.containsKey(node.id) ||
            _shouldUpdateNode(_nodes[node.id]!, node)) {
          _nodes[node.id] = node;
        }
        _trackNodeForSubgraph(node.id);
      }

      // Create edges between every node on this side and every node on the
      // next, which for the ordinary one-to-one case is a single edge.
      if (i >= arrows.length || i + 1 >= groups.length) continue;
      final arrow = arrows[i];

      for (final fromPart in groups[i]) {
        for (final toPart in groups[i + 1]) {
          final fromId = _extractId(fromPart);
          final toId = _extractId(toPart);

          // Check if either endpoint is a subgraph
          final isFromSubgraph = _subgraphIds.contains(fromId);
          final isToSubgraph = _subgraphIds.contains(toId);

          _edges.add(MermaidEdge(
            from: fromId,
            to: toId,
            label: arrow.label,
            arrowType: _parseArrowType(arrow.head),
            lineType: _parseLineType(arrow.line),
            bidirectional: arrow.bidirectional,
            // `A <--> B` draws a head at both ends.
            startArrowType:
                arrow.bidirectional ? ArrowType.arrow : ArrowType.none,
            isSubgraphEdge: isFromSubgraph || isToSubgraph,
          ));
        }
      }
    }
  }

  /// Splits `B & C` into its node strings.
  ///
  /// An ampersand inside a label — `A[Tom & Jerry]` — is content, so only
  /// ampersands outside brackets separate.
  static List<String> _splitOnAmpersand(String part) {
    if (!part.contains('&')) return [part];

    final result = <String>[];
    final current = StringBuffer();
    var depth = 0;
    for (var i = 0; i < part.length; i++) {
      final char = part[i];
      if (char == '[' || char == '(' || char == '{') depth++;
      if (char == ']' || char == ')' || char == '}') depth--;
      if (char == '&' && depth == 0) {
        result.add(current.toString().trim());
        current.clear();
        continue;
      }
      current.write(char);
    }
    result.add(current.toString().trim());
    return result.where((p) => p.isNotEmpty).toList();
  }

  /// Determines if a new node should replace an existing node
  bool _shouldUpdateNode(MermaidNode existing, MermaidNode newNode) {
    // Update if existing is plain (just ID as label) and new has different label
    if (existing.label == existing.id && newNode.label != newNode.id) {
      return true;
    }
    // Update if new node has a non-rectangle shape
    if (existing.shape == NodeShape.rectangle && newNode.shape != NodeShape.rectangle) {
      return true;
    }
    return false;
  }

  /// Extracts just the ID from a node string like "B{label}" -> "B"
  String _extractId(String nodeStr) {
    final match = RegExp(r'^([^\s\[\](){}<>|]+)').firstMatch(nodeStr);
    return match?.group(1) ?? nodeStr;
  }

  /// Strips the quotes mermaid uses to wrap a label.
  static String _unquoteLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.length >= 2 &&
        ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
            (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    return label;
  }

  /// Parses a node definition and returns a MermaidNode
  MermaidNode? _parseNode(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // Node ids accept any script. `\w` is ASCII-only in Dart, so
    // `开始 --> 结束` produced no nodes at all while still producing edges
    // that pointed at them — the diagram came out empty.

    // Try to match different node shapes
    // [text] - rectangle
    // (text) - rounded rect
    // ([text]) - stadium
    // {text} - diamond
    // {{text}} - hexagon
    // ((text)) - circle
    // [[text]] - subroutine
    // [(text)] - cylinder
    // >text] - asymmetric

    String id;
    String label;
    NodeShape shape;

    // Double bracket patterns first
    final doubleCircle = RegExp(r'^([^\s\[\](){}<>|]+)\(\((.+)\)\)$');
    final hexagon = RegExp(r'^([^\s\[\](){}<>|]+)\{\{(.+)\}\}$');
    final subroutine = RegExp(r'^([^\s\[\](){}<>|]+)\[\[(.+)\]\]$');
    final cylinder = RegExp(r'^([^\s\[\](){}<>|]+)\[\((.+)\)\]$');
    final stadium = RegExp(r'^([^\s\[\](){}<>|]+)\(\[(.+)\]\)$');

    // Single bracket patterns
    final rectangle = RegExp(r'^([^\s\[\](){}<>|]+)\[(.+)\]$');
    final roundedRect = RegExp(r'^([^\s\[\](){}<>|]+)\((.+)\)$');
    final diamond = RegExp(r'^([^\s\[\](){}<>|]+)\{(.+)\}$');
    final asymmetric = RegExp(r'^([^\s\[\](){}<>|]+)>(.+)\]$');

    // Parallelogram patterns
    final parallelogram = RegExp(r'^([^\s\[\](){}<>|]+)\[/(.+)/\]$');
    final parallelogramAlt = RegExp(r'^([^\s\[\](){}<>|]+)\[\\(.+)\\\]$');
    final trapezoid = RegExp(r'^([^\s\[\](){}<>|]+)\[/(.+)\\\]$');
    final trapezoidAlt = RegExp(r'^([^\s\[\](){}<>|]+)\[\\(.+)/\]$');

    Match? match;

    if ((match = doubleCircle.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.circle;
    } else if ((match = hexagon.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.hexagon;
    } else if ((match = subroutine.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.subroutine;
    } else if ((match = cylinder.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.cylinder;
    } else if ((match = stadium.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.stadium;
    } else if ((match = parallelogram.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.parallelogram;
    } else if ((match = parallelogramAlt.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.parallelogramAlt;
    } else if ((match = trapezoid.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.trapezoid;
    } else if ((match = trapezoidAlt.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.trapezoidAlt;
    } else if ((match = asymmetric.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.asymmetric;
    } else if ((match = rectangle.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.rectangle;
    } else if ((match = roundedRect.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.roundedRect;
    } else if ((match = diamond.firstMatch(trimmed)) != null) {
      id = match!.group(1)!;
      label = match.group(2)!;
      shape = NodeShape.diamond;
    } else {
      // Plain node ID without shape
      final plainId = RegExp(r'^([^\s\[\](){}<>|]+)$').firstMatch(trimmed);
      if (plainId != null) {
        id = plainId.group(1)!;
        label = id;
        shape = NodeShape.rectangle;
      } else {
        return null;
      }
    }

    // Handle escaped quotes in labels
    label = label.replaceAll('\\"', '"').replaceAll("\\'", "'");

    // Quotes around a label are delimiters, not content — they are how a
    // label containing a bracket, comma or space is written. Keeping them
    // put the quote marks on screen.
    label = _unquoteLabel(label);

    return MermaidNode(
      id: id,
      label: label,
      shape: shape,
    );
  }

  ArrowType _parseArrowType(String head) {
    switch (head) {
      case 'x':
        return ArrowType.cross;
      case 'o':
        return ArrowType.circle;
      case '>':
        return ArrowType.arrow;
      default:
        return ArrowType.none;
    }
  }

  LineType _parseLineType(String line) {
    if (line.contains('=')) return LineType.thick;
    if (line.contains('.')) return LineType.dotted;
    return LineType.solid;
  }

  void _parseClassDef(String line) {
    // classDef className fill:#f9f,stroke:#333,stroke-width:4px
    final pattern = RegExp(r'classDef\s+(\w+)\s+(.+)');
    final match = pattern.firstMatch(line);
    if (match == null) return;

    final className = match.group(1)!;
    final styleStr = match.group(2)!;

    final style = _parseStyleString(styleStr);
    if (style != null) {
      _classDefs[className] = style;
    }
  }

  void _parseClassAssignment(String line) {
    // class nodeId1,nodeId2 className
    final pattern = RegExp(r'class\s+([^\s]+)\s+(\w+)');
    final match = pattern.firstMatch(line);
    if (match == null) return;

    final nodeIds = match.group(1)!.split(',');
    final className = match.group(2)!;

    for (final nodeId in nodeIds) {
      _nodeClasses[nodeId.trim()] = className;
    }
  }

  void _parseStyle(String line) {
    // style nodeId fill:#f9f,stroke:#333
    final pattern = RegExp(r'style\s+([^\s\[\](){}<>|]+)\s+(.+)');
    final match = pattern.firstMatch(line);
    if (match == null) return;

    final nodeId = match.group(1)!;
    final styleStr = match.group(2)!;

    final style = _parseStyleString(styleStr);
    if (style != null && _nodes.containsKey(nodeId)) {
      final node = _nodes[nodeId]!;
      _nodes[nodeId] = node.copyWith(style: style);
    }
  }

  NodeStyle? _parseStyleString(String styleStr) {
    int? fillColor;
    int? strokeColor;
    double strokeWidth = 1.0;
    int? textColor;

    final props = styleStr.split(',');
    for (final prop in props) {
      final parts = prop.split(':');
      if (parts.length != 2) continue;

      final key = parts[0].trim();
      final value = parts[1].trim();

      switch (key) {
        case 'fill':
          fillColor = _parseColor(value);
          break;
        case 'stroke':
          strokeColor = _parseColor(value);
          break;
        case 'stroke-width':
          strokeWidth = double.tryParse(
                value.replaceAll('px', ''),
              ) ??
              1.0;
          break;
        case 'color':
          textColor = _parseColor(value);
          break;
      }
    }

    return NodeStyle(
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      textColor: textColor,
    );
  }

  int? _parseColor(String color) {
    if (color.startsWith('#')) {
      final hex = color.substring(1);
      if (hex.length == 3) {
        // Short form: #rgb -> #rrggbb
        final r = hex[0] + hex[0];
        final g = hex[1] + hex[1];
        final b = hex[2] + hex[2];
        return int.tryParse('FF$r$g$b', radix: 16);
      } else if (hex.length == 6) {
        return int.tryParse('FF$hex', radix: 16);
      } else if (hex.length == 8) {
        return int.tryParse(hex, radix: 16);
      }
    }

    // Named colors
    return _namedColors[color.toLowerCase()];
  }

  void _applyClassStyles() {
    for (final entry in _nodeClasses.entries) {
      final nodeId = entry.key;
      final className = entry.value;

      if (_nodes.containsKey(nodeId) && _classDefs.containsKey(className)) {
        final node = _nodes[nodeId]!;
        _nodes[nodeId] = node.copyWith(
          className: className,
          style: _classDefs[className],
        );
      }
    }
  }

  static const Map<String, int> _namedColors = {
    'red': 0xFFFF0000,
    'green': 0xFF00FF00,
    'blue': 0xFF0000FF,
    'white': 0xFFFFFFFF,
    'black': 0xFF000000,
    'yellow': 0xFFFFFF00,
    'orange': 0xFFFFA500,
    'purple': 0xFF800080,
    'pink': 0xFFFFC0CB,
    'cyan': 0xFF00FFFF,
    'gray': 0xFF808080,
    'grey': 0xFF808080,
    'lightgray': 0xFFD3D3D3,
    'lightgrey': 0xFFD3D3D3,
    'darkgray': 0xFFA9A9A9,
    'darkgrey': 0xFFA9A9A9,
  };
}

/// Helper class to track subgraph state during parsing
class _SubgraphState {
  _SubgraphState({
    required this.id,
    required this.label,
    required this.nodeIds,
  });

  final String id;
  final String label;
  final List<String> nodeIds;
}
