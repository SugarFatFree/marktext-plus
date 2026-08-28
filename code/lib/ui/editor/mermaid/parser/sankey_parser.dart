/// Parser for Sankey diagrams
library;

import '../models/diagram.dart';
import '../models/sankey.dart';

/// Parser for Mermaid Sankey diagrams (`sankey-beta`).
///
/// The body is CSV rather than a bespoke syntax: one `source,target,value` row
/// per flow, with the usual double-quote escaping. Nodes are never declared —
/// a name exists because a row mentions it.
class SankeyParser {
  /// Creates a Sankey parser.
  const SankeyParser();

  /// Parses a Sankey diagram from cleaned lines.
  ///
  /// Returns null when no usable flow was found, so the renderer can fall back
  /// to showing the source instead of an empty box.
  (MermaidDiagramData, SankeyChartData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    var i = 0;

    // The frontmatter block is read once, by MermaidParser, and never reaches
    // here: this parser used to read it a second time, so the two disagreed
    // about quoting and about `<br/>`, and only this diagram type could carry
    // a title that way. The title now arrives on the diagram itself.

    if (i < lines.length &&
        lines[i].trim().toLowerCase().startsWith('sankey-beta')) {
      i++;
    }

    final nodes = <String>[];
    final seen = <String>{};
    final links = <SankeyLink>[];

    for (; i < lines.length; i++) {
      final line = lines[i].trimRight();
      if (line.trim().isEmpty) continue;

      final fields = _splitCsv(line);
      if (fields.length < 3) continue;

      final source = fields[0].trim();
      final target = fields[1].trim();
      final value = double.tryParse(fields[2].trim());
      if (source.isEmpty || target.isEmpty || value == null) continue;

      for (final name in [source, target]) {
        if (seen.add(name)) nodes.add(name);
      }
      links.add(SankeyLink(source: source, target: target, value: value));
    }

    if (links.isEmpty) return null;

    return (
      MermaidDiagramData(
        type: DiagramType.sankey,
        nodes: const [],
        edges: const [],
        ),
      SankeyChartData(nodes: nodes, links: links),
    );
  }

  /// Splits one CSV row.
  ///
  /// A plain `split(',')` would cut through `"Agricultural, waste"`, which the
  /// upstream example file relies on, so quotes are tracked and a doubled `""`
  /// inside them is one literal quote.
  List<String> _splitCsv(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];

      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
          continue;
        }
        buffer.write(c);
        continue;
      }

      if (c == '"') {
        inQuotes = true;
        continue;
      }
      if (c == ',') {
        fields.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(c);
    }

    fields.add(buffer.toString());
    return fields;
  }

}
