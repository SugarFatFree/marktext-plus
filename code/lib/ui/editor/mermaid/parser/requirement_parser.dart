/// Parser for requirement diagrams
library;

import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';
import '../models/requirement_diagram.dart';
import 'identifier.dart';

/// Parser for Mermaid requirement diagrams (`requirementDiagram`).
class RequirementParser {
  const RequirementParser();

  /// `functionalRequirement test_req2 {`
  static final _blockRe = RegExp(
    r'^(\w+)\s+([^\s{]+)\s*\{?$',
  );

  /// `id: 1.1` — the value runs to the end of the line, and may contain
  /// colons, so only the first one separates.
  static final _fieldRe = RegExp(r'^(\w+)\s*:\s*(.*)$');

  /// `test_entity - satisfies -> test_req2`
  static final _forwardRelationRe = RegExp(
    r'^(\S+)\s*-\s*(\w+)\s*->\s*(\S+)$',
  );

  /// `test_req2 <- derives - test_req3`, which points the other way.
  static final _backwardRelationRe = RegExp(
    r'^(\S+)\s*<-\s*(\w+)\s*-\s*(\S+)$',
  );

  /// Parses a requirement diagram from cleaned lines.
  ///
  /// Returns null when nothing was declared, so the renderer falls back to
  /// showing the source rather than an empty canvas.
  (MermaidDiagramData, RequirementDiagramData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    final requirements = <Requirement>[];
    final elements = <RequirementElement>[];
    final relations = <RequirementRelation>[];

    // Open block being filled in, if any.
    String? blockName;
    RequirementKind? blockKind;
    var blockIsElement = false;
    final fields = <String, String>{};

    void closeBlock() {
      if (blockName == null) return;
      if (blockIsElement) {
        elements.add(RequirementElement(
          name: blockName!,
          type: fields['type'],
          docRef: fields['docref'],
        ));
      } else {
        requirements.add(Requirement(
          name: blockName!,
          kind: blockKind ?? RequirementKind.requirement,
          id: fields['id'],
          text: fields['text'],
          risk: RequirementRisk.fromName(fields['risk'] ?? ''),
          verifyMethod: VerifyMethod.fromName(fields['verifymethod'] ?? ''),
        ));
      }
      blockName = null;
      blockKind = null;
      blockIsElement = false;
      fields.clear();
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase() == 'requirementdiagram') continue;

      if (line == '}') {
        closeBlock();
        continue;
      }

      // Relationships first: `a - satisfies -> b` also matches the field
      // pattern once a block is open, and the relationship reading is right.
      final relation = _parseRelation(line);
      if (relation != null) {
        relations.add(relation);
        continue;
      }

      if (blockName != null) {
        final field = _fieldRe.firstMatch(line);
        if (field != null) {
          fields[field.group(1)!.toLowerCase()] =
              _unquote(field.group(2)!.trim());
          continue;
        }
        // Anything else means the block was never closed; start afresh rather
        // than swallowing the rest of the diagram.
        closeBlock();
      }

      final block = _blockRe.firstMatch(line);
      if (block == null) continue;

      final keyword = block.group(1)!;
      final name = normalizeMermaidId(_unquote(block.group(2)!));
      if (name.isEmpty) continue;

      if (keyword.toLowerCase() == 'element') {
        blockName = name;
        blockIsElement = true;
        continue;
      }

      final kind = RequirementKind.fromKeyword(keyword);
      if (kind == null) continue;
      blockName = name;
      blockKind = kind;
    }

    // A diagram that ends without its closing brace still described a box.
    closeBlock();

    if (requirements.isEmpty && elements.isEmpty) return null;

    final data = RequirementDiagramData(
      requirements: requirements,
      elements: elements,
      relations: relations,
    );

    final nodes = <MermaidNode>[
      for (final requirement in requirements)
        MermaidNode(
          id: requirement.name,
          label: requirement.name,
          shape: NodeShape.rectangle,
        ),
      for (final element in elements)
        MermaidNode(
          id: element.name,
          label: element.name,
          shape: NodeShape.rectangle,
        ),
    ];

    final known = {for (final node in nodes) node.id};
    final edges = <MermaidEdge>[
      for (final relation in relations)
        if (known.contains(relation.source) && known.contains(relation.target))
          MermaidEdge(
            from: relation.source,
            to: relation.target,
            label: relation.kind.label,
            lineType: LineType.solid,
            arrowType: ArrowType.arrow,
          ),
    ];

    return (
      MermaidDiagramData(
        type: DiagramType.requirementDiagram,
        nodes: nodes,
        edges: edges,
      ),
      data,
    );
  }

  RequirementRelation? _parseRelation(String line) {
    final forward = _forwardRelationRe.firstMatch(line);
    if (forward != null) {
      final kind = RequirementRelationKind.fromName(forward.group(2)!);
      if (kind == null) return null;
      return RequirementRelation(
        source: normalizeMermaidId(forward.group(1)!),
        target: normalizeMermaidId(forward.group(3)!),
        kind: kind,
      );
    }

    final backward = _backwardRelationRe.firstMatch(line);
    if (backward != null) {
      final kind = RequirementRelationKind.fromName(backward.group(2)!);
      if (kind == null) return null;
      // `a <- derives - b` reads "b derives a", so the arrow starts at b.
      return RequirementRelation(
        source: normalizeMermaidId(backward.group(3)!),
        target: normalizeMermaidId(backward.group(1)!),
        kind: kind,
      );
    }

    return null;
  }

  static String _unquote(String text) {
    if (text.length >= 2 &&
        ((text.startsWith('"') && text.endsWith('"')) ||
            (text.startsWith("'") && text.endsWith("'")))) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }
}
